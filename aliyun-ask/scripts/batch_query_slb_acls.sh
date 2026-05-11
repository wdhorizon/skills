#!/bin/bash

##############################################################################
# SLB 监听器 ACL 批量查询脚本
# 功能：批量查询多个 SLB 实例的监听端口及关联的 ACL 信息
# 用法：./batch_query_slb_acls.sh "lb-XXXXXXX,lb-YYYYYYY,lb-ZZZZZZZ" [RegionId]
# 可选环境变量：ALIYUN_PROFILE=dingtalk-readonly
#
# 输出：结果保存到 aliyun_memos/tmp/results_batch_slb_acls_<日期_时间>.json
##############################################################################

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 获取当前日期和时间
CURRENT_DATE=$(date +%Y%m%d)
CURRENT_TIME=$(date +%H%M%S)

# 输出目录
OUTPUT_DIR="./aliyun_memos/tmp"

# 显示帮助信息
show_help() {
    echo "用法: $0 \"<SLB_ID1>,<SLB_ID2>,...\" [RegionId]"
    echo ""
    echo "参数说明:"
    echo "  SLB_IDs  - 必填，多个 SLB 实例 ID，用逗号分隔"
    echo "             例如: \"lb-abc123,lb-def456,lb-ghi789\""
    echo "  RegionId - 可选，地域 ID（默认：cn-beijing；ALIYUN_PROFILE=dingtalk-readonly 时默认：cn-zhangjiakou）"
    echo ""
    echo "示例:"
    echo "  $0 \"lb-wz9fjlqmz0783y4vglx13,lb-abc123def456\""
    echo "  $0 \"lb-wz9fjlqmz0783y4vglx13,lb-abc123def456\" cn-hangzhou"
    echo "  ALIYUN_PROFILE=dingtalk-readonly $0 \"lb-wz9fjlqmz0783y4vglx13,lb-abc123def456\""
    echo ""
    echo "输出格式: JSON（保存到 $OUTPUT_DIR/results_batch_slb_acls_<日期_时间>.json）"
    echo "  {"
    echo "    \"LoadBalancerId\": \"lb-XXXXX\","
    echo "    \"LoadBalancerName\": \"XXXXXX\","
    echo "    \"ListenerPort\": XXXXX,"
    echo "    \"Protocol\": \"TCP\","
    echo "    \"AclStatus\": \"on\","
    echo "    \"AclType\": \"white\","
    echo "    \"AclIds\": [\"acl-xxxxx\"]"
    echo "  }"
}

# 检查参数
if [ $# -lt 1 ]; then
    echo -e "${RED}错误: 缺少必需参数${NC}"
    show_help
    exit 1
fi

# 解析输入参数
SLB_IDS_INPUT="$1"
DEFAULT_REGION_ID="cn-beijing"
if [ "${ALIYUN_PROFILE:-}" = "dingtalk-readonly" ]; then
    DEFAULT_REGION_ID="cn-zhangjiakou"
fi
REGION_ID="${2:-$DEFAULT_REGION_ID}"

ALIYUN_CMD=(aliyun)
if [ -n "${ALIYUN_PROFILE:-}" ]; then
    ALIYUN_CMD+=(--profile "$ALIYUN_PROFILE")
fi

# 验证输入不为空
if [ -z "$SLB_IDS_INPUT" ]; then
    echo -e "${RED}错误: SLB ID 列表不能为空${NC}"
    exit 1
fi

# 将逗号分隔的 SLB IDs 转换为数组
IFS=',' read -ra SLB_ID_ARRAY <<< "$SLB_IDS_INPUT"

# 验证至少有一个 SLB ID
if [ ${#SLB_ID_ARRAY[@]} -eq 0 ]; then
    echo -e "${RED}错误: 未找到有效的 SLB ID${NC}"
    exit 1
fi

# 验证每个 SLB ID 格式
for slb_id in "${SLB_ID_ARRAY[@]}"; do
    # 去除空格
    slb_id=$(echo "$slb_id" | xargs)
    if [[ ! "$slb_id" =~ ^lb-[a-z0-9]+$ ]]; then
        echo -e "${RED}错误: SLB ID 格式不正确: $slb_id${NC}"
        echo "正确格式示例: lb-wz9fjlqmz0783y4vglx13"
        exit 1
    fi
done

# 创建输出目录
mkdir -p "$OUTPUT_DIR"

# 输出文件路径
OUTPUT_FILE="$OUTPUT_DIR/results_batch_slb_acls_${CURRENT_DATE}_${CURRENT_TIME}.json"

# 临时文件存储所有结果
TEMP_RESULTS=$(mktemp)
> "$TEMP_RESULTS"

# 统计变量
TOTAL_SLBS=${#SLB_ID_ARRAY[@]}
SUCCESS_COUNT=0
FAILED_COUNT=0
FAILED_SLBS=()

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  SLB ACL 批量查询工具${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Profile: ${ALIYUN_PROFILE:-default}"
echo "地域: $REGION_ID"
echo "待查询 SLB 数量: $TOTAL_SLBS"
echo "输出文件: $OUTPUT_FILE"
echo ""

# 处理每个 SLB 实例
for slb_id in "${SLB_ID_ARRAY[@]}"; do
    # 去除空格
    slb_id=$(echo "$slb_id" | xargs)

    echo -e "${YELLOW}[$((SUCCESS_COUNT + FAILED_COUNT + 1))/$TOTAL_SLBS] 查询 SLB: $slb_id${NC}"

    # 查询 SLB 基本信息
    SLB_INFO=$("${ALIYUN_CMD[@]}" slb DescribeLoadBalancerAttribute \
        --LoadBalancerId "$slb_id" \
        --RegionId "$REGION_ID" \
        2>/dev/null)

    if [ $? -ne 0 ] || [ -z "$SLB_INFO" ]; then
        echo -e "  ${RED}✗ 无法查询 SLB 实例信息${NC}"
        ((FAILED_COUNT++))
        FAILED_SLBS+=("$slb_id")
        echo ""
        continue
    fi

    SLB_NAME=$(echo "$SLB_INFO" | jq -r '.LoadBalancerName // "未命名"')
    echo "  名称: $SLB_NAME"

    # 查询监听器
    LISTENERS=$("${ALIYUN_CMD[@]}" slb DescribeLoadBalancerListeners \
        --LoadBalancerId.1 "$slb_id" \
        --RegionId "$REGION_ID" \
        2>/dev/null)

    if [ $? -ne 0 ] || [ -z "$LISTENERS" ]; then
        echo -e "  ${RED}✗ 无法查询监听器信息${NC}"
        ((FAILED_COUNT++))
        FAILED_SLBS+=("$slb_id")
        echo ""
        continue
    fi

    LISTENER_ARRAY=$(echo "$LISTENERS" | jq '.Listeners // []')
    LISTENER_COUNT=$(echo "$LISTENER_ARRAY" | jq 'length')

    if [ "$LISTENER_COUNT" -eq 0 ]; then
        echo -e "  ${YELLOW}无监听器${NC}"
        ((SUCCESS_COUNT++))
        echo ""
        continue
    fi

    echo "  监听器: $LISTENER_COUNT 个"

    # 使用 jq 处理每个监听器并直接输出到临时文件
    echo "$LISTENER_ARRAY" | jq -c '.[]' | while IFS= read -r listener_json; do
        [ -z "$listener_json" ] && continue

        listener_port=$(echo "$listener_json" | jq -r '.ListenerPort // "0"')
        protocol=$(echo "$listener_json" | jq -r '.ListenerProtocol // "unknown"')
        acl_status=$(echo "$listener_json" | jq -r '.AclStatus // "off"')
        acl_type=$(echo "$listener_json" | jq -r '.AclType // ""')

        # 获取 ACL IDs
        acl_ids_array=$(echo "$listener_json" | jq -r '.AclIds // []')

        # 生成 JSON 输出
        jq -n \
            --arg lb_id "$slb_id" \
            --arg lb_name "$SLB_NAME" \
            --arg port "$listener_port" \
            --arg proto "$protocol" \
            --arg status "$acl_status" \
            --arg type "$acl_type" \
            --argjson acl_ids "$acl_ids_array" \
            '{
                LoadBalancerId: $lb_id,
                LoadBalancerName: $lb_name,
                ListenerPort: ($port | tonumber),
                Protocol: $proto,
                AclStatus: $status,
                AclType: $type,
                AclIds: $acl_ids
            }' >> "$TEMP_RESULTS"
        echo "" >> "$TEMP_RESULTS"
    done

    echo -e "  ${GREEN}✓ 查询完成${NC}"
    ((SUCCESS_COUNT++))
    echo ""
done

# 将结果写入输出文件
cp "$TEMP_RESULTS" "$OUTPUT_FILE"
rm -f "$TEMP_RESULTS"

# 统计信息 - 使用 jq 计算实际对象数量
TOTAL_ENTRIES=$(jq -s 'length' "$OUTPUT_FILE" 2>/dev/null || echo "0")
HAS_ACL_COUNT=$(jq -s '[.[] | select(.AclIds != null and (.AclIds | length) > 0)] | length' "$OUTPUT_FILE" 2>/dev/null || echo "0")

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  查询完成${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "输出文件: $OUTPUT_FILE"
echo ""
echo -e "${BLUE}📊 统计信息${NC}:"
echo "  SLB 实例总数: $TOTAL_SLBS"
echo "  查询成功: $SUCCESS_COUNT"
echo "  查询失败: $FAILED_COUNT"

if [ $FAILED_COUNT -gt 0 ]; then
    echo ""
    echo -e "${RED}失败的 SLB 实例${NC}:"
    for failed_slb in "${FAILED_SLBS[@]}"; do
        echo "  - $failed_slb"
    done
fi

echo ""
echo "  监听配置总数: $TOTAL_ENTRIES"
echo "  配置了 ACL 的监听器: $HAS_ACL_COUNT"
echo ""
