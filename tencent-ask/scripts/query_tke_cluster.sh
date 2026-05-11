#!/bin/bash
# query_tke_cluster.sh — 查询TKE集群详情、节点池及节点状态
# 用法: bash query_tke_cluster.sh <cluster-id> [region]

PROFILE="devops-readonly"
CLUSTER_ID="${1}"
REGION="${2:-ap-beijing}"
DATE=$(date +%Y-%m-%d)
OUTPUT_DIR="./tencent_memos/tmp"
mkdir -p "$OUTPUT_DIR"

if [ -z "$CLUSTER_ID" ]; then
  echo "查询所有TKE集群列表..."
  tccli tke DescribeClusters \
    --profile "$PROFILE" \
    --region "$REGION" \
    --Limit 20 | python3 -c "
import sys, json
data = json.load(sys.stdin)
clusters = data.get('Clusters', [])
print(f'共 {len(clusters)} 个集群:\n')
print(f'{'集群ID':<15} {'集群名称':<25} {'状态':<12} {'版本':<12} {'节点数':<8}')
print('-'*75)
for c in clusters:
    print(f\"{c['ClusterId']:<15} {c.get('ClusterName','')[:24]:<25} {c.get('ClusterStatus',''):<12} {c.get('ClusterVersion',''):<12} {c.get('ClusterNodeNum',0):<8}\")
"
  echo ""
  echo "提示：指定集群ID可查询详情，如: bash $0 cls-abc12345"
  exit 0
fi

echo "======================================================"
echo "  TKE 集群详情查询"
echo "  集群ID: $CLUSTER_ID | 地域: $REGION"
echo "======================================================"

# Step1: 集群基本信息
echo ""
echo "[1/3] 集群基本信息..."
CLUSTER_INFO=$(tccli tke DescribeClusters \
  --profile "$PROFILE" \
  --region "$REGION" \
  --ClusterIds "[\"$CLUSTER_ID\"]")

echo "$CLUSTER_INFO" > "$OUTPUT_DIR/tke_cluster_${CLUSTER_ID}.json"

echo "$CLUSTER_INFO" | python3 -c "
import sys, json
data = json.load(sys.stdin)
clusters = data.get('Clusters', [])
if clusters:
    c = clusters[0]
    print(f\"  集群名称: {c.get('ClusterName', '')}\")
    print(f\"  状态: {c.get('ClusterStatus', '')}\")
    print(f\"  K8s版本: {c.get('ClusterVersion', '')}\")
    print(f\"  集群类型: {c.get('ClusterType', '')}\")
    print(f\"  节点数: {c.get('ClusterNodeNum', 0)}\")
    print(f\"  VPC: {c.get('VpcId', '')}\")
    print(f\"  描述: {c.get('ClusterDescription', '无')}\")
"

# Step2: 节点池列表
echo ""
echo "[2/3] 节点池信息..."
NODE_POOLS=$(tccli tke DescribeClusterNodePools \
  --profile "$PROFILE" \
  --region "$REGION" \
  --ClusterId "$CLUSTER_ID")

echo "$NODE_POOLS" > "$OUTPUT_DIR/tke_${CLUSTER_ID}_nodepools.json"

echo "$NODE_POOLS" | python3 -c "
import sys, json
data = json.load(sys.stdin)
pools = data.get('NodePoolSet', [])
print(f'共 {len(pools)} 个节点池:\n')
for p in pools:
    print(f\"  [{p.get('NodePoolId','')}] {p.get('Name','')} - 状态: {p.get('LifeState','')} | 当前节点: {p.get('NodeCountSummary',{}).get('AutoscalingAdded',{}).get('Total',0)+p.get('NodeCountSummary',{}).get('ManuallyAdded',{}).get('Total',0)}\")
"

# Step3: 节点列表
echo ""
echo "[3/3] 节点列表..."
NODES=$(tccli tke DescribeClusterInstances \
  --profile "$PROFILE" \
  --region "$REGION" \
  --ClusterId "$CLUSTER_ID" \
  --Limit 100)

echo "$NODES" > "$OUTPUT_DIR/tke_${CLUSTER_ID}_nodes.json"

echo "$NODES" | python3 -c "
import sys, json
data = json.load(sys.stdin)
nodes = data.get('InstanceSet', [])
total = data.get('TotalCount', 0)
print(f'共 {total} 个节点:\n')
print(f'{'InstanceId':<15} {'InternalIP':<16} {'状态':<10} {'类型':<12}')
print('-'*55)
running = 0
for n in nodes:
    state = n.get('InstanceState', '')
    if state == 'running':
        running += 1
    print(f\"{n.get('InstanceId',''):<15} {n.get('LanIP',''):<16} {state:<10} {n.get('InstanceRole',''):<12}\")
print(f'\n运行正常: {running}/{total}')
if running < total:
    print(f'⚠️ 有 {total-running} 个节点状态异常，请检查！')
"

echo ""
echo "数据已保存至: $OUTPUT_DIR/"
