# API 操作映射库 — 腾讯云 tccli 命令参考

> 本文档映射用户自然语言意图到具体的 `tccli` 命令。所有命令均使用 `--profile devops-readonly`。

---

## 快速索引

| 服务 | tccli标识 | 核心只读操作 | 常用复杂度 |
|------|----------|------------|-----------|
| CVM 云服务器 | cvm | DescribeInstances, DescribeInstancesStatus | L1-L3 |
| CDB MySQL | cdb | DescribeDBInstances, DescribeSlowLogs | L1-L3 |
| Redis | redis | DescribeInstances, DescribeInstanceMonitorTopNCmd | L1-L3 |
| MongoDB | mongodb | DescribeDBInstances, DescribeSlowLogs | L1-L2 |
| CLB 负载均衡 | clb | DescribeLoadBalancers, DescribeTargetHealth | L2-L4 |
| VPC 私有网络 | vpc | DescribeVpcs, DescribeSecurityGroupPolicies | L1-L4 |
| CBS 云硬盘 | cbs | DescribeDisks, DescribeSnapshots | L1-L2 |
| TKE 容器服务 | tke | DescribeClusters, DescribeClusterInstances | L2-L4 |
| EMR 大数据 | emr | DescribeInstances, DescribeClusterNodes | L2-L3 |
| CKafka 消息队列 | ckafka | DescribeInstancesDetail, DescribeGroupOffsets | L2-L4 |
| COS 对象存储 | **coscli** | ls, stat, cat | L1-L2 |
| SCF 云函数 | scf | ListFunctions, GetFunction | L1-L2 |
| CAM 访问管理 | cam | DescribeRoleList, ListAttachedRolePolicies | L2-L3 |
| Monitor 云监控 | monitor | GetMonitorData, DescribeAlarmPolicies | L2-L3 |
| CLS 日志服务 | cls | DescribeTopics, SearchLog | L1-L3 |
| CDN 内容分发 | cdn | DescribeDomains, DescribeCdnData | L1-L2 |
| TCR 镜像仓库 | tcr | DescribeInstances, DescribeImages | L1-L2 |
| CFS 文件存储 | cfs | DescribeCfsFileSystems, DescribeMountTargets | L1-L2 |
| NAT 网关 | vpc | DescribeNatGateways, DescribeNatGateway... | L1-L2 |
| 私有域 DNS | privatedns | DescribePrivateZoneList, DescribePrivateZoneRecordList | L1-L2 |
| CDW-Doris | cdwdoris | DescribeInstances, DescribeInstance | L1-L2 |
| Lighthouse 轻量 | lighthouse | DescribeInstances, DescribeFirewallRules | L1-L2 |
| 账单 Billing | billing | DescribeBillSummaryByProduct, DescribeBillDetail | L2-L3 |
| STS 身份验证 | sts | GetCallerIdentity | L1 |

---

## 云服务器 CVM

**tccli 服务标识：`cvm`**

| 用户意图 | tccli 命令 | 关键参数 |
|---------|-----------|---------|
| 查询CVM实例列表 | `tccli cvm DescribeInstances` | `--region`, `--Limit`, `--Offset`, `--Filters` |
| 查询CVM实例详情 | `tccli cvm DescribeInstances` | `--InstanceIds '["ins-xxx"]'` |
| 查询CVM实例状态 | `tccli cvm DescribeInstancesStatus` | `--InstanceIds` |
| 查询可用区 | `tccli cvm DescribeZones` | `--region` |
| 查询CVM镜像列表 | `tccli cvm DescribeImages` | `--Filters`, `--ImageType` |
| 查询实例规格 | `tccli cvm DescribeInstanceTypeConfigs` | `--region`, `--Filters` |
| 查询密钥对 | `tccli cvm DescribeKeyPairs` | `--KeyIds`, `--Filters` |
| 查询弹性网卡 | `tccli cvm DescribeNetworkInterfaces` | `--InstanceId` |
| 查询安全组（从CVM角度） | `tccli cvm DescribeInstancesAttribute` | `--InstanceId` |
| 查询CVM监控数据 | `tccli monitor GetMonitorData` | `--Namespace QCE/CVM`, `--MetricName` |
| 查询实例带宽 | `tccli cvm DescribeInstanceInternetBandwidthConfigs` | `--InstanceId` |
| 查询置放群组 | `tccli cvm DescribeDisasterRecoverGroups` | `--Filters` |
| 查询专用宿主机 | `tccli cvm DescribeHosts` | `--Filters` |
| 查询实例价格 | `tccli cvm InquiryPriceRunInstances` | 各规格参数 |

**常用过滤器：**
```bash
# 按状态过滤（RUNNING/STOPPED/REBOOTING等）
--Filters '[{"Name":"instance-state","Values":["RUNNING"]}]'

# 按实例名称过滤（支持通配符）
--Filters '[{"Name":"instance-name","Values":["*web*"]}]'

# 按VPC过滤
--Filters '[{"Name":"vpc-id","Values":["vpc-xxxxxxxx"]}]'

# 按标签过滤
--Filters '[{"Name":"tag:环境","Values":["生产"]}]'

# 按内网IP查询
--Filters '[{"Name":"private-ip-address","Values":["10.0.0.1"]}]'
```

**代码示例 — 批量查询多地域CVM：**
```bash
for REGION in ap-beijing ap-beijing ap-shanghai ap-chengdu ap-nanjing; do
  COUNT=$(tccli cvm DescribeInstances \
    --profile devops-readonly --region $REGION \
    --Limit 1 2>/dev/null | python3 -c "
import sys, json
d = json.load(sys.stdin)
print(d.get('TotalCount', 0))
" 2>/dev/null || echo 0)
  echo "$REGION: $COUNT 台"
done
```

**代码示例 — 查询指定CVM详情：**
```bash
tccli cvm DescribeInstances \
  --profile devops-readonly \
  --region ap-beijing \
  --InstanceIds '["ins-abc12345"]' | python3 -c "
import sys, json
d = json.load(sys.stdin)
ins = d['InstanceSet'][0]
print(f\"名称: {ins.get('InstanceName')}\")
print(f\"状态: {ins.get('InstanceState')}\")
print(f\"规格: {ins.get('InstanceType')}\")
print(f\"内网IP: {ins.get('PrivateIpAddresses')}\")
print(f\"公网IP: {ins.get('PublicIpAddresses')}\")
print(f\"安全组: {ins.get('SecurityGroupIds')}\")
"
```

---

## 云数据库 MySQL (CDB)

**tccli 服务标识：`cdb`**

| 用户意图 | tccli 命令 | 关键参数 |
|---------|-----------|---------|
| 查询MySQL实例列表 | `tccli cdb DescribeDBInstances` | `--region`, `--Limit`, `--Offset` |
| 查询MySQL实例详情 | `tccli cdb DescribeDBInstances` | `--InstanceIds '["cdb-xxx"]'` |
| 查询实例规格 | `tccli cdb DescribeDBZoneConfig` | `--region` |
| 查询数据库参数 | `tccli cdb DescribeDBParameters` | `--InstanceId` |
| 查询慢查询日志 | `tccli cdb DescribeSlowLogs` | `--InstanceId`, `--StartTime`, `--EndTime` |
| 查询错误日志 | `tccli cdb DescribeErrorLogs` | `--InstanceId`, `--StartTime`, `--EndTime` |
| 查询实例任务列表 | `tccli cdb DescribeTasks` | `--InstanceId`, `--StartTimeBegin`, `--StartTimeEnd` |
| 查询备份列表 | `tccli cdb DescribeBackups` | `--InstanceId`, `--Limit` |
| 查询备份配置 | `tccli cdb DescribeBackupConfig` | `--InstanceId` |
| 查询只读实例 | `tccli cdb DescribeRoGroups` | `--InstanceId` |
| 查询数据库列表 | `tccli cdb DescribeDatabases` | `--InstanceId` |
| 查询表列表 | `tccli cdb DescribeTables` | `--InstanceId`, `--Database` |
| 查询账号列表 | `tccli cdb DescribeAccounts` | `--InstanceId` |
| 查询监控数据 | `tccli monitor GetMonitorData` | `--Namespace QCE/CDB`, `--MetricName` |
| 查询审计日志 | `tccli dbbrain DescribeSqlFilters` | `--InstanceId` |
| 查询健康报告 | `tccli dbbrain DescribeDBDiagEvent` | `--InstanceId` |

**代码示例 — 查询CDB慢查询（最近1天）：**
```bash
YESTERDAY=$(date -v-1d '+%Y-%m-%d %H:%M:%S' 2>/dev/null || date -d '1 day ago' '+%Y-%m-%d %H:%M:%S')
TODAY=$(date '+%Y-%m-%d %H:%M:%S')

tccli cdb DescribeSlowLogs \
  --profile devops-readonly \
  --region ap-beijing \
  --InstanceId "cdb-abc12345" \
  --StartTime "$YESTERDAY" \
  --EndTime "$TODAY" \
  --MinTime 1 \
  --Limit 10 | python3 -c "
import sys, json
d = json.load(sys.stdin)
total = d.get('TotalCount', 0)
logs = d.get('Items', [])
print(f'共 {total} 条慢查询（显示前10条）:')
for log in logs:
    print(f\"  [{log.get('Timestamp','')}] 耗时: {log.get('QueryTime','')}s\")
    print(f\"    SQL: {log.get('SqlText','')[:100]}\")
"
```

---

## 云数据库 Redis

**tccli 服务标识：`redis`**

| 用户意图 | tccli 命令 | 关键参数 |
|---------|-----------|---------|
| 查询Redis实例列表 | `tccli redis DescribeInstances` | `--region`, `--Limit`, `--Offset` |
| 查询Redis实例详情 | `tccli redis DescribeInstances` | `--InstanceId` |
| 查询Top命令统计 | `tccli redis DescribeInstanceMonitorTopNCmd` | `--InstanceId`, `--SpanType` |
| 查询大Key分析 | `tccli redis DescribeInstanceMonitorBigKeySizeDist` | `--InstanceId`, `--Date` |
| 查询热Key分析 | `tccli redis DescribeInstanceMonitorHotKey` | `--InstanceId`, `--SpanType` |
| 查询key类型分布 | `tccli redis DescribeInstanceMonitorBigKeyTypeDist` | `--InstanceId`, `--Date` |
| 查询备份列表 | `tccli redis DescribeInstanceBackups` | `--InstanceId`, `--Limit` |
| 查询参数配置 | `tccli redis DescribeInstanceParams` | `--InstanceId` |
| 查询实例节点信息 | `tccli redis DescribeInstanceNodeInfo` | `--InstanceId` |
| 查询实例账号 | `tccli redis DescribeInstanceAccount` | `--InstanceId` |
| 查询安全组 | `tccli redis DescribeInstanceSecurityGroup` | `--InstanceIds` |
| 查询内存监控 | `tccli monitor GetMonitorData` | `--Namespace QCE/REDIS`, `--MetricName MemUsed` |

**代码示例 — 查询Redis内存水位：**
```bash
tccli redis DescribeInstances \
  --profile devops-readonly \
  --region ap-beijing \
  --Limit 50 | python3 -c "
import sys, json
d = json.load(sys.stdin)
instances = d.get('InstanceSet', [])
print(f'Redis内存使用情况 ({len(instances)} 个实例):')
print(f'  {\"实例ID\":<15} {\"名称\":<25} {\"容量MB\":<10} {\"已用MB\":<10} {\"使用率%\":<10}')
print('-' * 75)
for ins in instances:
    size = ins.get('Size', 0)
    used = ins.get('SizeUsed', 0)
    pct = round(used / size * 100, 1) if size > 0 else 0
    flag = ' ⚠️' if pct > 80 else ''
    print(f\"  {ins['InstanceId']:<15} {ins.get('InstanceName','')[:24]:<25} {size:<10} {used:<10} {pct:<10}{flag}\")
"
```

---

## 云数据库 MongoDB

**tccli 服务标识：`mongodb`**

| 用户意图 | tccli 命令 | 关键参数 |
|---------|-----------|---------|
| 查询MongoDB实例列表 | `tccli mongodb DescribeDBInstances` | `--region`, `--Limit`, `--Offset` |
| 查询MongoDB实例详情 | `tccli mongodb DescribeDBInstances` | `--InstanceIds '["cmgo-xxx"]'` |
| 查询慢查询日志 | `tccli mongodb DescribeSlowLogs` | `--InstanceId`, `--StartTime`, `--EndTime` |
| 查询备份列表 | `tccli mongodb DescribeDBBackups` | `--InstanceId` |
| 查询实例参数 | `tccli mongodb DescribeInstanceParams` | `--InstanceId` |
| 查询副本集状态 | `tccli monitor GetMonitorData` | `--Namespace QCE/CMONGO` |
| 查询连接数监控 | `tccli monitor GetMonitorData` | `--Namespace QCE/CMONGO --MetricName Connections` |

---

## 消息队列 CKafka

**tccli 服务标识：`ckafka`**

| 用户意图 | tccli 命令 | 关键参数 |
|---------|-----------|---------|
| 查询CKafka实例列表 | `tccli ckafka DescribeInstancesDetail` | `--region`, `--Limit`, `--Offset` |
| 查询实例详情 | `tccli ckafka DescribeInstancesDetail` | `--InstanceId` |
| 查询Topic列表 | `tccli ckafka DescribeTopicDetail` | `--InstanceId`, `--Limit` |
| 查询消费组列表 | `tccli ckafka DescribeGroup` | `--InstanceId` |
| 查询消费组偏移 | `tccli ckafka DescribeGroupOffsets` | `--InstanceId`, `--Group`, `--Topics` |
| 查询ACL规则 | `tccli ckafka DescribeAcl` | `--InstanceId`, `--ResourceType`, `--ResourceName` |
| 查询路由列表 | `tccli ckafka DescribeRoute` | `--InstanceId` |
| 查询实例属性 | `tccli ckafka DescribeInstanceAttributes` | `--InstanceId` |
| 查询用户列表 | `tccli ckafka DescribeUser` | `--InstanceId` |
| 查询消费积压 | `tccli monitor GetMonitorData` | `--Namespace QCE/CKAFKA --MetricName ConsumerLag` |

**代码示例 — 查询消费组积压：**
```bash
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
        if lag > 1000:
            print(f\"⚠️ Topic={t['Topic']} Partition={p['Partition']} Lag={lag}\")
print(f'总积压: {total_lag}')
"
```

---

## 对象存储 COS

**⚠️ 重要说明：COS 不使用 `tccli`，必须使用专用的 `coscli` 工具。**

> `tccli` 不支持 `cos` 子命令。所有 COS 操作需通过 `coscli` 完成。
> 配置文件路径：`~/.cos-readonly.yaml`（只读凭证配置）

### 只读操作（允许执行）

| 用户意图 | coscli 命令 | 说明 |
|---------|------------|------|
| 查询存储桶列表 | `coscli ls -c ~/.cos-readonly.yaml` | 列出所有 Bucket |
| 列出Bucket中的文件 | `coscli ls cos://<BucketName-AppId>/ -c ~/.cos-readonly.yaml` | 列出根目录对象 |
| 递归列出Bucket文件 | `coscli ls cos://<BucketName-AppId>/ -r -c ~/.cos-readonly.yaml` | 递归列出所有对象 |
| 查询指定目录内容 | `coscli ls cos://<BucketName-AppId>/<prefix>/ -c ~/.cos-readonly.yaml` | 列出指定前缀下的对象 |
| 查看文件/对象信息 | `coscli stat cos://<BucketName-AppId>/<key> -c ~/.cos-readonly.yaml` | 查看对象元数据 |
| 查看Bucket存储用量 | `coscli du cos://<BucketName-AppId>/ -c ~/.cos-readonly.yaml` | 统计存储用量 |
| 下载文件（查阅内容） | `coscli cat cos://<BucketName-AppId>/<key> -c ~/.cos-readonly.yaml` | 输出文件内容到stdout |
| 查询Bucket版本控制 | `coscli bucket-versioning --method get cos://<BucketName-AppId> -c ~/.cos-readonly.yaml` | 查看版本控制状态 |
| 查询Bucket加密配置 | `coscli bucket-encryption --method get cos://<BucketName-AppId> -c ~/.cos-readonly.yaml` | 查看加密配置 |
| 查询Bucket访问控制 | `coscli bucket-acl --method get cos://<BucketName-AppId> -c ~/.cos-readonly.yaml` | 查看 ACL |
| 查询Bucket标签 | `coscli bucket-tagging --method get cos://<BucketName-AppId> -c ~/.cos-readonly.yaml` | 查看Bucket标签 |

### 写操作（严禁执行）

以下操作涉及数据变更，**本技能严格禁止执行**：

| 禁止操作 | 对应命令 |
|---------|---------|
| 上传文件 | `coscli cp <local> cos://...` |
| 删除对象 | `coscli rm cos://...` |
| 同步目录 | `coscli sync <local> cos://...` |
| 创建存储桶 | `coscli mb cos://...` |
| 删除存储桶 | `coscli rb cos://...` |
| 设置版本控制 | `coscli bucket-versioning --method put ...` |
| 设置加密配置 | `coscli bucket-encryption --method put ...` |
| 设置/删除标签 | `coscli bucket-tagging --method put/delete ...` |

### 代码示例

**列出所有存储桶：**
```bash
coscli ls -c ~/.cos-readonly.yaml
```

**列出指定存储桶中的文件（含大小）：**
```bash
BUCKET="my-bucket-1250000000"
coscli ls cos://${BUCKET}/ -c ~/.cos-readonly.yaml
```

**递归统计存储桶文件数量和大小：**
```bash
BUCKET="my-bucket-1250000000"
coscli du cos://${BUCKET}/ -c ~/.cos-readonly.yaml
```

**查询所有存储桶并展示信息：**
```bash
# 列出所有桶
coscli ls -c ~/.cos-readonly.yaml

# 遍历每个桶统计用量
coscli ls -c ~/.cos-readonly.yaml | awk '{print $3}' | while read BUCKET; do
  echo "=== $BUCKET ==="
  coscli du "$BUCKET" -c ~/.cos-readonly.yaml
done
```

> **Bucket 名称格式**：`<BucketName>-<AppId>`，如 `my-bucket-1250000000`
> **COS URI 格式**：`cos://<BucketName-AppId>/[prefix]`

---

## 云硬盘 CBS

**tccli 服务标识：`cbs`**

| 用户意图 | tccli 命令 | 关键参数 |
|---------|-----------|---------|
| 查询云盘列表 | `tccli cbs DescribeDisks` | `--region`, `--Limit`, `--Filters` |
| 查询云盘详情 | `tccli cbs DescribeDisks` | `--DiskIds '["disk-xxx"]'` |
| 查询快照列表 | `tccli cbs DescribeSnapshots` | `--DiskId`, `--Limit` |
| 查询快照策略 | `tccli cbs DescribeAutoSnapshotPolicies` | `--Filters` |
| 查询云盘关联实例 | `tccli cbs DescribeDisks` | `--Filters '[{"Name":"instance-id","Values":["ins-xxx"]}]'` |
| 查询可用云盘类型 | `tccli cbs DescribeDiskConfigQuota` | `--region`, `--InquiryType INQUIRY_CVM_CONFIG` |
| 查询云盘价格 | `tccli cbs InquiryPriceCreateDisks` | 各规格参数 |

**云盘过滤器：**
```bash
# 查找未挂载的云盘
--Filters '[{"Name":"disk-state","Values":["UNATTACHED"]}]'

# 按云盘类型过滤
--Filters '[{"Name":"disk-type","Values":["CLOUD_PREMIUM"]}]'

# 查找指定实例挂载的所有云盘
--Filters '[{"Name":"instance-id","Values":["ins-xxxxxxxx"]}]'
```

---

## 负载均衡 CLB

**tccli 服务标识：`clb`**

| 用户意图 | tccli 命令 | 关键参数 |
|---------|-----------|---------|
| 查询CLB实例列表 | `tccli clb DescribeLoadBalancers` | `--region`, `--Limit`, `--Filters` |
| 查询CLB详情 | `tccli clb DescribeLoadBalancers` | `--LoadBalancerIds '["lb-xxx"]'` |
| 查询监听器列表 | `tccli clb DescribeListeners` | `--LoadBalancerId` |
| 查询监听器详情 | `tccli clb DescribeListeners` | `--LoadBalancerId`, `--ListenerIds` |
| 查询转发规则 | `tccli clb DescribeRules` | `--LoadBalancerId`, `--ListenerId` |
| 查询后端服务器 | `tccli clb DescribeTargets` | `--LoadBalancerId`, `--ListenerIds` |
| 查询后端健康状态 | `tccli clb DescribeTargetHealth` | `--LoadBalancerIds` |
| 查询CLB监控数据 | `tccli monitor GetMonitorData` | `--Namespace QCE/LB_PUBLIC` |
| 查询绑定的EIP | `tccli clb DescribeLoadBalancers` | （从返回字段 LoadBalancerVips 提取） |
| 查询CLB关联安全组 | `tccli clb DescribeLoadBalancers` | （从返回字段 SecureGroups 提取）|

**代码示例 — 查询CLB后端健康状态：**
```bash
tccli clb DescribeTargetHealth \
  --profile devops-readonly \
  --region ap-beijing \
  --LoadBalancerIds '["lb-abc12345"]' | python3 -c "
import sys, json
d = json.load(sys.stdin)
lbs = d.get('LoadBalancers', [])
for lb in lbs:
    for listener in lb.get('Listeners', []):
        for rs in listener.get('Targets', []):
            health = rs.get('HealthStatus', False)
            status = '✅ 健康' if health else '❌ 不健康'
            print(f\"  {rs.get('InstanceId','')} :{rs.get('Port','')} {status}\")
"
```

---

## 私有网络 VPC

**tccli 服务标识：`vpc`**

| 用户意图 | tccli 命令 | 关键参数 |
|---------|-----------|---------|
| 查询VPC列表 | `tccli vpc DescribeVpcs` | `--region`, `--Filters` |
| 查询子网列表 | `tccli vpc DescribeSubnets` | `--region`, `--Filters` |
| 查询路由表 | `tccli vpc DescribeRouteTables` | `--region`, `--Filters` |
| 查询安全组列表 | `tccli vpc DescribeSecurityGroups` | `--region`, `--Filters` |
| 查询安全组规则 | `tccli vpc DescribeSecurityGroupPolicies` | `--SecurityGroupId` |
| 查询网络ACL | `tccli vpc DescribeNetworkAcls` | `--region`, `--Filters` |
| 查询弹性网卡 | `tccli vpc DescribeNetworkInterfaces` | `--region`, `--Filters` |
| 查询EIP列表 | `tccli vpc DescribeAddresses` | `--region`, `--Filters` |
| 查询EIP绑定关系 | `tccli vpc DescribeAddresses` | `--Filters '[{"Name":"instance-id","Values":["ins-xxx"]}]'` |
| 查询NAT网关列表 | `tccli vpc DescribeNatGateways` | `--region`, `--Filters` |
| 查询NAT转发规则 | `tccli vpc DescribeNatGatewayDestinationIpPortTranslationNatRules` | `--NatGatewayIds` |
| 查询VPN网关 | `tccli vpc DescribeVpnGateways` | `--region` |
| 查询对等连接 | `tccli vpc DescribeVpcPeeringConnections` | `--region` |
| 查询流日志 | `tccli vpc DescribeFlowLogs` | `--region` |
| 查询带宽包 | `tccli vpc DescribeBandwidthPackages` | `--region` |
| 查询VPC内IP占用 | `tccli vpc DescribeVpcIpv4Addresses` | `--VpcId` |
| 查询网络探测 | `tccli vpc DescribeNetDetects` | `--region` |

**代码示例 — 查询安全组规则：**
```bash
tccli vpc DescribeSecurityGroupPolicies \
  --profile devops-readonly \
  --region ap-beijing \
  --SecurityGroupId "sg-abc12345" | python3 -c "
import sys, json
d = json.load(sys.stdin)
policies = d.get('SecurityGroupPolicySet', {})
print('入站规则（Ingress）:')
for p in policies.get('Ingress', []):
    src = p.get('CidrBlock', p.get('SecurityGroupId', ''))
    print(f\"  {p.get('Protocol','ALL'):<6} {src:<20} Port:{p.get('Port','ALL'):<10} {p.get('Action','')}\")
print('出站规则（Egress）:')
for p in policies.get('Egress', []):
    dst = p.get('CidrBlock', p.get('SecurityGroupId', ''))
    print(f\"  {p.get('Protocol','ALL'):<6} {dst:<20} Port:{p.get('Port','ALL'):<10} {p.get('Action','')}\")
"
```

---

## 容器服务 TKE

**tccli 服务标识：`tke`**

| 用户意图 | tccli 命令 | 关键参数 |
|---------|-----------|---------|
| 查询TKE集群列表 | `tccli tke DescribeClusters` | `--region`, `--Limit` |
| 查询集群详情 | `tccli tke DescribeClusters` | `--ClusterIds '["cls-xxx"]'` |
| 查询集群节点列表 | `tccli tke DescribeClusterInstances` | `--ClusterId`, `--Limit` |
| 查询节点池列表 | `tccli tke DescribeClusterNodePools` | `--ClusterId` |
| 查询节点池详情 | `tccli tke DescribeClusterNodePool` | `--ClusterId`, `--NodePoolId` |
| 查询命名空间 | `tccli tke DescribeClusterNamespaces` | `--ClusterId` |
| 查询镜像缓存 | `tccli tke DescribeImageCaches` | `--region` |
| 查询弹性集群 | `tccli tke DescribeEKSClusters` | `--region` |
| 查询集群升级信息 | `tccli tke GetUpgradeInstanceProgress` | `--ClusterId` |
| 查询集群RBAC | `tccli tke DescribeClusterAuthenticationOptions` | `--ClusterId` |
| 查询超级节点池 | `tccli tke DescribeClusterVirtualNodePools` | `--ClusterId` |
| 查询节点监控 | `tccli monitor GetMonitorData` | `--Namespace QCE/DOCKER` |

**代码示例 — 查询TKE集群节点状态汇总：**
```bash
tccli tke DescribeClusterInstances \
  --profile devops-readonly \
  --region ap-beijing \
  --ClusterId "cls-abc12345" \
  --Limit 100 | python3 -c "
import sys, json
d = json.load(sys.stdin)
nodes = d.get('InstanceSet', [])
total = d.get('TotalCount', 0)
running = sum(1 for n in nodes if n.get('InstanceState') == 'running')
abnormal = [n for n in nodes if n.get('InstanceState') != 'running']
print(f'节点总数: {total}  运行中: {running}  异常: {total-running}')
if abnormal:
    print('异常节点:')
    for n in abnormal:
        print(f\"  {n.get('InstanceId','')} {n.get('LanIP','')} 状态: {n.get('InstanceState','')}\")
"
```

---

## 弹性 MapReduce EMR

**tccli 服务标识：`emr`**

| 用户意图 | tccli 命令 | 关键参数 |
|---------|-----------|---------|
| 查询EMR集群列表 | `tccli emr DescribeInstances` | `--region`, `--DisplayStrategy`, `--Limit` |
| 查询集群节点 | `tccli emr DescribeClusterNodes` | `--InstanceId`, `--NodeFlag` |
| 查询集群服务信息 | `tccli emr DescribeServiceNodeInfos` | `--InstanceId` |
| 查询节点资源信息 | `tccli emr DescribeResourceSchedule` | `--InstanceId` |
| 查询EMR监控数据 | `tccli monitor GetMonitorData` | `--Namespace QCE/TXMR_HDFS` |
| 查询自动扩缩容记录 | `tccli emr DescribeAutoScaleRecords` | `--InstanceId` |

---

## 内容分发网络 CDN

**tccli 服务标识：`cdn`**

| 用户意图 | tccli 命令 | 关键参数 |
|---------|-----------|---------|
| 查询CDN域名列表 | `tccli cdn DescribeDomains` | `--Limit`, `--Offset`, `--Filters` |
| 查询域名详情 | `tccli cdn DescribeDomainsConfig` | `--Filters '[{"Name":"domain","Value":["xxx.com"]}]'` |
| 查询CDN带宽数据 | `tccli cdn DescribeCdnData` | `--StartTime`, `--EndTime`, `--Metric bandwidth` |
| 查询CDN流量数据 | `tccli cdn DescribeCdnData` | `--StartTime`, `--EndTime`, `--Metric flux` |
| 查询回源统计 | `tccli cdn DescribeOriginData` | `--StartTime`, `--EndTime`, `--Metric bandwidth` |
| 查询请求数统计 | `tccli cdn DescribeCdnData` | `--StartTime`, `--EndTime`, `--Metric requests` |
| 查询状态码统计 | `tccli cdn DescribeCdnData` | `--StartTime`, `--EndTime`, `--Metric statusCode` |
| 查询刷新预热记录 | `tccli cdn GetPurgeHistory` | `--StartTime`, `--EndTime` |
| 查询CDN IP归属 | `tccli cdn DescribeCdnIp` | `--Ips '["1.2.3.4"]'` |
| 查询TOP URL | `tccli cdn ListTopData` | `--StartTime`, `--EndTime`, `--Metric url` |

---

## 日志服务 CLS

**tccli 服务标识：`cls`**

| 用户意图 | tccli 命令 | 关键参数 |
|---------|-----------|---------|
| 查询日志集列表 | `tccli cls DescribeLogsets` | `--region`, `--Limit` |
| 查询日志主题列表 | `tccli cls DescribeTopics` | `--region`, `--Limit`, `--Filters` |
| 搜索日志 | `tccli cls SearchLog` | `--TopicId`, `--From`, `--To`, `--Query`, `--Limit` |
| 查询采集规则 | `tccli cls DescribeConfigMachineGroups` | `--ConfigId` |
| 查询机器组 | `tccli cls DescribeMachineGroups` | `--region`, `--Filters` |
| 查询导出任务 | `tccli cls DescribeExports` | `--TopicId` |
| 查询CLS告警策略 | `tccli cls DescribeAlarms` | `--region`, `--Filters` |
| 查询仪表盘 | `tccli cls DescribeDashboards` | `--region` |
| 查询索引配置 | `tccli cls DescribeIndex` | `--TopicId` |

---

## 云函数 SCF

**tccli 服务标识：`scf`**

| 用户意图 | tccli 命令 | 关键参数 |
|---------|-----------|---------|
| 查询函数列表 | `tccli scf ListFunctions` | `--region`, `--Limit`, `--Offset` |
| 查询函数详情 | `tccli scf GetFunction` | `--FunctionName`, `--Qualifier` |
| 查询函数版本 | `tccli scf ListVersionByFunction` | `--FunctionName` |
| 查询函数别名 | `tccli scf ListAliases` | `--FunctionName` |
| 查询触发器 | `tccli scf ListTriggers` | `--FunctionName` |
| 查询运行日志 | `tccli scf GetFunctionLogs` | `--FunctionName`, `--StartTime`, `--EndTime` |
| 查询异步事件 | `tccli scf ListAsyncEvents` | `--FunctionName`, `--Status` |
| 查询命名空间 | `tccli scf ListNamespaces` | `--Limit` |
| 查询层列表 | `tccli scf ListLayers` | `--Limit` |
| 查询层版本 | `tccli scf ListLayerVersions` | `--LayerName` |
| 查询预置并发 | `tccli scf GetProvisionedConcurrencyConfig` | `--FunctionName`, `--Qualifier` |

---

## 访问管理 CAM

**tccli 服务标识：`cam`**（全局服务，无需 `--region`）

| 用户意图 | tccli 命令 | 关键参数 |
|---------|-----------|---------|
| 查询子账号列表 | `tccli cam ListUsers` | |
| 查询子账号详情 | `tccli cam GetUser` | `--Name` 或 `--Uin` |
| 查询角色列表 | `tccli cam DescribeRoleList` | `--Page`, `--Rp` |
| 查询角色详情 | `tccli cam GetRole` | `--RoleName` 或 `--RoleId` |
| 查询策略列表 | `tccli cam ListPolicies` | `--Page`, `--Rp`, `--Scope` |
| 查询策略详情 | `tccli cam GetPolicy` | `--PolicyId` |
| 查询用户绑定策略 | `tccli cam ListAttachedUserPolicies` | `--TargetUin` |
| 查询角色绑定策略 | `tccli cam ListAttachedRolePolicies` | `--RoleId` 或 `--RoleName` |
| 查询用户组列表 | `tccli cam ListGroups` | `--Page`, `--Rp` |
| 查询用户所在组 | `tccli cam ListGroupsForUser` | `--Uid` |
| 查询组内用户 | `tccli cam GetGroupMemberInfo` | `--GroupId` |
| 查询组绑定策略 | `tccli cam ListAttachedGroupPolicies` | `--TargetGroupId` |
| 查询API密钥 | `tccli cam ListAccessKeys` | `--TargetUin` |
| 查询账号摘要 | `tccli cam GetSummary` | |
| 查询SAML提供商 | `tccli cam ListSAMLProviders` | |
| 查询身份提供商 | `tccli cam ListOIDCConfig` | |

**代码示例 — 查询角色及绑定策略：**
```bash
# Step1: 列出角色
tccli cam DescribeRoleList \
  --profile devops-readonly \
  --Page 1 --Rp 20 | python3 -c "
import sys, json
d = json.load(sys.stdin)
roles = d.get('List', [])
print(f'共 {d.get(\"TotalNum\", 0)} 个角色:')
for r in roles:
    print(f\"  [{r.get('RoleId','')}] {r.get('RoleName','')}\")
"

# Step2: 查询指定角色绑定的策略
tccli cam ListAttachedRolePolicies \
  --profile devops-readonly \
  --RoleName "CVM_QCSRole" \
  --Page 1 --Rp 50 | python3 -c "
import sys, json
d = json.load(sys.stdin)
policies = d.get('List', [])
print(f'绑定策略数: {d.get(\"TotalNum\", 0)}')
for p in policies:
    print(f\"  [{p.get('PolicyId','')}] {p.get('PolicyName','')} ({p.get('PolicyType','')})\")
"
```

---

## 云监控 Monitor

**tccli 服务标识：`monitor`**（大多数告警接口为全局）

| 用户意图 | tccli 命令 | 关键参数 |
|---------|-----------|---------|
| 查询告警策略列表 | `tccli monitor DescribeAlarmPolicies` | `--Module monitor` |
| 查询告警历史 | `tccli monitor DescribeAlarmHistories` | `--Module monitor`, `--StartTime`, `--EndTime` |
| 查询通知模板 | `tccli monitor DescribeAlarmNotices` | `--Module monitor` |
| 查询监控数据 | `tccli monitor GetMonitorData` | `--Namespace`, `--MetricName`, `--Period`, `--StartTime`, `--EndTime` |
| 查询指标列表 | `tccli monitor DescribeBaseMetrics` | `--Namespace` |
| 查询Prometheus实例 | `tccli monitor DescribePrometheusInstances` | `--region` |
| 查询Grafana实例 | `tccli monitor DescribeGrafanaInstances` | `--region` |

**常用 Namespace：**

| Namespace | 服务 | 常用指标 |
|-----------|------|---------|
| QCE/CVM | 云服务器 | CPUUsage, MemUsage, LanOuttraffic |
| QCE/CDB | MySQL | mysql_threads_connected, BytesSent |
| QCE/REDIS | Redis | MemUsed, MemUtil, Qps |
| QCE/LB_PUBLIC | 公网CLB | InPkg, OutBandwidth, HealthyRsCount |
| QCE/LB_PRIVATE | 内网CLB | InPkg, OutBandwidth |
| QCE/DOCKER | TKE | CpuUsageForNode, MemUsageForNode |
| QCE/CKAFKA | CKafka | MsgInPerSec, ConsumerLag |
| QCE/CBS | 云硬盘 | DiskReadTraffic, DiskWriteTraffic |
| QCE/CMONGO | MongoDB | Inserts, Reads, Connections |
| QCE/EMRV2 | EMR | YARNMemUsed, HDFSBlocksMissing |
| QCE/CDWDORIS | CDW-Doris | CPUUsage, MemUsage |

**代码示例 — 查询CVM最近1小时CPU使用率：**
```bash
START=$(date -u -v-1H '+%Y-%m-%dT%H:%M:%S+08:00' 2>/dev/null || date -u -d '1 hour ago' '+%Y-%m-%dT%H:%M:%S+08:00')
END=$(date -u '+%Y-%m-%dT%H:%M:%S+08:00')

tccli monitor GetMonitorData \
  --profile devops-readonly \
  --region ap-beijing \
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
    print(f'CPU使用率: 平均={avg:.1f}% 最大={max(dps):.1f}% 最小={min(dps):.1f}%')
"
```

---

## 容器镜像服务 TCR

**tccli 服务标识：`tcr`**

| 用户意图 | tccli 命令 | 关键参数 |
|---------|-----------|---------|
| 查询TCR实例列表 | `tccli tcr DescribeInstances` | `--region`, `--Limit` |
| 查询仓库列表 | `tccli tcr DescribeRepositories` | `--RegistryId`, `--Limit` |
| 查询镜像版本列表 | `tccli tcr DescribeImages` | `--RegistryId`, `--NamespaceName`, `--RepositoryName` |
| 查询命名空间 | `tccli tcr DescribeNamespaces` | `--RegistryId` |
| 查询内网访问链路 | `tccli tcr DescribeInternalEndpoints` | `--RegistryId` |
| 查询同步规则 | `tccli tcr DescribeReplicationInstances` | `--RegistryId` |

---

## 文件存储 CFS

**tccli 服务标识：`cfs`**

| 用户意图 | tccli 命令 | 关键参数 |
|---------|-----------|---------|
| 查询CFS实例列表 | `tccli cfs DescribeCfsFileSystems` | `--region`, `--FileSystemId` |
| 查询挂载点列表 | `tccli cfs DescribeMountTargets` | `--FileSystemId` |
| 查询CFS权限组 | `tccli cfs DescribeCfsPGroups` | |
| 查询权限组规则 | `tccli cfs DescribeCfsRules` | `--PGroupId` |
| 查询CFS可用区 | `tccli cfs DescribeAvailableZoneInfo` | `--region` |

---

## 私有域 DNS

**tccli 服务标识：`privatedns`**

| 用户意图 | tccli 命令 | 关键参数 |
|---------|-----------|---------|
| 查询私有域列表 | `tccli privatedns DescribePrivateZoneList` | `--Limit`, `--Offset` |
| 查询私有域详情 | `tccli privatedns DescribePrivateZone` | `--ZoneId` |
| 查询DNS记录列表 | `tccli privatedns DescribePrivateZoneRecordList` | `--ZoneId`, `--Limit` |
| 查询关联VPC | `tccli privatedns DescribePrivateZone` | （从返回字段 VpcSet 提取） |

---

## 数据仓库 CDW-Doris (TCHouse-D)

**tccli 服务标识：`cdwdoris`**

| 用户意图 | tccli 命令 | 关键参数 |
|---------|-----------|---------|
| 查询Doris实例列表 | `tccli cdwdoris DescribeInstances` | `--region`, `--Limit` |
| 查询实例详情 | `tccli cdwdoris DescribeInstance` | `--InstanceId` |
| 查询实例节点 | `tccli cdwdoris DescribeInstanceNodes` | `--InstanceId` |
| 查询监控数据 | `tccli monitor GetMonitorData` | `--Namespace QCE/CDWDORIS` |

---

## 轻量应用服务器 Lighthouse

**tccli 服务标识：`lighthouse`**

| 用户意图 | tccli 命令 | 关键参数 |
|---------|-----------|---------|
| 查询轻量实例列表 | `tccli lighthouse DescribeInstances` | `--region`, `--Limit` |
| 查询实例流量包 | `tccli lighthouse DescribeInstancesTrafficPackages` | `--InstanceIds` |
| 查询防火墙规则 | `tccli lighthouse DescribeFirewallRules` | `--InstanceId` |
| 查询快照列表 | `tccli lighthouse DescribeSnapshots` | `--Filters` |
| 查询套餐列表 | `tccli lighthouse DescribeBundles` | |
| 查询镜像列表 | `tccli lighthouse DescribeBlueprints` | `--Filters` |

---

## 账单与费用 Billing

**tccli 服务标识：`billing`**

| 用户意图 | tccli 命令 | 关键参数 |
|---------|-----------|---------|
| 查询月度账单摘要 | `tccli billing DescribeBillSummaryByProduct` | `--BeginTime`, `--EndTime` |
| 按项目查询费用 | `tccli billing DescribeBillSummaryByProject` | `--BeginTime`, `--EndTime` |
| 按地域查询费用 | `tccli billing DescribeBillSummaryByRegion` | `--BeginTime`, `--EndTime` |
| 查询费用详单 | `tccli billing DescribeBillDetail` | `--Month`, `--Limit`, `--Offset` |
| 查询账户余额 | `tccli billing DescribeAccountBalance` | |

---

## 身份验证 STS

**tccli 服务标识：`sts`**

| 用户意图 | tccli 命令 | 关键参数 |
|---------|-----------|---------|
| 验证当前身份 | `tccli sts GetCallerIdentity` | `--profile devops-readonly` |

---

## 附录：最佳实践

### 分页查询规范

tccli 大多数 Describe 接口支持 `--Limit`（默认20，最大100）和 `--Offset` 翻页：

```bash
# 翻页获取所有结果（以CVM为例）
OFFSET=0; LIMIT=100; TOTAL=0
while true; do
  RESULT=$(tccli cvm DescribeInstances \
    --profile devops-readonly \
    --region ap-beijing \
    --Limit $LIMIT --Offset $OFFSET)
  TOTAL=$(echo "$RESULT" | python3 -c "import sys,json;d=json.load(sys.stdin);print(d.get('TotalCount',0))")
  COUNT=$(echo "$RESULT" | python3 -c "import sys,json;d=json.load(sys.stdin);print(len(d.get('InstanceSet',[])))")
  echo "$RESULT" >> /tmp/cvm_all.json
  OFFSET=$((OFFSET + LIMIT))
  [ $OFFSET -ge $TOTAL ] && break
done
```

### 多地域查询模式

```bash
# 查询所有国内地域的资源（通用模板）
REGIONS="ap-beijing ap-beijing ap-shanghai ap-chengdu ap-nanjing"
for REGION in $REGIONS; do
  echo "=== $REGION ==="
  tccli cvm DescribeInstances \
    --profile devops-readonly \
    --region $REGION \
    --Limit 100 2>/dev/null
done
```

### 错误处理

```bash
# 捕获并处理 tccli 错误
RESULT=$(tccli cvm DescribeInstances \
  --profile devops-readonly \
  --region ap-beijing 2>&1)

if echo "$RESULT" | grep -q '"Error"'; then
  CODE=$(echo "$RESULT" | python3 -c "import sys,json;d=json.load(sys.stdin);print(d.get('Response',{}).get('Error',{}).get('Code',''))")
  MSG=$(echo "$RESULT" | python3 -c "import sys,json;d=json.load(sys.stdin);print(d.get('Response',{}).get('Error',{}).get('Message',''))")
  echo "❌ 错误: $CODE - $MSG"
  # 常见错误处理
  case $CODE in
    AuthFailure.SecretIdNotFound) echo "建议: 检查 devops-readonly profile 配置" ;;
    AuthFailure.SignatureExpire) echo "建议: 检查系统时间是否同步" ;;
    ResourceNotFound) echo "建议: 检查资源ID是否存在于该地域" ;;
    *) echo "建议: 使用 tccli <service> <Action> --help 查看参数" ;;
  esac
else
  echo "$RESULT"
fi
```

### 常用 python3 结果处理片段

```python
# 提取列表总数
python3 -c "import sys,json;d=json.load(sys.stdin);print(d.get('TotalCount',0))"

# 格式化输出表格（CVM示例）
python3 -c "
import sys, json
d = json.load(sys.stdin)
for ins in d.get('InstanceSet', []):
    print(f\"{ins['InstanceId']:<15} {ins.get('InstanceName',''):<25} {ins.get('InstanceState',''):<10}\")
"

# 过滤特定状态（STOPPED）
python3 -c "
import sys, json
d = json.load(sys.stdin)
stopped = [i for i in d.get('InstanceSet',[]) if i.get('InstanceState') == 'STOPPED']
print(f'已停止: {len(stopped)} 台')
for i in stopped:
    print(f\"  {i['InstanceId']} {i.get('InstanceName','')}\")
"
```

### 常见错误代码

| 错误代码 | 说明 | 处理建议 |
|---------|------|---------|
| AuthFailure.SecretIdNotFound | SecretId不存在 | 检查profile配置 |
| AuthFailure.SignatureExpire | 签名过期 | 检查系统时间 |
| AuthFailure.TokenFailure | Token失效 | 检查临时密钥 |
| ResourceNotFound | 资源不存在 | 检查资源ID和地域 |
| LimitExceeded | 超出限制 | 减少请求频率 |
| RequestLimitExceeded | 请求频率超限 | 添加sleep延迟 |
| InvalidParameterValue | 参数值不合法 | 检查参数格式 |
| MissingParameter | 缺少必要参数 | 查看help补全参数 |
