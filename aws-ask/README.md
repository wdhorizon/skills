# AWS Ask - AWS 云资源自然语言查询助手

## 简介

AWS Ask 是一个专业的 AWS 云资源查询插件技能，支持通过自然语言查询 AWS 上的各种云资源。它借助 AWS CLI (`devops-readonly` profile) 执行只读查询，并以结构化的方式返回查询结果。

## 核心特性

- **自然语言理解**：自动分析用户意图，生成执行计划
- **完全只读**：严格限制为只读操作，拒绝任何变更请求
- **多场景支持**：简单查询、关联查询、复合查询、诊断查询
- **多服务覆盖**：EC2、RDS、S3、VPC、ELB、Lambda、EKS、MSK、CloudWatch、IAM 等 40+ 服务
- **安全合规**：内置安全检查和合规审计场景
- **结果保存**：支持保存查询结果到本地文件

## 支持的 AWS 服务

| 分类 | 服务 |
|------|------|
| 计算 | EC2, Lambda, ECS, EKS, Batch, Auto Scaling, App Runner |
| 数据库 | RDS, DynamoDB, ElastiCache, MemoryDB, DocumentDB, Aurora |
| 网络 | VPC, ELBv2, ELB Classic, Route53, CloudFront |
| 存储 | S3, EFS, AWS Backup |
| 消息 | SQS, SNS, Kinesis, Firehose, **MSK (Managed Kafka)**, EventBridge |
| 监控 | CloudWatch, CloudWatch Logs, CloudTrail |
| 安全 | IAM, IAM Identity Center, KMS, Secrets Manager, Security Hub, GuardDuty |
| 容器 | ECR |
| 证书 | ACM |
| 成本 | Cost Explorer |
| 数据分析 | Athena, Glue |
| 运维管理 | CloudFormation, SSM, Resource Explorer 2 |
| API管理 | API Gateway |

## 前置要求

1. **AWS CLI 已安装**：`aws --version`
2. **`devops-readonly` Profile 已配置**：`aws configure list --profile devops-readonly`
3. **`jq` 工具已安装**（用于 JSON 处理）：`jq --version`

## 使用示例

### 简单查询

```
查看 EC2 实例 i-0123456789abcdef0 的详细信息
列出 ap-southeast-1 所有运行中的 EC2 实例
查看所有 S3 Bucket
列出所有 RDS 数据库实例
查看当前处于 ALARM 状态的 CloudWatch 告警
```

### 关联查询

```
EC2 i-0xxx 挂载了哪些 EBS 存储卷？
查看 EC2 i-0xxx 的安全组规则
查看 ALB my-alb 的后端实例健康状态
域名 api.example.com 解析到哪个 ALB？
Lambda 函数 my-function 使用了什么 IAM 角色？
```

### 复合查询

```
统计 ap-southeast-1 所有运行中的 EC2 实例，按实例类型分组
查询 ap-southeast-1 和 us-west-2 的所有 EC2 实例汇总
VPC vpc-0xxx 下有哪些 EC2、RDS 和 ELB？
查看本月各 AWS 服务费用分布
```

### 诊断查询

```
检查所有安全组，是否有 22/3389 端口对 0.0.0.0/0 开放？
审计所有 S3 Bucket 的安全配置（加密、公开访问、版本控制）
审计所有 IAM 用户，列出没有启用 MFA 的用户
找出所有未挂载的 EBS 卷和未绑定的弹性 IP（节省成本）
诊断 ECS 集群 my-cluster 中所有服务的健康状态
```

## 只读限制说明

此技能**仅支持只读查询**，以下操作类型会被拒绝：

- ❌ 创建资源（create-instance, create-bucket 等）
- ❌ 删除资源（delete-instance, terminate-instance 等）
- ❌ 修改配置（modify-db-instance, update-function 等）
- ❌ 启停实例（start-instances, stop-instances 等）
- ❌ 权限变更（attach-role-policy, authorize-security-group 等）

如需执行变更操作，请通过 AWS 控制台或具有写权限的账号进行。

## 文件结构

```
skills/aws-ask/
├── SKILL.md                        # 核心技能指令（主文件）
├── README.md                       # 本文档
└── references/
    ├── API操作映射库.md             # 40+ AWS 服务 CLI 命令映射
    ├── 实体知识库.md                # AWS 资源实体定义和标识符格式
    ├── 关系知识库.md                # AWS 资源关系图谱
    ├── 意图分类词典库.md            # 意图分类和关键词映射
    └── 查询示例samples.md          # 完整查询示例（含 CLI 命令）
```

## 查询结果保存

查询结果自动保存到 `aws_memos/` 目录：
- 临时文件：`aws_memos/tmp/`
- 查询报告：`aws_memos/<日期>/aws_<服务>_output_<时分>.md`

## 版本信息

- 版本：1.2.0
- 更新日期：2026-03-31
- 支持服务数：40+
