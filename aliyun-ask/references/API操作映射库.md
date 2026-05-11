# 阿里云核心服务 API 操作映射知识库

> **版本**: v2.1 | **更新日期**: 2025-01-16

## 📖 快速索引

| 分类 | 服务 | 核心资源 | 查询复杂度 |
|------|------|----------|------------|
| 🖥️ **计算** | [ECS](#1-ecs-弹性计算服务) | Instance, Disk, SecurityGroup | ⭐⭐⭐ |
| 🗄️ **数据库** | [RDS](#2-rds-关系型数据库) | DBInstance, Database | ⭐⭐ |
| 🗄️ **数据库** | [Redis](#3-redis-缓存数据库) | Instance, Account | ⭐⭐ |
| 🗄️ **数据库** | [MongoDB](#4-mongodb-文档数据库) | DBInstance | ⭐ |
| 🗄️ **数据库** | [PolarDB](#5-polardb-云原生数据库) | DBCluster, DBNode | ⭐⭐ |
| ⚖️ **负载均衡** | [SLB](#6-slb-传统负载均衡) | LoadBalancer, Listener | ⭐⭐ |
| ⚖️ **负载均衡** | [ALB](#7-alb-应用型负载均衡) | LoadBalancer, Listener | ⭐⭐ |
| 🌐 **网络** | [VPC](#8-vpc-专有网络) | Vpc, VSwitch, RouteTable | ⭐⭐⭐ |
| 📦 **存储** | [OSS](#9-oss-对象存储) | Bucket, Object | ⭐ |
| 📁 **存储** | [NAS](#10-nas-文件存储) | FileSystem, MountTarget | ⭐ |
| 🌐 **网络** | [EIP](#11-eip-弹性公网ip) | Allocation | ⭐ |
| ⚡ **计算** | [FC](#12-fc-函数计算) | Service, Function | ⭐⭐ |
| 🐳 **容器** | [ACK](#13-ack-容器服务) | Cluster | ⭐ |
| 📨 **消息队列** | [RocketMQ/Kafka](#14-rocketmq--15-kafka-消息队列) | Instance, Topic | ⭐⭐ |
| 🌐 **网络** | [DNS](#16-dns-云解析) | Domain, Record | ⭐ |
| 📊 **监控** | [SLS](#17-sls-日志服务) | Project, LogStore | ⭐⭐ |
| 📊 **监控** | [CMS](#18-cms-云监控) | Metric, Alarm | ⭐⭐⭐ |
| 🛡️ **安全** | [WAF](#19-waf-web应用防火墙) | Domain, Rule | ⭐⭐ |
| 🛡️ **安全** | [DDoS](#20-ddos-防护) | Instance, AttackEvent | ⭐⭐ |
| 🌐 **网络** | [CDN](#21-cdn-内容分发网络) | Domain, Config | ⭐⭐ |
| 🐳 **容器** | [CR](#22-cr-容器镜像服务) | Instance, Namespace, Repository | ⭐⭐ |
| 🖥️ **计算** | [ECD](#23-ecd-无影云桌面) | Desktop, OfficeSite | ⭐⭐ |
| 🖥️ **计算** | [ESS](#24-ess-弹性伸缩) | ScalingGroup, ScalingRule, ScalingConfiguration | ⭐⭐⭐ |
| 🌐 **网络** | [CEN](#25-cen-云企业网) | CenInstance, TransitRouter, ChildInstance | ⭐⭐⭐ |
| 🌐 **网络** | [VPN](#26-vpn-vpn网关) | VpnGateway, VpnConnection, CustomerGateway | ⭐⭐ |
| 🌐 **网络** | [PrivateZone](#27-privatezone-内网dns) | Zone, Record | ⭐ |
| 🔐 **安全** | [SSL证书](#28-ssl证书服务) | Certificate | ⭐ |
| 📨 **消息** | [SMS](#29-sms-短信服务) | Template, SignName | ⭐ |
| 🌐 **网络** | [DCDN](#30-dcdn-全站加速) | Domain, Config | ⭐⭐ |
| 🌐 **网络** | [NAT](#31-nat-nat网关) | NatGateway, SnatEntry, ForwardEntry | ⭐⭐ |
| 🔍 **搜索** | [Elasticsearch](#32-elasticsearch-搜索服务) | Instance | ⭐⭐ |
| 🛡️ **安全** | [云安全中心](#33-云安全中心-threatdetection) | Instance, Vul, Alert | ⭐⭐ |
| 🌐 **网络** | [MSE](#34-mse-微服务引擎) | Gateway, Cluster | ⭐⭐ |

---

## API-Action 映射矩阵

### 1. ECS (弹性计算服务)

核心资源: 实例(Instance)、云盘(Disk)、安全组(SecurityGroup)、镜像(Image)、快照(Snapshot)

|用户意图 / 查询关键词|对应阿里云API操作 |主要参数示例|CLI命令参考 (简化)|
|---|---|---|---|
|查询地域列表|DescribeRegions|-|aliyun ecs DescribeRegions|
|单实例详情  (查看、详情、状态、配置) |DescribeInstances / DescribeInstanceAttribute|InstanceIds: `["i-bp1xxxx"]`<br>RegionId: `cn-hangzhou`|aliyun ecs DescribeInstances --InstanceIds '["i-xxx"]'|
|列表查询  (列出、所有、有哪些、批量) |DescribeInstances|RegionId: `cn-hangzhou`<br>Status: `Running` / `Stopped`<br>InstanceType: `ecs.g6.large`<br>VpcId: `vpc-xxxx`<br>PageSize: `50` (1-100)|aliyun ecs DescribeInstances --Status Running|
|查询实例监控数据 |DescribeInstanceMonitorData|InstanceId: `i-bp1xxxx`<br>RegionId: `cn-hangzhou`<br>Period: `60` (秒)<br>StartTime: `2024-01-01T00:00:00Z`<br>EndTime: `2024-01-01T01:00:00Z`|aliyun ecs DescribeInstanceMonitorData --InstanceId i-xxx|
|查询实例挂载的磁盘 |DescribeDisks|InstanceId: `i-bp1xxxx`<br>RegionId: `cn-hangzhou`<br>DiskIds: `["d-xxxx"]`<br>Status: `In_use` / `Available`|aliyun ecs DescribeDisks --InstanceId i-xxx|
|查询实例的安全组 |DescribeInstanceAttribute (解析SecurityGroupIds字段) |InstanceId: `i-bp1xxxx`<br>RegionId: `cn-hangzhou`|aliyun ecs DescribeInstanceAttribute --InstanceId i-xxx|
|查询安全组列表|DescribeSecurityGroups|SecurityGroupId: `sg-xxxx`<br>RegionId: `cn-hangzhou`<br>VpcId: `vpc-xxxx`<br>PageSize: `50`|aliyun ecs DescribeSecurityGroups --RegionId cn-hangzhou|
|查询安全组规则详情|DescribeSecurityGroupAttribute|SecurityGroupId: `sg-xxxx`<br>RegionId: `cn-hangzhou`<br>Direction: `ingress` / `egress`|aliyun ecs DescribeSecurityGroupAttribute --SecurityGroupId sg-xxx|
|查询镜像|DescribeImages|ImageId: `m-xxxx`<br>RegionId: `cn-hangzhou`<br>ImageName: `my-image`<br>Status: `Available`<br>ImageOwnerAlias: `self` / `system`|aliyun ecs DescribeImages --RegionId cn-hangzhou|
|查询快照|DescribeSnapshots|SnapshotId: `s-xxxx`<br>RegionId: `cn-hangzhou`<br>DiskId: `d-xxxx`<br>SourceDiskId: `d-xxxx`<br>Status: `accomplished`|aliyun ecs DescribeSnapshots --RegionId cn-hangzhou|

### 2. RDS (关系型数据库)

核心资源: 实例(DBInstance)、数据库(Database)、账号(Account)、备份(Backup)

|用户意图 / 查询关键词|对应阿里云API操作 |主要参数示例|CLI命令参考 (简化)|
|---|---|---|---|
|单实例详情  (数据库详情、连接信息) |DescribeDBInstanceAttribute|DBInstanceId: `rm-xxxx`|aliyun rds DescribeDBInstanceAttribute --DBInstanceId rm-xxx|
|列表查询  (列出数据库实例)|DescribeDBInstances|RegionId: `cn-beijing`<br>DBInstanceId: `rm-xxxx`<br>DBInstanceStatus: `Running`<br>DBInstanceType: `Primary` / `Readonly` / `Guard`<br>Engine: `MySQL` / `PostgreSQL` / `SQLServer`|aliyun rds DescribeDBInstances --RegionId cn-beijing|
|查询实例性能监控 |DescribeDBInstancePerformance (历史)  或 CMS API|DBInstanceId: `rm-xxxx`<br>Key: `MySQL_Sessions` / `MySQL_MemCpuUsage`<br>StartTime: `2024-01-01T00:00:00Z`<br>EndTime: `2024-01-01T01:00:00Z`|aliyun rds DescribeDBInstancePerformance --DBInstanceId rm-xxx|
|查询实例下的数据库|DescribeDatabases|DBInstanceId: `rm-xxxx`<br>DBName: `mydb`|aliyun rds DescribeDatabases --DBInstanceId rm-xxx|
|查询实例账号|DescribeAccounts|DBInstanceId: `rm-xxxx`<br>AccountName: `testuser`|aliyun rds DescribeAccounts --DBInstanceId rm-xxx|
|查询备份集|DescribeBackups|DBInstanceId: `rm-xxxx`<br>BackupId: `xxxx`<br>StartTime: `2024-01-01T00:00:00Z`<br>EndTime: `2024-01-02T00:00:00Z`<br>BackupStatus: `Success`|aliyun rds DescribeBackups --DBInstanceId rm-xxx|

### 3. Redis (缓存数据库)

核心资源: 实例(Instance)、账号(Account)、备份(Backup)

|用户意图 / 查询关键词|对应阿里云API操作 |主要参数示例|CLI命令参考 (简化)|
|---|---|---|---|
|单实例详情 |DescribeInstanceAttribute|InstanceId: `r-xxxx`|aliyun r-kvstore DescribeInstanceAttribute --InstanceId r-xxx|
|列表查询|DescribeInstances|RegionId: `cn-hangzhou`<br>InstanceId: `r-xxxx`<br>InstanceStatus: `Running` / `Flushing`<br>InstanceType: `Redis` / `Memcache`<br>ArchitectureType: `cluster` / `standard`<br>PageSize: `30`|aliyun r-kvstore DescribeInstances --RegionId cn-hangzhou|
|查询实例监控|CMS API (DescribeMetricList)|Namespace: `acs_kvstore`<br>MetricName: `IntranetInRatio` / `CpuUsage`<br>Dimensions: `{"instanceId": "r-xxxx"}`<br>Period: `60`|aliyun cms DescribeMetricList --Namespace acs_kvstore|
|查询实例账号|DescribeAccounts|InstanceId: `r-xxxx`<br>AccountName: `testuser`|aliyun r-kvstore DescribeAccounts --InstanceId r-xxx|
|查询备份|DescribeBackups|InstanceId: `r-xxxx`<br>StartTime: `2024-01-01T00:00:00Z`<br>EndTime: `2024-01-02T00:00:00Z`<br>BackupId: `xxxx`|aliyun r-kvstore DescribeBackups --InstanceId r-xxx|

### 4. MongoDB (文档数据库)

核心资源: 实例(DBInstance)、备份(Backup)

|用户意图 / 查询关键词|对应阿里云API操作 |主要参数示例|CLI命令参考 (简化)|
|---|---|---|---|
|单实例详情 |DescribeDBInstanceAttribute|DBInstanceId: `dds-xxxx`|aliyun dds DescribeDBInstanceAttribute --DBInstanceId dds-xxx|
|列表查询|DescribeDBInstances|RegionId: `cn-shanghai`<br>DBInstanceId: `dds-xxxx`<br>DBInstanceStatus: `Running`<br>DBInstanceType: `replicate` / `sharding` / `single`<br>PageSize: `30`|aliyun dds DescribeDBInstances --RegionId cn-shanghai|
|查询备份策略/集|DescribeBackupPolicy / DescribeBackups|DBInstanceId: `dds-xxxx`<br>BackupId: `xxxx`|aliyun dds DescribeBackupPolicy --DBInstanceId dds-xxx|

### 5. PolarDB (云原生数据库)

核心资源: 集群(DBCluster)、节点(DBNode)、数据库(Database)、账号(Account)

|用户意图 / 查询关键词|对应阿里云API操作 |主要参数示例|CLI命令参考 (简化)|
|---|---|---|---|
|集群详情|DescribeDBClusterAttribute|DBClusterId: `pc-xxxx`|aliyun polardb DescribeDBClusterAttribute --DBClusterId pc-xxx|
|集群列表|DescribeDBClusters|RegionId: `cn-hangzhou`<br>DBClusterId: `pc-xxxx`<br>DBClusterStatus: `Running`<br>DBType: `MySQL` / `PostgreSQL` / `Oracle`<br>PageSize: `30`|aliyun polardb DescribeDBClusters --RegionId cn-hangzhou|
|查询集群节点|DescribeDBNodes|DBClusterId: `pc-xxxx`<br>DBNodeId: `pn-xxxx`|aliyun polardb DescribeDBNodes --DBClusterId pc-xxx|
|查询数据库|DescribeDatabases|DBClusterId: `pc-xxxx`<br>DBName: `mydb`|aliyun polardb DescribeDatabases --DBClusterId pc-xxx|
|查询账号|DescribeAccounts|DBClusterId: `pc-xxxx`<br>AccountName: `testuser`|aliyun polardb DescribeAccounts --DBClusterId pc-xxx|

### 6. SLB (传统负载均衡)

核心资源: 实例(LoadBalancer)、监听(Listener)、后端服务器(BackendServer)、虚拟服务器组(VServerGroup)

|用户意图 / 查询关键词|对应阿里云API操作 |主要参数示例|CLI命令参考 (简化)|
|---|---|---|---|
|实例列表|DescribeLoadBalancers|RegionId: `cn-hangzhou`<br>LoadBalancerId: `lb-xxxx`<br>Address: `192.168.1.1`<br>LoadBalancerName: `my-slb`<br>PageSize: `50`|aliyun slb DescribeLoadBalancers --RegionId cn-hangzhou|
|实例详情|DescribeLoadBalancerAttribute|LoadBalancerId: `lb-xxxx`<br>RegionId: `cn-hangzhou`|aliyun slb DescribeLoadBalancerAttribute --LoadBalancerId lb-xxx|
|查询监听列表|DescribeLoadBalancerListeners|LoadBalancerId: `lb-xxxx`<br>RegionId: `cn-hangzhou`<br>ListenerPort: `80`<br>Protocol: `http` / `https` / `tcp` / `udp`|aliyun slb DescribeLoadBalancerListeners --LoadBalancerId lb-xxx|
|查询TCP监听配置|DescribeLoadBalancerTCPListenerAttribute|LoadBalancerId: `lb-xxxx`<br>ListenerPort: `80`<br>RegionId: `cn-hangzhou`|aliyun slb DescribeLoadBalancerTCPListenerAttribute --LoadBalancerId lb-xxx --ListenerPort 80|
|查询UDP监听配置|DescribeLoadBalancerUDPListenerAttribute|LoadBalancerId: `lb-xxxx`<br>ListenerPort: `80`<br>RegionId: `cn-hangzhou`|aliyun slb DescribeLoadBalancerUDPListenerAttribute --LoadBalancerId lb-xxx --ListenerPort 80|
|查询HTTP监听配置|DescribeLoadBalancerHTTPListenerAttribute|LoadBalancerId: `lb-xxxx`<br>ListenerPort: `80`<br>RegionId: `cn-hangzhou`|aliyun slb DescribeLoadBalancerHTTPListenerAttribute --LoadBalancerId lb-xxx --ListenerPort 80|
|查询HTTPS监听配置|DescribeLoadBalancerHTTPSListenerAttribute|LoadBalancerId: `lb-xxxx`<br>ListenerPort: `443`<br>RegionId: `cn-hangzhou`|aliyun slb DescribeLoadBalancerHTTPSListenerAttribute --LoadBalancerId lb-xxx --ListenerPort 443|
|查询后端服务器健康状态|DescribeHealthStatus|LoadBalancerId: `lb-xxxx`<br>ListenerPort: `80`<br>RegionId: `cn-hangzhou`|aliyun slb DescribeHealthStatus --LoadBalancerId lb-xxx|
|查询转发规则|DescribeRules / DescribeRuleAttribute|LoadBalancerId: `lb-xxxx`<br>RuleId: `rule-xxxx`<br>ListenerPort: `80`|aliyun slb DescribeRules --LoadBalancerId lb-xxx|
|查询虚拟服务器组列表|DescribeVServerGroups|LoadBalancerId: `lb-xxxx`<br>RegionId: `cn-hangzhou`<br>VServerGroupId: `vsp-xxxx`|aliyun slb DescribeVServerGroups --LoadBalancerId lb-xxx|
|查询虚拟服务器组详情|DescribeVServerGroupAttribute|VServerGroupId: `vsp-xxxx`<br>RegionId: `cn-hangzhou`|aliyun slb DescribeVServerGroupAttribute --VServerGroupId vsp-xxx|
|查询访问控制策略组列表|DescribeAccessControlLists|AclId: `acl-xxxx`<br>RegionId: `cn-hangzhou`<br>PageSize: `50`|aliyun slb DescribeAccessControlLists --RegionId cn-hangzhou|
|查询访问控制策略组配置|DescribeAccessControlListAttribute|AclId: `acl-xxxx`<br>RegionId: `cn-hangzhou`|aliyun slb DescribeAccessControlListAttribute --AclId acl-xxx|
|查询SLB监听器的ACL关联列表|DescribeLoadBalancerListeners|LoadBalancerId: `lb-xxxx`<br>ListenerPort: `80`<br>RegionId: `cn-hangzhou`|aliyun slb DescribeLoadBalancerListeners --LoadBalancerId lb-xxx --RegionId cn-hangzhou \| jq '.Listeners.Listener[] | select(.ListenerPort == 80) | .AclIds'|
|查询ACL详情（条目、名称等）|DescribeAccessControlListAttribute|AclId: `acl-xxxx`<br>RegionId: `cn-hangzhou`|aliyun slb DescribeAccessControlListAttribute --AclId acl-xxx --RegionId cn-hangzhou|

**说明**: SLB 的 ACL 关联信息存储在监听器对象的 `AclIds` 数组字段中（注意是复数形式），通过 `DescribeLoadBalancerListeners` API 获取监听器配置后，解析每个监听器的 `AclIds` 属性即可获取关联的 ACL ID 列表。然后使用 `DescribeAccessControlListAttribute` 查询 ACL 详情。与 ALB 不同（ALB 需调用 `ListAclRelations`），SLB 可直接通过监听器属性获取 ACL 关联。

---

### 7. ALB (应用型负载均衡)

核心资源: 实例(LoadBalancer)、监听(Listener)、服务器组(ServerGroup)、规则(Rule)

|用户意图 / 查询关键词|对应阿里云API操作 |主要参数示例|CLI命令参考 (简化)|
|---|---|---|---|
|实例列表|ListLoadBalancers|RegionId: `cn-hangzhou`<br>LoadBalancerId: `alb-xxxx`<br>Address: `192.168.1.1`<br>LoadBalancerName: `my-alb`<br>PageSize: `50`|aliyun alb ListLoadBalancers --RegionId cn-hangzhou|
|实例详情|GetLoadBalancerAttribute|LoadBalancerId: `alb-xxxx`<br>RegionId: `cn-hangzhou`|aliyun alb GetLoadBalancerAttribute --LoadBalancerId alb-xxx|
|查询监听列表|ListListeners|LoadBalancerId: `alb-xxxx`<br>RegionId: `cn-hangzhou`<br>ListenerId: `lsn-xxxx`|aliyun alb ListListeners --LoadBalancerId alb-xxx|
|查询监听属性|GetListenerAttribute|ListenerId: `lsn-xxxx`<br>RegionId: `cn-hangzhou`|aliyun alb GetListenerAttribute --ListenerId lsn-xxx|
|查询健康检查状态|GetListenerHealthStatus|ListenerId: `lsn-xxxx`<br>RegionId: `cn-hangzhou`|aliyun alb GetListenerHealthStatus --ListenerId lsn-xxx|
|查询服务器组列表|ListServerGroups|RegionId: `cn-hangzhou`<br>ServerGroupId: `sgp-xxxx`<br>ServerGroupName: `my-sg`<br>PageSize: `50`|aliyun alb ListServerGroups --RegionId cn-hangzhou|
|查询服务器组服务器列表|ListServerGroupServers|ServerGroupId: `sgp-xxxx`<br>RegionId: `cn-hangzhou`|aliyun alb ListServerGroupServers --ServerGroupId sgp-xxx|
|查询转发规则|ListRules|ListenerId: `lsn-xxxx`<br>RegionId: `cn-hangzhou`<br>RuleIds: `["rule-xxxx"]`|aliyun alb ListRules --ListenerId lsn-xxx|
|查询访问控制列表|ListAcls|AclId: `acl-xxxx`<br>RegionId: `cn-hangzhou`|aliyun alb ListAcls --RegionId cn-hangzhou|
|查询访问控制条目|ListAclEntries|AclId: `acl-xxxx`<br>RegionId: `cn-hangzhou`|aliyun alb ListAclEntries --AclId acl-xxx|
|查询访问控制关联关系|ListAclRelations|AclIds: `["acl-xxxx"]` 或 `["acl-1", "acl-2"]`<br>RegionId: `cn-hangzhou`|aliyun alb ListAclRelations --AclIds.1 'acl-xxxx' --RegionId cn-hangzhou --force<br>aliyun alb ListAclRelations --AclIds.1 'acl-1' --AclIds.2 'acl-2' --RegionId cn-hangzhou --force|

### 8. VPC (专有网络)

核心资源: VPC、交换机(VSwitch)、路由表(RouteTable)、安全组(SecurityGroup)、弹性网卡(ENI)

|用户意图 / 查询关键词|对应阿里云API操作 |主要参数示例|CLI命令参考 (简化)|
|---|---|---|---|
|VPC列表|DescribeVpcs|RegionId: `cn-beijing`<br>VpcId: `vpc-xxxx`<br>VpcName: `my-vpc`<br>PageSize: `50`|aliyun vpc DescribeVpcs --RegionId cn-beijing|
|VPC详情|DescribeVpcAttribute|VpcId: `vpc-xxxx`<br>RegionId: `cn-beijing`|aliyun vpc DescribeVpcAttribute --VpcId vpc-xxx|
|查询VPC下的交换机 |DescribeVSwitches|VpcId: `vpc-xxxx`<br>RegionId: `cn-beijing`<br>VSwitchId: `vsw-xxxx`<br>PageSize: `50`|aliyun vpc DescribeVSwitches --VpcId vpc-xxx|
|查询路由表|DescribeRouteTables|RouteTableId: `vtb-xxxx`<br>VpcId: `vpc-xxxx`<br>RegionId: `cn-beijing`|aliyun vpc DescribeRouteTables --RouteTableId vtb-xxx|
|查询弹性网卡|DescribeNetworkInterfaces|NetworkInterfaceId: `eni-xxxx`<br>InstanceId: `i-xxxx`<br>VSwitchId: `vsw-xxxx`<br>PageSize: `50`|aliyun vpc DescribeNetworkInterfaces --InstanceId i-xxx|
|查询VPC内资源拓扑 |DescribeVpcAttachedResources (BETA)|VpcId: `vpc-xxxx`<br>ResourceType: `VSwitch` / `RouteTable`|aliyun vpc DescribeVpcAttachedResources --VpcId vpc-xxx|

### 9. OSS (对象存储)

核心资源: 存储桶(Bucket)、对象(Object)、生命周期(Lifecycle)

|用户意图 / 查询关键词|对应阿里云API操作 |主要参数示例|CLI命令参考 (简化)|
|---|---|---|---|
|查询Bucket列表|ListBuckets|- (无地域参数，全局)|aliyun oss ls|
|查询Bucket详情/配置|GetBucketInfo / GetBucketStat|Bucket: `mybucket`|aliyun oss stat oss://mybucket|
|列出Bucket内文件|ListObjects (V2)|Bucket: `mybucket`<br>Prefix: `path/`<br>MaxKeys: `100`<br>Delimiter: `/`|aliyun oss ls oss://mybucket|
|查询文件详情|GetObjectMeta|Bucket: `mybucket`<br>Object: `path/to/object`|aliyun oss stat oss://mybucket/object|
|查询Bucket生命周期规则|GetBucketLifecycle|Bucket: `mybucket`|aliyun oss lifecycle get oss://mybucket|

### 10. NAS (文件存储)

核心资源: 文件系统(FileSystem)、挂载点(MountTarget)

|用户意图 / 查询关键词|对应阿里云API操作 |主要参数示例|CLI命令参考 (简化)|
|---|---|---|---|
|文件系统列表|DescribeFileSystems|RegionId: `cn-hangzhou`<br>FileSystemId: `31xxxx`<br>FileSystemType: `standard` / `extreme` / `cpfs`|aliyun nas DescribeFileSystems --RegionId cn-hangzhou|
|文件系统详情|DescribeFileSystems (通过ID)|FileSystemId: `31xxxx`<br>RegionId: `cn-hangzhou`|aliyun nas DescribeFileSystems --FileSystemId 31xxx|
|查询挂载点|DescribeMountTargets|FileSystemId: `31xxxx`<br>RegionId: `cn-hangzhou`<br>MountTargetDomainName: `xxxx.cn-hangzhou.nas.aliyuncs.com`|aliyun nas DescribeMountTargets --FileSystemId 31xxx|

### 11. EIP (弹性公网IP)

核心资源: 地址(Allocation)

|用户意图 / 查询关键词|对应阿里云API操作 |主要参数示例|CLI命令参考 (简化)|
|---|---|---|---|
|EIP列表|DescribeEipAddresses|RegionId: `cn-hangzhou`<br>AllocationId: `eip-xxxx`<br>AssociatedInstanceId: `i-xxxx`<br>Status: `Available` / `InUse`<br>PageSize: `50`|aliyun vpc DescribeEipAddresses --RegionId cn-hangzhou|
|EIP详情|DescribeEipAddresses (通过ID)|AllocationId: `eip-xxxx`<br>RegionId: `cn-hangzhou`|aliyun vpc DescribeEipAddresses --AllocationId eip-xxx|

### 12. FC (函数计算)

核心资源: 服务(Service)、函数(Function)、触发器(Trigger)

|用户意图 / 查询关键词|对应阿里云API操作 |主要参数示例|CLI命令参考 (简化)|
|---|---|---|---|
|服务列表/详情|ListServices / GetService|ServiceName: `my-service`<br>RegionId: `cn-hangzhou`|aliyun fc ListServices --RegionId cn-hangzhou|
|函数列表/详情|ListFunctions / GetFunction|ServiceName: `my-service`<br>FunctionName: `my-func`<br>RegionId: `cn-hangzhou`|aliyun fc ListFunctions --ServiceName my-service|
|触发器列表|ListTriggers|ServiceName: `my-service`<br>FunctionName: `my-func`<br>TriggerName: `my-trigger`|aliyun fc ListTriggers --ServiceName my-service --FunctionName my-func|

### 13. ACK (容器服务)

核心资源: 集群(Cluster)，需要结合kubectl或调用k8s API进行更细粒度查询。

|用户意图 / 查询关键词|对应阿里云API操作 |主要参数示例|CLI命令参考 (简化)|
|---|---|---|---|
|集群列表/详情|DescribeClusters / DescribeClusterDetail|ClusterId: `c-xxxx`<br>RegionId: `cn-hangzhou`<br>Name: `my-cluster`<br>ClusterType: `Kubernetes` / `ASK` / `Serverless`|aliyun cs DescribeClusters --RegionId cn-hangzhou|
|查询集群节点|DescribeClusterNodes|ClusterId: `c-xxxx`<br>RegionId: `cn-hangzhou`|aliyun cs DescribeClusterNodes --ClusterId c-xxx|

### 14. RocketMQ & 15. Kafka (消息队列)

**RocketMQ** 核心资源: 实例(Instance)、Topic、Group
**Kafka** 核心资源: 实例(Instance)、Topic

|用户意图 / 查询关键词|对应阿里云API操作 (RocketMQ)|对应阿里云API操作 (Kafka)|主要参数示例|CLI命令参考 (简化)|
|---|---|---|---|---|
|实例列表/详情|ListInstances / GetInstance|GetInstanceList / GetInstance|RegionId: `cn-hangzhou`<br>InstanceId: `MQS_xxx` / `alikafka_xxx`|aliyun mq ListInstances --RegionId cn-hangzhou|
|Topic列表/详情|ListTopics / GetTopic|GetTopicList / GetTopic|InstanceId: `MQS_xxx`<br>Topic: `my-topic`|aliyun mq ListTopics --InstanceId MQS_xxx|
|消费组列表 (RocketMQ)|ListConsumerGroups|N/A|InstanceId: `MQS_xxx`<br>Group: `my-group`|aliyun mq ListConsumerGroups --InstanceId MQS_xxx|

### 16. DNS (云解析)

核心资源: 域名(Domain)、解析记录(Record)、实例(Instance)

|用户意图 / 查询关键词|对应阿里云API操作 |主要参数示例|CLI命令参考 (简化)|
|---|---|---|---|
|域名列表|DescribeDomains|PageNumber: `1`<br>PageSize: `20`<br>KeyWord: `example`<br>GroupId: `xxxx`|aliyun alidns DescribeDomains|
|域名详情|DescribeDomainInfo|DomainName: `example.com`|aliyun alidns DescribeDomainInfo --DomainName example.com|
|实例绑定域名列表|DescribeInstanceDomains|InstanceId: `xxx`<br>PageNumber: `1`<br>PageSize: `20`|aliyun alidns DescribeInstanceDomains --InstanceId xxx|
|查询解析记录|DescribeDomainRecords|DomainName: `example.com`<br>RRKeyWord: `www`<br>TypeKeyWord: `A` / `CNAME`<br>PageNumber: `1`|aliyun alidns DescribeDomainRecords --DomainName example.com|

### 17. SLS (日志服务)

核心资源: 项目(Project)、日志库(LogStore)、日志(Shard)

|用户意图 / 查询关键词|对应阿里云API操作 |主要参数示例|
|---|---|---|
|项目列表|ListLogStores|RegionId: `cn-hangzhou`<br>ProjectName: `my-project`|
|日志库列表|ListLogStores|ProjectName: `my-project`<br>PageSize: `50`|
|查询日志|GetLogs / GetHistograms|ProjectName: `my-project`<br>LogStoreName: `my-logstore`<br>From: `1704067200` (时间戳)<br>To: `1704153600`<br>Query: `status:200` |

### 18. CMS (云监控)

核心资源: 指标(Metric)、报警规则(Alarm)、事件(Event)

|用户意图 / 查询关键词|对应阿里云API操作 |主要参数示例|
|---|---|---|
|查询监控指标数据|DescribeMetricList|Namespace: `acs_ecs` / `acs_rds`<br>MetricName: `CPUUtilization`<br>Dimensions: `{"instanceId": "i-xxxx"}`<br>Period: `60` (秒)<br>StartTime: `2024-01-01T00:00:00Z`<br>EndTime: `2024-01-01T01:00:00Z`|
|查询报警规则列表|DescribeMetricRuleList|RuleId: `alert-xxxx`<br>RuleName: `my-alert`<br>Namespace: `acs_ecs`<br>PageSize: `50`|
|查询监控事件|DescribeSystemEventHistogram / DescribeSystemEventAttribute|Product: `ECS` / `RDS`<br>EventType: `StatusNotification` / `Maintenance`<br>StartTime: `2024-01-01T00:00:00Z`<br>EndTime: `2024-01-02T00:00:00Z`|

### 19. WAF (Web应用防火墙)

核心资源: 域名(Domain)、防护规则(Rule)

|用户意图 / 查询关键词|对应阿里云API操作 |主要参数示例|
|---|---|---|
|防护域名列表|DescribeDomainNames|InstanceId: `xxxx`<br>Region: `cn`<br>Domain: `example.com`|
|查询防护配置/日志|DescribeProtectionModuleStatus / DescribeLogs|InstanceId: `xxxx`<br>Domain: `example.com`<br>ModuleName: `waf_group` / `cc`|

### 20. DDoS (DDoS防护)

核心资源: 实例(Instance)、攻击事件(AttackEvent)

|用户意图 / 查询关键词|对应阿里云API操作 |主要参数示例|CLI命令参考 (简化)|
|---|---|---|---|
|实例列表/详情|DescribeInstances|InstanceId: `ddoscoo-xxxx`<br>Region: `cn-hangzhou`|aliyun ddoscoo DescribeInstances --RegionId cn-hangzhou|
|查询攻击事件|DescribeDDoSEvents|InstanceId: `ddoscoo-xxxx`<br>StartTime: `2024-01-01T00:00:00Z`<br>EndTime: `2024-01-02T00:00:00Z`|aliyun ddoscoo DescribeDDoSEvents --InstanceId xxx|

---

### 21. CDN (内容分发网络)

核心资源: 域名(Domain)、配置(Config)

|用户意图 / 查询关键词|对应阿里云API操作 |主要参数示例|CLI命令参考 (简化)|
|---|---|---|---|
|查询用户域名|DescribeUserDomains|DomainName: `example.com`<br>PageSize: `50`<br>PageNumber: `1`<br>CdnType: `web` / `download` / `video`|aliyun cdn DescribeUserDomains|
|查询域名详情|DescribeCdnDomainDetail|DomainName: `example.com`|aliyun cdn DescribeCdnDomainDetail --DomainName example.com|
|查询域名配置|DescribeCdnDomainConfigs|DomainName: `example.com`<br>FunctionNames: `ipv6_switch` / `optimize_enable`|aliyun cdn DescribeCdnDomainConfigs --DomainName example.com|

---

### 22. CR (容器镜像服务)

核心资源: 实例(Instance)、命名空间(Namespace)、镜像仓库(Repository)

CLI产品代码: `cr`

|用户意图 / 查询关键词|对应阿里云API操作 |主要参数示例|CLI命令参考 (简化)|
|---|---|---|---|
|实例列表|ListInstance|-|aliyun cr ListInstance|
|实例详情|GetInstance|InstanceId: `cri-xxxx`|aliyun cr GetInstance --InstanceId cri-xxx|
|命名空间列表|ListNamespace|InstanceId: `cri-xxxx`<br>PageSize: `30`|aliyun cr ListNamespace --InstanceId cri-xxx|
|镜像仓库列表|ListRepository|InstanceId: `cri-xxxx`<br>RepoNamespaceName: `my-ns`<br>PageSize: `30`|aliyun cr ListRepository --InstanceId cri-xxx|
|镜像仓库详情|GetRepository|InstanceId: `cri-xxxx`<br>RepoId: `crr-xxxx`|aliyun cr GetRepository --InstanceId cri-xxx --RepoId crr-xxx|
|镜像Tag列表|ListRepoTag|InstanceId: `cri-xxxx`<br>RepoId: `crr-xxxx`<br>PageSize: `30`|aliyun cr ListRepoTag --InstanceId cri-xxx --RepoId crr-xxx|
|镜像构建记录|ListRepoBuildRecord|InstanceId: `cri-xxxx`<br>RepoId: `crr-xxxx`|aliyun cr ListRepoBuildRecord --InstanceId cri-xxx --RepoId crr-xxx|
|镜像同步规则|ListRepoSyncRule|InstanceId: `cri-xxxx`|aliyun cr ListRepoSyncRule --InstanceId cri-xxx|

---

### 23. ECD (无影云桌面)

核心资源: 云桌面(Desktop)、办公网络(OfficeSite)、桌面组(DesktopGroup)

CLI产品代码: `ecd`（版本 2020-09-30，部分 API 需安装插件 `aliyun plugin install --names aliyun-cli-ecd`）

|用户意图 / 查询关键词|对应阿里云API操作 |主要参数示例|CLI命令参考 (简化)|
|---|---|---|---|
|云桌面列表|DescribeDesktops|RegionId: `cn-beijing`<br>DesktopId: `ecd-xxxx`<br>DesktopStatus: `Running` / `Stopped`<br>OfficeSiteId: `cn-beijing+dir-xxxx`<br>PageSize: `50`|aliyun ecd DescribeDesktops --RegionId cn-beijing|
|办公网络列表|DescribeOfficeSites|RegionId: `cn-beijing`<br>OfficeSiteId: `cn-beijing+dir-xxxx`|aliyun ecd DescribeOfficeSites --RegionId cn-beijing|
|桌面组列表|DescribeDesktopGroups|RegionId: `cn-beijing`<br>DesktopGroupId: `dg-xxxx`|aliyun ecd DescribeDesktopGroups --RegionId cn-beijing|
|用户连接信息|DescribeDesktopSessions|RegionId: `cn-beijing`<br>DesktopId: `ecd-xxxx`|aliyun ecd DescribeDesktopSessions --RegionId cn-beijing|
|桌面快照列表|DescribeSnapshots|RegionId: `cn-beijing`<br>DesktopId: `ecd-xxxx`|aliyun ecd DescribeSnapshots --RegionId cn-beijing|

**说明**: ECD 部分 API 可能需要安装专用插件才能使用，执行 `aliyun plugin install --names aliyun-cli-ecd` 安装。

---

### 24. ESS (弹性伸缩)

核心资源: 伸缩组(ScalingGroup)、伸缩规则(ScalingRule)、伸缩配置(ScalingConfiguration)、伸缩活动(ScalingActivity)

CLI产品代码: `ess`

|用户意图 / 查询关键词|对应阿里云API操作 |主要参数示例|CLI命令参考 (简化)|
|---|---|---|---|
|伸缩组列表|DescribeScalingGroups|RegionId: `cn-beijing`<br>ScalingGroupId: `asg-xxxx`<br>ScalingGroupName: `my-group`<br>PageSize: `50`|aliyun ess DescribeScalingGroups --RegionId cn-beijing|
|伸缩配置列表|DescribeScalingConfigurations|RegionId: `cn-beijing`<br>ScalingGroupId: `asg-xxxx`<br>ScalingConfigurationId: `asc-xxxx`<br>PageSize: `50`|aliyun ess DescribeScalingConfigurations --RegionId cn-beijing|
|伸缩规则列表|DescribeScalingRules|RegionId: `cn-beijing`<br>ScalingGroupId: `asg-xxxx`<br>ScalingRuleId: `asr-xxxx`<br>PageSize: `50`|aliyun ess DescribeScalingRules --RegionId cn-beijing|
|伸缩活动列表|DescribeScalingActivities|RegionId: `cn-beijing`<br>ScalingGroupId: `asg-xxxx`<br>StatusCode: `Successful` / `Failed` / `InProgress`|aliyun ess DescribeScalingActivities --RegionId cn-beijing --ScalingGroupId asg-xxx|
|伸缩组内实例列表|DescribeScalingInstances|RegionId: `cn-beijing`<br>ScalingGroupId: `asg-xxxx`<br>LifecycleState: `InService` / `Pending` / `Removing`<br>PageSize: `50`|aliyun ess DescribeScalingInstances --RegionId cn-beijing --ScalingGroupId asg-xxx|
|定时任务列表|DescribeScheduledTasks|RegionId: `cn-beijing`<br>ScheduledTaskId: `edRtShc-xxxx`<br>PageSize: `50`|aliyun ess DescribeScheduledTasks --RegionId cn-beijing|

---

### 25. CEN (云企业网)

核心资源: 云企业网实例(CenInstance)、转发路由器(TransitRouter)、网络实例(ChildInstance)、带宽包(BandwidthPackage)

CLI产品代码: `cbn`

|用户意图 / 查询关键词|对应阿里云API操作 |主要参数示例|CLI命令参考 (简化)|
|---|---|---|---|
|云企业网实例列表|DescribeCens|PageSize: `50`|aliyun cbn DescribeCens|
|查询挂载的网络实例|DescribeCenAttachedChildInstances|CenId: `cen-xxxx`<br>ChildInstanceType: `VPC` / `VBR` / `CCN`<br>PageSize: `50`|aliyun cbn DescribeCenAttachedChildInstances --CenId cen-xxx|
|转发路由器列表|ListTransitRouters|CenId: `cen-xxxx`<br>RegionId: `cn-beijing`|aliyun cbn ListTransitRouters --CenId cen-xxx|
|转发路由器VPC附加列表|ListTransitRouterVpcAttachments|TransitRouterId: `tr-xxxx`<br>RegionId: `cn-beijing`|aliyun cbn ListTransitRouterVpcAttachments --TransitRouterId tr-xxx|
|转发路由器路由表|ListTransitRouterRouteTables|TransitRouterId: `tr-xxxx`|aliyun cbn ListTransitRouterRouteTables --TransitRouterId tr-xxx|
|转发路由器路由条目|ListTransitRouterRouteEntries|TransitRouterRouteTableId: `vtb-xxxx`|aliyun cbn ListTransitRouterRouteEntries --TransitRouterRouteTableId vtb-xxx|
|带宽包列表|DescribeCenBandwidthPackages|CenId: `cen-xxxx`|aliyun cbn DescribeCenBandwidthPackages --CenId cen-xxx|
|地域间路由策略|DescribeCenRegionDomainRouteEntries|CenId: `cen-xxxx`<br>CenRegionId: `cn-beijing`|aliyun cbn DescribeCenRegionDomainRouteEntries --CenId cen-xxx --CenRegionId cn-beijing|

---

### 26. VPN (VPN网关)

核心资源: VPN网关(VpnGateway)、IPsec连接(VpnConnection)、用户网关(CustomerGateway)、SSL服务端(SslVpnServer)

CLI产品代码: `vpc`（VPN 相关 API 归属于 VPC 产品下）

|用户意图 / 查询关键词|对应阿里云API操作 |主要参数示例|CLI命令参考 (简化)|
|---|---|---|---|
|VPN网关列表|DescribeVpnGateways|RegionId: `cn-beijing`<br>VpnGatewayId: `vpn-xxxx`<br>VpcId: `vpc-xxxx`<br>Status: `Active` / `Init`<br>PageSize: `50`|aliyun vpc DescribeVpnGateways --RegionId cn-beijing|
|IPsec连接列表|DescribeVpnConnections|RegionId: `cn-beijing`<br>VpnGatewayId: `vpn-xxxx`<br>VpnConnectionId: `vco-xxxx`<br>PageSize: `50`|aliyun vpc DescribeVpnConnections --RegionId cn-beijing|
|用户网关列表|DescribeCustomerGateways|RegionId: `cn-beijing`<br>CustomerGatewayId: `cgw-xxxx`<br>PageSize: `50`|aliyun vpc DescribeCustomerGateways --RegionId cn-beijing|
|SSL-VPN服务端列表|DescribeSslVpnServers|RegionId: `cn-beijing`<br>VpnGatewayId: `vpn-xxxx`<br>SslVpnServerId: `vss-xxxx`|aliyun vpc DescribeSslVpnServers --RegionId cn-beijing|
|SSL-VPN客户端证书列表|DescribeSslVpnClientCerts|RegionId: `cn-beijing`<br>SslVpnServerId: `vss-xxxx`<br>PageSize: `50`|aliyun vpc DescribeSslVpnClientCerts --RegionId cn-beijing|

---

### 27. PrivateZone (内网DNS)

核心资源: 内网域名(Zone)、解析记录(Record)

CLI产品代码: `pvtz`

|用户意图 / 查询关键词|对应阿里云API操作 |主要参数示例|CLI命令参考 (简化)|
|---|---|---|---|
|内网域名列表|DescribeZones|RegionId: `cn-beijing`<br>Keyword: `example`<br>PageSize: `50`|aliyun pvtz DescribeZones --RegionId cn-beijing|
|域名详情|DescribeZoneInfo|ZoneId: `xxxx`|aliyun pvtz DescribeZoneInfo --ZoneId xxx|
|解析记录列表|DescribeZoneRecords|ZoneId: `xxxx`<br>Keyword: `www`<br>PageSize: `50`|aliyun pvtz DescribeZoneRecords --ZoneId xxx|
|查询域名关联的VPC|DescribeZoneVpcTree|RegionId: `cn-beijing`|aliyun pvtz DescribeZoneVpcTree --RegionId cn-beijing|

---

### 28. SSL证书服务

核心资源: 证书(Certificate)、证书订单(CertificateOrder)

CLI产品代码: `cas`（需指定 endpoint: `--endpoint cas.aliyuncs.com`）

|用户意图 / 查询关键词|对应阿里云API操作 |主要参数示例|CLI命令参考 (简化)|
|---|---|---|---|
|证书订单列表|ListUserCertificateOrder|OrderType: `CERT` / `UPLOAD`<br>Status: `ISSUED` / `EXPIRED`<br>PageSize: `50`|aliyun cas ListUserCertificateOrder --endpoint cas.aliyuncs.com|
|证书详情|GetUserCertificateDetail|CertId: `xxxx`|aliyun cas GetUserCertificateDetail --CertId xxx --endpoint cas.aliyuncs.com|
|查询证书关联资源|ListCertificateDeployment|CertId: `xxxx`|aliyun cas ListCertificateDeployment --CertId xxx --endpoint cas.aliyuncs.com|

---

### 29. SMS (短信服务)

核心资源: 短信模板(Template)、签名(SignName)、发送记录(SendRecord)

CLI产品代码: `dysmsapi`（需指定 endpoint: `--endpoint dysmsapi.aliyuncs.com`）

|用户意图 / 查询关键词|对应阿里云API操作 |主要参数示例|CLI命令参考 (简化)|
|---|---|---|---|
|查询短信签名|QuerySmsSign|SignName: `阿里云`|aliyun dysmsapi QuerySmsSign --SignName xxx --endpoint dysmsapi.aliyuncs.com|
|查询短信模板|QuerySmsTemplate|TemplateCode: `SMS_123456`|aliyun dysmsapi QuerySmsTemplate --TemplateCode SMS_xxx --endpoint dysmsapi.aliyuncs.com|
|查询发送统计|QuerySendStatistics|IsGlobe: `1` / `2`<br>StartDate: `20260101`<br>EndDate: `20260131`<br>PageSize: `50`|aliyun dysmsapi QuerySendStatistics --IsGlobe 1 --StartDate 20260101 --EndDate 20260131 --endpoint dysmsapi.aliyuncs.com|
|查询发送详情|QuerySendDetails|PhoneNumber: `1380000xxxx`<br>SendDate: `20260101`<br>PageSize: `50`|aliyun dysmsapi QuerySendDetails --PhoneNumber 138xxxx --SendDate 20260101 --endpoint dysmsapi.aliyuncs.com|

**说明**: SMS 部分 API 可能需要安装专用插件 `aliyun plugin install --names aliyun-cli-dysmsapi`。

---

### 30. DCDN (全站加速)

核心资源: 域名(Domain)、配置(Config)

CLI产品代码: `dcdn`

|用户意图 / 查询关键词|对应阿里云API操作 |主要参数示例|CLI命令参考 (简化)|
|---|---|---|---|
|查询用户域名|DescribeDcdnUserDomains|DomainName: `example.com`<br>DomainStatus: `online` / `offline`<br>PageSize: `50`|aliyun dcdn DescribeDcdnUserDomains|
|域名详情|DescribeDcdnDomainDetail|DomainName: `example.com`|aliyun dcdn DescribeDcdnDomainDetail --DomainName example.com|
|域名配置|DescribeDcdnDomainConfigs|DomainName: `example.com`<br>FunctionNames: `origin_request_header`|aliyun dcdn DescribeDcdnDomainConfigs --DomainName example.com|
|查询域名流量数据|DescribeDcdnDomainTrafficData|DomainName: `example.com`<br>StartTime: `2026-01-01T00:00:00Z`<br>EndTime: `2026-01-02T00:00:00Z`|aliyun dcdn DescribeDcdnDomainTrafficData --DomainName example.com|
|查询域名证书信息|DescribeDcdnDomainCertificateInfo|DomainName: `example.com`|aliyun dcdn DescribeDcdnDomainCertificateInfo --DomainName example.com|

---

### 31. NAT (NAT网关)

核心资源: NAT网关(NatGateway)、SNAT条目(SnatEntry)、DNAT条目(ForwardEntry)

CLI产品代码: `vpc`（NAT 相关 API 归属于 VPC 产品下）

|用户意图 / 查询关键词|对应阿里云API操作 |主要参数示例|CLI命令参考 (简化)|
|---|---|---|---|
|NAT网关列表|DescribeNatGateways|RegionId: `cn-beijing`<br>NatGatewayId: `ngw-xxxx`<br>VpcId: `vpc-xxxx`<br>NatType: `Enhanced`<br>PageSize: `50`|aliyun vpc DescribeNatGateways --RegionId cn-beijing|
|SNAT条目列表|DescribeSnatTableEntries|RegionId: `cn-beijing`<br>SnatTableId: `stb-xxxx`<br>PageSize: `50`|aliyun vpc DescribeSnatTableEntries --RegionId cn-beijing --SnatTableId stb-xxx|
|DNAT条目列表|DescribeForwardTableEntries|RegionId: `cn-beijing`<br>ForwardTableId: `ftb-xxxx`<br>PageSize: `50`|aliyun vpc DescribeForwardTableEntries --RegionId cn-beijing --ForwardTableId ftb-xxx|

**说明**: NAT网关的 SnatTableId 和 ForwardTableId 可通过 `DescribeNatGateways` 返回的 `SnatTableIds` 和 `ForwardTableIds` 字段获取。

---

### 32. Elasticsearch (搜索服务)

核心资源: 实例(Instance)

CLI产品代码: `elasticsearch`（需指定 endpoint: `--endpoint elasticsearch.<region>.aliyuncs.com`）

|用户意图 / 查询关键词|对应阿里云API操作 |主要参数示例|CLI命令参考 (简化)|
|---|---|---|---|
|实例列表|ListInstance|description: `my-es`<br>instanceCategory: `x-pack`<br>page: `1`<br>size: `20`|aliyun elasticsearch ListInstance --endpoint elasticsearch.cn-beijing.aliyuncs.com|
|实例详情|DescribeInstance|InstanceId: `es-xxxx`|aliyun elasticsearch DescribeInstance --InstanceId es-xxx --endpoint elasticsearch.cn-beijing.aliyuncs.com|
|查询集群日志|ListSearchLog|InstanceId: `es-xxxx`<br>type: `INSTANCELOG` / `SEARCHSLOW` / `INDEXINGSLOW` / `GCLOG`|aliyun elasticsearch ListSearchLog --InstanceId es-xxx --endpoint elasticsearch.cn-beijing.aliyuncs.com|

---

### 33. 云安全中心 (ThreatDetection)

核心资源: 资产(Instance)、漏洞(Vul)、告警(Alert)

CLI产品代码: `sas`

|用户意图 / 查询关键词|对应阿里云API操作 |主要参数示例|CLI命令参考 (简化)|
|---|---|---|---|
|版本信息|DescribeVersionConfig|-|aliyun sas DescribeVersionConfig|
|资产列表|DescribeCloudCenterInstances|RegionId: `cn-beijing`<br>MachineTypes: `ecs` / `cloud_vm`<br>PageSize: `50`|aliyun sas DescribeCloudCenterInstances|
|漏洞列表|DescribeVulList|Type: `cve` / `sys` / `cms` / `app`<br>Necessity: `asap` / `later` / `nntf`<br>PageSize: `20`|aliyun sas DescribeVulList --Type cve|
|告警事件列表|DescribeAlarmEventList|From: `sas`<br>Levels: `serious` / `suspicious` / `remind`<br>PageSize: `20`|aliyun sas DescribeAlarmEventList --From sas|
|基线检查结果|DescribeCheckWarnings|RiskId: `xxxx`<br>PageSize: `20`|aliyun sas DescribeCheckWarnings --RiskId xxx|
|安全评分|DescribeSecurityStatInfo|-|aliyun sas DescribeSecurityStatInfo|

---

### 34. MSE (微服务引擎)

核心资源: 云原生网关(Gateway)、注册中心/配置中心(Cluster)

CLI产品代码: `mse`

|用户意图 / 查询关键词|对应阿里云API操作 |主要参数示例|CLI命令参考 (简化)|
|---|---|---|---|
|网关列表|ListGateway|PageSize: `20`|aliyun mse ListGateway|
|网关详情|GetGateway|GatewayUniqueId: `gw-xxxx`|aliyun mse GetGateway --GatewayUniqueId gw-xxx|
|网关路由列表|GetGatewayRouteDetail|GatewayUniqueId: `gw-xxxx`<br>RouteId: `xxxx`|aliyun mse GetGatewayRouteDetail --GatewayUniqueId gw-xxx --RouteId xxx|
|注册中心/配置中心集群列表|ListClusters|RegionId: `cn-beijing`<br>ClusterAliasName: `my-nacos`|aliyun mse ListClusters --RegionId cn-beijing|
|集群详情|QueryClusterDetail|InstanceId: `mse-xxxx`|aliyun mse QueryClusterDetail --InstanceId mse-xxx|
|查询Nacos服务列表|ListNacosConfigs|InstanceId: `mse-xxxx`<br>NamespaceId: `public`<br>PageSize: `20`|aliyun mse ListNacosConfigs --InstanceId mse-xxx|

---

## 📚 附录：最佳实践与使用说明

### 5️⃣ 版本更新记录

| 版本 | 日期 | 更新内容 |
|------|------|----------|
| v3.0 | 2026-04-03 | 新增 CR、ECD、ESS、CEN、VPN、PrivateZone、SSL证书、SMS、DCDN、NAT、Elasticsearch、云安全中心、MSE 共 13 个服务 |
| v2.2 | 2025-01-28 | 删除 --Output json 和 分页参数 |
| v2.1 | 2025-01-16 | ��面完善所有服务的"主要参数"列；添加参数值示例和可选值说明 |
| v2.0 | 2025-01-16 | 新增 CDN 服务；优化表格格式；补充 CLI 示例；添加快速索引 |
| v1.0 | 2024-xx-xx | 初始版本，涵盖 20+ 核心服务 |

---

> ⚠️ **重要提示**: 阿里云API会持续更新，具体参数和可用性请以 https://api.aliyun.com/ 为准。建议系统设计时加入API元数据管理机制，以支持动态更新。

