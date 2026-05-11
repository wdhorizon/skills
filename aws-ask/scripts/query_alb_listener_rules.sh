#!/bin/bash

##############################################################################
# ALB 监听器规则与目标组查询脚本
# 功能：根据 ALB ARN 或名称，查询所有监听器的转发规则及后端目标组详情
#       包含目标组健康状态，适合排查 ALB 流量转发问题
#
# 用法：./query_alb_listener_rules.sh <ALB_ARN_OR_NAME> [REGION]
#
# 说明：ALB 的规则查询需要多步骤：
#   1. 通过 ALB ARN/名称 获取监听器列表
#   2. 逐个监听器查询转发规则
#   3. 提取规则中的目标组 ARN
#   4. 查询目标组详情及健康状态
# 这是 AWS SDK 中典型的多跳关联查询，无法用单条命令完成。
#
# 输出：结果保存到 aws_memos/tmp/alb_rules_<ALB名称>_<日期时间>.json
##############################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PROFILE="devops-readonly"
CURRENT_DATE=$(date +%Y%m%d)
CURRENT_TIME=$(date +%H%M%S)
OUTPUT_DIR="./aws_memos/tmp"

show_help() {
    echo "用法: $0 <ALB_ARN_OR_NAME> [REGION]"
    echo ""
    echo "参数说明:"
    echo "  ALB_ARN_OR_NAME  - ALB 的 ARN 或名称"
    echo "                     ARN 示例: arn:aws:elasticloadbalancing:ap-southeast-1:123456789012:loadbalancer/app/my-alb/abc123"
    echo "                     名称示例: my-alb"
    echo "  REGION           - 可选，AWS 区域（默认：ap-southeast-1）"
    echo ""
    echo "示例:"
    echo "  $0 my-alb"
    echo "  $0 my-alb us-east-1"
    echo "  $0 arn:aws:elasticloadbalancing:ap-southeast-1:123456789012:loadbalancer/app/my-alb/abc123"
    echo ""
    echo "输出文件: $OUTPUT_DIR/alb_rules_<名称>_<日期时间>.json"
}

if [ $# -lt 1 ]; then
    echo -e "${RED}错误: 缺少必需参数${NC}"
    show_help
    exit 1
fi

ALB_INPUT="$1"
REGION="${2:-ap-southeast-1}"

mkdir -p "$OUTPUT_DIR"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  ALB 监听器规则与目标组查询工具${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "输入: $ALB_INPUT"
echo "区域: $REGION"
echo ""

# 第一步：获取 ALB 详情（支持 ARN 或名称输入）
echo -e "${YELLOW}[1/4] 获取 ALB 基本信息...${NC}"

if [[ "$ALB_INPUT" == arn:* ]]; then
    ALB_INFO=$(aws elbv2 describe-load-balancers \
        --load-balancer-arns "$ALB_INPUT" \
        --profile "$PROFILE" --region "$REGION" 2>/dev/null)
else
    ALB_INFO=$(aws elbv2 describe-load-balancers \
        --names "$ALB_INPUT" \
        --profile "$PROFILE" --region "$REGION" 2>/dev/null)
fi

if [ $? -ne 0 ] || [ -z "$ALB_INFO" ]; then
    echo -e "${RED}错误: 找不到 ALB '$ALB_INPUT'，请检查名称/ARN 和区域是否正确${NC}"
    exit 1
fi

ALB_ARN=$(echo "$ALB_INFO" | jq -r '.LoadBalancers[0].LoadBalancerArn')
ALB_NAME=$(echo "$ALB_INFO" | jq -r '.LoadBalancers[0].LoadBalancerName')
ALB_DNS=$(echo "$ALB_INFO" | jq -r '.LoadBalancers[0].DNSName')
ALB_STATE=$(echo "$ALB_INFO" | jq -r '.LoadBalancers[0].State.Code')
ALB_SCHEME=$(echo "$ALB_INFO" | jq -r '.LoadBalancers[0].Scheme')

echo "  名称: $ALB_NAME"
echo "  状态: $ALB_STATE"
echo "  类型: $ALB_SCHEME"
echo "  DNS: $ALB_DNS"

OUTPUT_FILE="$OUTPUT_DIR/alb_rules_${ALB_NAME}_${CURRENT_DATE}_${CURRENT_TIME}.json"

# 第二步：获取监听器列表
echo ""
echo -e "${YELLOW}[2/4] 获取监听器列表...${NC}"

LISTENERS=$(aws elbv2 describe-listeners \
    --load-balancer-arn "$ALB_ARN" \
    --profile "$PROFILE" --region "$REGION" 2>/dev/null)

LISTENER_COUNT=$(echo "$LISTENERS" | jq '.Listeners | length')
echo "  找到 $LISTENER_COUNT 个监听器"

if [ "$LISTENER_COUNT" -eq 0 ]; then
    echo -e "${YELLOW}该 ALB 没有监听器${NC}"
    exit 0
fi

# 第三步：逐个监听器查询转发规则
echo ""
echo -e "${YELLOW}[3/4] 查询各监听器转发规则...${NC}"

# 临时文件存放所有规则数据
TEMP_RULES=$(mktemp)
echo "[]" > "$TEMP_RULES"

# 收集所有目标组 ARN（用于第四步批量查询）
TARGET_GROUP_ARNS=()

echo "$LISTENERS" | jq -c '.Listeners[]' | while IFS= read -r listener_json; do
    listener_arn=$(echo "$listener_json" | jq -r '.ListenerArn')
    listener_port=$(echo "$listener_json" | jq -r '.Port')
    listener_proto=$(echo "$listener_json" | jq -r '.Protocol')

    echo -e "  查询 $listener_proto:$listener_port 监听器规则..."

    RULES=$(aws elbv2 describe-rules \
        --listener-arn "$listener_arn" \
        --profile "$PROFILE" --region "$REGION" 2>/dev/null)

    RULE_COUNT=$(echo "$RULES" | jq '.Rules | length')

    # 提取此监听器下的目标组 ARN
    TG_ARNS=$(echo "$RULES" | jq -r '.Rules[].Actions[].TargetGroupArn? // empty' | sort -u)

    # 构建监听器+规则对象并追加到临时文件
    LISTENER_WITH_RULES=$(jq -n \
        --arg arn "$listener_arn" \
        --arg port "$listener_port" \
        --arg proto "$listener_proto" \
        --argjson rules "$(echo "$RULES" | jq '.Rules')" \
        '{
            ListenerArn: $arn,
            Port: ($port | tonumber),
            Protocol: $proto,
            RuleCount: ($rules | length),
            Rules: $rules
        }')

    # 追加到结果数组
    CURRENT=$(cat "$TEMP_RULES")
    echo "$CURRENT" | jq --argjson item "$LISTENER_WITH_RULES" '. + [$item]' > "$TEMP_RULES"

    echo -e "    ${GREEN}✓ 找到 $RULE_COUNT 条规则${NC}"
done

# 第四步：查询目标组及健康状态
echo ""
echo -e "${YELLOW}[4/4] 查询目标组健康状态...${NC}"

# 获取所有涉及的目标组 ARN（从规则中提取）
ALL_TG_ARNS=$(cat "$TEMP_RULES" | \
    jq -r '.[].Rules[].Actions[].TargetGroupArn? // empty' | \
    sort -u | grep -v '^$' || true)

TG_COUNT=$(echo "$ALL_TG_ARNS" | grep -c . || echo 0)
echo "  涉及 $TG_COUNT 个目标组"

TEMP_TG_HEALTH=$(mktemp)
echo "{}" > "$TEMP_TG_HEALTH"

if [ -n "$ALL_TG_ARNS" ] && [ "$TG_COUNT" -gt 0 ]; then
    while IFS= read -r tg_arn; do
        [ -z "$tg_arn" ] && continue

        # 查询目标组基本信息
        TG_INFO=$(aws elbv2 describe-target-groups \
            --target-group-arns "$tg_arn" \
            --profile "$PROFILE" --region "$REGION" 2>/dev/null | \
            jq '.TargetGroups[0]')

        TG_NAME=$(echo "$TG_INFO" | jq -r '.TargetGroupName')
        TG_PROTO=$(echo "$TG_INFO" | jq -r '.Protocol')
        TG_PORT=$(echo "$TG_INFO" | jq -r '.Port')

        # 查询目标健康状态
        HEALTH=$(aws elbv2 describe-target-health \
            --target-group-arn "$tg_arn" \
            --profile "$PROFILE" --region "$REGION" 2>/dev/null)

        HEALTHY=$(echo "$HEALTH" | jq '[.TargetHealthDescriptions[] | select(.TargetHealth.State == "healthy")] | length')
        UNHEALTHY=$(echo "$HEALTH" | jq '[.TargetHealthDescriptions[] | select(.TargetHealth.State != "healthy")] | length')
        TOTAL=$(echo "$HEALTH" | jq '.TargetHealthDescriptions | length')

        # 状态标识
        if [ "$UNHEALTHY" -gt 0 ]; then
            STATUS_ICON="⚠️"
        else
            STATUS_ICON="✅"
        fi
        echo "  $STATUS_ICON $TG_NAME: $HEALTHY/$TOTAL 健康"

        TG_DETAIL=$(jq -n \
            --arg arn "$tg_arn" \
            --arg name "$TG_NAME" \
            --arg proto "$TG_PROTO" \
            --argjson port "$TG_PORT" \
            --argjson healthy "$HEALTHY" \
            --argjson unhealthy "$UNHEALTHY" \
            --argjson total "$TOTAL" \
            --argjson targets "$(echo "$HEALTH" | jq '.TargetHealthDescriptions')" \
            '{
                TargetGroupArn: $arn,
                TargetGroupName: $name,
                Protocol: $proto,
                Port: $port,
                HealthySummary: {Healthy: $healthy, Unhealthy: $unhealthy, Total: $total},
                Targets: $targets
            }')

        CURRENT_TG=$(cat "$TEMP_TG_HEALTH")
        echo "$CURRENT_TG" | jq --arg key "$tg_arn" --argjson val "$TG_DETAIL" '. + {($key): $val}' > "$TEMP_TG_HEALTH"

    done <<< "$ALL_TG_ARNS"
fi

# 生成最终输出
echo ""
echo -e "${BLUE}生成查询报告...${NC}"

LISTENERS_DATA=$(cat "$TEMP_RULES")
TG_HEALTH_DATA=$(cat "$TEMP_TG_HEALTH")

jq -n \
    --arg alb_arn "$ALB_ARN" \
    --arg alb_name "$ALB_NAME" \
    --arg alb_dns "$ALB_DNS" \
    --arg alb_state "$ALB_STATE" \
    --arg alb_scheme "$ALB_SCHEME" \
    --arg region "$REGION" \
    --arg query_time "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --argjson listeners "$LISTENERS_DATA" \
    --argjson target_groups "$TG_HEALTH_DATA" \
    '{
        QueryTime: $query_time,
        Region: $region,
        LoadBalancer: {
            LoadBalancerArn: $alb_arn,
            LoadBalancerName: $alb_name,
            DNSName: $alb_dns,
            State: $alb_state,
            Scheme: $alb_scheme
        },
        Listeners: $listeners,
        TargetGroups: $target_groups
    }' > "$OUTPUT_FILE"

rm -f "$TEMP_RULES" "$TEMP_TG_HEALTH"

# 统计汇总
TOTAL_RULES=$(jq '[.Listeners[].RuleCount] | add // 0' "$OUTPUT_FILE")
TOTAL_TG=$(jq '.TargetGroups | length' "$OUTPUT_FILE")
UNHEALTHY_TG=$(jq '[.TargetGroups[] | select(.HealthySummary.Unhealthy > 0)] | length' "$OUTPUT_FILE")

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  查询完成${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "输出文件: $OUTPUT_FILE"
echo ""
echo -e "${BLUE}📊 统计信息:${NC}"
echo "  监听器数量: $LISTENER_COUNT"
echo "  转发规则总数: $TOTAL_RULES"
echo "  目标组数量: $TOTAL_TG"
if [ "$UNHEALTHY_TG" -gt 0 ]; then
    echo -e "  ${RED}⚠ 存在不健康的目标组: $UNHEALTHY_TG 个${NC}"
else
    echo -e "  ${GREEN}✅ 所有目标组健康${NC}"
fi
echo ""
