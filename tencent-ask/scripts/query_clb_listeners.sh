#!/bin/bash
# query_clb_listeners.sh — 查询CLB监听器规则及后端服务器
# 用法: bash query_clb_listeners.sh <lb-id> [region]

PROFILE="devops-readonly"
LB_ID="${1}"
REGION="${2:-ap-beijing}"
DATE=$(date +%Y-%m-%d)
OUTPUT_DIR="./tencent_memos/tmp"
mkdir -p "$OUTPUT_DIR"

if [ -z "$LB_ID" ]; then
  echo "用法: bash query_clb_listeners.sh <lb-id> [region]"
  echo "示例: bash query_clb_listeners.sh lb-abc12345 ap-beijing"
  exit 1
fi

echo "======================================================"
echo "  CLB 监听器详情查询"
echo "  CLB ID: $LB_ID | 地域: $REGION"
echo "======================================================"

# Step1: 查询CLB基本信息
echo ""
echo "[1/3] 查询CLB实例信息..."
LB_INFO=$(tccli clb DescribeLoadBalancers \
  --profile "$PROFILE" \
  --region "$REGION" \
  --LoadBalancerIds "[\"$LB_ID\"]")

if ! echo "$LB_INFO" | grep -q '"RequestId"'; then
  echo "❌ 查询CLB失败: $LB_INFO"
  exit 1
fi

echo "$LB_INFO" | python3 -c "
import sys, json
data = json.load(sys.stdin)
lbs = data.get('LoadBalancerSet', [])
if lbs:
    lb = lbs[0]
    lb_type = '公网' if lb.get('LoadBalancerType') == 'OPEN' else '内网'
    print(f\"  名称: {lb.get('LoadBalancerName', '')}\")
    print(f\"  类型: {lb_type} | VIP: {', '.join(lb.get('LoadBalancerVips', []))}\")
    print(f\"  状态: {'正常' if lb.get('Status') == 1 else '创建中'} | VPC: {lb.get('VpcId', '')}\")
"

# Step2: 查询监听器列表
echo ""
echo "[2/3] 查询监听器列表..."
LISTENERS=$(tccli clb DescribeListeners \
  --profile "$PROFILE" \
  --region "$REGION" \
  --LoadBalancerId "$LB_ID")

echo "$LISTENERS" > "$OUTPUT_DIR/clb_${LB_ID}_listeners.json"

LISTENER_IDS=$(echo "$LISTENERS" | python3 -c "
import sys, json
data = json.load(sys.stdin)
listeners = data.get('Listeners', [])
print(f'  共 {len(listeners)} 个监听器:')
ids = []
for l in listeners:
    print(f\"    {l['ListenerId']}: {l['Protocol']}:{l['Port']} - {l.get('ListenerName', '')}\")
    ids.append(l['ListenerId'])
import json as j
print('LISTENER_IDS:' + j.dumps(ids))
" | tee /dev/stderr | grep "LISTENER_IDS:" | cut -d: -f2-)

# Step3: 查询后端服务器及健康状态
echo ""
echo "[3/3] 查询后端服务器..."
if [ -n "$LISTENER_IDS" ]; then
  TARGETS=$(tccli clb DescribeTargets \
    --profile "$PROFILE" \
    --region "$REGION" \
    --LoadBalancerId "$LB_ID")

  echo "$TARGETS" > "$OUTPUT_DIR/clb_${LB_ID}_targets.json"

  echo "$TARGETS" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for listener in data.get('Listeners', []):
    print(f\"\n  监听器 {listener['ListenerId']} ({listener['Protocol']}:{listener['Port']}):\")
    targets = listener.get('Targets', [])
    if targets:
        for t in targets:
            ips = ', '.join(t.get('PrivateIpAddresses', []))
            print(f\"    ✔ {t.get('InstanceId', t.get('EniIp', 'ENI'))} | IP: {ips} | Port: {t['Port']} | Weight: {t['Weight']}\")
    else:
        print('    （无后端服务器）')
"

  # 健康检查状态
  echo ""
  echo "后端健康状态："
  tccli clb DescribeTargetHealth \
    --profile "$PROFILE" \
    --region "$REGION" \
    --LoadBalancerIds "[\"$LB_ID\"]" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for lb in data.get('LoadBalancers', []):
    for listener in lb.get('Listeners', []):
        for target in listener.get('Targets', []):
            status = '✅ 健康' if target.get('HealthStatus') else '❌ 不健康'
            print(f\"  {target['IP']}:{target['Port']} - {status}\")
"
fi

echo ""
echo "数据已保存至: $OUTPUT_DIR/"
