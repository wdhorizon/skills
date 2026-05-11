#!/bin/bash
# batch_query_sg_rules.sh — 批量查询安全组规则
# 用法: bash batch_query_sg_rules.sh [region] [sg-id1 sg-id2 ...]

PROFILE="devops-readonly"
REGION="${1:-ap-beijing}"
DATE=$(date +%Y-%m-%d)
OUTPUT_DIR="./tencent_memos/tmp"
mkdir -p "$OUTPUT_DIR"

# 如果提供了安全组ID列表（从第2个参数开始）
shift
SG_IDS=("$@")

echo "======================================================"
echo "  安全组规则批量查询"
echo "  地域: $REGION"
echo "======================================================"

# 如果没有指定安全组ID，先列出所有安全组
if [ ${#SG_IDS[@]} -eq 0 ]; then
  echo ""
  echo "[1/2] 查询安全组列表..."
  SG_LIST=$(tccli vpc DescribeSecurityGroups \
    --profile "$PROFILE" \
    --region "$REGION" \
    --Limit 50)

  if ! echo "$SG_LIST" | grep -q '"RequestId"'; then
    echo "❌ 查询安全组失败: $SG_LIST"
    exit 1
  fi

  echo "$SG_LIST" | python3 -c "
import sys, json
data = json.load(sys.stdin)
sgs = data.get('SecurityGroupSet', [])
print(f'共 {len(sgs)} 个安全组:\n')
for sg in sgs:
    print(f\"  {sg['SecurityGroupId']}: {sg['SecurityGroupName']} - {sg.get('SecurityGroupDesc', '')}\")
"

  # 提取所有安全组ID（兼容 macOS/bash3，不使用 readarray）
  SG_IDS_JSON=$(echo "$SG_LIST" | python3 -c "
import sys, json
data = json.load(sys.stdin)
ids = [sg['SecurityGroupId'] for sg in data.get('SecurityGroupSet', [])]
print(json.dumps(ids))
")
  SG_IDS=()
  while IFS= read -r line; do
    SG_IDS+=("$line")
  done < <(echo "$SG_IDS_JSON" | python3 -c "import sys,json; [print(x) for x in json.load(sys.stdin)]")
fi

echo ""
echo "[2/2] 查询安全组规则..."
echo ""

for SG_ID in "${SG_IDS[@]}"; do
  echo "------------------------------------------------------"
  echo "安全组: $SG_ID"

  RULES=$(tccli vpc DescribeSecurityGroupPolicies \
    --profile "$PROFILE" \
    --region "$REGION" \
    --SecurityGroupId "$SG_ID")

  if ! echo "$RULES" | grep -q '"RequestId"'; then
    echo "  ⚠️ 查询失败: $RULES"
    continue
  fi

  echo "$RULES" > "$OUTPUT_DIR/sg_rules_${SG_ID}.json"

  echo "$RULES" | python3 -c "
import sys, json
data = json.load(sys.stdin)
policies = data.get('SecurityGroupPolicySet', {})

ingress = policies.get('Ingress', [])
egress = policies.get('Egress', [])

def format_rule(rule):
    action = '✅ ACCEPT' if rule.get('Action') == 'ACCEPT' else '❌ DROP'
    cidr = rule.get('CidrBlock') or rule.get('Ipv6CidrBlock') or rule.get('SecurityGroupId', 'ANY')
    proto = rule.get('Protocol', 'ALL')
    port = rule.get('Port', 'ALL')
    desc = rule.get('PolicyDescription', '')
    return f\"  {action} | {cidr:<20} | {proto:<6} | {port:<15} | {desc}\"

print(f'  入站规则 ({len(ingress)}条):')
for r in ingress:
    print(format_rule(r))

print(f'\n  出站规则 ({len(egress)}条):')
for r in egress:
    print(format_rule(r))
"
  echo ""
done

echo "======================================================"
echo "  查询完成！数据已保存至: $OUTPUT_DIR/"
echo "======================================================"
