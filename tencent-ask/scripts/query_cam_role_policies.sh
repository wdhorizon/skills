#!/bin/bash
# query_cam_role_policies.sh — 查询CAM角色及其绑定的权限策略
# 用法: bash query_cam_role_policies.sh [role-name]
# 若不指定角色名，则列出所有角色

PROFILE="devops-readonly"
ROLE_NAME="${1}"
DATE=$(date +%Y-%m-%d)
OUTPUT_DIR="./tencent_memos/tmp"
mkdir -p "$OUTPUT_DIR"

echo "======================================================"
echo "  CAM 角色及策略查询"
echo "======================================================"

# 查询角色列表
echo ""
echo "[1/2] 查询角色列表..."
ROLES=$(tccli cam DescribeRoleList \
  --profile "$PROFILE" \
  --Page 1 \
  --Rp 100)

if ! echo "$ROLES" | grep -q '"RequestId"'; then
  echo "❌ 查询角色失败: $ROLES"
  exit 1
fi

echo "$ROLES" > "$OUTPUT_DIR/cam_roles.json"

if [ -z "$ROLE_NAME" ]; then
  echo "$ROLES" | python3 -c "
import sys, json
data = json.load(sys.stdin)
roles = data.get('List', [])
print(f'共 {data.get(\"TotalNum\", 0)} 个角色:\n')
print(f'{'角色名':<40} {'类型':<12} {'创建时间':<22} {'描述'}')
print('-'*100)
for r in roles:
    role_type = '服务角色' if r.get('RoleType') == 'service_linked' else '普通角色'
    print(f\"{r.get('RoleName','')[:39]:<40} {role_type:<12} {r.get('AddTime',''):<22} {r.get('Description','')}\")
"
  echo ""
  echo "提示：指定角色名可查询详细策略，如: bash $0 CVM_QCSRole"
  exit 0
fi

# 查询特定角色的绑定策略
echo ""
echo "[2/2] 查询角色 '$ROLE_NAME' 的绑定策略..."
POLICIES=$(tccli cam ListAttachedRolePolicies \
  --profile "$PROFILE" \
  --RoleName "$ROLE_NAME" \
  --Page 1 \
  --Rp 50)

if ! echo "$POLICIES" | grep -q '"RequestId"'; then
  echo "❌ 查询策略失败: $POLICIES"
  exit 1
fi

echo "$POLICIES" > "$OUTPUT_DIR/cam_role_${ROLE_NAME}_policies.json"

echo "$POLICIES" | python3 -c "
import sys, json
data = json.load(sys.stdin)
policies = data.get('List', [])
total = data.get('TotalNum', 0)
print(f'角色 {\"$ROLE_NAME\"} 共绑定 {total} 个策略:\n')
for p in policies:
    scope = '系统策略' if p.get('PolicyType') == 'QCS' else '自定义策略'
    print(f\"  [{scope}] {p.get('PolicyName', '')} (ID: {p.get('PolicyId', '')})\")
    print(f\"    描述: {p.get('Description', '无')}\")
    print()
"

echo "数据已保存至: $OUTPUT_DIR/"
