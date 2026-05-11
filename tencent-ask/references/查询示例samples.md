# 查询示例 Samples — 腾讯云常见查询场景

> 本文档提供常见查询场景的完整 tccli 命令序列，可直接参考执行。所有命令使用 `--profile devops-readonly`。

---

## 目录

| 类别 | 示例 | 复杂度 |
|------|------|--------|
| CVM 云服务器 | 示例1-4 | L1-L3 |
| CDB MySQL | 示例5-7 | L1-L2 |
| CLB 负载均衡 | 示例8-9 | L2-L3 |
| VPC 网络 | 示例10-11 | L2-L3 |
| TKE 容器服务 | 示例12 | L2-L3 |
| Redis 缓存 | 示例13 | L1-L2 |
| CAM 权限 | 示例14 | L2-L3 |
| Monitor 监控 | 示例15-16 | L2 |
| CKafka 消息队列 | 示例17 | L2-L3 |
| 账单费用 | 示例18 | L2 |
| 综合诊断 | 示例19-22 | L4-L5 |
| 批量导出 | 示例23-24 | L3-L4 |
| 安全审计 | 示例25 | L4 |

---

## 一、CVM 云服务器查询

### 示例1：查询广州地域所有运行中的CVM

```bash
# 查询运行中的CVM（使用状态过滤）
tccli cvm DescribeInstances \
  --profile devops-readonly \
  --region ap-beijing \
  --Filters '[{"Name":"instance-state","Values":["RUNNING"]}]' \
  --Limit 100 \
  --Offset 0 | python3 -c "
import sys, json
data = json.load(sys.stdin)
instances = data.get('InstanceSet', [])
print(f'共 {data.get(\"TotalCount\", 0)} 台运行中的实例\n')
print(f'  {\"InstanceId\":<15} {\"Name\":<25} {\"PrivateIP\":<15} {\"PublicIP\":<15} {\"Type\":<15}')
print('  ' + '-'*85)
for ins in instances:
    private_ips = ', '.join(ins.get('PrivateIpAddresses', []))
    public_ips = ', '.join(ins.get('PublicIpAddresses', []) or [])
    print(f\"  {ins['InstanceId']:<15} {ins.get('InstanceName','')[:24]:<25} {private_ips:<15} {public_ips:<15} {ins.get('InstanceType',''):<15}\")
"
```

**预期输出：**
```
共 12 台运行中的实例

  InstanceId      Name                      PrivateIP       PublicIP        Type
  ---------------------------------------------------------------------------------
  ins-abc12345    web-server-prod-01        10.0.1.10       1.2.3.4         S5.MEDIUM4
  ins-def67890    api-server-01             10.0.1.11                       S5.LARGE8
  ...
```

### 示例2：查询特定CVM实例详情

```bash
# 查询指定CVM实例
tccli cvm DescribeInstances \
  --profile devops-readonly \
  --region ap-beijing \
  --InstanceIds '["ins-abc12345"]' | python3 -c "
import sys, json
d = json.load(sys.stdin)
ins = d['InstanceSet'][0]
vpc = ins.get('VirtualPrivateCloud', {})
print(f'名称: {ins.get(\"InstanceName\", \"\")}')
print(f'状态: {ins.get(\"InstanceState\", \"\")}')
print(f'规格: {ins.get(\"InstanceType\", \"\")} | CPU: {ins.get(\"CPU\",0)}C | 内存: {ins.get(\"Memory\",0)}GB')
print(f'内网IP: {ins.get(\"PrivateIpAddresses\", [])}')
print(f'公网IP: {ins.get(\"PublicIpAddresses\", [])}')
print(f'安全组: {ins.get(\"SecurityGroupIds\", [])}')
print(f'VPC: {vpc.get(\"VpcId\",\"\")} | 子网: {vpc.get(\"SubnetId\",\"\")}')
print(f'操作系统: {ins.get(\"OsName\",\"\")}')
print(f'到期时间: {ins.get(\"ExpiredTime\", \"按量付费\")}')
"
```

### 示例3：查询CVM绑定的安全组规则

```bash
# Step1: 获取CVM的安全组ID
CVM_INFO=$(tccli cvm DescribeInstances \
  --profile devops-readonly \
  --region ap-beijing \
  --InstanceIds '["ins-abc12345"]')

SG_ID=$(echo $CVM_INFO | python3 -c "
import sys, json
data = json.load(sys.stdin)
sgs = data['InstanceSet'][0]['SecurityGroupIds']
print(sgs[0] if sgs else '')
")

echo "安全组ID: $SG_ID"

# Step2: 查询安全组规则
tccli vpc DescribeSecurityGroupPolicies \
  --profile devops-readonly \
  --region ap-beijing \
  --SecurityGroupId "$SG_ID" | python3 -c "
import sys, json
d = json.load(sys.stdin)
policies = d.get('SecurityGroupPolicySet', {})
print('入站规则（Ingress）:')
for p in policies.get('Ingress', []):
    src = p.get('CidrBlock', '') or p.get('SecurityGroupId', '')
    action = '✅ 允许' if p.get('Action') == 'ACCEPT' else '❌ 拒绝'
    print(f\"  {action}: {p.get('Protocol','ALL'):<6} {src:<20} Port:{p.get('Port','ALL')}\")
print('出站规则（Egress）:')
for p in policies.get('Egress', []):
    dst = p.get('CidrBlock', '') or p.get('SecurityGroupId', '')
    action = '✅ 允许' if p.get('Action') == 'ACCEPT' else '❌ 拒绝'
    print(f\"  {action}: {p.get('Protocol','ALL'):<6} {dst:<20} Port:{p.get('Port','ALL')}\")
"
```

### 示例4：查询所有地域的CVM数量汇总

```bash
REGIONS=("ap-beijing" "ap-beijing" "ap-shanghai" "ap-chengdu" "ap-nanjing" "ap-singapore" "ap-hongkong")
echo "地域 | CVM数量"
echo "------|-------"
TOTAL=0
for REGION in "${REGIONS[@]}"; do
  COUNT=$(tccli cvm DescribeInstances \
    --profile devops-readonly \
    --region $REGION \
    --Limit 1 2>/dev/null | python3 -c "import sys,json; print(json.load(sys.stdin).get('TotalCount',0))" 2>/dev/null || echo 0)
  echo "$REGION | $COUNT"
  TOTAL=$((TOTAL + COUNT))
done
echo "------+-------"
echo "合计   | $TOTAL"
```

---

## 二、CDB MySQL 数据库查询

### 示例5：查询所有CDB实例列表

```bash
tccli cdb DescribeDBInstances \
  --profile devops-readonly \
  --region ap-beijing \
  --Limit 20 \
  --Offset 0 | python3 -c "
import sys, json
data = json.load(sys.stdin)
instances = data.get('Items', [])
total = data.get('TotalCount', 0)
status_map = {0:'创建中', 1:'运行中', 4:'隔离中', 5:'已隔离'}
print(f'共 {total} 个MySQL实例\n')
print(f'  {\"ID\":<15} {\"名称\":<25} {\"状态\":<8} {\"版本\":<8} {\"内网地址\":<22}')
print('  ' + '-'*80)
for ins in instances:
    vip_port = f\"{ins.get('Vip','')}:{ins.get('Vport','')}\"
    print(f\"  {ins['InstanceId']:<15} {ins.get('InstanceName','')[:24]:<25} {status_map.get(ins.get('Status'),'?'):<8} {ins.get('EngineVersion',''):<8} {vip_port:<22}\")
"
```

### 示例6：查询CDB实例的慢查询日志

```bash
# 查询最近1天的慢查询
YESTERDAY=$(date -v-1d '+%Y-%m-%d %H:%M:%S' 2>/dev/null || date -d '1 day ago' '+%Y-%m-%d %H:%M:%S')
TODAY=$(date '+%Y-%m-%d %H:%M:%S')

tccli cdb DescribeSlowLogs \
  --profile devops-readonly \
  --region ap-beijing \
  --InstanceId "cdb-abc12345" \
  --StartTime "$YESTERDAY" \
  --EndTime "$TODAY" \
  --MinTime 1 \
  --Limit 20 | python3 -c "
import sys, json
data = json.load(sys.stdin)
total = data.get('TotalCount', 0)
logs = data.get('Items', [])
print(f'共 {total} 条慢查询（显示前20条）:')
for log in logs:
    print(f\"  [{log.get('Timestamp','')}] 耗时: {log.get('QueryTime','')}s 锁等: {log.get('LockTime','')}s\")
    print(f\"    SQL: {log.get('SqlText','')[:120]}\")
"
```

### 示例7：查询CDB数据库参数配置

```bash
tccli cdb DescribeDBParameters \
  --profile devops-readonly \
  --region ap-beijing \
  --InstanceId "cdb-abc12345" | python3 -c "
import sys, json
data = json.load(sys.stdin)
params = data.get('Items', [])
key_params = ['max_connections', 'innodb_buffer_pool_size', 'slow_query_log',
              'long_query_time', 'max_allowed_packet', 'character_set_server',
              'time_zone', 'innodb_flush_log_at_trx_commit']
print('关键参数值：')
for p in params:
    if p['Name'] in key_params:
        modified = ' ⚠️(已修改)' if p.get('CurrentValue') != p.get('Default') else ''
        print(f\"  {p['Name']:<40} = {p.get('CurrentValue','')}{modified}\")
"
```

---

## 三、CLB 负载均衡查询

### 示例8：查询CLB及其监听器配置

```bash
# Step1: 查询CLB实例列表
tccli clb DescribeLoadBalancers \
  --profile devops-readonly \
  --region ap-beijing \
  --Limit 20 | python3 -c "
import sys, json
d = json.load(sys.stdin)
lbs = d.get('LoadBalancerSet', [])
print(f'共 {d.get(\"TotalCount\",0)} 个CLB实例:')
for lb in lbs:
    lbtype = '公网' if lb.get('LoadBalancerType') == 'OPEN' else '内网'
    vips = ', '.join(lb.get('LoadBalancerVips', []))
    print(f\"  [{lb['LoadBalancerId']}] {lb.get('LoadBalancerName','')} ({lbtype}) VIP: {vips}\")
"

# Step2: 查询特定CLB的监听器
tccli clb DescribeListeners \
  --profile devops-readonly \
  --region ap-beijing \
  --LoadBalancerId "lb-abc12345" | python3 -c "
import sys, json
d = json.load(sys.stdin)
listeners = d.get('Listeners', [])
print(f'共 {len(listeners)} 个监听器:')
for l in listeners:
    print(f\"  [{l['ListenerId']}] {l.get('Protocol','')}: {l.get('Port','')} - {l.get('ListenerName','')}\")
"

# Step3: 查询监听器的后端服务器
tccli clb DescribeTargets \
  --profile devops-readonly \
  --region ap-beijing \
  --LoadBalancerId "lb-abc12345" \
  --ListenerIds '["lbl-xxxxxxxx"]' | python3 -c "
import sys, json
data = json.load(sys.stdin)
for listener in data.get('Listeners', []):
    print(f\"监听器: {listener['ListenerId']} ({listener.get('Protocol','')}: {listener.get('Port','')}) - 后端数: {len(listener.get('Targets', []))}\")
    for target in listener.get('Targets', []):
        print(f\"  后端: {target.get('InstanceId','')} IP: {', '.join(target.get('PrivateIpAddresses',[]))} Port: {target.get('Port','')} Weight: {target.get('Weight','')}\")
"
```

### 示例9：查询CLB后端健康状态

```bash
tccli clb DescribeTargetHealth \
  --profile devops-readonly \
  --region ap-beijing \
  --LoadBalancerIds '["lb-abc12345"]' | python3 -c "
import sys, json
data = json.load(sys.stdin)
all_healthy = True
for lb in data.get('LoadBalancers', []):
    print(f\"CLB: {lb['LoadBalancerId']}\")
    for listener in lb.get('Listeners', []):
        print(f\"  监听器: {listener['ListenerId']} {listener.get('Protocol','')}: {listener.get('Port','')}\")
        for target in listener.get('Targets', []):
            health = target.get('HealthStatus', False)
            status = '✅ 健康' if health else '❌ 不健康'
            if not health:
                all_healthy = False
            print(f\"    {target.get('IP','')}: {target.get('Port','')} - {status}\")
if not all_healthy:
    print('\n⚠️ 存在不健康的后端，请检查安全组规则和服务进程状态')
"
```

---

## 四、VPC 网络查询

### 示例10：查询VPC下的所有子网

```bash
# 先查询VPC列表
tccli vpc DescribeVpcs \
  --profile devops-readonly \
  --region ap-beijing | python3 -c "
import sys, json
d = json.load(sys.stdin)
vpcs = d.get('VpcSet', [])
print(f'共 {d.get(\"TotalCount\",0)} 个VPC:')
for v in vpcs:
    default = ' (默认)' if v.get('IsDefault') else ''
    print(f\"  [{v['VpcId']}] {v.get('VpcName','')} CIDR: {v.get('CidrBlock','')}{default}\")
"

# 查询特定VPC下的子网
tccli vpc DescribeSubnets \
  --profile devops-readonly \
  --region ap-beijing \
  --Filters '[{"Name":"vpc-id","Values":["vpc-abc12345"]}]' | python3 -c "
import sys, json
data = json.load(sys.stdin)
subnets = data.get('SubnetSet', [])
print(f'共 {len(subnets)} 个子网：\n')
print(f'  {\"子网ID\":<20} {\"名称\":<25} {\"CIDR\":<18} {\"可用IP\":<8} {\"可用区\"}')
print('  ' + '-'*85)
for s in subnets:
    print(f\"  {s['SubnetId']:<20} {s.get('SubnetName','')[:24]:<25} {s.get('CidrBlock',''):<18} {s.get('AvailableIpAddressCount',0):<8} {s.get('Zone','')}\")
"
```

### 示例11：查询EIP绑定关系

```bash
# 查询所有EIP及其绑定状态
tccli vpc DescribeAddresses \
  --profile devops-readonly \
  --region ap-beijing \
  --Limit 50 | python3 -c "
import sys, json
data = json.load(sys.stdin)
addrs = data.get('AddressSet', [])
total = data.get('TotalCount', 0)
print(f'共 {total} 个EIP\n')
print(f'  {\"EIP ID\":<15} {\"IP地址\":<16} {\"状态\":<12} {\"绑定实例\"}')
print('  ' + '-'*65)
unbound = 0
for a in addrs:
    status_map = {'UNBIND': '未绑定', 'BIND': '已绑定', 'BIND_ENI': '绑定ENI'}
    instance_id = a.get('InstanceId', '-')
    status = status_map.get(a['AddressStatus'], a['AddressStatus'])
    if a['AddressStatus'] == 'UNBIND':
        unbound += 1
    print(f\"  {a['AddressId']:<15} {a['AddressIp']:<16} {status:<12} {instance_id}\")
if unbound > 0:
    print(f'\n⚠️ 有 {unbound} 个EIP未绑定（闲置收费）')
"
```

---

## 五、TKE 容器服务查询

### 示例12：查询TKE集群及节点状态

```bash
# 查询集群列表
tccli tke DescribeClusters \
  --profile devops-readonly \
  --region ap-beijing \
  --Limit 10 | python3 -c "
import sys, json
d = json.load(sys.stdin)
clusters = d.get('Clusters', [])
print(f'共 {len(clusters)} 个TKE集群:')
for c in clusters:
    print(f\"  [{c['ClusterId']}] {c.get('ClusterName','')} - K8s: {c.get('ClusterVersion','')} - 状态: {c.get('ClusterStatus','')} - 节点: {c.get('ClusterNodeNum',0)}\")
"

# 查询集群节点池
tccli tke DescribeClusterNodePools \
  --profile devops-readonly \
  --region ap-beijing \
  --ClusterId "cls-abc12345" | python3 -c "
import sys, json
d = json.load(sys.stdin)
pools = d.get('NodePoolSet', [])
print(f'共 {len(pools)} 个节点池:')
for p in pools:
    ns = p.get('NodeCountSummary', {})
    auto = ns.get('AutoscalingAdded', {}).get('Total', 0)
    manual = ns.get('ManuallyAdded', {}).get('Total', 0)
    print(f\"  [{p.get('NodePoolId','')}] {p.get('Name','')} 状态: {p.get('LifeState','')} 节点: {auto+manual} (弹性:{auto} 手动:{manual})\")
"

# 查询集群节点列表
tccli tke DescribeClusterInstances \
  --profile devops-readonly \
  --region ap-beijing \
  --ClusterId "cls-abc12345" \
  --Limit 100 | python3 -c "
import sys, json
data = json.load(sys.stdin)
nodes = data.get('InstanceSet', [])
total = data.get('TotalCount', 0)
running = sum(1 for n in nodes if n.get('InstanceState') == 'running')
print(f'共 {total} 个节点 | 运行中: {running} | 异常: {total-running}')
if running < total:
    print('异常节点:')
    for n in nodes:
        if n.get('InstanceState') != 'running':
            print(f\"  ❌ {n.get('InstanceId','')} {n.get('LanIP','')} 状态: {n.get('InstanceState','')}\")
"
```

---

## 六、Redis 缓存查询

### 示例13：查询Redis实例信息及内存水位

```bash
tccli redis DescribeInstances \
  --profile devops-readonly \
  --region ap-beijing \
  --Limit 20 | python3 -c "
import sys, json
data = json.load(sys.stdin)
instances = data.get('InstanceSet', [])
total = data.get('TotalCount', 0)
status_map = {0:'初始化', 1:'运行中', 2:'扩容中', -2:'已隔离', -3:'待删除'}
print(f'共 {total} 个Redis实例\n')
print(f'  {\"实例ID\":<15} {\"名称\":<25} {\"版本\":<6} {\"容量GB\":<8} {\"已用GB\":<8} {\"使用率%\":<8} {\"内网地址\"}')
print('  ' + '-'*95)
for ins in instances:
    size_gb = ins.get('Size', 0) / 1024
    used_gb = ins.get('SizeUsed', 0) / 1024
    pct = round(used_gb / size_gb * 100, 1) if size_gb > 0 else 0
    flag = ' ⚠️' if pct > 80 else ''
    vip_port = f\"{ins.get('Vip','')}:{ins.get('Vport',6379)}\"
    print(f\"  {ins['InstanceId']:<15} {ins.get('InstanceName','')[:24]:<25} {ins.get('RedisVersion',''):<6} {size_gb:<8.1f} {used_gb:<8.2f} {str(pct)+'%':<8}{flag} {vip_port}\")
"

# 查询Top命令（最近1小时）
tccli redis DescribeInstanceMonitorTopNCmd \
  --profile devops-readonly \
  --region ap-beijing \
  --InstanceId "crs-abc12345" \
  --SpanType 1 | python3 -c "
import sys, json
d = json.load(sys.stdin)
cmds = d.get('Data', [])
print('\nTop 10 命令（最近1小时）:')
for i, cmd in enumerate(cmds[:10], 1):
    print(f\"  {i:2}. {cmd.get('CmdName',''):<15} 次数: {cmd.get('Count',''):>10}\")
"
```

---

## 七、CAM 权限查询

### 示例14：查询CAM子账号及其权限

```bash
# 查询子账号列表
tccli cam ListUsers --profile devops-readonly | python3 -c "
import sys, json
d = json.load(sys.stdin)
users = d.get('Data', [])
print(f'共 {len(users)} 个子账号:')
for u in users:
    status = '启用' if u.get('Status') == 1 else '禁用'
    print(f\"  UIN:{u.get('Uin','')} 名称:{u.get('Name','')} 状态:{status}\")
"

# 查询特定用户的绑定策略
tccli cam ListAttachedUserPolicies \
  --profile devops-readonly \
  --TargetUin 100000000001 \
  --Page 1 \
  --Rp 50 | python3 -c "
import sys, json
d = json.load(sys.stdin)
policies = d.get('List', [])
print(f'绑定策略数: {d.get(\"TotalNum\", 0)}')
for p in policies:
    print(f\"  [{p.get('PolicyId','')}] {p.get('PolicyName','')} ({p.get('PolicyType','')})\")
"

# 查询角色列表
tccli cam DescribeRoleList \
  --profile devops-readonly \
  --Page 1 \
  --Rp 50 | python3 -c "
import sys, json
data = json.load(sys.stdin)
roles = data.get('List', [])
print(f'共 {data.get(\"TotalNum\", 0)} 个角色\n')
for r in roles:
    print(f\"  {r.get('RoleId','')}: {r.get('RoleName','')} 类型:{r.get('RoleType','')} 创建:{r.get('AddTime','')}\")
"
```

---

## 八、Monitor 监控查询

### 示例15：查询CVM CPU使用率

```bash
# 查询最近1小时CVM CPU使用率（300s粒度）
START=$(date -u -v-1H '+%Y-%m-%dT%H:%M:%S+08:00' 2>/dev/null || date -u -d '1 hour ago' '+%Y-%m-%dT%H:%M:%S+08:00')
END=$(date -u '+%Y-%m-%dT%H:%M:%S+08:00')

tccli monitor GetMonitorData \
  --profile devops-readonly \
  --Namespace "QCE/CVM" \
  --MetricName "CPUUsage" \
  --Period 300 \
  --StartTime "$START" \
  --EndTime "$END" \
  --Instances '[{"Dimensions":[{"Name":"InstanceId","Value":"ins-abc12345"}]}]' | python3 -c "
import sys, json
d = json.load(sys.stdin)
dps = d.get('DataPoints', [{}])[0].get('Values', [])
if dps:
    avg = sum(dps) / len(dps)
    print(f'CPU使用率 (最近1小时):')
    print(f'  平均: {avg:.1f}%  最大: {max(dps):.1f}%  最小: {min(dps):.1f}%')
    if max(dps) > 80:
        print(f'  ⚠️ 最大CPU使用率超过80%，请关注负载情况')
else:
    print('未获取到监控数据')
"
```

### 示例16：查询告警策略列表

```bash
tccli monitor DescribeAlarmPolicies \
  --profile devops-readonly \
  --Module "monitor" \
  --PageSize 20 \
  --PageNumber 1 | python3 -c "
import sys, json
data = json.load(sys.stdin)
policies = data.get('Policies', [])
print(f'共 {data.get(\"TotalCount\", 0)} 条告警策略\n')
print(f'  {\"状态\":<6} {\"策略名称\":<35} {\"Namespace\":<25} {\"告警数\":<6}')
print('  ' + '-'*80)
for p in policies:
    status = '✅启用' if p.get('Enable') == 1 else '⛔停用'
    print(f\"  {status:<6} {p.get('PolicyName','')[:34]:<35} {p.get('Namespace',''):<25} {p.get('TriggerTasksNo',0)}\")
"
```

---

## 九、CKafka 消息队列查询

### 示例17：查询CKafka消费组积压

```bash
# 查询实例列表
tccli ckafka DescribeInstancesDetail \
  --profile devops-readonly \
  --region ap-beijing \
  --Limit 10 | python3 -c "
import sys, json
d = json.load(sys.stdin)
result = d.get('Result', {})
instances = result.get('InstanceList', [])
print(f'共 {result.get(\"TotalCount\",0)} 个CKafka实例:')
for ins in instances:
    print(f\"  [{ins.get('InstanceId','')}] {ins.get('InstanceName','')} 版本:{ins.get('Version','')} Bandwidth:{ins.get('Bandwidth','')}MB/s\")
"

# 查询消费组列表
tccli ckafka DescribeGroup \
  --profile devops-readonly \
  --region ap-beijing \
  --InstanceId "ckafka-abc12345" | python3 -c "
import sys, json
d = json.load(sys.stdin)
result = d.get('Result', {})
groups = result.get('GroupList', [])
print(f'共 {len(groups)} 个消费组:')
for g in groups:
    print(f\"  {g.get('Group','')} 状态: {g.get('Status','')}\")
"

# 查询消费积压（以特定消费组为例）
tccli ckafka DescribeGroupOffsets \
  --profile devops-readonly \
  --region ap-beijing \
  --InstanceId "ckafka-abc12345" \
  --Group "my-consumer-group" \
  --Topics '[{"TopicName":"my-topic"}]' | python3 -c "
import sys, json
d = json.load(sys.stdin)
topics = d.get('Result', {}).get('Topics', [])
total_lag = 0
for t in topics:
    for p in t.get('Partitions', []):
        lag = p.get('Lag', 0)
        total_lag += lag
        if lag > 10000:
            print(f\"⚠️ Topic={t['Topic']} Partition={p['Partition']} Lag={lag}\")
print(f'总消费积压(Lag): {total_lag}')
"
```

---

## 十、账单查询

### 示例18：查询上月账单摘要

```bash
# 按产品汇总上月费用（修改日期为上月）
tccli billing DescribeBillSummaryByProduct \
  --profile devops-readonly \
  --BeginTime "2026-03-01 00:00:00" \
  --EndTime "2026-03-31 23:59:59" | python3 -c "
import sys, json
data = json.load(sys.stdin)
summary = data.get('SummaryOverview', [])
total = data.get('SummaryTotal', {}).get('RealTotalCost', '0')
print(f'上月总费用: ¥{float(total):.2f}\n')
summary.sort(key=lambda x: float(x.get('RealTotalCost', '0')), reverse=True)
print(f'  {\"服务\":<30} {\"费用(元)\":>12} {\"占比\":<8}')
print('  ' + '-'*55)
for item in summary[:15]:
    pct = item.get('RealTotalCostRatio', '0')
    cost = float(item.get('RealTotalCost','0'))
    print(f\"  {item.get('BusinessCodeName','')[:29]:<30} {cost:>12.2f} {pct}%\")
"
```

---

## 十一、综合诊断示例

### 示例19：诊断CVM无法访问外网

```bash
#!/bin/bash
REGION="ap-beijing"
INSTANCE_ID="ins-abc12345"
PROFILE="devops-readonly"

echo "=== 诊断 $INSTANCE_ID 外网访问问题 ==="

echo -e "\n[1/5] 查询实例基本信息..."
CVM_INFO=$(tccli cvm DescribeInstances \
  --profile $PROFILE \
  --region $REGION \
  --InstanceIds "[\"$INSTANCE_ID\"]")

VPC_ID=$(echo $CVM_INFO | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['InstanceSet'][0]['VirtualPrivateCloud']['VpcId'])")
SUBNET_ID=$(echo $CVM_INFO | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['InstanceSet'][0]['VirtualPrivateCloud']['SubnetId'])")
PUBLIC_IPS=$(echo $CVM_INFO | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['InstanceSet'][0].get('PublicIpAddresses', []))")
echo "  VPC: $VPC_ID | 子网: $SUBNET_ID | 公网IP: $PUBLIC_IPS"

echo -e "\n[2/5] 检查EIP绑定..."
tccli vpc DescribeAddresses \
  --profile $PROFILE \
  --region $REGION \
  --Filters "[{\"Name\":\"instance-id\",\"Values\":[\"$INSTANCE_ID\"]}]" | python3 -c "
import sys, json
data = json.load(sys.stdin)
addrs = data.get('AddressSet', [])
if addrs:
    print(f'  ✅ 已绑定EIP: {addrs[0][\"AddressIp\"]} ({addrs[0][\"AddressId\"]})')
else:
    print('  ⚠️ 未绑定EIP，检查是否有NAT网关')
"

echo -e "\n[3/5] 查询子网路由表..."
RTB_INFO=$(tccli vpc DescribeRouteTables \
  --profile $PROFILE \
  --region $REGION \
  --Filters "[{\"Name\":\"association.subnet-id\",\"Values\":[\"$SUBNET_ID\"]}]")

echo $RTB_INFO | python3 -c "
import sys, json
data = json.load(sys.stdin)
tables = data.get('RouteTableSet', [])
for rtb in tables:
    print(f'  路由表: {rtb[\"RouteTableId\"]} ({rtb[\"RouteTableName\"]})')
    has_default = False
    for route in rtb.get('RouteSet', []):
        if route.get('DestinationCidrBlock') == '0.0.0.0/0':
            has_default = True
            print(f'  ✅ 默认路由: 0.0.0.0/0 → {route.get(\"GatewayType\",\"\")} ({route.get(\"GatewayId\",\"\")})')
            break
    if not has_default:
        print('  ❌ 未找到默认路由 0.0.0.0/0，无法访问外网！')
"

echo -e "\n[4/5] 查询安全组出站规则..."
SG_ID=$(echo $CVM_INFO | python3 -c "import sys,json; d=json.load(sys.stdin); sgs=d['InstanceSet'][0]['SecurityGroupIds']; print(sgs[0] if sgs else '')")
if [ -n "$SG_ID" ]; then
  tccli vpc DescribeSecurityGroupPolicies \
    --profile $PROFILE \
    --region $REGION \
    --SecurityGroupId "$SG_ID" | python3 -c "
import sys, json
data = json.load(sys.stdin)
egress = data.get('SecurityGroupPolicySet', {}).get('Egress', [])
print(f'  出站规则 (共{len(egress)}条):')
has_allow_all = any(r.get('CidrBlock') == '0.0.0.0/0' and r.get('Action') == 'ACCEPT' for r in egress)
for rule in egress[:5]:
    action = '✅ 允许' if rule.get('Action') == 'ACCEPT' else '❌ 拒绝'
    print(f\"    {action}: {rule.get('CidrBlock','')or rule.get('SecurityGroupId','')} 协议:{rule.get('Protocol','ALL')} 端口:{rule.get('Port','ALL')}\")
if not has_allow_all:
    print('  ⚠️ 安全组出站未放通0.0.0.0/0，可能导致外网不通')
"
fi

echo -e "\n[5/5] 检查网络ACL..."
tccli vpc DescribeNetworkAcls \
  --profile $PROFILE \
  --region $REGION \
  --Filters "[{\"Name\":\"association.subnet-id\",\"Values\":[\"$SUBNET_ID\"]}]" | python3 -c "
import sys, json
d = json.load(sys.stdin)
acls = d.get('NetworkAclSet', [])
if not acls:
    print('  ✅ 该子网无网络ACL绑定')
else:
    for acl in acls:
        print(f'  ACL: {acl[\"NetworkAclId\"]} ({acl.get(\"NetworkAclName\",\"\")})')
        egress = acl.get('EgressEntries', [])
        print(f'  出站规则: {len(egress)} 条（请人工检查是否有拒绝规则）')
"

echo -e "\n=== 诊断完成 ==="
```

### 示例20：诊断CLB后端不健康

```bash
#!/bin/bash
REGION="ap-beijing"
LB_ID="lb-abc12345"
PROFILE="devops-readonly"

echo "=== 诊断 $LB_ID 后端健康状态 ==="

echo -e "\n[1/4] 查询CLB详情..."
CLB_INFO=$(tccli clb DescribeLoadBalancers \
  --profile $PROFILE \
  --region $REGION \
  --LoadBalancerIds "[\"$LB_ID\"]")

echo $CLB_INFO | python3 -c "
import sys, json
d = json.load(sys.stdin)
lb = d.get('LoadBalancerSet', [{}])[0]
print(f'  名称: {lb.get(\"LoadBalancerName\",\"\")} ({lb.get(\"LoadBalancerType\",\"\")})')
print(f'  VIP: {\", \".join(lb.get(\"LoadBalancerVips\",[]))}')
print(f'  安全组: {lb.get(\"SecureGroups\",[])}')
"

echo -e "\n[2/4] 查询后端健康状态..."
tccli clb DescribeTargetHealth \
  --profile $PROFILE \
  --region $REGION \
  --LoadBalancerIds "[\"$LB_ID\"]" | python3 -c "
import sys, json
data = json.load(sys.stdin)
unhealthy = []
for lb in data.get('LoadBalancers', []):
    for listener in lb.get('Listeners', []):
        for rs in listener.get('Targets', []):
            if not rs.get('HealthStatus', True):
                unhealthy.append({'ip': rs.get('IP',''), 'port': rs.get('Port',''), 'id': rs.get('InstanceId','')})
                print(f'  ❌ 不健康: {rs.get(\"IP\",\"\")}:{rs.get(\"Port\",\"\")} ({rs.get(\"InstanceId\",\"\")})')
            else:
                print(f'  ✅ 健康: {rs.get(\"IP\",\"\")}:{rs.get(\"Port\",\"\")} ({rs.get(\"InstanceId\",\"\")})')
if unhealthy:
    print(f'\n  共 {len(unhealthy)} 个后端不健康，建议检查安全组规则')
"

echo -e "\n[3/4] 查询监听器配置..."
tccli clb DescribeListeners \
  --profile $PROFILE \
  --region $REGION \
  --LoadBalancerId "$LB_ID" | python3 -c "
import sys, json
d = json.load(sys.stdin)
for l in d.get('Listeners', []):
    print(f'  监听器: {l[\"ListenerId\"]} {l.get(\"Protocol\",\"\")}:{l.get(\"Port\",\"\")} 健康检查端口: {l.get(\"HealthCheck\",{}).get(\"CheckPort\",\"默认\")}')
"

echo -e "\n=== 诊断完成，建议检查后端CVM的安全组是否放通了健康检查端口 ==="
```

### 示例21：诊断CDB连接数过高

```bash
#!/bin/bash
REGION="ap-beijing"
CDB_ID="cdb-abc12345"
PROFILE="devops-readonly"

echo "=== 诊断 $CDB_ID 连接数问题 ==="

echo -e "\n[1/4] 实例基本信息..."
tccli cdb DescribeDBInstances \
  --profile $PROFILE --region $REGION \
  --InstanceIds "[\"$CDB_ID\"]" | python3 -c "
import sys, json
d = json.load(sys.stdin)
ins = d.get('Items', [{}])[0]
print(f'  名称: {ins.get(\"InstanceName\",\"\")} | 规格: {ins.get(\"DBInstanceClass\",\"\")} | 内存: {ins.get(\"Memory\",0)/1000:.0f}GB')
print(f'  内网: {ins.get(\"Vip\",\"\")}:{ins.get(\"Vport\",\"\")} | MySQL版本: {ins.get(\"EngineVersion\",\"\")}')
"

echo -e "\n[2/4] 查询 max_connections 参数..."
tccli cdb DescribeDBParameters \
  --profile $PROFILE --region $REGION \
  --InstanceId "$CDB_ID" | python3 -c "
import sys, json
d = json.load(sys.stdin)
params = d.get('Items', [])
for p in params:
    if p['Name'] in ['max_connections', 'wait_timeout', 'interactive_timeout']:
        print(f'  {p[\"Name\"]} = {p.get(\"CurrentValue\",\"\")} (默认: {p.get(\"Default\",\"\")})')
"

echo -e "\n[3/4] 查询连接数监控（最近1小时）..."
START=$(date -u -v-1H '+%Y-%m-%dT%H:%M:%S+08:00' 2>/dev/null || date -u -d '1 hour ago' '+%Y-%m-%dT%H:%M:%S+08:00')
END=$(date -u '+%Y-%m-%dT%H:%M:%S+08:00')
tccli monitor GetMonitorData \
  --profile $PROFILE \
  --Namespace "QCE/CDB" \
  --MetricName "mysql_threads_connected" \
  --Period 300 \
  --StartTime "$START" \
  --EndTime "$END" \
  --Instances "[{\"Dimensions\":[{\"Name\":\"InstanceId\",\"Value\":\"$CDB_ID\"}]}]" | python3 -c "
import sys, json
d = json.load(sys.stdin)
vals = d.get('DataPoints', [{}])[0].get('Values', [])
if vals:
    print(f'  连接数: 当前≈{vals[-1]:.0f} 平均={sum(vals)/len(vals):.0f} 最大={max(vals):.0f}')
"

echo -e "\n[4/4] 查询慢查询..."
YESTERDAY=$(date -v-1d '+%Y-%m-%d %H:%M:%S' 2>/dev/null || date -d '1 day ago' '+%Y-%m-%d %H:%M:%S')
TODAY=$(date '+%Y-%m-%d %H:%M:%S')
tccli cdb DescribeSlowLogs \
  --profile $PROFILE --region $REGION \
  --InstanceId "$CDB_ID" \
  --StartTime "$YESTERDAY" --EndTime "$TODAY" \
  --MinTime 5 --Limit 5 | python3 -c "
import sys, json
d = json.load(sys.stdin)
total = d.get('TotalCount', 0)
logs = d.get('Items', [])
print(f'  慢查询总数: {total}（显示前5条超过5秒的）')
for log in logs:
    print(f\"  [{log.get('Timestamp','')}] {log.get('QueryTime','')}s\")
    print(f\"    {log.get('SqlText','')[:100]}\")
"

echo -e "\n=== 诊断完成 ==="
```

### 示例22：Redis内存水位诊断

```bash
#!/bin/bash
REGION="ap-beijing"
REDIS_ID="crs-abc12345"
PROFILE="devops-readonly"

echo "=== Redis $REDIS_ID 内存诊断 ==="

echo -e "\n[1/4] 实例基本信息..."
tccli redis DescribeInstances \
  --profile $PROFILE --region $REGION \
  --InstanceId "$REDIS_ID" | python3 -c "
import sys, json
d = json.load(sys.stdin)
ins = d.get('InstanceSet', [{}])[0]
size_gb = ins.get('Size', 0) / 1024
used_gb = ins.get('SizeUsed', 0) / 1024
pct = round(used_gb / size_gb * 100, 1) if size_gb > 0 else 0
print(f'  名称: {ins.get(\"InstanceName\",\"\")} | 版本: {ins.get(\"RedisVersion\",\"\")}')
print(f'  容量: {size_gb:.0f}GB | 已用: {used_gb:.2f}GB | 使用率: {pct}%')
if pct > 85:
    print(f'  ⚠️ 内存使用率超过85%，存在OOM风险！')
"

echo -e "\n[2/4] Top命令统计（最近1小时）..."
tccli redis DescribeInstanceMonitorTopNCmd \
  --profile $PROFILE --region $REGION \
  --InstanceId "$REDIS_ID" --SpanType 1 | python3 -c "
import sys, json
d = json.load(sys.stdin)
cmds = d.get('Data', [])
print('  Top 10 命令:')
for i, cmd in enumerate(cmds[:10], 1):
    print(f\"  {i:2}. {cmd.get('CmdName',''):<15} 次数: {cmd.get('Count',''):>10}\")
" 2>/dev/null

echo -e "\n[3/4] 查询 maxmemory-policy 参数..."
tccli redis DescribeInstanceParams \
  --profile $PROFILE --region $REGION \
  --InstanceId "$REDIS_ID" | python3 -c "
import sys, json
d = json.load(sys.stdin)
all_params = (d.get('InstanceEnumParam', []) + d.get('InstanceIntegerParam', []) +
              d.get('InstanceTextParam', []))
for p in all_params:
    if p.get('ParamName') in ['maxmemory-policy', 'hz', 'lazyfree-lazy-eviction']:
        print(f'  {p.get(\"ParamName\",\"\"):<40} = {p.get(\"CurrentValue\",\"\")}')
" 2>/dev/null

echo -e "\n[4/4] 最近备份..."
tccli redis DescribeInstanceBackups \
  --profile $PROFILE --region $REGION \
  --InstanceId "$REDIS_ID" --Limit 3 | python3 -c "
import sys, json
d = json.load(sys.stdin)
backups = d.get('Items', [])
status_map = {1:'备份中', 2:'备份成功', 3:'备份失败'}
for b in backups:
    print(f\"  [{b.get('StartTime','')}] {status_map.get(b.get('Status',''),'')} | 大小: {b.get('BackupSize',0)/1024/1024:.1f}MB\")
" 2>/dev/null

echo -e "\n=== 诊断完成 ==="
```

---

## 十二、批量导出

### 示例23：导出全量CVM资产清单（多地域）

```bash
#!/bin/bash
DATE=$(date +%Y-%m-%d)
OUTPUT_DIR="tencent_memos/$DATE"
mkdir -p $OUTPUT_DIR

PROFILE="devops-readonly"
REGIONS=("ap-beijing" "ap-beijing" "ap-shanghai" "ap-chengdu" "ap-nanjing")
ALL_INSTANCES=()

for REGION in "${REGIONS[@]}"; do
  echo "查询 $REGION 的CVM..."
  OFFSET=0; LIMIT=100
  while true; do
    RESULT=$(tccli cvm DescribeInstances \
      --profile $PROFILE --region $REGION \
      --Offset $OFFSET --Limit $LIMIT 2>/dev/null)
    TOTAL=$(echo $RESULT | python3 -c "import sys,json; print(json.load(sys.stdin).get('TotalCount',0))" 2>/dev/null || echo 0)
    COUNT=$(echo $RESULT | python3 -c "import sys,json; print(len(json.load(sys.stdin).get('InstanceSet',[])))" 2>/dev/null || echo 0)
    echo $RESULT >> $OUTPUT_DIR/cvm_raw_${REGION}.json
    OFFSET=$((OFFSET + LIMIT))
    [ $OFFSET -ge $TOTAL ] && break
  done
  echo "  $REGION: 共 $TOTAL 台CVM"
done

# 汇总生成CSV
python3 - << 'EOF'
import json, os, glob
from datetime import date

date_str = date.today().strftime('%Y-%m-%d')
output_dir = f"tencent_memos/{date_str}"
rows = []
regions = ["ap-beijing", "ap-beijing", "ap-shanghai", "ap-chengdu", "ap-nanjing"]
for region in regions:
    f = f"{output_dir}/cvm_raw_{region}.json"
    if not os.path.exists(f):
        continue
    with open(f) as fp:
        for line in fp:
            line = line.strip()
            if not line:
                continue
            try:
                d = json.loads(line)
                for ins in d.get('InstanceSet', []):
                    rows.append({
                        'Region': region,
                        'InstanceId': ins.get('InstanceId', ''),
                        'InstanceName': ins.get('InstanceName', ''),
                        'State': ins.get('InstanceState', ''),
                        'Type': ins.get('InstanceType', ''),
                        'PrivateIP': ', '.join(ins.get('PrivateIpAddresses', [])),
                        'PublicIP': ', '.join(ins.get('PublicIpAddresses') or []),
                    })
            except:
                pass

outfile = f"{output_dir}/cvm_inventory.csv"
with open(outfile, 'w') as f:
    f.write("Region,InstanceId,Name,State,Type,PrivateIP,PublicIP\n")
    for r in rows:
        f.write(f"{r['Region']},{r['InstanceId']},{r['InstanceName']},{r['State']},{r['Type']},{r['PrivateIP']},{r['PublicIP']}\n")
print(f"已导出 {len(rows)} 台CVM到 {outfile}")
EOF
```

### 示例24：导出所有数据库实例清单

```bash
#!/bin/bash
DATE=$(date +%Y-%m-%d)
OUTPUT_DIR="tencent_memos/$DATE"
mkdir -p $OUTPUT_DIR

PROFILE="devops-readonly"
REGION="ap-beijing"

echo "=== 数据库实例清单 - $REGION ==="

# MySQL
echo -e "\n[CDB MySQL]"
tccli cdb DescribeDBInstances \
  --profile $PROFILE --region $REGION \
  --Limit 50 | python3 -c "
import sys, json
d = json.load(sys.stdin)
total = d.get('TotalCount', 0)
print(f'MySQL: {total} 个实例')
for ins in d.get('Items', []):
    status_map = {0:'创建中', 1:'运行中', 4:'隔离中', 5:'已隔离'}
    print(f\"  {ins['InstanceId']}: {ins.get('InstanceName','')} MySQL{ins.get('EngineVersion','')} {status_map.get(ins.get('Status'),'?')} {ins.get('Vip','')}:{ins.get('Vport','')}\")
" | tee $OUTPUT_DIR/db_cdb.txt

# Redis
echo -e "\n[Redis]"
tccli redis DescribeInstances \
  --profile $PROFILE --region $REGION \
  --Limit 50 | python3 -c "
import sys, json
d = json.load(sys.stdin)
total = d.get('TotalCount', 0)
status_map = {0:'初始化', 1:'运行中', 2:'扩容中', -2:'已隔离'}
print(f'Redis: {total} 个实例')
for ins in d.get('InstanceSet', []):
    size = f\"{ins.get('Size',0)//1024}GB\"
    print(f\"  {ins['InstanceId']}: {ins.get('InstanceName','')} Redis{ins.get('RedisVersion','')} {status_map.get(ins.get('Status',''),'?')} {size} {ins.get('Vip','')}:{ins.get('Vport',6379)}\")
" | tee $OUTPUT_DIR/db_redis.txt

# MongoDB
echo -e "\n[MongoDB]"
tccli mongodb DescribeDBInstances \
  --profile $PROFILE --region $REGION \
  --Limit 50 2>/dev/null | python3 -c "
import sys, json
d = json.load(sys.stdin)
total = d.get('TotalCount', 0)
print(f'MongoDB: {total} 个实例')
for ins in d.get('InstanceSet', []):
    print(f\"  {ins.get('InstanceId','')}: {ins.get('InstanceName','')} {ins.get('MongoVersion','')} {ins.get('Vip','')}:{ins.get('Vport',27017)}\")
" 2>/dev/null | tee $OUTPUT_DIR/db_mongo.txt

echo -e "\n数据已保存到 $OUTPUT_DIR/"
```

---

## 十三、安全审计示例

### 示例25：检查安全组中的危险规则

```bash
#!/bin/bash
REGION="ap-beijing"
PROFILE="devops-readonly"

echo "=== 安全组安全审计 - $REGION ==="
echo "检查允许 0.0.0.0/0 入站的安全组规则..."

# 获取所有安全组
SG_LIST=$(tccli vpc DescribeSecurityGroups \
  --profile $PROFILE --region $REGION \
  --Limit 100)

echo $SG_LIST | python3 -c "
import sys, json, subprocess
d = json.load(sys.stdin)
sgs = d.get('SecurityGroupSet', [])
print(f'共检查 {len(sgs)} 个安全组...')

dangerous_rules = []
for sg in sgs:
    sg_id = sg['SecurityGroupId']
    sg_name = sg.get('SecurityGroupName', '')
    # 注：实际执行时需单独调用 DescribeSecurityGroupPolicies
    print(f'  检查: [{sg_id}] {sg_name}')
"

# 查询特定安全组规则（批量检查时需循环）
tccli vpc DescribeSecurityGroupPolicies \
  --profile $PROFILE --region $REGION \
  --SecurityGroupId "sg-abc12345" | python3 -c "
import sys, json
d = json.load(sys.stdin)
ingress = d.get('SecurityGroupPolicySet', {}).get('Ingress', [])
risky = []
for rule in ingress:
    cidr = rule.get('CidrBlock', '')
    if cidr in ['0.0.0.0/0', '::/0'] and rule.get('Action') == 'ACCEPT':
        port = rule.get('Port', 'ALL')
        proto = rule.get('Protocol', 'ALL')
        risky.append((cidr, proto, port))
        print(f'⚠️ 高危规则: 来源={cidr} 协议={proto} 端口={port}')

if not risky:
    print('✅ 未发现允许0.0.0.0/0的入站规则')
else:
    print(f'\n共 {len(risky)} 条高危入站规则，建议收窄访问来源IP范围')
"
```

---

## 附录：常用 python3 处理片段

### 通用分页结果合并

```python
# 合并多次分页查询结果（以CVM为例）
import subprocess, json

def query_all(service, action, region, key, **kwargs):
    """分页查询所有结果"""
    offset, limit = 0, 100
    all_items = []
    while True:
        cmd = ['tccli', service, action, '--profile', 'devops-readonly',
               '--region', region, '--Limit', str(limit), '--Offset', str(offset)]
        for k, v in kwargs.items():
            cmd += [f'--{k}', v]
        result = subprocess.run(cmd, capture_output=True, text=True)
        data = json.loads(result.stdout)
        items = data.get(key, [])
        all_items.extend(items)
        total = data.get('TotalCount', len(items))
        offset += limit
        if offset >= total:
            break
    return all_items

# 使用示例
instances = query_all('cvm', 'DescribeInstances', 'ap-beijing', 'InstanceSet')
print(f"共 {len(instances)} 台CVM")
```

### 常用 jq 等价的 python3 提取

```bash
# 提取列表总数
tccli cvm DescribeInstances --profile devops-readonly --region ap-beijing \
  | python3 -c "import sys,json;print(json.load(sys.stdin)['TotalCount'])"

# 提取所有实例ID列表
tccli cvm DescribeInstances --profile devops-readonly --region ap-beijing \
  | python3 -c "import sys,json;[print(i['InstanceId']) for i in json.load(sys.stdin).get('InstanceSet',[])]"

# 统计各状态数量
tccli cvm DescribeInstances --profile devops-readonly --region ap-beijing --Limit 100 \
  | python3 -c "
import sys, json
from collections import Counter
d = json.load(sys.stdin)
states = Counter(i.get('InstanceState') for i in d.get('InstanceSet',[]))
for state, count in states.most_common():
    print(f'{state}: {count}')
"

# 过滤并格式化
tccli cbs DescribeDisks --profile devops-readonly --region ap-beijing \
  --Filters '[{"Name":"disk-state","Values":["UNATTACHED"]}]' \
  | python3 -c "
import sys, json
d = json.load(sys.stdin)
disks = d.get('DiskSet', [])
print(f'未挂载云盘 ({d.get(\"TotalCount\",0)} 块):')
for disk in disks:
    print(f\"  {disk['DiskId']}: {disk.get('DiskName','')} {disk.get('DiskSize',0)}GB {disk.get('DiskType','')} 到期:{disk.get('ExpireTime','按量')}\")
"
```
