#!/bin/bash

##############################################################################
# 安全组高危规则批量扫描脚本
# 功能：扫描指定区域所有安全组，检测对 0.0.0.0/0 或 ::/0 开放的高危端口
#       包含 SSH(22)、RDP(3389)、数据库端口、Redis 等常见高危端口
#
# 用法：./batch_query_sg_rules.sh [REGION] [--all-regions]
#
# 说明：AWS 安全组规则查询需要两步：
#   1. describe-security-groups 获取规则
#   2. 检测哪些规则对 0.0.0.0/0 开放了敏感端口
# 数量大时需要分页，且需要应用诊断规则判断高危性，单条命令难以完成。
#
# 输出：结果保存到 aws_memos/tmp/sg_audit_<REGION>_<日期时间>.json
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

# 高危端口定义
HIGH_RISK_PORTS=(22 3389 3306 5432 6379 27017 11211 9200 5601 8080 8443 2375 2376)
HIGH_RISK_PORT_NAMES=(
    "SSH" "RDP" "MySQL" "PostgreSQL" "Redis" "MongoDB"
    "Memcached" "Elasticsearch" "Kibana" "HTTP-Alt" "HTTPS-Alt"
    "Docker" "Docker-TLS"
)

show_help() {
    echo "用法: $0 [REGION] [--all-regions]"
    echo ""
    echo "参数说明:"
    echo "  REGION        - 可选，AWS 区域（默认：ap-southeast-1）"
    echo "  --all-regions - 可选，扫描所有区域（覆盖 REGION 参数）"
    echo ""
    echo "示例:"
    echo "  $0                        # 扫描默认区域"
    echo "  $0 us-east-1              # 扫描指定区域"
    echo "  $0 --all-regions          # 扫描所有区域"
    echo ""
    echo "检测的高危端口: ${HIGH_RISK_PORTS[*]}"
    echo "输出文件: $OUTPUT_DIR/sg_audit_<region>_<日期时间>.json"
}

# 解析参数
REGION="ap-southeast-1"
ALL_REGIONS=false

for arg in "$@"; do
    case $arg in
        --all-regions) ALL_REGIONS=true ;;
        --help|-h) show_help; exit 0 ;;
        *) REGION="$arg" ;;
    esac
done

mkdir -p "$OUTPUT_DIR"

# 检查端口是否为高危端口（返回端口名称或空）
get_risk_port_name() {
    local port=$1
    for i in "${!HIGH_RISK_PORTS[@]}"; do
        if [ "${HIGH_RISK_PORTS[$i]}" -eq "$port" ] 2>/dev/null; then
            echo "${HIGH_RISK_PORT_NAMES[$i]}"
            return 0
        fi
    done
    echo ""
}

# 扫描单个区域
scan_region() {
    local region=$1
    local output_file="$OUTPUT_DIR/sg_audit_${region}_${CURRENT_DATE}_${CURRENT_TIME}.json"

    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  扫描区域: $region${NC}"
    echo -e "${BLUE}========================================${NC}"

    # 获取该区域所有安全组
    echo -e "${YELLOW}[1/2] 获取安全组列表...${NC}"

    ALL_SGS=$(aws ec2 describe-security-groups \
        --profile "$PROFILE" \
        --region "$region" \
        --query 'SecurityGroups[*]' \
        2>/dev/null)

    if [ $? -ne 0 ] || [ -z "$ALL_SGS" ] || [ "$ALL_SGS" = "[]" ]; then
        echo -e "  ${YELLOW}该区域无安全组或无权限访问${NC}"
        return
    fi

    SG_COUNT=$(echo "$ALL_SGS" | jq 'length')
    echo "  找到 $SG_COUNT 个安全组"

    # 分析每个安全组的规则
    echo -e "${YELLOW}[2/2] 分析高危规则...${NC}"

    TEMP_FINDINGS=$(mktemp)
    echo "[]" > "$TEMP_FINDINGS"

    RISK_COUNT=0

    echo "$ALL_SGS" | jq -c '.[]' | while IFS= read -r sg_json; do
        sg_id=$(echo "$sg_json" | jq -r '.GroupId')
        sg_name=$(echo "$sg_json" | jq -r '.GroupName')
        sg_desc=$(echo "$sg_json" | jq -r '.Description')
        vpc_id=$(echo "$sg_json" | jq -r '.VpcId // "classic"')

        # 检查入站规则（IpPermissions）
        RISK_RULES="[]"

        # 遍历 IPv4 规则
        while IFS= read -r rule_json; do
            [ -z "$rule_json" ] && continue

            from_port=$(echo "$rule_json" | jq -r '.FromPort // -1')
            to_port=$(echo "$rule_json" | jq -r '.ToPort // -1')
            proto=$(echo "$rule_json" | jq -r '.IpProtocol')

            # 检查是否对 0.0.0.0/0 或 ::/0 开放
            has_open_ipv4=$(echo "$rule_json" | jq -r '[.IpRanges[]? | select(.CidrIp == "0.0.0.0/0")] | length')
            has_open_ipv6=$(echo "$rule_json" | jq -r '[.Ipv6Ranges[]? | select(.CidrIpv6 == "::/0")] | length')

            if [ "$has_open_ipv4" -gt 0 ] || [ "$has_open_ipv6" -gt 0 ]; then
                # 全端口开放（proto=-1 或端口范围 0-65535）
                if [ "$proto" = "-1" ] || ([ "$from_port" -eq 0 ] && [ "$to_port" -eq 65535 ] 2>/dev/null); then
                    RISK_RULE=$(jq -n \
                        --arg proto "$proto" \
                        --arg from "$from_port" \
                        --arg to "$to_port" \
                        --arg severity "CRITICAL" \
                        --arg reason "所有端口对公网开放 (0.0.0.0/0)" \
                        '{Protocol: $proto, FromPort: $from, ToPort: $to, Severity: $severity, Reason: $reason}')
                    RISK_RULES=$(echo "$RISK_RULES" | jq --argjson rule "$RISK_RULE" '. + [$rule]')
                else
                    # 检查端口范围内是否含高危端口
                    for i in "${!HIGH_RISK_PORTS[@]}"; do
                        hport=${HIGH_RISK_PORTS[$i]}
                        hname=${HIGH_RISK_PORT_NAMES[$i]}
                        if [ "$from_port" -le "$hport" ] && [ "$to_port" -ge "$hport" ] 2>/dev/null; then
                            RISK_RULE=$(jq -n \
                                --arg proto "$proto" \
                                --arg from "$from_port" \
                                --arg to "$to_port" \
                                --arg port "$hport" \
                                --arg name "$hname" \
                                --arg severity "HIGH" \
                                --arg reason "${hname}端口(${hport})对公网开放 (0.0.0.0/0)" \
                                '{Protocol: $proto, FromPort: $from, ToPort: $to, RiskyPort: ($port | tonumber), PortName: $name, Severity: $severity, Reason: $reason}')
                            RISK_RULES=$(echo "$RISK_RULES" | jq --argjson rule "$RISK_RULE" '. + [$rule]')
                        fi
                    done
                fi
            fi

        done < <(echo "$sg_json" | jq -c '.IpPermissions[]?')

        # 如果有风险规则则记录
        RISK_RULE_COUNT=$(echo "$RISK_RULES" | jq 'length')
        if [ "$RISK_RULE_COUNT" -gt 0 ]; then
            FINDING=$(jq -n \
                --arg sg_id "$sg_id" \
                --arg sg_name "$sg_name" \
                --arg sg_desc "$sg_desc" \
                --arg vpc_id "$vpc_id" \
                --argjson risk_rules "$RISK_RULES" \
                '{
                    SecurityGroupId: $sg_id,
                    GroupName: $sg_name,
                    Description: $sg_desc,
                    VpcId: $vpc_id,
                    RiskRuleCount: ($risk_rules | length),
                    RiskRules: $risk_rules
                }')
            CURRENT=$(cat "$TEMP_FINDINGS")
            echo "$CURRENT" | jq --argjson item "$FINDING" '. + [$item]' > "$TEMP_FINDINGS"
            echo -e "  ${RED}⚠ $sg_name ($sg_id): $RISK_RULE_COUNT 条高危规则${NC}"
        fi

    done

    FINDINGS=$(cat "$TEMP_FINDINGS")
    RISK_SG_COUNT=$(echo "$FINDINGS" | jq 'length')

    # 生成报告
    jq -n \
        --arg region "$region" \
        --arg query_time "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        --argjson sg_total "$SG_COUNT" \
        --argjson risk_count "$RISK_SG_COUNT" \
        --argjson findings "$FINDINGS" \
        '{
            QueryTime: $query_time,
            Region: $region,
            Summary: {
                TotalSecurityGroups: $sg_total,
                RiskySecurityGroups: $risk_count,
                CleanSecurityGroups: ($sg_total - $risk_count)
            },
            RiskySecurityGroups: $findings
        }' > "$output_file"

    rm -f "$TEMP_FINDINGS"

    echo ""
    echo -e "${BLUE}📊 区域 $region 统计:${NC}"
    echo "  安全组总数: $SG_COUNT"
    if [ "$RISK_SG_COUNT" -gt 0 ]; then
        echo -e "  ${RED}⚠ 高危安全组: $RISK_SG_COUNT 个${NC}"
    else
        echo -e "  ${GREEN}✅ 未发现高危安全组${NC}"
    fi
    echo "  输出文件: $output_file"
}

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  AWS 安全组高危规则扫描工具${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "检测高危端口: ${HIGH_RISK_PORTS[*]}"
echo "检测条件: 入站规则来源为 0.0.0.0/0 或 ::/0"

if $ALL_REGIONS; then
    echo ""
    echo -e "${YELLOW}获取所有可用区域...${NC}"
    REGIONS=$(aws ec2 describe-regions \
        --profile "$PROFILE" \
        --query 'Regions[].RegionName' \
        --output text 2>/dev/null | tr '\t' '\n')

    REGION_COUNT=$(echo "$REGIONS" | wc -l | xargs)
    echo "找到 $REGION_COUNT 个区域"

    while IFS= read -r r; do
        [ -n "$r" ] && scan_region "$r"
    done <<< "$REGIONS"

    echo ""
    echo -e "${GREEN}所有区域扫描完成，结果文件保存在: $OUTPUT_DIR/${NC}"
else
    scan_region "$REGION"
fi
