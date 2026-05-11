#!/bin/bash

##############################################################################
# SLB 监听器 ACL 查询脚本
# 功能：根据 SLB ID 查询监听端口及关联的 ACL 信息
# 用法：./query_slb_acls.sh <SLB_ID> [RegionId]
# 可选环境变量：ALIYUN_PROFILE=dingtalk-readonly
##############################################################################

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 显示帮助信息
show_help() {
    echo "用法: $0 <SLB_ID> [RegionId]"
    echo ""
    echo "参数说明:"
    echo "  SLB_ID    - 必填，SLB 实例 ID（例如：lb-wz9fjlqmz0783y4vglx13）"
    echo "  RegionId  - 可选，地域 ID（默认：cn-beijing；ALIYUN_PROFILE=dingtalk-readonly 时默认：cn-zhangjiakou）"
    echo ""
    echo "示例:"
    echo "  $0 lb-wz9fjlqmz0783y4vglx13"
    echo "  $0 lb-wz9fjlqmz0783y4vglx13 cn-hangzhou"
    echo "  ALIYUN_PROFILE=dingtalk-readonly $0 lb-wz9fjlqmz0783y4vglx13"
    echo ""
    echo "输出格式: JSON"
    echo "  {"
    echo "    \"LoadBalancerId\": \"lb-XXXXX\","
    echo "    \"LoadBalancerName\": \"XXXXXX\","
    echo "    \"ListenerPort\": XXXXX,"
    echo "    \"Protocol\": \"XXXX\","
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

SLB_ID="$1"
DEFAULT_REGION_ID="cn-beijing"
if [ "${ALIYUN_PROFILE:-}" = "dingtalk-readonly" ]; then
    DEFAULT_REGION_ID="cn-zhangjiakou"
fi
REGION_ID="${2:-$DEFAULT_REGION_ID}"

ALIYUN_CMD=(aliyun)
if [ -n "${ALIYUN_PROFILE:-}" ]; then
    ALIYUN_CMD+=(--profile "$ALIYUN_PROFILE")
fi

# 验证 SLB ID 格式
if [[ ! "$SLB_ID" =~ ^lb-[a-z0-9]+$ ]]; then
    echo -e "${RED}错误: SLB ID 格式不正确${NC}"
    echo "正确格式示例: lb-wz9fjlqmz0783y4vglx13"
    exit 1
fi

echo -e "${GREEN}开始查询 SLB 监听器 ACL 信息${NC}"
echo "SLB ID: $SLB_ID"
echo "Profile: ${ALIYUN_PROFILE:-default}"
echo "地域: $REGION_ID"
echo ""

# 查询 SLB 基本信息
echo -e "${YELLOW}[1/2] 查询 SLB 实例信息...${NC}"
SLB_INFO=$("${ALIYUN_CMD[@]}" slb DescribeLoadBalancerAttribute --LoadBalancerId "$SLB_ID" --RegionId "$REGION_ID" 2>/dev/null)

if [ $? -ne 0 ]; then
    echo -e "${RED}错误: 无法查询 SLB 实例信息${NC}"
    echo "请检查:"
    echo "  1. SLB ID 是否正确"
    echo "  2. 地域 ID 是否正确"
    echo "  3. 是否有足够的权限"
    exit 1
fi

SLB_NAME=$(echo "$SLB_INFO" | jq -r '.LoadBalancerName // "未命名"')
echo "SLB 名称: $SLB_NAME"
echo ""

# 查询监听器配置及 ACL 信息
echo -e "${YELLOW}[2/2] 查询监听器 ACL 信息...${NC}"

# 使用 LoadBalancerId.1 数组格式查询
LISTENERS=$("${ALIYUN_CMD[@]}" slb DescribeLoadBalancerListeners \
    --LoadBalancerId.1 "$SLB_ID" \
    --RegionId "$REGION_ID" \
    2>/dev/null)

if [ $? -ne 0 ] || [ -z "$LISTENERS" ]; then
    echo -e "${RED}错误: 无法查询监听器信息${NC}"
    exit 1
fi

# 获取监听器数组
LISTENER_ARRAY=$(echo "$LISTENERS" | jq '.Listeners // []')
LISTENER_COUNT=$(echo "$LISTENER_ARRAY" | jq 'length')

if [ "$LISTENER_COUNT" -eq 0 ]; then
    echo -e "${YELLOW}警告: 该 SLB 实例没有监听器${NC}"
    exit 0
fi

echo -e "  成功获取 ${GREEN}$LISTENER_COUNT${NC} 个监听器"

# 生成 JSON 输出
echo "$LISTENER_ARRAY" | jq -r '.[] | {
    LoadBalancerId: "'"$SLB_ID"'",
    LoadBalancerName: "'"$SLB_NAME"'",
    ListenerPort: .ListenerPort,
    Protocol: .ListenerProtocol,
    AclStatus: (.AclStatus // "off"),
    AclType: (.AclType // ""),
    AclIds: (.AclIds // [])
}'

echo ""
echo -e "${GREEN}✅ 查询完成${NC}"
