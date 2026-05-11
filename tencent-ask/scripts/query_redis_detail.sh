#!/bin/bash
# query_redis_detail.sh — 查询Redis实例详情，包含内存使用、Top命令等
# 用法: bash query_redis_detail.sh <redis-instance-id> [region]

PROFILE="devops-readonly"
INSTANCE_ID="${1}"
REGION="${2:-ap-beijing}"
DATE=$(date +%Y-%m-%d)
OUTPUT_DIR="./tencent_memos/tmp"
mkdir -p "$OUTPUT_DIR"

if [ -z "$INSTANCE_ID" ]; then
  echo "查询所有Redis实例列表..."
  tccli redis DescribeInstances \
    --profile "$PROFILE" \
    --region "$REGION" \
    --Limit 20 | python3 -c "
import sys, json
data = json.load(sys.stdin)
instances = data.get('InstanceSet', [])
total = data.get('TotalCount', 0)
status_map = {0:'初始化', 1:'运行中', 2:'扩容中', -2:'已隔离', -3:'待删除'}
print(f'共 {total} 个Redis实例:\n')
print(f'{'实例ID':<15} {'名称':<25} {'状态':<8} {'版本':<6} {'容量':<10} {'已用':<10} {'内网地址':<20}')
print('-'*97)
for ins in instances:
    size = f\"{ins.get('Size',0)//1024}GB\"
    used_mb = ins.get('SizeUsed', 0)
    used = f\"{used_mb/1024:.1f}GB\"
    vip_port = f\"{ins.get('Vip','')}:{ins.get('Vport',6379)}\"
    print(f\"{ins['InstanceId']:<15} {ins.get('InstanceName','')[:24]:<25} {status_map.get(ins.get('Status',''),'?'):<8} {ins.get('RedisVersion',''):<6} {size:<10} {used:<10} {vip_port:<20}\")
"
  echo ""
  echo "提示：指定实例ID可查询详情，如: bash $0 crs-abc12345"
  exit 0
fi

echo "======================================================"
echo "  Redis 实例详情查询"
echo "  实例ID: $INSTANCE_ID | 地域: $REGION"
echo "======================================================"

# Step1: 基本信息
echo ""
echo "[1/4] 实例基本信息..."
REDIS_INFO=$(tccli redis DescribeInstances \
  --profile "$PROFILE" \
  --region "$REGION" \
  --InstanceId "$INSTANCE_ID")

echo "$REDIS_INFO" > "$OUTPUT_DIR/redis_${INSTANCE_ID}_info.json"

echo "$REDIS_INFO" | python3 -c "
import sys, json
data = json.load(sys.stdin)
instances = data.get('InstanceSet', [])
status_map = {0:'初始化', 1:'运行中', 2:'扩容中', -2:'已隔离', -3:'待删除'}
if instances:
    ins = instances[0]
    size_gb = ins.get('Size', 0) / 1024
    used_gb = ins.get('SizeUsed', 0) / 1024
    used_pct = round(used_gb / size_gb * 100, 1) if size_gb > 0 else 0
    print(f\"  名称: {ins.get('InstanceName', '')}\")
    print(f\"  状态: {status_map.get(ins.get('Status',''), '未知')}\")
    print(f\"  版本: Redis {ins.get('RedisVersion', '')}\")
    print(f\"  容量: {size_gb:.0f}GB | 已用: {used_gb:.2f}GB ({used_pct}%)\")
    print(f\"  内网: {ins.get('Vip','')}:{ins.get('Vport', 6379)}\")
    print(f\"  VPC: {ins.get('VpcId','')} | 子网: {ins.get('SubnetId','')}\")
"

# Step2: 参数配置
echo ""
echo "[2/4] 实例参数配置..."
tccli redis DescribeInstanceParams \
  --profile "$PROFILE" \
  --region "$REGION" \
  --InstanceId "$INSTANCE_ID" | python3 -c "
import sys, json
data = json.load(sys.stdin)
params = data.get('InstanceEnumParam', []) + data.get('InstanceIntegerParam', []) + data.get('InstanceTextParam', [])
key_params = ['maxmemory-policy', 'hz', 'activerehashing', 'lazyfree-lazy-eviction', 'notify-keyspace-events']
print('  关键参数：')
for p in params:
    if p.get('ParamName') in key_params:
        print(f\"  {p.get('ParamName',''):<40} = {p.get('CurrentValue','')}\")
" 2>/dev/null

# Step3: Top命令统计（最近1小时）
echo ""
echo "[3/4] Top 命令统计（最近1小时）..."
tccli redis DescribeInstanceMonitorTopNCmd \
  --profile "$PROFILE" \
  --region "$REGION" \
  --InstanceId "$INSTANCE_ID" \
  --SpanType 1 | python3 -c "
import sys, json
data = json.load(sys.stdin)
data_list = data.get('Data', [])
print('  命令排名（按执行次数）:')
for i, cmd in enumerate(data_list[:10], 1):
    print(f\"  {i:2}. {cmd.get('CmdName',''):<15} 次数: {cmd.get('Count',''):>10} 使用率: {cmd.get('UsedMemory','')} bytes\")
" 2>/dev/null

# Step4: 备份列表
echo ""
echo "[4/4] 最近备份列表..."
tccli redis DescribeInstanceBackups \
  --profile "$PROFILE" \
  --region "$REGION" \
  --InstanceId "$INSTANCE_ID" \
  --Limit 5 | python3 -c "
import sys, json
data = json.load(sys.stdin)
backups = data.get('Items', [])
total = data.get('TotalCount', 0)
print(f'  共 {total} 个备份（显示最近5个）:')
status_map = {1:'备份中', 2:'备份成功', 3:'备份失败', 4:'备份删除中', 5:'备份已删除'}
for b in backups:
    print(f\"  [{b.get('StartTime','')}] 状态: {status_map.get(b.get('Status',''), b.get('Status',''))} | 大小: {b.get('BackupSize',0)/1024/1024:.1f}MB\")
" 2>/dev/null

echo ""
echo "数据已保存至: $OUTPUT_DIR/"
