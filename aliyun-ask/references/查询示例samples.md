# Aliyun Ask 查询示例 (Query Samples)

> 所有 CLI 命令默认使用 `cn-beijing` 地域，如需其他地域请替换 `--RegionId` 参数。

---

## 目录

| 类别 | 示例 | 复杂度 |
|------|------|--------|
| ECS 弹性计算 | 示例1-4 | L1-L3 |
| RDS 数据库 | 示例5-6 | L1-L2 |
| SLB/ALB 负载均衡 | 示例7-9 | L2-L3 |
| VPC 网络 | 示例10-11 | L2-L3 |
| Redis 缓存 | 示例12 | L1-L2 |
| OSS 对象存储 | 示例13 | L1 |
| ESS 弹性伸缩 | 示例14 | L2-L3 |
| CEN 云企业网 | 示例15 | L2-L3 |
| NAT 网关 | 示例16 | L2 |
| CR 容器镜像 | 示例17 | L2 |
| 综合诊断 | 示例18-21 | L4-L5 |
| 批量导出 | 示例22-23 | L3-L4 |
| 安全审计 | 示例24-25 | L4 |

---

## 一、ECS 弹性计算查询

### 示例1：查询所有运行中的 ECS 实例

**用户查询**: "列出北京地域所有运行中的 ECS 实例"

```bash
aliyun ecs DescribeInstances \
  --RegionId cn-beijing \
  --Status Running \
  --PageSize 100 \
  | jq '.Instances.Instance[] | {
      InstanceId,
      InstanceName,
      Status,
      InstanceType,
      Cpu,
      Memory: (.Memory / 1024 | tostring) + "GB",
      PrivateIp: .VpcAttributes.PrivateIpAddress.IpAddress[0],
      PublicIp: (.PublicIpAddress.IpAddress[0] // .EipAddress.IpAddress // "N/A"),
      VpcId: .VpcAttributes.VpcId,
      ZoneId,
      CreationTime
    }'
```

**预期输出**:
```json
{
  "InstanceId": "i-2ze1234567890abcd",
  "InstanceName": "web-server-01",
  "Status": "Running",
  "InstanceType": "ecs.g6.large",
  "Cpu": 2,
  "Memory": "8GB",
  "PrivateIp": "172.16.1.10",
  "PublicIp": "47.95.123.45",
  "VpcId": "vpc-2ze1234567890abcd",
  "ZoneId": "cn-beijing-h",
  "CreationTime": "2025-06-01T08:00Z"
}
```

---

### 示例2：查询单个 ECS 实例详情

**用户查询**: "查看 ECS 实例 i-2ze1234567890abcd 的详细信息"

```bash
aliyun ecs DescribeInstanceAttribute \
  --InstanceId i-2ze1234567890abcd \
  | jq '{
      InstanceId,
      InstanceName,
      Status,
      InstanceType,
      Cpu,
      Memory: (.Memory / 1024 | tostring) + "GB",
      PrivateIp: .VpcAttributes.PrivateIpAddress.IpAddress[0],
      SecurityGroupIds: .SecurityGroupIds.SecurityGroupId,
      VpcId: .VpcAttributes.VpcId,
      VSwitchId: .VpcAttributes.VSwitchId,
      ZoneId,
      ImageId,
      CreationTime,
      ExpiredTime
    }'
```

---

### 示例3：查询 ECS 挂载的云盘

**用户查询**: "ECS 实例 i-2ze1234567890abcd 挂载了哪些云盘？"

```bash
aliyun ecs DescribeDisks \
  --RegionId cn-beijing \
  --InstanceId i-2ze1234567890abcd \
  | jq '.Disks.Disk[] | {
      DiskId,
      DiskName,
      Type,
      Category,
      Size: (.Size | tostring) + "GB",
      Status,
      Device,
      DeleteWithInstance,
      Encrypted
    }'
```

**预期输出**:
```json
{
  "DiskId": "d-2ze1234567890abcd",
  "DiskName": "系统盘",
  "Type": "system",
  "Category": "cloud_essd",
  "Size": "40GB",
  "Status": "In_use",
  "Device": "/dev/xvda",
  "DeleteWithInstance": true,
  "Encrypted": false
}
```

---

### 示例4：按实例类型统计 ECS

**用户查询**: "统计北京地域所有运行中的 ECS，按实例类型分组显示数量"

```bash
aliyun ecs DescribeInstances \
  --RegionId cn-beijing \
  --Status Running \
  --PageSize 100 \
  | jq '
    [.Instances.Instance[].InstanceType] |
    group_by(.) |
    map({类型: .[0], 数量: length}) |
    sort_by(.数量) |
    reverse
  '
```

**预期输出**:
```json
[
  {"类型": "ecs.g6.large", "数量": 15},
  {"类型": "ecs.c6.xlarge", "数量": 8},
  {"类型": "ecs.r6.2xlarge", "数量": 3}
]
```

---

## 二、RDS 数据库查询

### 示例5：查询所有 RDS 实例列表

**用户查询**: "列出所有 RDS 数据库实例"

```bash
aliyun rds DescribeDBInstances \
  --RegionId cn-beijing \
  | jq '.Items.DBInstance[] | {
      DBInstanceId,
      DBInstanceDescription,
      DBInstanceStatus,
      Engine,
      EngineVersion,
      DBInstanceClass,
      DBInstanceStorage: (.DBInstanceStorage | tostring) + "GB",
      ConnectionString,
      VpcId,
      ZoneId,
      PayType,
      ExpireTime
    }'
```

---

### 示例6：查询 RDS 实例的数据库和账号

**用户查询**: "查看 RDS 实例 rm-2ze1234567890 下有哪些数据库和账号"

```bash
# Step 1: 查询数据库列表
echo "=== 数据库列表 ==="
aliyun rds DescribeDatabases \
  --DBInstanceId rm-2ze1234567890 \
  | jq '.Databases.Database[] | {DBName, DBStatus, CharacterSetName}'

# Step 2: 查询账号列表
echo "=== 账号列表 ==="
aliyun rds DescribeAccounts \
  --DBInstanceId rm-2ze1234567890 \
  | jq '.Accounts.DBInstanceAccount[] | {AccountName, AccountStatus, AccountType, DatabasePrivileges: [.DatabasePrivileges.DatabasePrivilege[] | {DBName, AccountPrivilege}]}'
```

---

## 三、SLB/ALB 负载均衡查询

### 示例7：查询所有 SLB 实例及监听

**用户查询**: "列出所有 SLB 实例和它们的监听配置"

```bash
# Step 1: 查询 SLB 列表
aliyun slb DescribeLoadBalancers \
  --RegionId cn-beijing \
  | jq '.LoadBalancers.LoadBalancer[] | {
      LoadBalancerId,
      LoadBalancerName,
      Address,
      AddressType,
      LoadBalancerStatus,
      VpcId,
      PayType
    }'

# Step 2: 查询指定 SLB 的监听列表
aliyun slb DescribeLoadBalancerListeners \
  --RegionId cn-beijing \
  --LoadBalancerId lb-2ze1234567890abcd \
  | jq '.Listeners.Listener[] | {
      ListenerPort,
      ListenerProtocol,
      Status: .Status,
      BackendServerPort,
      AclStatus,
      AclType,
      AclIds: .AclIds
    }'
```

---

### 示例8：查询 ALB 监听器和转发规则

**用户查询**: "查看 ALB alb-2ze1234567890abcd 的监听器和转发规则"

```bash
ALB_ID="alb-2ze1234567890abcd"
REGION="cn-beijing"

# Step 1: 查询 ALB 基本信息
echo "=== ALB 信息 ==="
aliyun alb GetLoadBalancerAttribute \
  --LoadBalancerId $ALB_ID \
  | jq '{LoadBalancerId, LoadBalancerName, AddressType, LoadBalancerStatus, VpcId}'

# Step 2: 查询监听器列表
echo "=== 监听器列表 ==="
aliyun alb ListListeners \
  --LoadBalancerIds.1 $ALB_ID \
  | jq '.Listeners[] | {ListenerId, ListenerProtocol, ListenerPort, ListenerStatus}'

# Step 3: 查询转发规则（需要 ListenerId）
LISTENER_ID="lsn-2ze1234567890abcd"
echo "=== 转发规则 ==="
aliyun alb ListRules \
  --ListenerId $LISTENER_ID \
  | jq '.Rules[] | {
      RuleId,
      RuleName,
      Priority,
      RuleConditions: [.RuleConditions[] | {Type, HostConfig, PathConfig}],
      RuleActions: [.RuleActions[] | {Type, ForwardGroupConfig}]
    }'
```

---

### 示例9：查询 SLB 后端服务器健康状态

**用户查询**: "查看 SLB lb-xxx 的后端服务器健康状态"

```bash
LB_ID="lb-2ze1234567890abcd"

# Step 1: 查询虚拟服务器组
echo "=== 虚拟服务器组 ==="
aliyun slb DescribeVServerGroups \
  --RegionId cn-beijing \
  --LoadBalancerId $LB_ID \
  | jq '.VServerGroups.VServerGroup[] | {VServerGroupId, VServerGroupName}'

# Step 2: 查询健康检查状态
echo "=== 健康检查状态 ==="
aliyun slb DescribeHealthStatus \
  --RegionId cn-beijing \
  --LoadBalancerId $LB_ID \
  | jq '.BackendServers.BackendServer[] | {
      ServerId,
      ServerHealthStatus,
      ListenerPort,
      Port
    }'
```

---

## 四、VPC 网络查询

### 示例10：查询 VPC 下的所有资源

**用户查询**: "VPC vpc-2ze1234567890abcd 下有哪些交换机和 ECS 实例？"

```bash
VPC_ID="vpc-2ze1234567890abcd"
REGION="cn-beijing"

# Step 1: 查询 VPC 基本信息
echo "=== VPC 信息 ==="
aliyun vpc DescribeVpcAttribute \
  --VpcId $VPC_ID \
  --RegionId $REGION \
  | jq '{VpcId, VpcName, CidrBlock, Status, VSwitchIds}'

# Step 2: 查询交换机
echo "=== 交换机列表 ==="
aliyun vpc DescribeVSwitches \
  --VpcId $VPC_ID \
  --RegionId $REGION \
  | jq '.VSwitches.VSwitch[] | {
      VSwitchId,
      VSwitchName,
      CidrBlock,
      ZoneId,
      AvailableIpAddressCount,
      Status
    }'

# Step 3: 查询 VPC 下的 ECS 实例
echo "=== ECS 实例列表 ==="
aliyun ecs DescribeInstances \
  --RegionId $REGION \
  --VpcId $VPC_ID \
  --PageSize 100 \
  | jq '.Instances.Instance[] | {
      InstanceId,
      InstanceName,
      Status,
      PrivateIp: .VpcAttributes.PrivateIpAddress.IpAddress[0],
      VSwitchId: .VpcAttributes.VSwitchId
    }'
```

---

### 示例11：查询 EIP 绑定关系

**用户查询**: "列出所有 EIP 及其绑定的资源"

```bash
aliyun vpc DescribeEipAddresses \
  --RegionId cn-beijing \
  --PageSize 100 \
  | jq '.EipAddresses.EipAddress[] | {
      AllocationId,
      IpAddress,
      Status,
      InstanceId,
      InstanceType,
      Bandwidth: (.Bandwidth | tostring) + "Mbps",
      ChargeType: .InternetChargeType
    }'
```

---

## 五、Redis 缓存查询

### 示例12：查询所有 Redis 实例

**用户查询**: "列出所有 Redis 实例及其连接信息"

```bash
aliyun r-kvstore DescribeInstances \
  --RegionId cn-beijing \
  --PageSize 50 \
  | jq '.Instances.KVStoreInstance[] | {
      InstanceId,
      InstanceName,
      InstanceStatus,
      InstanceClass,
      ArchitectureType,
      EngineVersion,
      ConnectionDomain,
      PrivateIp,
      Bandwidth: (.Bandwidth | tostring) + "MB/s",
      Capacity: (.Capacity | tostring) + "MB",
      VpcId
    }'
```

---

## 六、OSS 对象存储查询

### 示例13：查询所有 OSS Bucket

**用户查询**: "列出所有 OSS Bucket 及其基本信息"

```bash
# 列出所有 Bucket
aliyun oss ls

# 查询指定 Bucket 的详细信息
aliyun oss stat oss://my-bucket
```

---

## 七、ESS 弹性伸缩查询

### 示例14：查询伸缩组及其实例

**用户查询**: "查看伸缩组 asg-xxx 的配置和当前实例列表"

```bash
ASG_ID="asg-2ze1234567890abcd"
REGION="cn-beijing"

# Step 1: 查询伸缩组详情
echo "=== 伸缩组信息 ==="
aliyun ess DescribeScalingGroups \
  --RegionId $REGION \
  --ScalingGroupId.1 $ASG_ID \
  | jq '.ScalingGroups.ScalingGroup[] | {
      ScalingGroupId,
      ScalingGroupName,
      MinSize,
      MaxSize,
      DesiredCapacity,
      ActiveCapacity,
      LifecycleState,
      VpcId,
      LoadBalancerIds,
      DBInstanceIds
    }'

# Step 2: 查询伸缩组内的实例
echo "=== 伸缩组内实例 ==="
aliyun ess DescribeScalingInstances \
  --RegionId $REGION \
  --ScalingGroupId $ASG_ID \
  --PageSize 50 \
  | jq '.ScalingInstances.ScalingInstance[] | {
      InstanceId,
      LifecycleState,
      HealthStatus,
      CreationType,
      ScalingConfigurationId,
      CreationTime
    }'

# Step 3: 查询最近的伸缩活动
echo "=== 最近伸缩活动 ==="
aliyun ess DescribeScalingActivities \
  --RegionId $REGION \
  --ScalingGroupId $ASG_ID \
  --PageSize 10 \
  | jq '.ScalingActivities.ScalingActivity[] | {
      ScalingActivityId,
      StatusCode,
      Cause: (.Cause[:80]),
      TotalCapacity,
      StartTime,
      EndTime
    }'
```

---

## 八、CEN 云企业网查询

### 示例15：查询云企业网拓扑

**用户查询**: "查看云企业网 cen-xxx 挂载了哪些 VPC，跨地域带宽是多少"

```bash
CEN_ID="cen-y6g4qm5bg2jur8ic89"

# Step 1: 查询 CEN 基本信息
echo "=== CEN 信息 ==="
aliyun cbn DescribeCens \
  | jq --arg cen "$CEN_ID" '.Cens.Cen[] | select(.CenId == $cen) | {CenId, Name, Status}'

# Step 2: 查询挂载的网络实例
echo "=== 挂载的网络实例 ==="
aliyun cbn DescribeCenAttachedChildInstances \
  --CenId $CEN_ID \
  --PageSize 50 \
  | jq '.ChildInstances.ChildInstance[] | {
      ChildInstanceId,
      ChildInstanceType,
      ChildInstanceRegionId,
      Status
    }'

# Step 3: 查询转发路由器
echo "=== 转发路由器 ==="
aliyun cbn ListTransitRouters \
  --CenId $CEN_ID \
  | jq '.TransitRouters[] | {
      TransitRouterId,
      TransitRouterName,
      RegionId,
      Status
    }'

# Step 4: 查询带宽包
echo "=== 跨地域带宽包 ==="
aliyun cbn DescribeCenBandwidthPackages \
  | jq --arg cen "$CEN_ID" '.CenBandwidthPackages.CenBandwidthPackage[] | select(.CenIds.CenId[] == $cen) | {
      CenBandwidthPackageId,
      Bandwidth: (.Bandwidth | tostring) + "Mbps",
      GeographicRegionAId,
      GeographicRegionBId,
      Status
    }'
```

---

## 九、NAT 网关查询

### 示例16：查询 NAT 网关的 SNAT/DNAT 规则

**用户查询**: "查看 VPC 下 NAT 网关的 SNAT 和 DNAT 规则"

```bash
REGION="cn-beijing"

# Step 1: 查询 NAT 网关列表
echo "=== NAT 网关列表 ==="
aliyun vpc DescribeNatGateways \
  --RegionId $REGION \
  | jq '.NatGateways.NatGateway[] | {
      NatGatewayId,
      Name,
      VpcId,
      NatType,
      Status,
      SnatTableIds: .SnatTableIds.SnatTableId,
      ForwardTableIds: .ForwardTableIds.ForwardTableId
    }'

# Step 2: 查询 SNAT 规则（需要 SnatTableId）
SNAT_TABLE_ID="stb-2ze1234567890abcd"
echo "=== SNAT 规则 ==="
aliyun vpc DescribeSnatTableEntries \
  --RegionId $REGION \
  --SnatTableId $SNAT_TABLE_ID \
  | jq '.SnatTableEntries.SnatTableEntry[] | {
      SnatEntryId,
      SnatEntryName,
      SourceVSwitchId,
      SourceCIDR,
      SnatIp,
      Status
    }'

# Step 3: 查询 DNAT 规则（需要 ForwardTableId）
FORWARD_TABLE_ID="ftb-2ze1234567890abcd"
echo "=== DNAT 规则 ==="
aliyun vpc DescribeForwardTableEntries \
  --RegionId $REGION \
  --ForwardTableId $FORWARD_TABLE_ID \
  | jq '.ForwardTableEntries.ForwardTableEntry[] | {
      ForwardEntryId,
      ForwardEntryName,
      ExternalIp,
      ExternalPort,
      InternalIp,
      InternalPort,
      IpProtocol,
      Status
    }'
```

---

## 十、CR 容器镜像查询

### 示例17：查询容器镜像仓库和版本

**用户查询**: "列出 CR 企业版实例的命名空间和镜像仓库"

```bash
# Step 1: 查询 CR 企业版实例
echo "=== CR 实例列表 ==="
aliyun cr ListInstance \
  | jq '.Instances[] | {
      InstanceId,
      InstanceName,
      InstanceStatus,
      RegionId,
      CreateTime
    }'

# Step 2: 查询命名空间（需要 InstanceId）
INSTANCE_ID="cri-1234567890abcdef"
echo "=== 命名空间列表 ==="
aliyun cr ListNamespace \
  --InstanceId $INSTANCE_ID \
  | jq '.Namespaces[] | {
      NamespaceName,
      NamespaceStatus,
      AutoCreateRepo,
      DefaultRepoType
    }'

# Step 3: 查询镜像仓库
echo "=== 镜像仓库列表 ==="
aliyun cr ListRepository \
  --InstanceId $INSTANCE_ID \
  --PageSize 50 \
  | jq '.Repositories[] | {
      RepoId,
      RepoName,
      RepoNamespaceName,
      RepoType,
      Summary,
      CreateTime
    }'
```

---

## 十一、综合诊断示例 (L4-L5)

### 示例18：安全组高危端口检查

**用户查询**: "检查所有安全组，是否有 22/3389/3306 端口对 0.0.0.0/0 开放？"

```bash
REGION="cn-beijing"

echo "=== 安全组高危端口检查 ==="
# 获取所有安全组
SG_IDS=$(aliyun ecs DescribeSecurityGroups \
  --RegionId $REGION \
  --PageSize 100 \
  | jq -r '.SecurityGroups.SecurityGroup[].SecurityGroupId')

for sg_id in $SG_IDS; do
  aliyun ecs DescribeSecurityGroupAttribute \
    --RegionId $REGION \
    --SecurityGroupId $sg_id \
    --Direction ingress \
    | jq --arg sg "$sg_id" '
      .Permissions.Permission[] |
      select(
        .SourceCidrIp == "0.0.0.0/0" and
        (.IpProtocol == "TCP" or .IpProtocol == "ALL") and
        (
          (.PortRange | split("/") | (.[0] | tonumber) <= 22 and (.[1] | tonumber) >= 22) or
          (.PortRange | split("/") | (.[0] | tonumber) <= 3389 and (.[1] | tonumber) >= 3389) or
          (.PortRange | split("/") | (.[0] | tonumber) <= 3306 and (.[1] | tonumber) >= 3306) or
          .PortRange == "-1/-1"
        )
      ) |
      {
        风险: "⚠️ 高危",
        安全组ID: $sg,
        协议: .IpProtocol,
        端口范围: .PortRange,
        来源: .SourceCidrIp,
        策略: .Policy,
        描述: (.Description // "无描述")
      }
    ' 2>/dev/null
done
```

---

### 示例19：VPC 全栈资源拓扑

**用户查询**: "列出 VPC vpc-xxx 下的 ECS、RDS、SLB、Redis 所有资源"

```bash
VPC_ID="vpc-2ze1234567890abcd"
REGION="cn-beijing"

echo "=== EC2 实例 ==="
aliyun ecs DescribeInstances \
  --RegionId $REGION \
  --VpcId $VPC_ID \
  --PageSize 100 \
  | jq '.Instances.Instance[] | {类型: "ECS", ID: .InstanceId, 名称: .InstanceName, IP: .VpcAttributes.PrivateIpAddress.IpAddress[0], 状态: .Status}'

echo "=== RDS 实例 ==="
aliyun rds DescribeDBInstances \
  --RegionId $REGION \
  | jq --arg vpc "$VPC_ID" '
    .Items.DBInstance[] |
    select(.VpcId == $vpc) |
    {类型: "RDS", ID: .DBInstanceId, 名称: .DBInstanceDescription, 引擎: (.Engine + " " + .EngineVersion), 状态: .DBInstanceStatus}
  '

echo "=== SLB 实例 ==="
aliyun slb DescribeLoadBalancers \
  --RegionId $REGION \
  --VpcId $VPC_ID \
  | jq '.LoadBalancers.LoadBalancer[] | {类型: "SLB", ID: .LoadBalancerId, 名称: .LoadBalancerName, 地址: .Address, 类型2: .AddressType, 状态: .LoadBalancerStatus}'

echo "=== Redis 实例 ==="
aliyun r-kvstore DescribeInstances \
  --RegionId $REGION \
  --VpcId $VPC_ID \
  | jq '.Instances.KVStoreInstance[] | {类型: "Redis", ID: .InstanceId, 名称: .InstanceName, 连接: .ConnectionDomain, 状态: .InstanceStatus}'
```

---

### 示例20：SLB 后端健康全面诊断

**用户查询**: "诊断所有 SLB 的后端服务器健康状态，找出不健康的实例"

```bash
REGION="cn-beijing"

echo "=== SLB 后端健康诊断 ==="
# 获取所有 SLB
LB_IDS=$(aliyun slb DescribeLoadBalancers \
  --RegionId $REGION \
  --PageSize 100 \
  | jq -r '.LoadBalancers.LoadBalancer[] | .LoadBalancerId + "|" + .LoadBalancerName')

for lb_info in $LB_IDS; do
  LB_ID=$(echo $lb_info | cut -d'|' -f1)
  LB_NAME=$(echo $lb_info | cut -d'|' -f2)

  UNHEALTHY=$(aliyun slb DescribeHealthStatus \
    --RegionId $REGION \
    --LoadBalancerId $LB_ID \
    | jq '[.BackendServers.BackendServer[] | select(.ServerHealthStatus != "normal")] | length')

  if [ "$UNHEALTHY" -gt 0 ] 2>/dev/null; then
    echo "⚠️  SLB: $LB_NAME ($LB_ID) - $UNHEALTHY 个不健康后端"
    aliyun slb DescribeHealthStatus \
      --RegionId $REGION \
      --LoadBalancerId $LB_ID \
      | jq '.BackendServers.BackendServer[] | select(.ServerHealthStatus != "normal") | {
          ServerId,
          ServerHealthStatus,
          ListenerPort,
          Port
        }'
  fi
done
```

---

### 示例21：SSL 证书到期检查

**用户查询**: "检查所有 SSL 证书，哪些即将在 30 天内到期？"

```bash
echo "=== SSL 证书到期检查 ==="
aliyun cas ListUserCertificateOrder \
  --endpoint cas.aliyuncs.com \
  --OrderType CERT \
  --Status ISSUED \
  | jq --arg cutoff "$(date -v+30d +%s 2>/dev/null || date -d '+30 days' +%s)" '
    .CertificateOrderList[] |
    select(.CertEndTime != null) |
    select((.CertEndTime / 1000) < ($cutoff | tonumber)) |
    {
      风险: "⚠️ 即将到期",
      证书名: .Name,
      域名: .Domain,
      到期时间: (.CertEndTime / 1000 | strftime("%Y-%m-%d")),
      剩余天数: (((.CertEndTime / 1000) - now) / 86400 | floor)
    }
  '
```

---

## 十二、批量导出示例 (L3-L4)

### 示例22：导出所有 ECS 实例清单

**用户查询**: "导出所有 ECS 实例的完整清单到文件"

```bash
REGION="cn-beijing"
OUTPUT_FILE="aliyun_memos/tmp/ecs_inventory_$(date +%Y%m%d_%H%M).json"
mkdir -p aliyun_memos/tmp

aliyun ecs DescribeInstances \
  --RegionId $REGION \
  --PageSize 100 \
  | jq '[.Instances.Instance[] | {
      InstanceId,
      InstanceName,
      Status,
      InstanceType,
      Cpu,
      Memory: (.Memory / 1024),
      PrivateIp: .VpcAttributes.PrivateIpAddress.IpAddress[0],
      PublicIp: (.PublicIpAddress.IpAddress[0] // .EipAddress.IpAddress // "N/A"),
      VpcId: .VpcAttributes.VpcId,
      VSwitchId: .VpcAttributes.VSwitchId,
      SecurityGroups: .SecurityGroupIds.SecurityGroupId,
      ZoneId,
      OSName: .OSName,
      CreationTime,
      ExpiredTime,
      ChargeType: .InstanceChargeType,
      Tags: [(.Tags.Tag[]? | {Key: .TagKey, Value: .TagValue})]
    }]' > $OUTPUT_FILE

echo "已导出到: $OUTPUT_FILE"
echo "实例总数: $(jq 'length' $OUTPUT_FILE)"
```

---

### 示例23：导出所有安全组规则

**用户查询**: "导出所有安全组及其入站规则"

```bash
REGION="cn-beijing"
OUTPUT_FILE="aliyun_memos/tmp/sg_rules_$(date +%Y%m%d_%H%M).json"
mkdir -p aliyun_memos/tmp

echo "[]" > $OUTPUT_FILE

SG_IDS=$(aliyun ecs DescribeSecurityGroups \
  --RegionId $REGION \
  --PageSize 100 \
  | jq -r '.SecurityGroups.SecurityGroup[] | .SecurityGroupId + "|" + .SecurityGroupName')

for sg_info in $SG_IDS; do
  SG_ID=$(echo $sg_info | cut -d'|' -f1)
  SG_NAME=$(echo $sg_info | cut -d'|' -f2)

  aliyun ecs DescribeSecurityGroupAttribute \
    --RegionId $REGION \
    --SecurityGroupId $SG_ID \
    --Direction ingress \
    | jq --arg sg_id "$SG_ID" --arg sg_name "$SG_NAME" '{
        SecurityGroupId: $sg_id,
        SecurityGroupName: $sg_name,
        IngressRules: [.Permissions.Permission[] | {
          IpProtocol,
          PortRange,
          SourceCidrIp,
          Policy,
          Description
        }]
      }' >> $OUTPUT_FILE

  sleep 0.2
done

echo "已导出到: $OUTPUT_FILE"
echo "安全组总数: $(jq -s 'length' $OUTPUT_FILE)"
```

---

## 十三、安全审计示例 (L4)

### 示例24：云安全中心漏洞和告警检查

**用户查询**: "查看云安全中心的高危漏洞和最近的安全告警"

```bash
echo "=== 云安全中心安全评分 ==="
aliyun sas DescribeSecurityStatInfo \
  | jq '{SecurityScore: .SecurityScore}'

echo "=== 高危漏洞列表 ==="
aliyun sas DescribeVulList \
  --Type cve \
  --Necessity asap \
  --PageSize 20 \
  | jq '.VulRecords[] | {
      Name,
      AliasName,
      Necessity,
      Level: .Level,
      InstanceName,
      Ip,
      FirstTs: (.FirstTs | strftime("%Y-%m-%d")),
      Status
    }'

echo "=== 最近安全告警 ==="
aliyun sas DescribeAlarmEventList \
  --From sas \
  --Levels serious \
  --PageSize 10 \
  | jq '.SuspEvents[] | {
      AlarmEventName,
      Level,
      InstanceName,
      InternetIp,
      IntranetIp,
      AlarmUniqueInfo,
      StartTime: (.StartTime | tostring)
    }'
```

---

### 示例25：全账号资源安全合规报告

**用户查询**: "生成一个账号安全合规检查报告"

```bash
REGION="cn-beijing"

echo "============================================="
echo " 阿里云账号安全合规检查报告"
echo " 时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo " 地域: $REGION"
echo "============================================="

echo ""
echo "## 1. ECS 安全检查"

# 1.1 安全组高危端口统计
TOTAL_SG=$(aliyun ecs DescribeSecurityGroups \
  --RegionId $REGION \
  --PageSize 1 \
  | jq '.TotalCount')
echo "  安全组总数: $TOTAL_SG"

# 1.2 运行中实例统计
RUNNING_ECS=$(aliyun ecs DescribeInstances \
  --RegionId $REGION \
  --Status Running \
  --PageSize 1 \
  | jq '.TotalCount')
echo "  运行中 ECS: $RUNNING_ECS"

echo ""
echo "## 2. 数据库安全检查"

# 2.1 RDS 实例统计
RDS_COUNT=$(aliyun rds DescribeDBInstances \
  --RegionId $REGION \
  | jq '.Items.DBInstance | length')
echo "  RDS 实例数: $RDS_COUNT"

# 2.2 Redis 实例统计
REDIS_COUNT=$(aliyun r-kvstore DescribeInstances \
  --RegionId $REGION \
  | jq '.Instances.KVStoreInstance | length')
echo "  Redis 实例数: $REDIS_COUNT"

echo ""
echo "## 3. 网络安全检查"

# 3.1 公网 SLB 统计
PUBLIC_SLB=$(aliyun slb DescribeLoadBalancers \
  --RegionId $REGION \
  --AddressType internet \
  | jq '.LoadBalancers.LoadBalancer | length')
echo "  公网 SLB 数: $PUBLIC_SLB"

# 3.2 EIP 统计
EIP_COUNT=$(aliyun vpc DescribeEipAddresses \
  --RegionId $REGION \
  --PageSize 1 \
  | jq '.TotalCount')
echo "  EIP 总数: $EIP_COUNT"

echo ""
echo "## 4. 云安全中心"
aliyun sas DescribeVersionConfig \
  | jq '{版本: .Version, 授权数: .InstanceCount, 已使用: .AssetLevel}'

echo ""
echo "============================================="
echo " 报告生成完毕"
echo "============================================="
```

---

## 十四、常用 jq 处理模式

### 14.1 提取 ECS Name 标签

```bash
# ECS 实例的 Tags 提取
.Tags.Tag[] | select(.TagKey == "Name") | .TagValue
```

### 14.2 处理分页查询

```bash
# 阿里云 CLI 分页查询模式
PAGE=1
while true; do
  RESULT=$(aliyun ecs DescribeInstances \
    --RegionId cn-beijing \
    --PageNumber $PAGE \
    --PageSize 100)
  
  TOTAL=$(echo $RESULT | jq '.TotalCount')
  echo $RESULT | jq '.Instances.Instance[]'
  
  if [ $((PAGE * 100)) -ge $TOTAL ]; then break; fi
  PAGE=$((PAGE + 1))
done
```

### 14.3 多条件过滤

```bash
# 按标签过滤 ECS
aliyun ecs DescribeInstances \
  --RegionId cn-beijing \
  --Tag.1.Key "env" \
  --Tag.1.Value "production" \
  --Status Running \
  | jq '.Instances.Instance[] | {InstanceId, InstanceName, Status}'
```

### 14.4 JSON 数组聚合统计

```bash
# 按可用区统计 ECS 数量
aliyun ecs DescribeInstances \
  --RegionId cn-beijing \
  --PageSize 100 \
  | jq '
    [.Instances.Instance[].ZoneId] |
    group_by(.) |
    map({可用区: .[0], 数量: length})
  '
```

### 14.5 跨服务数据关联

```bash
# 查询 ECS 实例并关联其 EIP 信息
aliyun ecs DescribeInstances \
  --RegionId cn-beijing \
  --PageSize 100 \
  | jq '.Instances.Instance[] | {
      InstanceId,
      InstanceName,
      PrivateIp: .VpcAttributes.PrivateIpAddress.IpAddress[0],
      EipAddress: (.EipAddress.IpAddress // "无"),
      EipBandwidth: ((.EipAddress.Bandwidth // 0) | tostring) + "Mbps"
    }'
```
