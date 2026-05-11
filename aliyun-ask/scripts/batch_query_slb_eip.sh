#!/bin/bash

##############################################################################
# SLB EIP 关联批量查询脚本
# 功能：批量查询多个 SLB 实例是否有关联的 EIP（外网 IP）
# 用法：./batch_query_slb_eip.sh "<SLB_ID1>,<SLB_ID2>,..." [RegionId]
# 可选环境变量：ALIYUN_PROFILE=dingtalk-readonly
#
# 说明：关联了 EIP 即代表 SLB 对外网（internet）开放
# 输出：结果保存到 aliyun_memos/tmp/results_batch_slb_eip_<日期_时间>.json
##############################################################################

# 退出时遇到错误（但允许某些命令失败）
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
    echo "输出格式: JSON（保存到 $OUTPUT_DIR/results_batch_slb_eip_<日期_时间>.json）"
    echo "  {"
    echo "    \"LoadBalancerId\": \"lb-XXXXX\","
    echo "    \"LoadBalancerName\": \"XXXXXX\","
    echo "    \"HasEip\": \"是\" 或 \"否\","
    echo "    \"EipAddress\": \"47.xxx.xxx.xxx\" 或 \"\","
    echo "    \"EipId\": \"eip-xxxxx\" 或 \"\","
    echo "    \"InternetAccessible\": \"是\" 或 \"否\""
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
OUTPUT_FILE="$OUTPUT_DIR/results_batch_slb_eip_${CURRENT_DATE}_${CURRENT_TIME}.json"

# 临时文件存储所有结果
TEMP_RESULTS=$(mktemp)
> "$TEMP_RESULTS"

# 临时文件存储 EIP 信息
TEMP_EIP_INFO=$(mktemp)
> "$TEMP_EIP_INFO"

# 统计变量
TOTAL_SLBS=${#SLB_ID_ARRAY[@]}
SUCCESS_COUNT=0
FAILED_COUNT=0
FAILED_SLBS=()

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  SLB EIP 关联批量查询工具${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Profile: ${ALIYUN_PROFILE:-default}"
echo "地域: $REGION_ID"
echo "待查询 SLB 数量: $TOTAL_SLBS"
echo "输出文件: $OUTPUT_FILE"
echo ""

# 查询该地域所有 EIP 实例信息
echo -e "${BLUE}[1/2] 查询该地域所有 EIP 实例...${NC}"
ALL_EIPS=$("${ALIYUN_CMD[@]}" vpc DescribeEipAddresses \
    --RegionId "$REGION_ID" \
    --PageSize 100 \
    2>/dev/null)

if [ $? -ne 0 ] || [ -z "$ALL_EIPS" ]; then
    echo -e "${RED}警告: 无法查询 EIP 实例信息，将尝试从 SLB 属性判断${NC}"
    ALL_EIPS='{"EipAddresses": {"EipAddress": []}}'
fi

# 提取所有与 SLB 关联的 EIP 并保存到临时文件
echo "$ALL_EIPS" | jq -r '.EipAddresses.EipAddress[]? |
    select(.InstanceType == "SlbInstance") |
    "\(.InstanceId)|\(.AllocationId)|\(.IpAddress // "")"' 2>/dev/null > "$TEMP_EIP_INFO" || true

EIP_COUNT=$(wc -l < "$TEMP_EIP_INFO" | xargs)
echo -e "  ${GREEN}找到 $EIP_COUNT 个关联 SLB 的 EIP${NC}"
echo ""

# 处理每个 SLB 实例
echo -e "${BLUE}[2/2] 查询 SLB 实例并匹配 EIP...${NC}"
echo ""

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
        FAILED_COUNT=$((FAILED_COUNT + 1))
        FAILED_SLBS+=("$slb_id")
        echo ""
        continue
    fi

    SLB_NAME=$(echo "$SLB_INFO" | jq -r '.LoadBalancerName // "未命名"')
    ADDRESS_TYPE=$(echo "$SLB_INFO" | jq -r '.AddressType // ""')

    echo "  名称: $SLB_NAME"
    echo "  地址类型: $ADDRESS_TYPE"

    # 在 EIP 列表中查找匹配的 EIP
    EIP_INFO=$(grep "^${slb_id}|" "$TEMP_EIP_INFO" 2>/dev/null || true)

    if [ -n "$EIP_INFO" ]; then
        # 找到关联的 EIP
        EIP_ID=$(echo "$EIP_INFO" | cut -d'|' -f2)
        EIP_ADDRESS=$(echo "$EIP_INFO" | cut -d'|' -f3)
        HAS_EIP="是"
        INTERNET_ACCESSIBLE="是"

        echo -e "  ${GREEN}✓ 已关联 EIP${NC}"
        echo "    EIP ID: $EIP_ID"
        echo "    EIP 地址: $EIP_ADDRESS"
    else
        # 未找到关联的 EIP
        EIP_ID=""
        EIP_ADDRESS=""
        HAS_EIP="否"

        # 根据 AddressType 判断是否有公网类型
        # internet 表示公网类型，intranet 表示内网类型
        if [ "$ADDRESS_TYPE" = "internet" ]; then
            INTERNET_ACCESSIBLE="是"
            echo -e "  ${YELLOW}⚠ 公网类型但未绑定 EIP（可能有直接公网IP）${NC}"
        else
            INTERNET_ACCESSIBLE="否"
            echo -e "  ${GREEN}✓ 内网实例${NC}"
        fi
    fi

    # 生成 JSON 输出（不添加空行，保持纯 JSONL 格式）
    jq -n \
        --arg lb_id "$slb_id" \
        --arg lb_name "$SLB_NAME" \
        --arg has_eip "$HAS_EIP" \
        --arg eip_address "$EIP_ADDRESS" \
        --arg eip_id "$EIP_ID" \
        --arg internet_accessible "$INTERNET_ACCESSIBLE" \
        --arg address_type "$ADDRESS_TYPE" \
        '{
            LoadBalancerId: $lb_id,
            LoadBalancerName: $lb_name,
            HasEip: $has_eip,
            EipAddress: $eip_address,
            EipId: $eip_id,
            InternetAccessible: $internet_accessible,
            AddressType: $address_type
        }' >> "$TEMP_RESULTS"

    echo -e "  ${GREEN}✓ 查询完成${NC}"
    SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    echo ""
done

# 清理临时文件
rm -f "$TEMP_EIP_INFO"

# 将结果写入输出文件
cp "$TEMP_RESULTS" "$OUTPUT_FILE"
rm -f "$TEMP_RESULTS"

# 统计信息 - 使用 slurp 模式读取 JSONL
TOTAL_ENTRIES=$(jq -s 'length' "$OUTPUT_FILE" 2>/dev/null || echo "0")
HAS_EIP_COUNT=$(jq -s '[.[] | select(.HasEip == "是")] | length' "$OUTPUT_FILE" 2>/dev/null || echo "0")
INTERNET_COUNT=$(jq -s '[.[] | select(.InternetAccessible == "是")] | length' "$OUTPUT_FILE" 2>/dev/null || echo "0")

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
echo "  已关联 EIP 的 SLB: $HAS_EIP_COUNT"
echo "  外网可访问的 SLB: $INTERNET_COUNT"
echo ""

# 显示已关联 EIP 的列表
if [ $HAS_EIP_COUNT -gt 0 ]; then
    echo -e "${BLUE}📋 已关联 EIP 的 SLB 列表${NC}:"
    jq -r -s '.[] | select(.HasEip == "是") |
        "  \(.LoadBalancerId) (\(.LoadBalancerName)) → \(.EipAddress)"' "$OUTPUT_FILE"
    echo ""
fi
