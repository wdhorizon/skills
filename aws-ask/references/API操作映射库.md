# AWS 核心服务 CLI 操作映射知识库

> **版本**: v1.0 | **更新日期**: 2026-03-31
> **重要**: 所有命令必须附加 `--profile devops-readonly`

## 📖 快速索引

| 分类 | 服务 | 核心资源 | 查询复杂度 |
|------|------|----------|------------|
| 🖥️ **计算** | [EC2](#1-ec2-弹性计算) | Instance, Volume, SecurityGroup, AMI | ⭐⭐⭐ |
| ⚡ **计算** | [Lambda](#2-lambda-函数计算) | Function, Layer, EventSourceMapping | ⭐⭐ |
| 🐳 **容器** | [ECS](#3-ecs-弹性容器服务) | Cluster, Service, Task, TaskDefinition | ⭐⭐⭐ |
| 🐳 **容器** | [EKS](#4-eks-kubernetes服务) | Cluster, NodeGroup, FargateProfile | ⭐⭐ |
| 🗄️ **数据库** | [RDS](#5-rds-关系型数据库) | DBInstance, DBCluster, Snapshot | ⭐⭐ |
| 🗄️ **数据库** | [DynamoDB](#6-dynamodb-nosql数据库) | Table, GlobalSecondaryIndex | ⭐ |
| 🗄️ **数据库** | [ElastiCache](#7-elasticache-缓存服务) | CacheCluster, ReplicationGroup | ⭐⭐ |
| 🗄️ **数据库** | [DocumentDB](#8-documentdb-文档数据库) | DBCluster, DBInstance | ⭐ |
| ⚖️ **负载均衡** | [ELBv2](#9-elbv2-应用网络负载均衡) | LoadBalancer, Listener, TargetGroup | ⭐⭐⭐ |
| ⚖️ **负载均衡** | [ELB Classic](#10-elb-classic-经典负载均衡) | LoadBalancer | ⭐ |
| 🌐 **网络** | [VPC](#11-vpc-虚拟私有云) | VPC, Subnet, RouteTable, NatGateway | ⭐⭐⭐ |
| 📦 **存储** | [S3](#12-s3-对象存储) | Bucket, Object | ⭐⭐ |
| 📁 **存储** | [EFS](#13-efs-弹性文件系统) | FileSystem, MountTarget | ⭐ |
| 🌐 **网络** | [Route53](#14-route53-dns服务) | HostedZone, ResourceRecordSet | ⭐⭐ |
| 🌐 **网络** | [CloudFront](#15-cloudfront-cdn) | Distribution, OriginAccessIdentity | ⭐ |
| 📨 **消息** | [SQS](#16-sqs-消息队列) | Queue | ⭐ |
| 📨 **消息** | [SNS](#17-sns-消息通知) | Topic, Subscription | ⭐ |
| 📨 **消息** | [Kinesis](#18-kinesis-数据流) | Stream, Consumer | ⭐⭐ |
| 📨 **消息** | [MSK](#29-msk-托管kafka服务) | Cluster, Broker, Topic | ⭐⭐ |
| 📊 **监控** | [CloudWatch](#19-cloudwatch-监控服务) | Metric, Alarm, Dashboard, LogGroup | ⭐⭐⭐ |
| 📊 **监控** | [CloudTrail](#20-cloudtrail-操作审计) | Trail, Event | ⭐⭐ |
| 🛡️ **安全** | [IAM](#21-iam-身份权限管理) | User, Role, Policy, Group | ⭐⭐⭐ |
| 🛡️ **安全** | [IAM Identity Center](#30-iam-identity-center-单点登录) | Instance, PermissionSet, AccountAssignment, User, Group | ⭐⭐⭐ |
| 🛡️ **安全** | [KMS](#22-kms-密钥管理) | Key, Alias | ⭐ |
| 🛡️ **安全** | [Secrets Manager](#23-secrets-manager-密钥存储) | Secret | ⭐ |
| 🛡️ **安全** | [Security Hub](#24-security-hub-安全中心) | Finding, Standard | ⭐⭐ |
| 🛡️ **安全** | [GuardDuty](#25-guardduty-威胁检测) | Detector, Finding | ⭐⭐ |
| 📦 **容器注册** | [ECR](#26-ecr-容器镜像仓库) | Repository, Image | ⭐ |
| 🔐 **证书** | [ACM](#27-acm-证书管理) | Certificate | ⭐ |
| 💰 **成本** | [Cost Explorer](#28-cost-explorer-成本分析) | Cost, Usage | ⭐⭐ |

---

## API-Action 映射矩阵

### 1. EC2 (弹性计算)

核心资源: 实例(Instance)、存储卷(Volume)、安全组(SecurityGroup)、镜像(AMI)、快照(Snapshot)、弹性IP(EIP)

| 用户意图 / 查询关键词 | AWS CLI 命令 | 主要参数示例 | 说明 |
|---|---|---|---|
| 查询区域列表 | `aws ec2 describe-regions` | `--profile devops-readonly` | 无需 --region |
| 单实例详情 | `aws ec2 describe-instances` | `--instance-ids i-0xxx --region ap-southeast-1 --profile devops-readonly` | 使用 Reservations 嵌套结构 |
| 实例列表查询 | `aws ec2 describe-instances` | `--filters "Name=instance-state-name,Values=running" --region ap-southeast-1 --profile devops-readonly` | 支持多种过滤条件 |
| 按VPC查询实例 | `aws ec2 describe-instances` | `--filters "Name=vpc-id,Values=vpc-xxx" --region ap-southeast-1 --profile devops-readonly` | - |
| 按标签查询实例 | `aws ec2 describe-instances` | `--filters "Name=tag:Name,Values=web-*" --region ap-southeast-1 --profile devops-readonly` | 支持通配符 |
| 查询实例状态 | `aws ec2 describe-instance-status` | `--instance-ids i-0xxx --region ap-southeast-1 --profile devops-readonly` | 含系统检查状态 |
| 查询挂载的存储卷 | `aws ec2 describe-volumes` | `--filters "Name=attachment.instance-id,Values=i-0xxx" --region ap-southeast-1 --profile devops-readonly` | - |
| 查询存储卷列表 | `aws ec2 describe-volumes` | `--region ap-southeast-1 --profile devops-readonly` | - |
| 查询安全组列表 | `aws ec2 describe-security-groups` | `--region ap-southeast-1 --profile devops-readonly` | - |
| 查询安全组规则 | `aws ec2 describe-security-groups` | `--group-ids sg-0xxx --region ap-southeast-1 --profile devops-readonly` | 含 IpPermissions |
| 查询安全组规则详情 | `aws ec2 describe-security-group-rules` | `--filters "Name=group-id,Values=sg-0xxx" --region ap-southeast-1 --profile devops-readonly` | 新版 API |
| 查询镜像(AMI) | `aws ec2 describe-images` | `--owners self --region ap-southeast-1 --profile devops-readonly` | owners: self/amazon/aws-marketplace |
| 查询快照 | `aws ec2 describe-snapshots` | `--owner-ids self --region ap-southeast-1 --profile devops-readonly` | - |
| 查询弹性IP | `aws ec2 describe-addresses` | `--region ap-southeast-1 --profile devops-readonly` | - |
| 查询密钥对 | `aws ec2 describe-key-pairs` | `--region ap-southeast-1 --profile devops-readonly` | - |
| 查询实例类型 | `aws ec2 describe-instance-types` | `--instance-types t3.medium --region ap-southeast-1 --profile devops-readonly` | - |
| 查询网络接口 | `aws ec2 describe-network-interfaces` | `--filters "Name=attachment.instance-id,Values=i-0xxx" --region ap-southeast-1 --profile devops-readonly` | - |
| 查询Placement Groups | `aws ec2 describe-placement-groups` | `--region ap-southeast-1 --profile devops-readonly` | - |
| 查询启动模板 | `aws ec2 describe-launch-templates` | `--region ap-southeast-1 --profile devops-readonly` | - |
| 查询Auto Scaling组 | `aws autoscaling describe-auto-scaling-groups` | `--region ap-southeast-1 --profile devops-readonly` | 使用autoscaling服务 |

**重要说明**: EC2 使用 `Reservations` 嵌套结构:
```bash
# 获取实例列表（含名称标签）
aws ec2 describe-instances --profile devops-readonly --region ap-southeast-1 \
  | jq '.Reservations[].Instances[] | {
      InstanceId,
      Name: (.Tags // [] | map(select(.Key == "Name")) | first | .Value // "N/A"),
      State: .State.Name,
      Type: .InstanceType,
      PrivateIp: .PrivateIpAddress,
      PublicIp: (.PublicIpAddress // "N/A")
    }'
```

---

### 2. Lambda (函数计算)

核心资源: 函数(Function)、层(Layer)、事件源映射(EventSourceMapping)

| 用户意图 / 查询关键词 | AWS CLI 命令 | 主要参数示例 | 说明 |
|---|---|---|---|
| 函数列表 | `aws lambda list-functions` | `--region ap-southeast-1 --profile devops-readonly` | - |
| 函数详情 | `aws lambda get-function` | `--function-name my-func --region ap-southeast-1 --profile devops-readonly` | 含代码位置 |
| 函数配置 | `aws lambda get-function-configuration` | `--function-name my-func --region ap-southeast-1 --profile devops-readonly` | 不含代码 |
| 查询Layer列表 | `aws lambda list-layers` | `--region ap-southeast-1 --profile devops-readonly` | - |
| 查询事件源映射 | `aws lambda list-event-source-mappings` | `--function-name my-func --region ap-southeast-1 --profile devops-readonly` | - |
| 查询函数别名 | `aws lambda list-aliases` | `--function-name my-func --region ap-southeast-1 --profile devops-readonly` | - |
| 查询函数版本 | `aws lambda list-versions-by-function` | `--function-name my-func --region ap-southeast-1 --profile devops-readonly` | - |
| 查询函数策略 | `aws lambda get-policy` | `--function-name my-func --region ap-southeast-1 --profile devops-readonly` | 资源权限策略 |
| 查询并发配置 | `aws lambda get-function-concurrency` | `--function-name my-func --region ap-southeast-1 --profile devops-readonly` | - |

---

### 3. ECS (弹性容器服务)

核心资源: 集群(Cluster)、服务(Service)、任务(Task)、任务定义(TaskDefinition)

| 用户意图 / 查询关键词 | AWS CLI 命令 | 主要参数示例 | 说明 |
|---|---|---|---|
| 集群列表 | `aws ecs list-clusters` | `--region ap-southeast-1 --profile devops-readonly` | 返回 ARN 列表 |
| 集群详情 | `aws ecs describe-clusters` | `--clusters my-cluster --region ap-southeast-1 --profile devops-readonly` | - |
| 服务列表 | `aws ecs list-services` | `--cluster my-cluster --region ap-southeast-1 --profile devops-readonly` | - |
| 服务详情 | `aws ecs describe-services` | `--cluster my-cluster --services my-service --region ap-southeast-1 --profile devops-readonly` | - |
| 任务列表 | `aws ecs list-tasks` | `--cluster my-cluster --region ap-southeast-1 --profile devops-readonly` | - |
| 任务详情 | `aws ecs describe-tasks` | `--cluster my-cluster --tasks task-arn --region ap-southeast-1 --profile devops-readonly` | - |
| 任务定义列表 | `aws ecs list-task-definitions` | `--region ap-southeast-1 --profile devops-readonly` | - |
| 任务定义详情 | `aws ecs describe-task-definition` | `--task-definition my-task:1 --region ap-southeast-1 --profile devops-readonly` | - |
| 容器实例列表 | `aws ecs list-container-instances` | `--cluster my-cluster --region ap-southeast-1 --profile devops-readonly` | EC2 启动类型 |

---

### 4. EKS (Kubernetes 服务)

核心资源: 集群(Cluster)、节点组(NodeGroup)、Fargate配置

| 用户意图 / 查询关键词 | AWS CLI 命令 | 主要参数示例 | 说明 |
|---|---|---|---|
| 集群列表 | `aws eks list-clusters` | `--region ap-southeast-1 --profile devops-readonly` | - |
| 集群详情 | `aws eks describe-cluster` | `--name my-cluster --region ap-southeast-1 --profile devops-readonly` | - |
| 节点组列表 | `aws eks list-nodegroups` | `--cluster-name my-cluster --region ap-southeast-1 --profile devops-readonly` | - |
| 节点组详情 | `aws eks describe-nodegroup` | `--cluster-name my-cluster --nodegroup-name ng-xxx --region ap-southeast-1 --profile devops-readonly` | - |
| Fargate配置列表 | `aws eks list-fargate-profiles` | `--cluster-name my-cluster --region ap-southeast-1 --profile devops-readonly` | - |
| 插件列表 | `aws eks list-addons` | `--cluster-name my-cluster --region ap-southeast-1 --profile devops-readonly` | - |
| 插件详情 | `aws eks describe-addon` | `--cluster-name my-cluster --addon-name vpc-cni --region ap-southeast-1 --profile devops-readonly` | - |

---

### 5. RDS (关系型数据库)

核心资源: 实例(DBInstance)、集群(DBCluster)、快照(Snapshot)、参数组(ParameterGroup)

| 用户意图 / 查询关键词 | AWS CLI 命令 | 主要参数示例 | 说明 |
|---|---|---|---|
| 实例列表 | `aws rds describe-db-instances` | `--region ap-southeast-1 --profile devops-readonly` | 含 Aurora 实例 |
| 单实例详情 | `aws rds describe-db-instances` | `--db-instance-identifier mydb --region ap-southeast-1 --profile devops-readonly` | - |
| Aurora集群列表 | `aws rds describe-db-clusters` | `--region ap-southeast-1 --profile devops-readonly` | - |
| 快照列表 | `aws rds describe-db-snapshots` | `--db-instance-identifier mydb --region ap-southeast-1 --profile devops-readonly` | - |
| 集群快照列表 | `aws rds describe-db-cluster-snapshots` | `--db-cluster-identifier my-cluster --region ap-southeast-1 --profile devops-readonly` | - |
| 参数组列表 | `aws rds describe-db-parameter-groups` | `--region ap-southeast-1 --profile devops-readonly` | - |
| 参数组配置 | `aws rds describe-db-parameters` | `--db-parameter-group-name default.mysql8.0 --region ap-southeast-1 --profile devops-readonly` | - |
| 子网组列表 | `aws rds describe-db-subnet-groups` | `--region ap-southeast-1 --profile devops-readonly` | - |
| 事件列表 | `aws rds describe-events` | `--source-type db-instance --source-identifier mydb --region ap-southeast-1 --profile devops-readonly` | 操作历史 |
| 查询数据库引擎版本 | `aws rds describe-db-engine-versions` | `--engine mysql --region ap-southeast-1 --profile devops-readonly` | - |

---

### 6. DynamoDB (NoSQL 数据库)

核心资源: 表(Table)、全局二级索引(GSI)、流(Stream)

| 用户意图 / 查询关键词 | AWS CLI 命令 | 主要参数示例 | 说明 |
|---|---|---|---|
| 表列表 | `aws dynamodb list-tables` | `--region ap-southeast-1 --profile devops-readonly` | - |
| 表详情 | `aws dynamodb describe-table` | `--table-name my-table --region ap-southeast-1 --profile devops-readonly` | 含索引和流信息 |
| 查询表限额 | `aws dynamodb describe-limits` | `--region ap-southeast-1 --profile devops-readonly` | RCU/WCU 限额 |
| 备份列表 | `aws dynamodb list-backups` | `--table-name my-table --region ap-southeast-1 --profile devops-readonly` | - |
| 全局表列表 | `aws dynamodb list-global-tables` | `--profile devops-readonly` | - |
| 时间点恢复配置 | `aws dynamodb describe-continuous-backups` | `--table-name my-table --region ap-southeast-1 --profile devops-readonly` | PITR 状态 |

---

### 7. ElastiCache (缓存服务)

核心资源: 集群(CacheCluster)、复制组(ReplicationGroup)

| 用户意图 / 查询关键词 | AWS CLI 命令 | 主要参数示例 | 说明 |
|---|---|---|---|
| 集群列表 | `aws elasticache describe-cache-clusters` | `--region ap-southeast-1 --profile devops-readonly` | Redis/Memcached |
| 集群详情 | `aws elasticache describe-cache-clusters` | `--cache-cluster-id my-cluster --show-cache-node-info --region ap-southeast-1 --profile devops-readonly` | - |
| Redis复制组列表 | `aws elasticache describe-replication-groups` | `--region ap-southeast-1 --profile devops-readonly` | - |
| 复制组详情 | `aws elasticache describe-replication-groups` | `--replication-group-id my-redis --region ap-southeast-1 --profile devops-readonly` | - |
| 参数组列表 | `aws elasticache describe-cache-parameter-groups` | `--region ap-southeast-1 --profile devops-readonly` | - |
| 子网组列表 | `aws elasticache describe-cache-subnet-groups` | `--region ap-southeast-1 --profile devops-readonly` | - |
| 事件列表 | `aws elasticache describe-events` | `--region ap-southeast-1 --profile devops-readonly` | - |

---

### 8. DocumentDB (文档数据库)

核心资源: 集群(DBCluster)、实例(DBInstance)

| 用户意图 / 查询关键词 | AWS CLI 命令 | 主要参数示例 | 说明 |
|---|---|---|---|
| 集群列表 | `aws docdb describe-db-clusters` | `--region ap-southeast-1 --profile devops-readonly` | - |
| 集群详情 | `aws docdb describe-db-clusters` | `--db-cluster-identifier my-docdb --region ap-southeast-1 --profile devops-readonly` | - |
| 实例列表 | `aws docdb describe-db-instances` | `--region ap-southeast-1 --profile devops-readonly` | - |
| 快照列表 | `aws docdb describe-db-cluster-snapshots` | `--db-cluster-identifier my-docdb --region ap-southeast-1 --profile devops-readonly` | - |

---

### 9. ELBv2 (应用/网络负载均衡)

核心资源: 负载均衡(LoadBalancer)、监听器(Listener)、目标组(TargetGroup)、规则(Rule)

| 用户意图 / 查询关键词 | AWS CLI 命令 | 主要参数示例 | 说明 |
|---|---|---|---|
| 负载均衡列表 | `aws elbv2 describe-load-balancers` | `--region ap-southeast-1 --profile devops-readonly` | ALB/NLB/GLB |
| 单负载均衡详情 | `aws elbv2 describe-load-balancers` | `--names my-alb --region ap-southeast-1 --profile devops-readonly` | - |
| 监听器列表 | `aws elbv2 describe-listeners` | `--load-balancer-arn arn:aws:elasticloadbalancing:... --region ap-southeast-1 --profile devops-readonly` | - |
| 监听器规则 | `aws elbv2 describe-rules` | `--listener-arn arn:aws:elasticloadbalancing:... --region ap-southeast-1 --profile devops-readonly` | - |
| 目标组列表 | `aws elbv2 describe-target-groups` | `--load-balancer-arn arn:aws:elasticloadbalancing:... --region ap-southeast-1 --profile devops-readonly` | - |
| 目标组健康状态 | `aws elbv2 describe-target-health` | `--target-group-arn arn:aws:elasticloadbalancing:... --region ap-southeast-1 --profile devops-readonly` | - |
| 负载均衡属性 | `aws elbv2 describe-load-balancer-attributes` | `--load-balancer-arn arn:aws:elasticloadbalancing:... --region ap-southeast-1 --profile devops-readonly` | - |
| 目标组属性 | `aws elbv2 describe-target-group-attributes` | `--target-group-arn arn:aws:elasticloadbalancing:... --region ap-southeast-1 --profile devops-readonly` | - |
| SSL证书列表 | `aws elbv2 describe-listener-certificates` | `--listener-arn arn:aws:elasticloadbalancing:... --region ap-southeast-1 --profile devops-readonly` | - |

---

### 10. ELB Classic (经典负载均衡)

核心资源: 负载均衡(LoadBalancer)

| 用户意图 / 查询关键词 | AWS CLI 命令 | 主要参数示例 | 说明 |
|---|---|---|---|
| 负载均衡列表 | `aws elb describe-load-balancers` | `--region ap-southeast-1 --profile devops-readonly` | 仅经典类型 |
| 单负载均衡详情 | `aws elb describe-load-balancers` | `--load-balancer-names my-elb --region ap-southeast-1 --profile devops-readonly` | - |
| 后端实例健康状态 | `aws elb describe-instance-health` | `--load-balancer-name my-elb --region ap-southeast-1 --profile devops-readonly` | - |
| 负载均衡属性 | `aws elb describe-load-balancer-attributes` | `--load-balancer-name my-elb --region ap-southeast-1 --profile devops-readonly` | - |

---

### 11. VPC (虚拟私有云)

核心资源: VPC、子网(Subnet)、路由表(RouteTable)、Internet网关(IGW)、NAT网关、安全组、网络ACL、VPC对等连接

| 用户意图 / 查询关键词 | AWS CLI 命令 | 主要参数示例 | 说明 |
|---|---|---|---|
| VPC列表 | `aws ec2 describe-vpcs` | `--region ap-southeast-1 --profile devops-readonly` | - |
| VPC详情 | `aws ec2 describe-vpcs` | `--vpc-ids vpc-xxx --region ap-southeast-1 --profile devops-readonly` | - |
| 子网列表 | `aws ec2 describe-subnets` | `--filters "Name=vpc-id,Values=vpc-xxx" --region ap-southeast-1 --profile devops-readonly` | - |
| 路由表列表 | `aws ec2 describe-route-tables` | `--filters "Name=vpc-id,Values=vpc-xxx" --region ap-southeast-1 --profile devops-readonly` | - |
| Internet网关 | `aws ec2 describe-internet-gateways` | `--filters "Name=attachment.vpc-id,Values=vpc-xxx" --region ap-southeast-1 --profile devops-readonly` | - |
| NAT网关 | `aws ec2 describe-nat-gateways` | `--filter "Name=vpc-id,Values=vpc-xxx" --region ap-southeast-1 --profile devops-readonly` | - |
| 网络ACL | `aws ec2 describe-network-acls` | `--filters "Name=vpc-id,Values=vpc-xxx" --region ap-southeast-1 --profile devops-readonly` | - |
| VPC对等连接 | `aws ec2 describe-vpc-peering-connections` | `--region ap-southeast-1 --profile devops-readonly` | - |
| VPN网关 | `aws ec2 describe-vpn-gateways` | `--region ap-southeast-1 --profile devops-readonly` | - |
| VPN连接 | `aws ec2 describe-vpn-connections` | `--region ap-southeast-1 --profile devops-readonly` | - |
| Transit Gateway列表 | `aws ec2 describe-transit-gateways` | `--region ap-southeast-1 --profile devops-readonly` | - |
| VPC端点列表 | `aws ec2 describe-vpc-endpoints` | `--region ap-southeast-1 --profile devops-readonly` | - |
| 流日志 | `aws ec2 describe-flow-logs` | `--region ap-southeast-1 --profile devops-readonly` | - |

---

### 12. S3 (对象存储)

核心资源: 存储桶(Bucket)、对象(Object)

| 用户意图 / 查询关键词 | AWS CLI 命令 | 主要参数示例 | 说明 |
|---|---|---|---|
| Bucket列表 | `aws s3 ls` | `--profile devops-readonly` | 全局，无需 --region |
| Bucket内容列表 | `aws s3 ls` | `s3://my-bucket/ --profile devops-readonly` | - |
| Bucket信息 | `aws s3api get-bucket-location` | `--bucket my-bucket --profile devops-readonly` | 获取区域 |
| Bucket策略 | `aws s3api get-bucket-policy` | `--bucket my-bucket --profile devops-readonly` | - |
| Bucket ACL | `aws s3api get-bucket-acl` | `--bucket my-bucket --profile devops-readonly` | - |
| Bucket版本控制 | `aws s3api get-bucket-versioning` | `--bucket my-bucket --profile devops-readonly` | - |
| Bucket加密配置 | `aws s3api get-bucket-encryption` | `--bucket my-bucket --profile devops-readonly` | - |
| Bucket生命周期 | `aws s3api get-bucket-lifecycle-configuration` | `--bucket my-bucket --profile devops-readonly` | - |
| Bucket日志配置 | `aws s3api get-bucket-logging` | `--bucket my-bucket --profile devops-readonly` | - |
| Bucket通知配置 | `aws s3api get-bucket-notification-configuration` | `--bucket my-bucket --profile devops-readonly` | - |
| Bucket网站托管 | `aws s3api get-bucket-website` | `--bucket my-bucket --profile devops-readonly` | - |
| Bucket CORS配置 | `aws s3api get-bucket-cors` | `--bucket my-bucket --profile devops-readonly` | - |
| 对象列表(高级) | `aws s3api list-objects-v2` | `--bucket my-bucket --prefix path/ --profile devops-readonly` | 支持更多选项 |
| 对象元数据 | `aws s3api head-object` | `--bucket my-bucket --key path/to/object --profile devops-readonly` | - |
| 查询Bucket标签 | `aws s3api get-bucket-tagging` | `--bucket my-bucket --profile devops-readonly` | - |
| 查询公开访问配置 | `aws s3api get-public-access-block` | `--bucket my-bucket --profile devops-readonly` | 重要安全检查 |

---

### 13. EFS (弹性文件系统)

核心资源: 文件系统(FileSystem)、挂载目标(MountTarget)、访问点(AccessPoint)

| 用户意图 / 查询关键词 | AWS CLI 命令 | 主要参数示例 | 说明 |
|---|---|---|---|
| 文件系统列表 | `aws efs describe-file-systems` | `--region ap-southeast-1 --profile devops-readonly` | - |
| 文件系统详情 | `aws efs describe-file-systems` | `--file-system-id fs-xxx --region ap-southeast-1 --profile devops-readonly` | - |
| 挂载目标列表 | `aws efs describe-mount-targets` | `--file-system-id fs-xxx --region ap-southeast-1 --profile devops-readonly` | - |
| 访问点列表 | `aws efs describe-access-points` | `--file-system-id fs-xxx --region ap-southeast-1 --profile devops-readonly` | - |
| 备份策略 | `aws efs describe-backup-policy` | `--file-system-id fs-xxx --region ap-southeast-1 --profile devops-readonly` | - |

---

### 14. Route53 (DNS 服务)

核心资源: 托管区域(HostedZone)、资源记录集(ResourceRecordSet)

> **注意**: Route53 是全局服务，不需要 `--region`

| 用户意图 / 查询关键词 | AWS CLI 命令 | 主要参数示例 | 说明 |
|---|---|---|---|
| 托管区域列表 | `aws route53 list-hosted-zones` | `--profile devops-readonly` | - |
| 托管区域详情 | `aws route53 get-hosted-zone` | `--id Z1234567890ABC --profile devops-readonly` | - |
| DNS记录列表 | `aws route53 list-resource-record-sets` | `--hosted-zone-id Z1234567890ABC --profile devops-readonly` | - |
| 通过域名查找 | `aws route53 list-hosted-zones-by-name` | `--dns-name example.com --profile devops-readonly` | - |
| 健康检查列表 | `aws route53 list-health-checks` | `--profile devops-readonly` | - |
| 健康检查详情 | `aws route53 get-health-check` | `--health-check-id xxx --profile devops-readonly` | - |
| 流量策略列表 | `aws route53 list-traffic-policies` | `--profile devops-readonly` | - |

---

### 15. CloudFront (CDN)

核心资源: 分发(Distribution)

> **注意**: CloudFront 是全局服务，不需要 `--region`

| 用户意图 / 查询关键词 | AWS CLI 命令 | 主要参数示例 | 说明 |
|---|---|---|---|
| 分发列表 | `aws cloudfront list-distributions` | `--profile devops-readonly` | - |
| 分发详情 | `aws cloudfront get-distribution` | `--id EDFDVBD6EXAMPLE --profile devops-readonly` | - |
| Origin Access Identity列表 | `aws cloudfront list-cloud-front-origin-access-identities` | `--profile devops-readonly` | OAI |
| 缓存策略列表 | `aws cloudfront list-cache-policies` | `--profile devops-readonly` | - |
| WAF关联查询 | `aws cloudfront get-distribution-config` | `--id EDFDVBD6EXAMPLE --profile devops-readonly` | 查 WebACLId 字段 |

---

### 16. SQS (消息队列)

核心资源: 队列(Queue)

| 用户意图 / 查询关键词 | AWS CLI 命令 | 主要参数示例 | 说明 |
|---|---|---|---|
| 队列列表 | `aws sqs list-queues` | `--region ap-southeast-1 --profile devops-readonly` | - |
| 队列属性 | `aws sqs get-queue-attributes` | `--queue-url https://... --attribute-names All --region ap-southeast-1 --profile devops-readonly` | - |
| 按前缀查队列 | `aws sqs list-queues` | `--queue-name-prefix my-queue --region ap-southeast-1 --profile devops-readonly` | - |
| 死信队列查询 | `aws sqs list-dead-letter-source-queues` | `--queue-url https://... --region ap-southeast-1 --profile devops-readonly` | - |

---

### 17. SNS (消息通知)

核心资源: 主题(Topic)、订阅(Subscription)

| 用户意图 / 查询关键词 | AWS CLI 命令 | 主要参数示例 | 说明 |
|---|---|---|---|
| 主题列表 | `aws sns list-topics` | `--region ap-southeast-1 --profile devops-readonly` | - |
| 主题属性 | `aws sns get-topic-attributes` | `--topic-arn arn:aws:sns:... --region ap-southeast-1 --profile devops-readonly` | - |
| 订阅列表 | `aws sns list-subscriptions` | `--region ap-southeast-1 --profile devops-readonly` | - |
| 特定主题订阅 | `aws sns list-subscriptions-by-topic` | `--topic-arn arn:aws:sns:... --region ap-southeast-1 --profile devops-readonly` | - |
| 订阅详情 | `aws sns get-subscription-attributes` | `--subscription-arn arn:aws:sns:... --region ap-southeast-1 --profile devops-readonly` | - |

---

### 18. Kinesis (数据流)

核心资源: 数据流(Stream)、消费者(Consumer)

| 用户意图 / 查询关键词 | AWS CLI 命令 | 主要参数示例 | 说明 |
|---|---|---|---|
| 数据流列表 | `aws kinesis list-streams` | `--region ap-southeast-1 --profile devops-readonly` | - |
| 数据流详情 | `aws kinesis describe-stream` | `--stream-name my-stream --region ap-southeast-1 --profile devops-readonly` | - |
| 流摘要 | `aws kinesis describe-stream-summary` | `--stream-name my-stream --region ap-southeast-1 --profile devops-readonly` | 更快 |
| 消费者列表 | `aws kinesis list-stream-consumers` | `--stream-arn arn:aws:kinesis:... --region ap-southeast-1 --profile devops-readonly` | - |
| Firehose列表 | `aws firehose list-delivery-streams` | `--region ap-southeast-1 --profile devops-readonly` | 不同服务 |
| Firehose详情 | `aws firehose describe-delivery-stream` | `--delivery-stream-name my-stream --region ap-southeast-1 --profile devops-readonly` | - |

---

### 19. CloudWatch (监控服务)

核心资源: 指标(Metric)、告警(Alarm)、日志组(LogGroup)、仪表板(Dashboard)

| 用户意图 / 查询关键词 | AWS CLI 命令 | 主要参数示例 | 说明 |
|---|---|---|---|
| 告警列表 | `aws cloudwatch describe-alarms` | `--region ap-southeast-1 --profile devops-readonly` | - |
| 告警状态 | `aws cloudwatch describe-alarms` | `--state-value ALARM --region ap-southeast-1 --profile devops-readonly` | 筛选告警中的 |
| 查询指标列表 | `aws cloudwatch list-metrics` | `--namespace AWS/EC2 --region ap-southeast-1 --profile devops-readonly` | - |
| 查询指标数据 | `aws cloudwatch get-metric-statistics` | `--namespace AWS/EC2 --metric-name CPUUtilization --dimensions Name=InstanceId,Value=i-xxx --start-time 2025-01-01T00:00:00Z --end-time 2025-01-02T00:00:00Z --period 3600 --statistics Average --region ap-southeast-1 --profile devops-readonly` | - |
| 查询仪表板列表 | `aws cloudwatch list-dashboards` | `--region ap-southeast-1 --profile devops-readonly` | - |
| 日志组列表 | `aws logs describe-log-groups` | `--region ap-southeast-1 --profile devops-readonly` | 使用 logs 服务 |
| 日志流列表 | `aws logs describe-log-streams` | `--log-group-name /aws/lambda/my-func --region ap-southeast-1 --profile devops-readonly` | - |
| 查询日志 | `aws logs filter-log-events` | `--log-group-name /aws/lambda/my-func --filter-pattern "ERROR" --start-time 1704067200000 --region ap-southeast-1 --profile devops-readonly` | 时间为毫秒时间戳 |
| Insights查询 | `aws logs start-query` | `--log-group-name /aws/lambda/my-func --start-time 1704067200 --end-time 1704153600 --query-string 'fields @timestamp, @message' --region ap-southeast-1 --profile devops-readonly` | 异步查询 |
| 复合告警列表 | `aws cloudwatch describe-alarm-history` | `--alarm-name my-alarm --region ap-southeast-1 --profile devops-readonly` | - |

---

### 20. CloudTrail (操作审计)

核心资源: Trail、事件(Event)

| 用户意图 / 查询关键词 | AWS CLI 命令 | 主要参数示例 | 说明 |
|---|---|---|---|
| Trail列表 | `aws cloudtrail describe-trails` | `--region ap-southeast-1 --profile devops-readonly` | - |
| Trail状态 | `aws cloudtrail get-trail-status` | `--name my-trail --region ap-southeast-1 --profile devops-readonly` | 是否启用 |
| 查询事件历史 | `aws cloudtrail lookup-events` | `--lookup-attributes AttributeKey=EventName,AttributeValue=RunInstances --start-time 2025-01-01 --end-time 2025-01-02 --region ap-southeast-1 --profile devops-readonly` | 最近90天 |
| 查询特定用户操作 | `aws cloudtrail lookup-events` | `--lookup-attributes AttributeKey=Username,AttributeValue=myuser --region ap-southeast-1 --profile devops-readonly` | - |

---

### 21. IAM (身份权限管理)

核心资源: 用户(User)、角色(Role)、策略(Policy)、组(Group)

> **注意**: IAM 是全局服务，不需要 `--region`

| 用户意图 / 查询关键词 | AWS CLI 命令 | 主要参数示例 | 说明 |
|---|---|---|---|
| 用户列表 | `aws iam list-users` | `--profile devops-readonly` | - |
| 用户详情 | `aws iam get-user` | `--user-name myuser --profile devops-readonly` | - |
| 用户附加策略 | `aws iam list-attached-user-policies` | `--user-name myuser --profile devops-readonly` | 托管策略 |
| 用户内联策略 | `aws iam list-user-policies` | `--user-name myuser --profile devops-readonly` | 内联策略列表 |
| 用户所属组 | `aws iam list-groups-for-user` | `--user-name myuser --profile devops-readonly` | - |
| 用户访问密钥 | `aws iam list-access-keys` | `--user-name myuser --profile devops-readonly` | 不含密钥值 |
| 角色列表 | `aws iam list-roles` | `--profile devops-readonly` | - |
| 角色详情 | `aws iam get-role` | `--role-name my-role --profile devops-readonly` | 含信任策略 |
| 角色附加策略 | `aws iam list-attached-role-policies` | `--role-name my-role --profile devops-readonly` | - |
| 策略列表 | `aws iam list-policies` | `--scope Local --profile devops-readonly` | Local=自定义, AWS=托管 |
| 策略详情 | `aws iam get-policy` | `--policy-arn arn:aws:iam::xxx:policy/my-policy --profile devops-readonly` | - |
| 策略文档 | `aws iam get-policy-version` | `--policy-arn arn:aws:iam::xxx:policy/my-policy --version-id v1 --profile devops-readonly` | - |
| 组列表 | `aws iam list-groups` | `--profile devops-readonly` | - |
| 组成员 | `aws iam get-group` | `--group-name my-group --profile devops-readonly` | - |
| 密码策略 | `aws iam get-account-password-policy` | `--profile devops-readonly` | - |
| 账号摘要 | `aws iam get-account-summary` | `--profile devops-readonly` | 用户/角色统计 |
| MFA设备列表 | `aws iam list-mfa-devices` | `--user-name myuser --profile devops-readonly` | - |
| 账号别名 | `aws iam list-account-aliases` | `--profile devops-readonly` | - |
| SAML提供商 | `aws iam list-saml-providers` | `--profile devops-readonly` | - |

---

### 22. KMS (密钥管理)

核心资源: 密钥(Key)、别名(Alias)

| 用户意图 / 查询关键词 | AWS CLI 命令 | 主要参数示例 | 说明 |
|---|---|---|---|
| 密钥列表 | `aws kms list-keys` | `--region ap-southeast-1 --profile devops-readonly` | - |
| 密钥详情 | `aws kms describe-key` | `--key-id key-id-or-arn --region ap-southeast-1 --profile devops-readonly` | - |
| 别名列表 | `aws kms list-aliases` | `--region ap-southeast-1 --profile devops-readonly` | - |
| 密钥策略 | `aws kms get-key-policy` | `--key-id key-id --policy-name default --region ap-southeast-1 --profile devops-readonly` | - |

---

### 23. Secrets Manager (密钥存储)

核心资源: 密钥(Secret)

| 用户意图 / 查询关键词 | AWS CLI 命令 | 主要参数示例 | 说明 |
|---|---|---|---|
| 密钥列表 | `aws secretsmanager list-secrets` | `--region ap-southeast-1 --profile devops-readonly` | 仅元数据 |
| 密钥详情 | `aws secretsmanager describe-secret` | `--secret-id my-secret --region ap-southeast-1 --profile devops-readonly` | 不含值 |
| 密钥轮换状态 | `aws secretsmanager describe-secret` | `--secret-id my-secret --region ap-southeast-1 --profile devops-readonly` | 查 RotationEnabled 字段 |

> ⚠️ **安全提示**: `get-secret-value` 命令会返回密钥的实际值，属于敏感操作。如果 `devops-readonly` profile 有此权限且用户请求，需明确提示密钥值的敏感性。

---

### 24. Security Hub (安全中心)

核心资源: 发现(Finding)、标准(Standard)

| 用户意图 / 查询关键词 | AWS CLI 命令 | 主要参数示例 | 说明 |
|---|---|---|---|
| 安全发现列表 | `aws securityhub get-findings` | `--region ap-southeast-1 --profile devops-readonly` | - |
| 安全评分 | `aws securityhub get-insights` | `--region ap-southeast-1 --profile devops-readonly` | - |
| 启用的标准 | `aws securityhub describe-standards-subscriptions` | `--region ap-southeast-1 --profile devops-readonly` | - |

---

### 25. GuardDuty (威胁检测)

核心资源: 探测器(Detector)、发现(Finding)

| 用户意图 / 查询关键词 | AWS CLI 命令 | 主要参数示例 | 说明 |
|---|---|---|---|
| 探测器列表 | `aws guardduty list-detectors` | `--region ap-southeast-1 --profile devops-readonly` | - |
| 探测器详情 | `aws guardduty get-detector` | `--detector-id xxx --region ap-southeast-1 --profile devops-readonly` | - |
| 发现列表 | `aws guardduty list-findings` | `--detector-id xxx --region ap-southeast-1 --profile devops-readonly` | - |
| 发现详情 | `aws guardduty get-findings` | `--detector-id xxx --finding-ids xxx --region ap-southeast-1 --profile devops-readonly` | - |

---

### 26. ECR (容器镜像仓库)

核心资源: 仓库(Repository)、镜像(Image)

| 用户意图 / 查询关键词 | AWS CLI 命令 | 主要参数示例 | 说明 |
|---|---|---|---|
| 仓库列表 | `aws ecr describe-repositories` | `--region ap-southeast-1 --profile devops-readonly` | - |
| 仓库详情 | `aws ecr describe-repositories` | `--repository-names my-repo --region ap-southeast-1 --profile devops-readonly` | - |
| 镜像列表 | `aws ecr describe-images` | `--repository-name my-repo --region ap-southeast-1 --profile devops-readonly` | - |
| 镜像扫描结果 | `aws ecr describe-image-scan-findings` | `--repository-name my-repo --image-id imageDigest=sha256:xxx --region ap-southeast-1 --profile devops-readonly` | - |
| 仓库策略 | `aws ecr get-repository-policy` | `--repository-name my-repo --region ap-southeast-1 --profile devops-readonly` | - |

---

### 27. ACM (证书管理)

核心资源: 证书(Certificate)

| 用户意图 / 查询关键词 | AWS CLI 命令 | 主要参数示例 | 说明 |
|---|---|---|---|
| 证书列表 | `aws acm list-certificates` | `--region ap-southeast-1 --profile devops-readonly` | - |
| 证书详情 | `aws acm describe-certificate` | `--certificate-arn arn:aws:acm:... --region ap-southeast-1 --profile devops-readonly` | - |
| 即将过期证书 | `aws acm list-certificates` | `--includes keyTypes=RSA_2048 --region ap-southeast-1 --profile devops-readonly` | 结合 jq 过滤 |

---

### 28. Cost Explorer (成本分析)

核心资源: 成本(Cost)、使用量(Usage)

> **注意**: Cost Explorer 需要在 `ap-southeast-1` 区域访问

| 用户意图 / 查询关键词 | AWS CLI 命令 | 主要参数示例 | 说明 |
|---|---|---|---|
| 查询月度费用 | `aws ce get-cost-and-usage` | `--time-period Start=2025-01-01,End=2025-02-01 --granularity MONTHLY --metrics BlendedCost --profile devops-readonly` | 需 --region ap-southeast-1 |
| 按服务分组 | `aws ce get-cost-and-usage` | `--time-period Start=2025-01-01,End=2025-02-01 --granularity MONTHLY --metrics BlendedCost --group-by Type=DIMENSION,Key=SERVICE --profile devops-readonly` | - |
| 按标签分组 | `aws ce get-cost-and-usage` | `--time-period Start=2025-01-01,End=2025-02-01 --granularity MONTHLY --metrics BlendedCost --group-by Type=TAG,Key=Environment --profile devops-readonly` | - |
| 使用预测 | `aws ce get-cost-forecast` | `--time-period Start=2025-02-01,End=2025-03-01 --granularity MONTHLY --metric BLENDED_COST --profile devops-readonly` | - |

---

### 29. MSK (托管 Kafka 服务)

核心资源: 集群(Cluster)、Broker节点、配置(Configuration)
服务代码: `kafka`

> **注意**: MSK 全称 Amazon Managed Streaming for Apache Kafka，AWS CLI 命令使用 `kafka` 服务代码

| 用户意图 / 查询关键词 | AWS CLI 命令 | 主要参数示例 | 说明 |
|---|---|---|---|
| 集群列表 | `aws kafka list-clusters` | `--region ap-southeast-1 --profile devops-readonly` | 返回所有 MSK 集群 |
| 集群列表(V2) | `aws kafka list-clusters-v2` | `--region ap-southeast-1 --profile devops-readonly` | 支持 Provisioned 和 Serverless |
| 集群详情 | `aws kafka describe-cluster` | `--cluster-arn arn:aws:kafka:... --region ap-southeast-1 --profile devops-readonly` | - |
| 集群详情(V2) | `aws kafka describe-cluster-v2` | `--cluster-arn arn:aws:kafka:... --region ap-southeast-1 --profile devops-readonly` | 推荐使用 |
| 集群操作列表 | `aws kafka list-cluster-operations` | `--cluster-arn arn:aws:kafka:... --region ap-southeast-1 --profile devops-readonly` | 查看历史操作 |
| Broker节点列表 | `aws kafka list-nodes` | `--cluster-arn arn:aws:kafka:... --region ap-southeast-1 --profile devops-readonly` | - |
| 集群配置列表 | `aws kafka list-configurations` | `--region ap-southeast-1 --profile devops-readonly` | - |
| 集群配置详情 | `aws kafka describe-configuration` | `--arn arn:aws:kafka:... --region ap-southeast-1 --profile devops-readonly` | - |
| 配置版本详情 | `aws kafka describe-configuration-revision` | `--arn arn:aws:kafka:... --revision 1 --region ap-southeast-1 --profile devops-readonly` | 查看配置内容 |
| Bootstrap Brokers | `aws kafka get-bootstrap-brokers` | `--cluster-arn arn:aws:kafka:... --region ap-southeast-1 --profile devops-readonly` | 获取连接地址 |
| 兼容Kafka版本 | `aws kafka list-kafka-versions` | `--region ap-southeast-1 --profile devops-readonly` | - |
| Serverless集群列表 | `aws kafka list-clusters-v2` | `--cluster-type SERVERLESS --region ap-southeast-1 --profile devops-readonly` | 仅 Serverless |
| 集群策略 | `aws kafka get-cluster-policy` | `--cluster-arn arn:aws:kafka:... --region ap-southeast-1 --profile devops-readonly` | 基于资源的策略 |
| VPC连接列表 | `aws kafka list-vpc-connections` | `--region ap-southeast-1 --profile devops-readonly` | - |
| 复制器列表 | `aws kafka list-replicators` | `--region ap-southeast-1 --profile devops-readonly` | 跨集群复制 |

**常用查询示例**:
```bash
# 列出所有 MSK 集群及状态
aws kafka list-clusters-v2 --profile devops-readonly --region ap-southeast-1 \
  | jq '.ClusterInfoList[] | {
      ClusterName,
      ClusterArn,
      State,
      ClusterType,
      CreationTime
    }'

# 获取集群 Broker 连接地址
CLUSTER_ARN=$(aws kafka list-clusters-v2 --profile devops-readonly --region ap-southeast-1 \
  | jq -r '.ClusterInfoList[0].ClusterArn')
aws kafka get-bootstrap-brokers --cluster-arn $CLUSTER_ARN \
  --profile devops-readonly --region ap-southeast-1

# 查看 Broker 节点状态
aws kafka list-nodes --cluster-arn $CLUSTER_ARN \
  --profile devops-readonly --region ap-southeast-1 \
  | jq '.NodeInfoList[] | {NodeARN, BrokerNodeInfo: .BrokerNodeInfo | {BrokerId, ClientSubnet, ClientVpcIpAddress}}'
```

---

### 30. IAM Identity Center (单点登录)

核心资源: 实例(Instance)、权限集(PermissionSet)、账号分配(AccountAssignment)、用户(User)、组(Group)
服务代码: `sso-admin`（管理操作）/ `identitystore`（用户目录）

> **⚠️ 重要**: 示例账号的 IAM Identity Center 实例部署在 **`eu-north-1`** 区域
> - Instance ARN: `arn:aws:sso:::instance/ssoins-0123456789abcdef0`
> - Identity Store ID: `d-0123456789`
> - 所有 `sso-admin` 和 `identitystore` 命令必须使用 `--region eu-north-1`

#### sso-admin - 管理侧（权限集、账号分配）

| 用户意图 / 查询关键词 | AWS CLI 命令 | 主要参数示例 | 说明 |
|---|---|---|---|
| Identity Center 实例列表 | `aws sso-admin list-instances` | `--region eu-north-1 --profile devops-readonly` | 获取 InstanceArn 和 IdentityStoreId |
| 权限集列表 | `aws sso-admin list-permission-sets` | `--instance-arn arn:aws:sso:::instance/ssoins-0123456789abcdef0 --region eu-north-1 --profile devops-readonly` | 返回 ARN 列表 |
| 权限集详情 | `aws sso-admin describe-permission-set` | `--instance-arn arn:aws:sso:::instance/ssoins-0123456789abcdef0 --permission-set-arn arn:aws:sso:::permissionSet/... --region eu-north-1 --profile devops-readonly` | 含名称、描述、会话时长 |
| 权限集附加的托管策略 | `aws sso-admin list-managed-policies-in-permission-set` | `--instance-arn ... --permission-set-arn ... --region eu-north-1 --profile devops-readonly` | AWS 托管策略 |
| 权限集附加的内联策略 | `aws sso-admin get-inline-policy-for-permission-set` | `--instance-arn ... --permission-set-arn ... --region eu-north-1 --profile devops-readonly` | 自定义内联策略 |
| 账号分配列表（按权限集） | `aws sso-admin list-account-assignments` | `--instance-arn ... --account-id 123456789012 --permission-set-arn ... --region eu-north-1 --profile devops-readonly` | 查看哪些用户/组被授权 |
| 权限集适用的账号列表 | `aws sso-admin list-accounts-for-provisioned-permission-set` | `--instance-arn ... --permission-set-arn ... --region eu-north-1 --profile devops-readonly` | 该权限集被分配到哪些账号 |
| 账号已分配的权限集列表 | `aws sso-admin list-permission-sets-provisioned-to-account` | `--instance-arn ... --account-id 123456789012 --region eu-north-1 --profile devops-readonly` | 某账号被分配了哪些权限集 |

#### identitystore - 用户目录侧（用户、组）

| 用户意图 / 查询关键词 | AWS CLI 命令 | 主要参数示例 | 说明 |
|---|---|---|---|
| 用户列表 | `aws identitystore list-users` | `--identity-store-id d-0123456789 --region eu-north-1 --profile devops-readonly` | - |
| 用户详情 | `aws identitystore describe-user` | `--identity-store-id d-0123456789 --user-id <user-id> --region eu-north-1 --profile devops-readonly` | - |
| 按用户名查找用户 | `aws identitystore get-user-id` | `--identity-store-id d-0123456789 --alternate-identifier UniqueAttribute={AttributePath=userName,AttributeValue=alice} --region eu-north-1 --profile devops-readonly` | - |
| 组列表 | `aws identitystore list-groups` | `--identity-store-id d-0123456789 --region eu-north-1 --profile devops-readonly` | - |
| 组详情 | `aws identitystore describe-group` | `--identity-store-id d-0123456789 --group-id <group-id> --region eu-north-1 --profile devops-readonly` | - |
| 组成员列表 | `aws identitystore list-group-memberships` | `--identity-store-id d-0123456789 --group-id <group-id> --region eu-north-1 --profile devops-readonly` | - |
| 用户所属的组 | `aws identitystore list-group-memberships-for-member` | `--identity-store-id d-0123456789 --member-id UserId=<user-id> --region eu-north-1 --profile devops-readonly` | - |

**常用查询示例**:
```bash
# 固定变量（示例账号）
INSTANCE_ARN="arn:aws:sso:::instance/ssoins-0123456789abcdef0"
IDENTITY_STORE_ID="d-0123456789"
REGION="eu-north-1"

# 列出所有权限集名称
aws sso-admin list-permission-sets \
  --instance-arn $INSTANCE_ARN \
  --region $REGION --profile devops-readonly \
  | jq -r '.PermissionSets[]' \
  | while read arn; do
      aws sso-admin describe-permission-set \
        --instance-arn $INSTANCE_ARN \
        --permission-set-arn "$arn" \
        --region $REGION --profile devops-readonly \
        | jq -r '.PermissionSet | {Name, PermissionSetArn, SessionDuration}'
    done

# 列出所有 Identity Center 用户
aws identitystore list-users \
  --identity-store-id $IDENTITY_STORE_ID \
  --region $REGION --profile devops-readonly \
  | jq '.Users[] | {UserId, UserName, DisplayName, Emails: (.Emails // [] | map(.Value))}'

# 查看某账号下所有权限分配（用户/组 -> 权限集）
aws sso-admin list-permission-sets-provisioned-to-account \
  --instance-arn $INSTANCE_ARN \
  --account-id 123456789012 \
  --region $REGION --profile devops-readonly \
  | jq -r '.PermissionSets[]'
```

---

### 31. Resource Explorer 2 (资源搜索)

核心资源: 索引(Index)、视图(View)
服务代码: `resource-explorer-2`

> **示例账号配置**:
> - AGGREGATOR 索引区域: `ap-southeast-1`（汇聚全账号所有区域）
> - View ARN: `arn:aws:resource-explorer-2:ap-southeast-1:123456789012:view/all-resources/00000000-0000-0000-0000-000000000000`
> - 查询时使用 `--region ap-southeast-1` 即可获取全账号资源

| 用户意图 / 查询关键词 | AWS CLI 命令 | 主要参数示例 | 说明 |
|---|---|---|---|
| 索引列表 | `aws resource-explorer-2 list-indexes` | `--region ap-southeast-1 --profile devops-readonly` | 查看所有区域的索引 |
| 视图列表 | `aws resource-explorer-2 list-views` | `--region ap-southeast-1 --profile devops-readonly` | 返回可用视图 ARN |
| 搜索所有资源 | `aws resource-explorer-2 search` | `--query-string "" --view-arn <view-arn> --region ap-southeast-1 --profile devops-readonly` | 返回全账号资源 |
| 按资源类型搜索 | `aws resource-explorer-2 search` | `--query-string "resourcetype:ec2:instance" --view-arn <view-arn> --region ap-southeast-1 --profile devops-readonly` | 精确类型过滤 |
| 按区域搜索 | `aws resource-explorer-2 search` | `--query-string "region:ap-southeast-1" --view-arn <view-arn> --region ap-southeast-1 --profile devops-readonly` | 过滤特定区域 |
| 按标签搜索 | `aws resource-explorer-2 search` | `--query-string "tag:Environment=prod" --view-arn <view-arn> --region ap-southeast-1 --profile devops-readonly` | 标签键值过滤 |
| 按服务搜索 | `aws resource-explorer-2 search` | `--query-string "service:rds" --view-arn <view-arn> --region ap-southeast-1 --profile devops-readonly` | 服务级过滤 |
| 获取支持的资源类型 | `aws resource-explorer-2 list-supported-resource-types` | `--region ap-southeast-1 --profile devops-readonly` | 查看 RE2 支持哪些资源类型 |
| 视图详情 | `aws resource-explorer-2 get-view` | `--view-arn <view-arn> --region ap-southeast-1 --profile devops-readonly` | 查看视图过滤条件 |

**常用查询示例**:
```bash
VIEW_ARN="arn:aws:resource-explorer-2:ap-southeast-1:123456789012:view/all-resources/00000000-0000-0000-0000-000000000000"

# 按资源类型统计全账号资源数量
aws resource-explorer-2 search \
  --query-string "" \
  --view-arn "$VIEW_ARN" \
  --region ap-southeast-1 --profile devops-readonly \
  | jq '.Resources | group_by(.ResourceType) | map({ResourceType: .[0].ResourceType, Count: length}) | sort_by(-.Count)'

# 查找特定名称的资源（跨服务）
aws resource-explorer-2 search \
  --query-string "my-app" \
  --view-arn "$VIEW_ARN" \
  --region ap-southeast-1 --profile devops-readonly \
  | jq '.Resources[] | {ResourceType, Arn, Region}'

# 查找所有 ap-southeast-1 区域的 EC2 实例
aws resource-explorer-2 search \
  --query-string "resourcetype:ec2:instance region:ap-southeast-1" \
  --view-arn "$VIEW_ARN" \
  --region ap-southeast-1 --profile devops-readonly \
  | jq '.Resources[] | {Arn, Region}'
```

---

### 32. MemoryDB (Redis 兼容内存数据库)

核心资源: 集群(Cluster)、子网组(SubnetGroup)、参数组(ParameterGroup)、用户(User)、ACL
服务代码: `memorydb`

> **注意**: MemoryDB 与 ElastiCache 是不同的服务，MemoryDB 提供持久化 Redis，数据不会丢失

| 用户意图 / 查询关键词 | AWS CLI 命令 | 主要参数示例 | 说明 |
|---|---|---|---|
| 集群列表 | `aws memorydb describe-clusters` | `--region ap-southeast-1 --profile devops-readonly` | - |
| 集群详情 | `aws memorydb describe-clusters` | `--cluster-name my-cluster --region ap-southeast-1 --profile devops-readonly` | - |
| 子网组列表 | `aws memorydb describe-subnet-groups` | `--region ap-southeast-1 --profile devops-readonly` | - |
| 参数组列表 | `aws memorydb describe-parameter-groups` | `--region ap-southeast-1 --profile devops-readonly` | - |
| 参数组详情 | `aws memorydb describe-parameters` | `--parameter-group-name my-pg --region ap-southeast-1 --profile devops-readonly` | - |
| 用户列表 | `aws memorydb describe-users` | `--region ap-southeast-1 --profile devops-readonly` | - |
| ACL 列表 | `aws memorydb describe-acls` | `--region ap-southeast-1 --profile devops-readonly` | - |
| 快照列表 | `aws memorydb describe-snapshots` | `--cluster-name my-cluster --region ap-southeast-1 --profile devops-readonly` | - |
| 引擎版本列表 | `aws memorydb describe-engine-versions` | `--region ap-southeast-1 --profile devops-readonly` | - |
| 保留节点列表 | `aws memorydb describe-reserved-nodes` | `--region ap-southeast-1 --profile devops-readonly` | - |
| 服务更新列表 | `aws memorydb describe-service-updates` | `--region ap-southeast-1 --profile devops-readonly` | - |

---

### 33. Athena (交互式查询服务)

核心资源: 工作组(Workgroup)、数据目录(DataCatalog)、查询(QueryExecution)
服务代码: `athena`

> **注意**: Athena 对 S3 中的数据执行 SQL 查询，无需移动数据，按扫描量计费

| 用户意图 / 查询关键词 | AWS CLI 命令 | 主要参数示例 | 说明 |
|---|---|---|---|
| 工作组列表 | `aws athena list-work-groups` | `--region ap-southeast-1 --profile devops-readonly` | - |
| 工作组详情 | `aws athena get-work-group` | `--work-group my-wg --region ap-southeast-1 --profile devops-readonly` | 含配置和统计 |
| 数据目录列表 | `aws athena list-data-catalogs` | `--region ap-southeast-1 --profile devops-readonly` | - |
| 数据目录详情 | `aws athena get-data-catalog` | `--name my-catalog --region ap-southeast-1 --profile devops-readonly` | - |
| 数据库列表 | `aws athena list-databases` | `--catalog-name AwsDataCatalog --region ap-southeast-1 --profile devops-readonly` | - |
| 表列表 | `aws athena list-table-metadata` | `--catalog-name AwsDataCatalog --database-name my-db --region ap-southeast-1 --profile devops-readonly` | - |
| 查询执行历史 | `aws athena list-query-executions` | `--work-group my-wg --region ap-southeast-1 --profile devops-readonly` | 返回查询 ID 列表 |
| 查询详情 | `aws athena get-query-execution` | `--query-execution-id <id> --region ap-southeast-1 --profile devops-readonly` | 含状态、耗时、扫描量 |
| 命名查询列表 | `aws athena list-named-queries` | `--work-group my-wg --region ap-southeast-1 --profile devops-readonly` | 保存的 SQL 查询 |

---

### 34. App Runner (容器应用托管)

核心资源: 服务(Service)、自动扩缩容配置(AutoScalingConfiguration)、VPC连接(VpcConnector)
服务代码: `apprunner`

| 用户意图 / 查询关键词 | AWS CLI 命令 | 主要参数示例 | 说明 |
|---|---|---|---|
| 服务列表 | `aws apprunner list-services` | `--region ap-southeast-1 --profile devops-readonly` | - |
| 服务详情 | `aws apprunner describe-service` | `--service-arn arn:aws:apprunner:... --region ap-southeast-1 --profile devops-readonly` | 含状态和配置 |
| 自动扩缩容配置列表 | `aws apprunner list-auto-scaling-configurations` | `--region ap-southeast-1 --profile devops-readonly` | - |
| 自动扩缩容配置详情 | `aws apprunner describe-auto-scaling-configuration` | `--auto-scaling-configuration-arn arn:aws:apprunner:... --region ap-southeast-1 --profile devops-readonly` | - |
| VPC 连接列表 | `aws apprunner list-vpc-connectors` | `--region ap-southeast-1 --profile devops-readonly` | - |
| 自定义域名列表 | `aws apprunner list-custom-domains` | `--service-arn arn:aws:apprunner:... --region ap-southeast-1 --profile devops-readonly` | - |
| 操作历史 | `aws apprunner list-operations` | `--service-arn arn:aws:apprunner:... --region ap-southeast-1 --profile devops-readonly` | 部署、更新历史 |
| 可观测性配置列表 | `aws apprunner list-observability-configurations` | `--region ap-southeast-1 --profile devops-readonly` | - |

---

### 35. AWS Backup (统一备份管理)

核心资源: 备份库(BackupVault)、备份计划(BackupPlan)、恢复点(RecoveryPoint)
服务代码: `backup`

| 用户意图 / 查询关键词 | AWS CLI 命令 | 主要参数示例 | 说明 |
|---|---|---|---|
| 备份库列表 | `aws backup list-backup-vaults` | `--region ap-southeast-1 --profile devops-readonly` | - |
| 备份库详情 | `aws backup describe-backup-vault` | `--backup-vault-name my-vault --region ap-southeast-1 --profile devops-readonly` | - |
| 备份计划列表 | `aws backup list-backup-plans` | `--region ap-southeast-1 --profile devops-readonly` | - |
| 备份计划详情 | `aws backup get-backup-plan` | `--backup-plan-id <id> --region ap-southeast-1 --profile devops-readonly` | 含规则和调度 |
| 备份计划选择器 | `aws backup list-backup-selections` | `--backup-plan-id <id> --region ap-southeast-1 --profile devops-readonly` | 哪些资源被纳入备份 |
| 恢复点列表 | `aws backup list-recovery-points-by-backup-vault` | `--backup-vault-name my-vault --region ap-southeast-1 --profile devops-readonly` | 备份快照列表 |
| 按资源查恢复点 | `aws backup list-recovery-points-by-resource` | `--resource-arn arn:aws:rds:... --region ap-southeast-1 --profile devops-readonly` | 某资源的所有备份点 |
| 备份任务历史 | `aws backup list-backup-jobs` | `--region ap-southeast-1 --profile devops-readonly` | - |
| 恢复任务历史 | `aws backup list-restore-jobs` | `--region ap-southeast-1 --profile devops-readonly` | - |
| 受保护资源列表 | `aws backup list-protected-resources` | `--region ap-southeast-1 --profile devops-readonly` | 哪些资源已被 Backup 保护 |

---

### 36. API Gateway (REST/HTTP API)

核心资源: REST API(RestApi)、阶段(Stage)、资源(Resource)、方法(Method)
服务代码: `apigateway`

| 用户意图 / 查询关键词 | AWS CLI 命令 | 主要参数示例 | 说明 |
|---|---|---|---|
| REST API 列表 | `aws apigateway get-rest-apis` | `--region ap-southeast-1 --profile devops-readonly` | - |
| REST API 详情 | `aws apigateway get-rest-api` | `--rest-api-id <api-id> --region ap-southeast-1 --profile devops-readonly` | - |
| 阶段列表 | `aws apigateway get-stages` | `--rest-api-id <api-id> --region ap-southeast-1 --profile devops-readonly` | prod/staging/dev 等 |
| 资源列表 | `aws apigateway get-resources` | `--rest-api-id <api-id> --region ap-southeast-1 --profile devops-readonly` | API 路径资源树 |
| 使用计划列表 | `aws apigateway get-usage-plans` | `--region ap-southeast-1 --profile devops-readonly` | 流控和配额 |
| API 密钥列表 | `aws apigateway get-api-keys` | `--region ap-southeast-1 --profile devops-readonly` | - |
| 域名列表 | `aws apigateway get-domain-names` | `--region ap-southeast-1 --profile devops-readonly` | 自定义域名 |
| 授权方列表 | `aws apigateway get-authorizers` | `--rest-api-id <api-id> --region ap-southeast-1 --profile devops-readonly` | Lambda/Cognito 授权 |
| HTTP API 列表(v2) | `aws apigatewayv2 get-apis` | `--region ap-southeast-1 --profile devops-readonly` | HTTP API 和 WebSocket |

---

### 37. CloudFormation (基础设施即代码)

核心资源: 栈(Stack)、栈集(StackSet)、变更集(ChangeSet)
服务代码: `cloudformation`

| 用户意图 / 查询关键词 | AWS CLI 命令 | 主要参数示例 | 说明 |
|---|---|---|---|
| 栈列表 | `aws cloudformation list-stacks` | `--stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE --region ap-southeast-1 --profile devops-readonly` | 建议过滤状态 |
| 栈详情 | `aws cloudformation describe-stacks` | `--stack-name my-stack --region ap-southeast-1 --profile devops-readonly` | 含输出和参数 |
| 栈资源列表 | `aws cloudformation list-stack-resources` | `--stack-name my-stack --region ap-southeast-1 --profile devops-readonly` | 栈管理的所有资源 |
| 栈事件 | `aws cloudformation describe-stack-events` | `--stack-name my-stack --region ap-southeast-1 --profile devops-readonly` | 部署历史 |
| 变更集列表 | `aws cloudformation list-change-sets` | `--stack-name my-stack --region ap-southeast-1 --profile devops-readonly` | - |
| 栈集列表 | `aws cloudformation list-stack-sets` | `--region ap-southeast-1 --profile devops-readonly` | 多账号/多区域部署 |
| 漂移检测状态 | `aws cloudformation describe-stack-drift-detection-status` | `--stack-drift-detection-id <id> --region ap-southeast-1 --profile devops-readonly` | 配置漂移检查 |

---

### 38. SSM (Systems Manager)

核心资源: 托管实例(ManagedInstance)、参数(Parameter)、文档(Document)、会话(Session)
服务代码: `ssm`

| 用户意图 / 查询关键词 | AWS CLI 命令 | 主要参数示例 | 说明 |
|---|---|---|---|
| 托管实例列表 | `aws ssm describe-instance-information` | `--region ap-southeast-1 --profile devops-readonly` | 已注册到 SSM 的实例 |
| 实例合规性 | `aws ssm list-compliance-summaries` | `--region ap-southeast-1 --profile devops-readonly` | 补丁合规状态 |
| 参数列表 | `aws ssm describe-parameters` | `--region ap-southeast-1 --profile devops-readonly` | Parameter Store |
| 参数值 | `aws ssm get-parameter` | `--name /my/param --region ap-southeast-1 --profile devops-readonly` | 普通参数值 |
| 文档列表 | `aws ssm list-documents` | `--filters Key=Owner,Values=Self --region ap-southeast-1 --profile devops-readonly` | 自定义 SSM 文档 |
| 补丁基准列表 | `aws ssm describe-patch-baselines` | `--region ap-southeast-1 --profile devops-readonly` | - |
| 维护窗口列表 | `aws ssm describe-maintenance-windows` | `--region ap-southeast-1 --profile devops-readonly` | - |
| 运行命令历史 | `aws ssm list-command-invocations` | `--region ap-southeast-1 --profile devops-readonly` | 命令执行记录 |

---

### 39. EventBridge (事件总线)

核心资源: 事件总线(EventBus)、规则(Rule)、目标(Target)
服务代码: `events`

| 用户意图 / 查询关键词 | AWS CLI 命令 | 主要参数示例 | 说明 |
|---|---|---|---|
| 事件总线列表 | `aws events list-event-buses` | `--region ap-southeast-1 --profile devops-readonly` | 含默认总线 |
| 事件总线详情 | `aws events describe-event-bus` | `--name my-bus --region ap-southeast-1 --profile devops-readonly` | - |
| 规则列表 | `aws events list-rules` | `--event-bus-name default --region ap-southeast-1 --profile devops-readonly` | - |
| 规则详情 | `aws events describe-rule` | `--name my-rule --region ap-southeast-1 --profile devops-readonly` | 含调度表达式 |
| 规则目标列表 | `aws events list-targets-by-rule` | `--rule my-rule --region ap-southeast-1 --profile devops-readonly` | 触发哪些服务 |
| 事件源列表 | `aws events list-event-sources` | `--region ap-southeast-1 --profile devops-readonly` | SaaS 集成源 |
| 归档列表 | `aws events list-archives` | `--region ap-southeast-1 --profile devops-readonly` | 事件归档 |
| 连接列表 | `aws events list-connections` | `--region ap-southeast-1 --profile devops-readonly` | API 目标连接 |

---

### 40. Glue (数据集成/ETL)

核心资源: 数据库(Database)、表(Table)、爬虫(Crawler)、作业(Job)
服务代码: `glue`

| 用户意图 / 查询关键词 | AWS CLI 命令 | 主要参数示例 | 说明 |
|---|---|---|---|
| 数据库列表 | `aws glue get-databases` | `--region ap-southeast-1 --profile devops-readonly` | Glue Data Catalog |
| 数据库详情 | `aws glue get-database` | `--name my-db --region ap-southeast-1 --profile devops-readonly` | - |
| 表列表 | `aws glue get-tables` | `--database-name my-db --region ap-southeast-1 --profile devops-readonly` | - |
| 爬虫列表 | `aws glue list-crawlers` | `--region ap-southeast-1 --profile devops-readonly` | - |
| 爬虫详情 | `aws glue get-crawler` | `--name my-crawler --region ap-southeast-1 --profile devops-readonly` | - |
| 作业列表 | `aws glue list-jobs` | `--region ap-southeast-1 --profile devops-readonly` | - |
| 作业运行历史 | `aws glue get-job-runs` | `--job-name my-job --region ap-southeast-1 --profile devops-readonly` | - |
| 连接列表 | `aws glue get-connections` | `--region ap-southeast-1 --profile devops-readonly` | 数据源连接配置 |

---

## 📚 附录：最佳实践与使用说明

### 1️⃣ AWS CLI 常用全局参数

| 参数 | 说明 | 示例 |
|------|------|------|
| `--profile devops-readonly` | **必须**: 指定 AWS profile | 所有命令必须包含 |
| `--region <region>` | 指定 AWS 区域 | `--region ap-southeast-1` |
| `--output json` | 输出格式 (默认 json) | `--output json` |
| `--query '<JMESPath>'` | AWS 内置 JMESPath 过滤 | `--query 'Reservations[].Instances[].InstanceId'` |
| `--no-paginate` | 禁用自动分页，一次返回全部 | 谨慎使用，数据量可能很大 |
| `--max-items <n>` | 限制返回数量 | `--max-items 50` |

### 2️⃣ 常用 AWS 区域

| 区域 ID | 地理位置 |
|---------|---------|
| ap-southeast-1 | 亚太地区（新加坡）**【默认】** |
| us-east-1 | 美国东部（弗吉尼亚北部） |
| us-east-2 | 美国东部（俄亥俄） |
| us-west-1 | 美国西部（加利福尼亚北部） |
| us-west-2 | 美国西部（俄勒冈） |
| ap-east-1 | 亚太地区（香港） |
| ap-southeast-1 | 亚太地区（新加坡） |
| ap-northeast-1 | 亚太地区（东京） |
| ap-northeast-2 | 亚太地区（首尔） |
| eu-west-1 | 欧洲（爱尔兰） |
| eu-central-1 | 欧洲（法兰克福） |
| cn-north-1 | 中国（北京）- 需要独立账号 |
| cn-northwest-1 | 中国（宁夏）- 需要独立账号 |

### 3️⃣ JMESPath vs jq 使用建议

- **简单字段提取**: 优先使用 `--query` (AWS 内置 JMESPath，无需额外工具)
- **复杂数据转换**: 使用 `jq`（功能更强大）
- **管道处理**: 多命令组合时使用 `jq`

```bash
# 使用 --query (JMESPath) - 简单场景
aws ec2 describe-instances --profile devops-readonly --region ap-southeast-1 \
  --query 'Reservations[].Instances[].{ID:InstanceId,State:State.Name}'

# 使用 jq - 复杂处理（如提取标签）
aws ec2 describe-instances --profile devops-readonly --region ap-southeast-1 \
  | jq '.Reservations[].Instances[] | {
      InstanceId,
      Name: (.Tags // [] | map(select(.Key == "Name")) | first | .Value // "N/A"),
      State: .State.Name
    }'
```

### 4️⃣ 多区域查询模式

```bash
# 查询多个区域的 EC2 实例
for region in ap-southeast-1 us-west-2 ap-southeast-1; do
  echo "=== Region: $region ==="
  aws ec2 describe-instances \
    --profile devops-readonly \
    --region $region \
    --query 'Reservations[].Instances[].{ID:InstanceId,State:State.Name,Type:InstanceType}' \
    --output table
done
```

### 5️⃣ 错误处理最佳实践

```bash
# 带错误处理的查询
result=$(aws ec2 describe-instances \
  --instance-ids i-0123456789abcdef0 \
  --profile devops-readonly \
  --region ap-southeast-1 2>&1)

if echo "$result" | grep -q "InvalidInstanceID.NotFound"; then
  echo "实例不存在，请确认实例ID和区域是否正确"
elif echo "$result" | grep -q "AccessDenied"; then
  echo "权限不足，devops-readonly profile 没有此资源的查看权限"
else
  echo "$result" | jq '.'
fi
```

### 6️⃣ 版本更新记录

| 版本 | 日期 | 更新内容 |
|------|------|----------|
| v1.1 | 2026-03-31 | 新增 MSK (Managed Kafka) 服务，补充 29 个核心服务 |
| v1.0 | 2026-03-31 | 初始版本，覆盖 AWS 28 个核心服务 |

---

> ⚠️ **重要提示**: AWS API 会持续更新，具体参数和可用性请以 https://docs.aws.amazon.com/cli/latest/reference/ 为准。
