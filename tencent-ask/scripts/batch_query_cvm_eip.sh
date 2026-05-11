#!/bin/bash
# batch_query_cvm_eip.sh — 查询CVM与EIP绑定关系
# 用法: bash batch_query_cvm_eip.sh [region]

PROFILE="devops-readonly"
REGION="${1:-ap-beijing}"
DATE=$(date +%Y-%m-%d)
OUTPUT_DIR="./tencent_memos/tmp"
mkdir -p "$OUTPUT_DIR"

echo "======================================================"
echo "  CVM & EIP 绑定关系查询"
echo "  地域: $REGION"
echo "======================================================"

# Step1: 查询所有EIP
echo ""
echo "[1/2] 查询EIP列表..."
EIP_RESULT=$(tccli vpc DescribeAddresses \
  --profile "$PROFILE" \
  --region "$REGION" \
  --Limit 100)

if ! echo "$EIP_RESULT" | grep -q '"RequestId"'; then
  echo "❌ 查询EIP失败: $EIP_RESULT"
  exit 1
fi

echo "$EIP_RESULT" > "$OUTPUT_DIR/eip_list_${REGION}.json"

# Step2: 展示绑定关系
echo "[2/2] 分析EIP绑定关系..."
echo ""
echo "$EIP_RESULT" | python3 -c "
import sys, json
data = json.load(sys.stdin)
addrs = data.get('AddressSet', [])

print(f'共 {data.get(\"TotalCount\", 0)} 个EIP\n')
print(f'{'EIP ID':<15} {'公网IP':<16} {'状态':<12} {'绑定资源':<25} {'带宽':<10}')
print('-'*80)

bound = []
unbound = []
for a in addrs:
    status_map = {'UNBIND': '未绑定', 'BIND': '已绑定CVM', 'BIND_ENI': '绑定ENI'}
    status = status_map.get(a.get('AddressStatus', ''), a.get('AddressStatus', ''))
    instance = a.get('InstanceId', '-') or a.get('NetworkInterfaceId', '-') or '-'
    bandwidth = str(a.get('Bandwidth', '-')) + 'Mbps' if a.get('Bandwidth') else '-'
    row = f\"{a['AddressId']:<15} {a['AddressIp']:<16} {status:<12} {instance:<25} {bandwidth:<10}\"
    if a.get('AddressStatus') == 'UNBIND':
        unbound.append(row)
    else:
        bound.append(row)

print('--- 已绑定 ---')
for r in bound:
    print(r)
print()
print('--- 未绑定 ---')
for r in unbound:
    print(r)
print()
print(f'小结: 已绑定 {len(bound)} 个, 未绑定 {len(unbound)} 个')
"

echo ""
echo "数据已保存至: $OUTPUT_DIR/eip_list_${REGION}.json"
