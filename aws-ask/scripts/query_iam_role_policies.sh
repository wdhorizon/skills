#!/bin/bash

##############################################################################
# IAM Role 完整权限链查询脚本
# 功能：查询 IAM Role 的完整权限链，包括：
#   - 信任策略（哪些实体可以假设此角色）
#   - 所有附加的托管策略及其权限
#   - 内联策略及其权限
#   - 权限边界（如有）
#
# 用法：./query_iam_role_policies.sh <ROLE_NAME>
#
# 说明：IAM 权限链查询需要多步骤：
#   1. GetRole 获取角色基本信息和信任策略
#   2. ListAttachedRolePolicies 获取托管策略列表
#   3. GetPolicyVersion 逐一获取托管策略内容
#   4. ListRolePolicies + GetRolePolicy 获取内联策略
# 这是典型的多跳递归查询，必须用脚本串联完成。
#
# 输出：结果保存到 aws_memos/tmp/iam_role_<角色名>_<日期时间>.json
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
    echo "用法: $0 <ROLE_NAME>"
    echo ""
    echo "参数说明:"
    echo "  ROLE_NAME  - IAM Role 名称（不是 ARN）"
    echo ""
    echo "示例:"
    echo "  $0 eks-node-role"
    echo "  $0 lambda-execution-role"
    echo ""
    echo "输出文件: $OUTPUT_DIR/iam_role_<角色名>_<日期时间>.json"
}

if [ $# -lt 1 ]; then
    echo -e "${RED}错误: 缺少必需参数${NC}"
    show_help
    exit 1
fi

ROLE_NAME="$1"
mkdir -p "$OUTPUT_DIR"
OUTPUT_FILE="$OUTPUT_DIR/iam_role_${ROLE_NAME}_${CURRENT_DATE}_${CURRENT_TIME}.json"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  IAM Role 权限链完整查询工具${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Role: $ROLE_NAME"
echo ""

# 第一步：获取 Role 基本信息
echo -e "${YELLOW}[1/4] 获取 Role 基本信息...${NC}"

ROLE_INFO=$(aws iam get-role \
    --role-name "$ROLE_NAME" \
    --profile "$PROFILE" 2>/dev/null)

if [ $? -ne 0 ] || [ -z "$ROLE_INFO" ]; then
    echo -e "${RED}错误: 找不到 Role '$ROLE_NAME'，请检查名称是否正确${NC}"
    exit 1
fi

ROLE_ARN=$(echo "$ROLE_INFO" | jq -r '.Role.Arn')
ROLE_CREATE_DATE=$(echo "$ROLE_INFO" | jq -r '.Role.CreateDate')
ROLE_DESCRIPTION=$(echo "$ROLE_INFO" | jq -r '.Role.Description // "无描述"')
TRUST_POLICY=$(echo "$ROLE_INFO" | jq -r '.Role.AssumeRolePolicyDocument' | python3 -c "import sys,urllib.parse; print(urllib.parse.unquote(sys.stdin.read()))" 2>/dev/null || echo "$ROLE_INFO" | jq '.Role.AssumeRolePolicyDocument')
PERMISSIONS_BOUNDARY=$(echo "$ROLE_INFO" | jq -r '.Role.PermissionsBoundary.PermissionsBoundaryArn // ""')

echo "  ARN: $ROLE_ARN"
echo "  创建时间: $ROLE_CREATE_DATE"
if [ -n "$PERMISSIONS_BOUNDARY" ]; then
    echo -e "  ${YELLOW}权限边界: $PERMISSIONS_BOUNDARY${NC}"
fi

# 第二步：获取托管策略列表
echo ""
echo -e "${YELLOW}[2/4] 获取附加的托管策略...${NC}"

ATTACHED_POLICIES=$(aws iam list-attached-role-policies \
    --role-name "$ROLE_NAME" \
    --profile "$PROFILE" 2>/dev/null)

MANAGED_POLICY_COUNT=$(echo "$ATTACHED_POLICIES" | jq '.AttachedPolicies | length')
echo "  找到 $MANAGED_POLICY_COUNT 个托管策略"

# 逐一获取托管策略内容
TEMP_MANAGED=$(mktemp)
echo "[]" > "$TEMP_MANAGED"

echo "$ATTACHED_POLICIES" | jq -c '.AttachedPolicies[]' > /tmp/_aws_policies_$$.txt
while IFS= read -r policy_json; do
    policy_arn=$(echo "$policy_json" | jq -r '.PolicyArn')
    policy_name=$(echo "$policy_json" | jq -r '.PolicyName')

    echo -e "  获取策略: $policy_name ..."

    # 获取策略默认版本
    POLICY_META=$(aws iam get-policy \
        --policy-arn "$policy_arn" \
        --profile "$PROFILE" 2>/dev/null)

    DEFAULT_VERSION=$(echo "$POLICY_META" | jq -r '.Policy.DefaultVersionId')

    # 获取策略内容
    POLICY_CONTENT=$(aws iam get-policy-version \
        --policy-arn "$policy_arn" \
        --version-id "$DEFAULT_VERSION" \
        --profile "$PROFILE" 2>/dev/null)

    POLICY_DOCUMENT=$(echo "$POLICY_CONTENT" | jq '.PolicyVersion.Document')

    POLICY_DETAIL=$(jq -n \
        --arg arn "$policy_arn" \
        --arg name "$policy_name" \
        --arg version "$DEFAULT_VERSION" \
        --argjson doc "$POLICY_DOCUMENT" \
        '{PolicyArn: $arn, PolicyName: $name, DefaultVersionId: $version, Document: $doc}')

    CURRENT=$(cat "$TEMP_MANAGED")
    echo "$CURRENT" | jq --argjson item "$POLICY_DETAIL" '. + [$item]' > "$TEMP_MANAGED"
done < /tmp/_aws_policies_$$.txt
rm -f /tmp/_aws_policies_$$.txt

# 第三步：获取内联策略
echo ""
echo -e "${YELLOW}[3/4] 获取内联策略...${NC}"

INLINE_POLICY_NAMES=$(aws iam list-role-policies \
    --role-name "$ROLE_NAME" \
    --profile "$PROFILE" 2>/dev/null | \
    jq -r '.PolicyNames[]')

INLINE_COUNT=$(echo "$INLINE_POLICY_NAMES" | grep -c . || echo 0)
echo "  找到 $INLINE_COUNT 个内联策略"

TEMP_INLINE=$(mktemp)
echo "[]" > "$TEMP_INLINE"

if [ -n "$INLINE_POLICY_NAMES" ] && [ "$INLINE_COUNT" -gt 0 ]; then
    echo "$INLINE_POLICY_NAMES" > /tmp/_aws_inline_$$.txt
    while IFS= read -r policy_name; do
        [ -z "$policy_name" ] && continue
        echo -e "  获取内联策略: $policy_name ..."

        INLINE_POLICY=$(aws iam get-role-policy \
            --role-name "$ROLE_NAME" \
            --policy-name "$policy_name" \
            --profile "$PROFILE" 2>/dev/null)

        # AWS CLI 返回的 PolicyDocument 已是 JSON 对象，直接提取
        INLINE_DOC=$(echo "$INLINE_POLICY" | jq '.PolicyDocument')

        INLINE_DETAIL=$(jq -n \
            --arg name "$policy_name" \
            --argjson doc "$INLINE_DOC" \
            '{PolicyName: $name, Document: $doc}')

        CURRENT=$(cat "$TEMP_INLINE")
        echo "$CURRENT" | jq --argjson item "$INLINE_DETAIL" '. + [$item]' > "$TEMP_INLINE"
    done < /tmp/_aws_inline_$$.txt
    rm -f /tmp/_aws_inline_$$.txt
fi

# 第四步：分析权限摘要（提取所有 Action）
echo ""
echo -e "${YELLOW}[4/4] 生成权限摘要...${NC}"

MANAGED_POLICIES=$(cat "$TEMP_MANAGED")
INLINE_POLICIES=$(cat "$TEMP_INLINE")

# 合并提取所有 Allow 的 Action（写入临时文件避免子 shell 变量丢失）
TEMP_ACTIONS=$(mktemp)
echo "$MANAGED_POLICIES" | jq -r '.[].Document.Statement[]? | select(.Effect == "Allow") | .Action | if type == "array" then .[] else . end' 2>/dev/null >> "$TEMP_ACTIONS" || true
echo "$INLINE_POLICIES" | jq -r '.[].Document.Statement[]? | select(.Effect == "Allow") | .Action | if type == "array" then .[] else . end' 2>/dev/null >> "$TEMP_ACTIONS" || true
ALL_ALLOW_ACTIONS=$(sort -u "$TEMP_ACTIONS")
rm -f "$TEMP_ACTIONS"

ACTION_COUNT=$(echo "$ALL_ALLOW_ACTIONS" | grep -c . || echo 0)

# 检测是否存在高危权限
DANGEROUS_ACTIONS=("iam:*" "sts:AssumeRole" "ec2:*" "s3:*" "*:*" "iam:CreateUser" "iam:AttachUserPolicy" "iam:PutUserPolicy")
FOUND_DANGEROUS=()

for dangerous in "${DANGEROUS_ACTIONS[@]}"; do
    if echo "$ALL_ALLOW_ACTIONS" | grep -qF "$dangerous" 2>/dev/null; then
        FOUND_DANGEROUS+=("$dangerous")
    fi
done

echo "  Allow 权限总数: $ACTION_COUNT"
if [ ${#FOUND_DANGEROUS[@]} -gt 0 ]; then
    echo -e "  ${RED}⚠ 检测到高危权限: ${FOUND_DANGEROUS[*]}${NC}"
else
    echo -e "  ${GREEN}✅ 未发现明显高危权限${NC}"
fi

# 生成最终报告
TRUST_POLICY_JSON=$(echo "$ROLE_INFO" | jq '.Role.AssumeRolePolicyDocument')

jq -n \
    --arg role_name "$ROLE_NAME" \
    --arg role_arn "$ROLE_ARN" \
    --arg create_date "$ROLE_CREATE_DATE" \
    --arg description "$ROLE_DESCRIPTION" \
    --arg boundary "$PERMISSIONS_BOUNDARY" \
    --arg query_time "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --argjson trust_policy "$TRUST_POLICY_JSON" \
    --argjson managed_policies "$MANAGED_POLICIES" \
    --argjson inline_policies "$INLINE_POLICIES" \
    --argjson allow_action_count "$ACTION_COUNT" \
    '{
        QueryTime: $query_time,
        Role: {
            RoleName: $role_name,
            RoleArn: $role_arn,
            CreateDate: $create_date,
            Description: $description,
            PermissionsBoundaryArn: $boundary
        },
        TrustPolicy: $trust_policy,
        ManagedPolicies: $managed_policies,
        InlinePolicies: $inline_policies,
        PermissionSummary: {
            TotalAllowActions: $allow_action_count,
            ManagedPolicyCount: ($managed_policies | length),
            InlinePolicyCount: ($inline_policies | length)
        }
    }' > "$OUTPUT_FILE"

rm -f "$TEMP_MANAGED" "$TEMP_INLINE"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  查询完成${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "输出文件: $OUTPUT_FILE"
echo ""
echo -e "${BLUE}📊 统计信息:${NC}"
echo "  托管策略数: $MANAGED_POLICY_COUNT"
echo "  内联策略数: $INLINE_COUNT"
echo "  Allow 权限总数: $ACTION_COUNT"
if [ ${#FOUND_DANGEROUS[@]} -gt 0 ]; then
    echo -e "  ${RED}⚠ 高危权限: ${FOUND_DANGEROUS[*]}${NC}"
fi
echo ""
