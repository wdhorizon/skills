#!/bin/bash

##############################################################################
# EC2 实例公网 IP / EIP 关联批量查询脚本
# 功能：批量查询 EC2 实例的公网访问情况：
#   - 是否分配了弹性公网 IP（EIP）
#   - 是否有临时公网 IP（非固定，重启会变）
#   - EIP 的分配信息（AllocationId、绑定时间）
#
# 用法：./batch_query_ec2_eip.sh [REGION] [--filter-public]
#
# 说明：EC2 实例的 EIP 关联查询需要两步：
#   1. describe-instances 获取实例及其 PublicIpAddress / NetworkInterfaces
#   2. describe-addresses 获取 EIP 列表，再通过 InstanceId 匹配
#   直接从实例信息无法区分 EIP（固定）和临时公网 IP，必须交叉查询。
#
# 输出：结果保存到 aws_memos/tmp/ec2_eip_<REGION>_<日期时间>.json
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
    echo "用法: $0 [REGION] [--filter-public]"
    echo ""
    echo "参数说明:"
    echo "  REGION          - 可选，AWS 区域（默认：ap-southeast-1）"
    echo "  --filter-public - 可选，仅输出有公网 IP 的实例"
    echo ""
    echo "示例:"
    echo "  $0                           # 查询默认区域所有实例"
    echo "  $0 us-east-1                 # 查询指定区域"
    echo "  $0 ap-southeast-1 --filter-public  # 仅显示有公网 IP 的实例"
    echo ""
    echo "输出字段说明:"
    echo "  HasEIP           - 是否绑定了弹性公网 IP（固定 IP，重启不变）"
    echo "  HasPublicIP      - 是否有公网 IP（包含临时公网 IP）"
    echo "  PublicIpAddress  - 当前公网 IP（EIP 或临时）"
    echo "  EipAllocationId  - EIP 的分配 ID（仅 EIP 有）"
    echo ""
    echo "输出文件: $OUTPUT_DIR/ec2_eip_<region>_<日期时间>.json"
}

# 解析参数
REGION="ap-southeast-1"
FILTER_PUBLIC=false

for arg in "$@"; do
    case $arg in
        --filter-public) FILTER_PUBLIC=true ;;
        --help|-h) show_help; exit 0 ;;
        *) REGION="$arg" ;;
    esac
done

mkdir -p "$OUTPUT_DIR"
OUTPUT_FILE="$OUTPUT_DIR/ec2_eip_${REGION}_${CURRENT_DATE}_${CURRENT_TIME}.json"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  EC2 公网 IP / EIP 批量查询工具${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "区域: $REGION"
$FILTER_PUBLIC && echo "过滤: 仅显示有公网 IP 的实例"
echo ""

# 第一步：获取所有 EC2 实例
echo -e "${YELLOW}[1/3] 获取 EC2 实例列表...${NC}"

ALL_INSTANCES=$(aws ec2 describe-instances \
    --profile "$PROFILE" \
    --region "$REGION" \
    --query 'Reservations[*].Instances[*]' \
    --output json 2>/dev/null | jq 'flatten')

if [ $? -ne 0 ] || [ -z "$ALL_INSTANCES" ] || [ "$ALL_INSTANCES" = "[]" ]; then
    echo -e "${YELLOW}该区域无 EC2 实例${NC}"
    exit 0
fi

INSTANCE_COUNT=$(echo "$ALL_INSTANCES" | jq 'length')
echo "  找到 $INSTANCE_COUNT 个实例"

# 第二步：获取所有 EIP 信息（一次性拉取，用于后续匹配）
echo ""
echo -e "${YELLOW}[2/3] 获取 EIP 列表...${NC}"

ALL_EIPS=$(aws ec2 describe-addresses \
    --profile "$PROFILE" \
    --region "$REGION" 2>/dev/null)

EIP_COUNT=$(echo "$ALL_EIPS" | jq '.Addresses | length')
echo "  找到 $EIP_COUNT 个 EIP"

# 建立 EIP 映射：InstanceId -> EIP 信息（保存到临时文件）
TEMP_EIP_MAP=$(mktemp)
echo "{}" > "$TEMP_EIP_MAP"

echo "$ALL_EIPS" | jq -c '.Addresses[] | select(.InstanceId != null)' | while IFS= read -r eip_json; do
    instance_id=$(echo "$eip_json" | jq -r '.InstanceId')
    allocation_id=$(echo "$eip_json" | jq -r '.AllocationId')
    public_ip=$(echo "$eip_json" | jq -r '.PublicIp')
    association_id=$(echo "$eip_json" | jq -r '.AssociationId // ""')

    EIP_ENTRY=$(jq -n \
        --arg alloc "$allocation_id" \
        --arg ip "$public_ip" \
        --arg assoc "$association_id" \
        '{AllocationId: $alloc, PublicIp: $ip, AssociationId: $assoc}')

    CURRENT=$(cat "$TEMP_EIP_MAP")
    echo "$CURRENT" | jq --arg key "$instance_id" --argjson val "$EIP_ENTRY" '. + {($key): $val}' > "$TEMP_EIP_MAP"
done

EIP_MAP=$(cat "$TEMP_EIP_MAP")
rm -f "$TEMP_EIP_MAP"

# 第三步：匹配并生成结果
echo ""
echo -e "${YELLOW}[3/3] 匹配 EIP 关联关系...${NC}"

TEMP_RESULTS=$(mktemp)
echo "[]" > "$TEMP_RESULTS"

EIP_COUNT_ACTUAL=0
PUBLIC_IP_COUNT=0
NO_PUBLIC_COUNT=0

echo "$ALL_INSTANCES" | jq -c '.[]' | while IFS= read -r inst_json; do
    instance_id=$(echo "$inst_json" | jq -r '.InstanceId')
    instance_name=$(echo "$inst_json" | jq -r '(.Tags // [] | map(select(.Key == "Name")) | first | .Value) // "N/A"')
    instance_type=$(echo "$inst_json" | jq -r '.InstanceType')
    instance_state=$(echo "$inst_json" | jq -r '.State.Name')
    private_ip=$(echo "$inst_json" | jq -r '.PrivateIpAddress // ""')
    public_ip=$(echo "$inst_json" | jq -r '.PublicIpAddress // ""')
    vpc_id=$(echo "$inst_json" | jq -r '.VpcId // "classic"')
    subnet_id=$(echo "$inst_json" | jq -r '.SubnetId // ""')

    # 从 EIP 映射中查找
    EIP_INFO=$(echo "$EIP_MAP" | jq --arg id "$instance_id" '.[$id] // null')

    if [ "$EIP_INFO" != "null" ] && [ -n "$EIP_INFO" ]; then
        HAS_EIP="true"
        EIP_ALLOC_ID=$(echo "$EIP_INFO" | jq -r '.AllocationId')
        EIP_IP=$(echo "$EIP_INFO" | jq -r '.PublicIp')
        # 如果有 EIP，public_ip 就是 EIP
        PUBLIC_IP_FINAL="$EIP_IP"
    else
        HAS_EIP="false"
        EIP_ALLOC_ID=""
        PUBLIC_IP_FINAL="$public_ip"
    fi

    HAS_PUBLIC_IP="false"
    [ -n "$PUBLIC_IP_FINAL" ] && HAS_PUBLIC_IP="true"

    # 过滤模式：跳过无公网 IP 的实例
    if $FILTER_PUBLIC && [ "$HAS_PUBLIC_IP" = "false" ]; then
        continue
    fi

    RESULT=$(jq -n \
        --arg id "$instance_id" \
        --arg name "$instance_name" \
        --arg type "$instance_type" \
        --arg state "$instance_state" \
        --arg private_ip "$private_ip" \
        --arg public_ip "$PUBLIC_IP_FINAL" \
        --arg has_eip "$HAS_EIP" \
        --arg has_public "$HAS_PUBLIC_IP" \
        --arg eip_alloc "$EIP_ALLOC_ID" \
        --arg vpc "$vpc_id" \
        --arg subnet "$subnet_id" \
        '{
            InstanceId: $id,
            Name: $name,
            InstanceType: $type,
            State: $state,
            PrivateIpAddress: $private_ip,
            PublicIpAddress: $public_ip,
            HasEIP: ($has_eip == "true"),
            HasPublicIP: ($has_public == "true"),
            EipAllocationId: $eip_alloc,
            VpcId: $vpc,
            SubnetId: $subnet
        }')

    CURRENT=$(cat "$TEMP_RESULTS")
    echo "$CURRENT" | jq --argjson item "$RESULT" '. + [$item]' > "$TEMP_RESULTS"
done

RESULTS=$(cat "$TEMP_RESULTS")
rm -f "$TEMP_RESULTS"

# 统计
TOTAL=$(echo "$RESULTS" | jq 'length')
HAS_EIP_COUNT=$(echo "$RESULTS" | jq '[.[] | select(.HasEIP == true)] | length')
HAS_PUBLIC_COUNT=$(echo "$RESULTS" | jq '[.[] | select(.HasPublicIP == true)] | length')
TEMP_PUBLIC_COUNT=$(echo "$RESULTS" | jq '[.[] | select(.HasPublicIP == true and .HasEIP == false)] | length')
NO_PUBLIC=$(echo "$RESULTS" | jq '[.[] | select(.HasPublicIP == false)] | length')

# 生成最终报告
jq -n \
    --arg region "$REGION" \
    --arg query_time "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --argjson total "$TOTAL" \
    --argjson has_eip "$HAS_EIP_COUNT" \
    --argjson has_public "$HAS_PUBLIC_COUNT" \
    --argjson temp_public "$TEMP_PUBLIC_COUNT" \
    --argjson no_public "$NO_PUBLIC" \
    --argjson instances "$RESULTS" \
    '{
        QueryTime: $query_time,
        Region: $region,
        Summary: {
            TotalInstances: $total,
            HasEIP: $has_eip,
            HasTemporaryPublicIP: $temp_public,
            HasAnyPublicIP: $has_public,
            NoPublicIP: $no_public
        },
        Instances: $instances
    }' > "$OUTPUT_FILE"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  查询完成${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "输出文件: $OUTPUT_FILE"
echo ""
echo -e "${BLUE}📊 统计信息:${NC}"
echo "  实例总数: $TOTAL"
echo "  绑定 EIP（固定公网 IP）: $HAS_EIP_COUNT"
echo "  仅有临时公网 IP: $TEMP_PUBLIC_COUNT"
echo "  无公网 IP（纯内网）: $NO_PUBLIC"
echo ""

# 打印有公网 IP 的实例列表
if [ "$HAS_PUBLIC_COUNT" -gt 0 ]; then
    echo -e "${BLUE}📋 有公网 IP 的实例:${NC}"
    echo "$RESULTS" | jq -r '.[] | select(.HasPublicIP == true) |
        "  \(.InstanceId) (\(.Name)) \(.State) → \(.PublicIpAddress)\(if .HasEIP then " [EIP: \(.EipAllocationId)]" else " [临时IP]" end)"'
    echo ""
fi
