#!/bin/bash
# query_cdb_detail.sh — 查询CDB MySQL实例详情，包含参数、备份、慢查询等
# 用法: bash query_cdb_detail.sh <cdb-instance-id> [region]

PROFILE="devops-readonly"
INSTANCE_ID="${1}"
REGION="${2:-ap-beijing}"
DATE=$(date +%Y-%m-%d)
OUTPUT_DIR="./tencent_memos/tmp"
mkdir -p "$OUTPUT_DIR"

if [ -z "$INSTANCE_ID" ]; then
  echo "查询所有CDB实例列表..."
  tccli cdb DescribeDBInstances \
    --profile "$PROFILE" \
    --region "$REGION" \
    --Limit 20 | python3 -c "
import sys, json
data = json.load(sys.stdin)
instances = data.get('Items', [])
total = data.get('TotalCount', 0)
print(f'共 {total} 个MySQL实例:\n')
status_map = {0:'创建中', 1:'运行中', 4:'隔离中', 5:'已隔离'}
print(f'{'实例ID':<15} {'名称':<25} {'状态':<8} {'版本':<8} {'内网地址':<20}')
print('-'*80)
for ins in instances:
    vip_port = f\"{ins.get('Vip','')}:{ins.get('Vport','')}\"
    print(f\"{ins['InstanceId']:<15} {ins.get('InstanceName','')[:24]:<25} {status_map.get(ins.get('Status',''),'?'):<8} {ins.get('EngineVersion',''):<8} {vip_port:<20}\")
"
  echo ""
  echo "提示：指定实例ID可查询详情，如: bash $0 cdb-abc12345"
  exit 0
fi

echo "======================================================"
echo "  CDB MySQL 实例详情查询"
echo "  实例ID: $INSTANCE_ID | 地域: $REGION"
echo "======================================================"

# Step1: 基本信息
echo ""
echo "[1/4] 实例基本信息..."
tccli cdb DescribeDBInstances \
  --profile "$PROFILE" \
  --region "$REGION" \
  --InstanceIds "[\"$INSTANCE_ID\"]" | python3 -c "
import sys, json
data = json.load(sys.stdin)
instances = data.get('Items', [])
if instances:
    ins = instances[0]
    status_map = {0:'创建中', 1:'运行中', 4:'隔离中', 5:'已隔离'}
    print(f\"  名称: {ins.get('InstanceName', '')}\")
    print(f\"  状态: {status_map.get(ins.get('Status',''), '未知')}\")
    print(f\"  规格: {ins.get('DBInstanceClass', '')} | Memory: {ins.get('Memory',0)/1000:.0f}GB | Disk: {ins.get('Volume',0)}GB\")
    print(f\"  版本: MySQL {ins.get('EngineVersion', '')}\")
    print(f\"  内网: {ins.get('Vip','')}:{ins.get('Vport','')}\")
    print(f\"  VPC: {ins.get('UniqVpcId','')} | 子网: {ins.get('UniqSubnetId','')}\")
    print(f\"  到期: {ins.get('DeadlineTime', '按量付费')}\")
" | tee "$OUTPUT_DIR/cdb_${INSTANCE_ID}_info.txt"

# Step2: 关键参数
echo ""
echo "[2/4] 关键参数配置..."
tccli cdb DescribeInstanceParams \
  --profile "$PROFILE" \
  --region "$REGION" \
  --InstanceId "$INSTANCE_ID" | python3 -c "
import sys, json
data = json.load(sys.stdin)
params = data.get('Items', [])
key_params = ['max_connections', 'innodb_buffer_pool_size', 'slow_query_log',
              'long_query_time', 'max_allowed_packet', 'character_set_server',
              'time_zone', 'lower_case_table_names', 'innodb_flush_log_at_trx_commit']
print('  关键参数：')
for p in params:
    if p['Name'] in key_params:
        modified = ' ⚠️(已修改)' if p.get('CurrentValue') != p.get('Default') else ''
        print(f\"  {p['Name']:<40} = {p.get('CurrentValue','')}{modified}\")
" 2>/dev/null

# Step3: 备份配置
echo ""
echo "[3/4] 备份配置..."
tccli cdb DescribeBackupConfig \
  --profile "$PROFILE" \
  --region "$REGION" \
  --InstanceId "$INSTANCE_ID" | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(f\"  备份时间: {data.get('StartTimeMin','')}:00 - {data.get('StartTimeMax','')}:00\")
print(f\"  备份保留天数: {data.get('BackupExpireDays', '')} 天\")
print(f\"  Binlog保留天数: {data.get('BinlogExpireDays', '')} 天\")
" 2>/dev/null

# Step4: 最近慢查询（最近1天）
echo ""
echo "[4/4] 最近慢查询（最近24小时 Top 10）..."
START_TS=$(date -v-1d '+%s' 2>/dev/null || date -d '1 day ago' '+%s' 2>/dev/null)
END_TS=$(date '+%s')

tccli cdb DescribeSlowLogData \
  --profile "$PROFILE" \
  --region "$REGION" \
  --InstanceId "$INSTANCE_ID" \
  --StartTime "$START_TS" \
  --EndTime "$END_TS" \
  --SortBy QueryTime \
  --OrderBy DESC \
  --Limit 10 | python3 -c "
import sys, json
data = json.load(sys.stdin)
total = data.get('TotalCount', 0)
logs = data.get('Items', [])
print(f'  共 {total} 条慢查询（显示前10条）:')
for log in logs:
    print(f\"  [{log.get('Timestamp','')}] 耗时: {log.get('QueryTime','')}s | 锁等待: {log.get('LockTime','')}s\")
    sql = log.get('SqlText', '')[:100]
    print(f\"    SQL: {sql}\")
" 2>/dev/null

echo ""
echo "数据已保存至: $OUTPUT_DIR/"
