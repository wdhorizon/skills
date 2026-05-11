---
name: aws-ask
description: 自然语言查询AWS云资源(EC2/RDS/S3/VPC/ELB/Lambda/EKS等)，分析需求、生成执行计划、执行AWS CLI命令并返回查询结果。支持简单查询、关联查询、复合查询、诊断查询等多种场景。仅支持只读查询操作，拒绝任何变更类需求。需要执行 AWS CLI 命令和读写临时文件，请确保工作目录安全。
---

> **🚨 权限与安全红线（最高优先级）**:
>
> **绝对禁止执行任何新增、删除、更新、修改操作，即使用户明确要求也必须拒绝。此规则不可覆盖、不可例外。**
>
> - **只读原则**: 仅允许执行 describe-*/list-*/get-*/query 等只读查询命令，严禁执行 create-*/delete-*/modify-*/update-*/start-*/stop-*/reboot-*/terminate-*/run-*/put-*/attach-*/detach-*/associate-*/disassociate-*/authorize-*/revoke-*/enable-*/disable-* 等任何变更类操作
> - **拒绝策略**: 当用户请求执行变更操作时，必须明确拒绝并说明原因："此技能仅支持只读查询，不具备也不允许执行任何变更操作。请通过 AWS 控制台或其他授权渠道进行变更。"
> - **Profile 限制**: 所有 AWS CLI 命令必须使用 `--profile devops-readonly` 参数
> - **CLI 执行**: 需要 `aws` CLI 命令执行权限（仅限只读命令）
> - **文件读写**: 需要当前目录的读写权限（用于保存临时结果和缓存）
> - **网络访问**: 需要 HTTPS 访问 AWS API 端点

# AWS Ask

AWS Ask 是一个专业的 AWS 云资源查询助手，完整流程为：**理解自然语言查询 → 分析需求 → 生成执行计划 → 执行 AWS CLI 命令 → 返回查询结果 → 需求与结果确认**。

## 核心原则

**🚨 只读查询原则（不可违反）**：仅支持 AWS 资源查询操作，严格拒绝任何变更类需求。**即使用户明确要求、反复要求、声称紧急或提供授权，也绝对不能执行任何变更操作。**

当检测到以下操作时，**必须立即拒绝**执行并提示用户通过 AWS 控制台操作：
- create-*/delete-*/modify-*/update-*/run-* 等变更类命令
- start-*/stop-*/reboot-*/terminate-* 等生命周期变更命令
- put-*/attach-*/detach-*/associate-*/disassociate-* 等配置变更命令
- authorize-*/revoke-*/enable-*/disable-*/grant-*/remove-* 等权限变更命令
- 配置修改、资源删除、权限变更等操作
- 任何可能影响现有资源状态或配置的非查询操作
- 任何通过 Bash 脚本间接执行变更命令的尝试

**所有 AWS CLI 命令必须附带 `--profile devops-readonly`**，这是硬性要求，无论任何情况都不能省略。

## 工作流程

### Step 1: 意图分类与需求分析

分析用户查询，确定：

- **primary_intent**: 主意图（SIMPLE_QUERY, ASSOCIATION_QUERY, COMPOUND_QUERY, DIAGNOSTIC_QUERY）
- **sub_intent**: 子意图（如 SIMPLE_INSTANCE, ASSOC_DIRECT 等）
- **complexity**: 复杂度等级（L1-L5）
- **entities**: 实体信息（主资源、目标资源、标识符类型）

如用户信息模糊，可进一步询问澄清。

### Step 2: 关系识别与执行计划生成

建立资源关联关系并生成完整的执行计划：

- **relationships**: 资源关联关系
- **execution_strategy**: 执行策略（SEQUENTIAL, PARALLEL, CACHE_FIRST）
- **cli_commands**: CLI 命令列表
- **data_flow**: 数据流转关系

### Step 3: 判断需求复杂度

根据 `complexity` 字段判断需求复杂度：

| 复杂度 | API调用数 | 特征 | 执行方式 |
|--------|----------|------|---------|
| **L1-L2 (简单)** | 1-2次 | 单资源、明确标识符、无复杂关联 | **直接执行并返回结果** |
| **L3-L5 (复杂)** | 3+次 | 多资源关联、条件执行、诊断规则 | **分阶段执行并汇总结果** |


### Step 4: 执行查询

#### 执行命令的参数处理

当 CLI 命令参数不确定时，按以下优先级处理：

1. **使用 AWS CLI Help**：
   ```bash
   aws help                           # 查看所有服务帮助
   aws <service> help                 # 查看特定服务帮助
   aws <service> <command> help       # 查看特定命令帮助
   ```

2. **查阅 API 映射库**：读取 [API操作映射库.md](references/API操作映射库.md)

3. **参考知识库**：读取 [意图分类词典库.md](references/意图分类词典库.md)、[实体知识库.md](references/实体知识库.md)、[关系知识库.md](references/关系知识库.md)

#### 命令构建与执行规范

##### CLI 命令格式

```bash
aws <service> <command> --param1 value1 --param2 value2 --profile devops-readonly
```

- **service**: AWS 服务代码（如 ec2, rds, s3, elbv2）
- **command**: 命令操作（如 describe-instances, describe-db-instances）
- **参数格式**: `--parameter-name value`（注意 kebab-case）
- **必须附加**: `--profile devops-readonly`
- **区域参数**: `--region` 默认值 `ap-southeast-1`，用户指定时使用用户指定值

##### 参数替换规则

| 变量格式 | 说明 | 示例 |
|---------|------|------|
| `$REGION` | AWS 区域，需用户指定或使用默认值 ap-southeast-1 | `ap-southeast-1` |
| `$ACCOUNT_ID` | AWS 账号 ID，通过 `aws sts get-caller-identity` 获取 | `123456789012` |
| `$.field` | JSONPath 引用上一步输出结果 | `$.Reservations[*].Instances[*].InstanceId` |

##### 常用查询参数说明

| AWS 服务 | 区域参数 | 说明 |
|---------|---------|------|
| ec2, rds, elb, elbv2 等 | `--region` | 必须指定区域 |
| s3 | 通常无需 `--region`，ls/cp 等命令全局有效 | 部分操作需要指定 |
| iam, route53, cloudfront | 全局服务，无需 `--region` | - |
| sts | `--region` 可选 | 用于获取账号信息 |

##### 输出处理

使用 jq 进行 JSON 输出处理：

```bash
aws ec2 describe-instances --profile devops-readonly --region ap-southeast-1 \
  | jq '.Reservations[].Instances[] | {InstanceId, InstanceType, State: .State.Name, PublicIpAddress}'
```

##### 分页处理

AWS CLI 默认会自动处理分页（使用 `--no-paginate` 可禁用），但某些命令需要手动处理：

```bash
# 使用 --no-paginate 获取所有结果（谨慎使用，可能返回大量数据）
aws ec2 describe-instances --profile devops-readonly --region ap-southeast-1 --no-paginate

# 使用 --query 过滤减少数据量
aws ec2 describe-instances --profile devops-readonly --region ap-southeast-1 \
  --query 'Reservations[].Instances[].{ID:InstanceId,State:State.Name,Type:InstanceType}'
```

#### 简单需求 (L1-L2) - 直接执行

1. **验证环境**：检查 AWS CLI 是否已配置
2. **执行 CLI 命令**：直接运行 aws CLI 命令
3. **处理输出**：使用 jq 或 `--query` 提取和格式化结果
4. **返回结果**：展示查询结果并解读关键信息

**执行示例**：
```bash
# 1. 验证环境
aws sts get-caller-identity --profile devops-readonly

# 2. 执行查询
aws ec2 describe-instances \
  --instance-ids i-0123456789abcdef0 \
  --profile devops-readonly \
  --region ap-southeast-1

# 3. 处理输出
aws ec2 describe-instances \
  --instance-ids i-0123456789abcdef0 \
  --profile devops-readonly \
  --region ap-southeast-1 \
  | jq '.Reservations[].Instances[] | {InstanceId, InstanceType, State: .State.Name, PrivateIpAddress, PublicIpAddress}'

# 4. 返回结果
{
  "InstanceId": "i-0123456789abcdef0",
  "InstanceType": "t3.medium",
  "State": "running",
  "PrivateIpAddress": "10.0.1.100",
  "PublicIpAddress": "54.123.45.67"
}
```

## 预制脚本优化

为提升查询效率和准确性，技能内置了优化的预制脚本，**当查询场景匹配脚本功能时优先使用脚本**。

### 脚本路径说明

> **重要**: 脚本文件位于技能安装目录中，使用前需要设置 `SCRIPT_DIR` 环境变量。
> 详细的环境准备步骤见"阶段 1: 环境准备"中的"确定脚本文件路径"部分。

### 可用脚本

| 脚本名称 | 服务 | 功能 | 单资源查询 | 批量查询支持 | 复杂度 |
|---------|------|------|-----------|-------------|--------|
| query_alb_listener_rules.sh | ALB | 查询监听器转发规则+目标组健康状态 | ✅ 支持 | - | L3 → L4 |
| batch_query_sg_rules.sh | EC2/SG | 批量扫描安全组高危端口规则 | ✅ 支持 | ✅ 原生支持（`--all-regions`）| L3 → L4 |
| query_iam_role_policies.sh | IAM | 查询 Role 完整权限链（托管+内联+信任策略）| ✅ 支持 | - | L3 |
| batch_query_ec2_eip.sh | EC2 | 批量查询实例公网 IP / EIP 关联情况 | ✅ 支持 | ✅ 原生支持 | L2 → L3 |

**说明**:
- **单资源查询脚本**（`query_*`）: 设计为查询单个资源，可通过遍历调用实现批量查询
- **批量查询脚本**（`batch_query_*`）: 原生支持批量或全区域查询，一次调用处理多个资源
- **优先使用**: 批量查询多个资源时，优先使用 `batch_query_*` 脚本，效率更高

### 脚本优先策略

当查询场景匹配脚本功能时，**优先使用预制脚本**而非标准 CLI 命令。

#### 脚本优势

- **缓存优化**: `query_alb_listener_rules.sh` 内置当天缓存，减少重复 API 调用
- **错误处理**: 统一的错误处理和重试机制，单资源失败不影响批量任务
- **格式化输出**: 标准化 JSON 输出，保存到 `aws_memos/tmp/`，便于后续 jq 处理
- **参数验证**: 自动验证 ARN/名称格式
- **批量处理**: 自动分批查询，避免 API 限流（IAM 策略批量查询等）
- **诊断内置**: 高危规则识别、不健康目标检测等诊断逻辑已内置

#### 脚本匹配规则

**自动匹配场景**:
1. **精确匹配**: 服务 + 资源类型 + 关系类型完全匹配
2. **模糊匹配**: 服务 + 关键词（如 "安全组"、"高危端口"、"IAM权限"、"EIP"）
3. **场景匹配**: 业务场景描述匹配（如 "安全审计"、"网络诊断"、"权限审计"）

**示例匹配**:
```
用户查询: "查询 ALB my-alb 的转发规则和后端健康状态"
↓ 匹配到关键词: ALB + 转发规则 / 健康状态
脚本: query_alb_listener_rules.sh
↓ 优先使用脚本执行

用户查询: "检查所有安全组是否有端口对 0.0.0.0/0 开放"
↓ 匹配到关键词: 安全组 + 高危 / 开放 / 公网
脚本: batch_query_sg_rules.sh
↓ 优先使用脚本执行（支持 --all-regions）

用户查询: "查询 IAM Role eks-node-role 的所有权限"
↓ 匹配到关键词: IAM Role + 权限 / 策略
脚本: query_iam_role_policies.sh
↓ 优先使用脚本执行

用户查询: "哪些 EC2 实例绑定了 EIP？"
↓ 匹配到关键词: EC2 + EIP / 公网 IP
脚本: batch_query_ec2_eip.sh
↓ 优先使用脚本执行（加 --filter-public 过滤）
```

### 脚本使用示例

#### 单个 ALB 监听器规则查询

```bash
# 使用脚本（支持名称或 ARN 输入）
"$SCRIPT_DIR/query_alb_listener_rules.sh" my-alb ap-southeast-1

# 输出示例
========================================
  ALB 监听器规则与目标组查询工具
========================================
输入: my-alb
区域: ap-southeast-1

[1/4] 获取 ALB 基本信息...
  名称: my-alb
  状态: active
  类型: internet-facing
  DNS: my-alb-123456789.ap-southeast-1.elb.amazonaws.com

[2/4] 获取监听器列表...
  找到 2 个监听器

[3/4] 查询各监听器转发规则...
  查询 HTTPS:443 监听器规则...
    ✓ 找到 5 条规则
  查询 HTTP:80 监听器规则...
    ✓ 找到 1 条规则

[4/4] 查询目标组健康状态...
  ✅ api-tg: 3/3 健康
  ⚠️ web-tg: 2/3 健康

📊 统计信息:
  监听器数量: 2
  转发规则总数: 6
  目标组数量: 2
  ⚠ 存在不健康的目标组: 1 个

输出文件: ./aws_memos/tmp/alb_rules_my-alb_20260331_143000.json
```

#### 安全组高危规则批量扫描

```bash
# 扫描指定区域
"$SCRIPT_DIR/batch_query_sg_rules.sh" ap-southeast-1

# 扫描所有区域（全局安全审计）
"$SCRIPT_DIR/batch_query_sg_rules.sh" --all-regions

# 输出示例
========================================
  AWS 安全组高危规则扫描工具
========================================
检测高危端口: 22 3389 3306 5432 6379 27017 11211 9200 5601 8080 8443 2375 2376
检测条件: 入站规则来源为 0.0.0.0/0 或 ::/0

[1/2] 获取安全组列表...
  找到 42 个安全组

[2/2] 分析高危规则...
  ⚠ default (sg-0abc123): 1 条高危规则
  ⚠ web-sg (sg-0def456): 2 条高危规则

📊 区域 ap-southeast-1 统计:
  安全组总数: 42
  ⚠ 高危安全组: 2 个

输出文件: ./aws_memos/tmp/sg_audit_ap-southeast-1_20260331_143000.json
```

#### IAM Role 权限链查询

```bash
# 查询 Role 完整权限
"$SCRIPT_DIR/query_iam_role_policies.sh" eks-node-role

# 输出示例
========================================
  IAM Role 权限链完整查询工具
========================================
Role: eks-node-role

[1/4] 获取 Role 基本信息...
  ARN: arn:aws:iam::123456789012:role/eks-node-role
  创建时间: 2024-01-15T08:30:00Z

[2/4] 获取附加的托管策略...
  找到 3 个托管策略
  获取策略: AmazonEKSWorkerNodePolicy ...
  获取策略: AmazonEC2ContainerRegistryReadOnly ...
  获取策略: AmazonEKS_CNI_Policy ...

[3/4] 获取内联策略...
  找到 1 个内联策略

[4/4] 生成权限摘要...
  Allow 权限总数: 47
  ✅ 未发现明显高危权限

📊 统计信息:
  托管策略数: 3
  内联策略数: 1
  Allow 权限总数: 47

输出文件: ./aws_memos/tmp/iam_role_eks-node-role_20260331_143000.json
```

#### EC2 实例 EIP 批量查询

```bash
# 查询区域内所有 EC2 实例的公网 IP 情况
"$SCRIPT_DIR/batch_query_ec2_eip.sh" ap-southeast-1

# 仅显示有公网 IP 的实例
"$SCRIPT_DIR/batch_query_ec2_eip.sh" ap-southeast-1 --filter-public

# 输出示例
========================================
  EC2 公网 IP / EIP 批量查询工具
========================================
区域: ap-southeast-1
过滤: 仅显示有公网 IP 的实例

[1/3] 获取 EC2 实例列表...
  找到 18 个实例

[2/3] 获取 EIP 列表...
  找到 3 个 EIP

[3/3] 匹配 EIP 关联关系...

📊 统计信息:
  实例总数: 18
  绑定 EIP（固定公网 IP）: 3
  仅有临时公网 IP: 2
  无公网 IP（纯内网）: 13

📋 有公网 IP 的实例:
  i-0abc123 (web-01) running → 13.215.xxx.xxx [EIP: eip-0abc123]
  i-0def456 (api-01) running → 52.221.xxx.xxx [EIP: eip-0def456]
  i-0ghi789 (bastion) running → 54.169.xxx.xxx [EIP: eip-0ghi789]
  i-0jkl012 (worker-01) running → 18.136.xxx.xxx [临时IP]
  i-0mno345 (worker-02) running → 18.140.xxx.xxx [临时IP]

输出文件: ./aws_memos/tmp/ec2_eip_ap-southeast-1_20260331_143000.json
```

**批量查询脚本优势**：
- **效率提升**: 一次调用完成区域内所有资源扫描，无需逐一查询
- **统一输出**: 所有结果汇总到一个 JSON 文件
- **错误隔离**: 单个资源查询失败不影响其他资源
- **统计报告**: 自动生成汇总统计信息
- **临时文件管理**: 结果自动保存到 `aws_memos/tmp/` 目录

### 复杂需求中的脚本使用

即使是 L3-L5 的复杂需求，如果某个阶段的子任务有预制脚本支持，也应该**优先使用脚本**。

**关键原则**:
- **单资源查询子任务**: 优先使用单资源查询脚本（`query_*`）
- **批量资源查询**: 优先使用批量查询脚本（`batch_query_*`），效率更高
- **脚本不可用**: 回退到标准 AWS CLI 命令

**示例 1: 批量审计所有 ALB 的转发规则和健康状态**

```markdown
## 阶段 2: 资源发现
- [ ] 2.1 查询所有 ALB 实例
      ```bash
      aws elbv2 describe-load-balancers \
        --profile devops-readonly --region $REGION \
        | jq -r '.LoadBalancers[] | select(.Type == "application") | .LoadBalancerArn' \
        > aws_memos/tmp/alb_arns.txt
      ```

## 阶段 3: 关联查询
- [ ] 3.1 使用脚本逐个查询各 ALB 规则和目标组健康状态
      ```bash
      while IFS= read -r alb_arn; do
        echo "查询 ALB: $alb_arn"
        "$SCRIPT_DIR/query_alb_listener_rules.sh" "$alb_arn" "$REGION"
        sleep 0.5
      done < aws_memos/tmp/alb_arns.txt
      ```
- [ ] 3.2 汇总所有不健康目标组
      ```bash
      LATEST=$(ls -t aws_memos/tmp/alb_rules_*.json 2>/dev/null | head -1)
      jq '.TargetGroups[] | select(.HealthySummary.Unhealthy > 0)' "$LATEST"
      ```
```

**示例 2: 全区域安全组合规审计**

```markdown
## 阶段 1: 环境准备
- [ ] 1.1 验证脚本可用性
      ```bash
      chmod +x "$SCRIPT_DIR/batch_query_sg_rules.sh"
      "$SCRIPT_DIR/batch_query_sg_rules.sh" --help
      ```

## 阶段 3: 关联查询（使用批量脚本）
- [ ] 3.1 全区域扫描高危安全组规则
      ```bash
      # 一条命令扫描所有区域
      "$SCRIPT_DIR/batch_query_sg_rules.sh" --all-regions
      ```

## 阶段 4: 数据处理
- [ ] 4.1 分析各区域扫描结果
      ```bash
      # 汇总所有区域的高危安全组
      for f in aws_memos/tmp/sg_audit_*.json; do
        echo "=== 区域: $(jq -r '.Region' "$f") ==="
        jq '.RiskySecurityGroups[] | {GroupName: .GroupName, GroupId: .SecurityGroupId, RiskCount: .RiskRuleCount}' "$f"
      done
      ```
```

**示例 3: IAM 权限审计（多 Role 批量）**

```markdown
## 阶段 2: 资源发现
- [ ] 2.1 获取所有 IAM Role 列表
      ```bash
      aws iam list-roles --profile devops-readonly \
        | jq -r '.Roles[].RoleName' > aws_memos/tmp/role_names.txt
      ```

## 阶段 3: 关联查询
- [ ] 3.1 逐一查询每个 Role 的完整权限链
      ```bash
      while IFS= read -r role_name; do
        echo "查询 Role: $role_name"
        "$SCRIPT_DIR/query_iam_role_policies.sh" "$role_name"
        sleep 0.2  # 避免 IAM API 限流
      done < aws_memos/tmp/role_names.txt
      ```
- [ ] 3.2 汇总发现高危权限的 Role
      ```bash
      # 查找包含 iam:* 或 *:* 的 Role
      for f in aws_memos/tmp/iam_role_*.json; do
        role=$(jq -r '.Role.RoleName' "$f")
        dangerous=$(jq -r '[
          .ManagedPolicies[].Document.Statement[]? |
          select(.Effect == "Allow") |
          .Action | if type == "array" then .[] else . end |
          select(test("\\*"))
        ] | unique | join(",")' "$f" 2>/dev/null)
        [ -n "$dangerous" ] && echo "⚠ $role: $dangerous"
      done
      ```
```

### 批量查询最佳实践

#### 方式一：使用批量查询脚本（推荐）

**适用场景**: 查询多个指定的 EC2/安全组实例，或需要全区域扫描

```bash
# 1. 查询资源列表
aws ec2 describe-instances \
  --profile devops-readonly --region $REGION \
  | jq -r '.Reservations[].Instances[].InstanceId' > aws_memos/tmp/ec2_ids.txt

# 2. 使用批量查询脚本（推荐）
"$SCRIPT_DIR/batch_query_ec2_eip.sh" "$REGION" --filter-public

# 输出文件: ./aws_memos/tmp/ec2_eip_<region>_<日期时间>.json
```

**优势**:
- ✅ 一次调用处理区域内所有实例
- ✅ 内置 EIP 与临时公网 IP 的区分逻辑
- ✅ 统一的 JSON 输出格式
- ✅ 详细的统计报告
- ✅ 结果自动保存到 `aws_memos/tmp/`

#### 方式二：遍历调用单资源查询脚本

**适用场景**: 需要对每个资源单独处理的场景

```bash
# 遍历调用单资源查询脚本
while IFS= read -r resource_id; do
  "$SCRIPT_DIR/query_alb_listener_rules.sh" "$resource_id" "$REGION"
  sleep 0.5  # 避免 API 限流
done < aws_memos/tmp/alb_arns.txt
```

#### 方式选择建议

| 查询场景 | 推荐方式 | 说明 |
|---------|---------|------|
| 查询区域内所有 EC2 的 EIP | **batch_query_ec2_eip.sh** | 原生支持全区域批量 |
| 安全组高危规则全量扫描 | **batch_query_sg_rules.sh** | 支持 `--all-regions` 一键全局扫描 |
| 单个 ALB 的详细规则 | **query_alb_listener_rules.sh** | 单实例详情+健康状态 |
| 多个 ALB 的规则审计 | 遍历调用 **query_alb_listener_rules.sh** | 逐个处理，便于控制 |
| IAM Role 权限审计 | 遍历调用 **query_iam_role_policies.sh** | 需要加 sleep 避免限流 |

### 缓存机制

`query_alb_listener_rules.sh` 脚本内置当天缓存，减少重复 API 调用：

```
缓存文件路径: ./aws_cache/alb-rules-<region>-<YYYYMMDD>.json
缓存有效期:   当天有效（日期变更后自动重新查询）
缓存保留:     自动清理 3 天前的旧缓存文件
手动清除:     rm -rf ./aws_cache
```

**注意**: 其他脚本（`batch_query_sg_rules.sh`、`query_iam_role_policies.sh`、`batch_query_ec2_eip.sh`）**不使用缓存**，每次调用均实时查询 AWS API，确保安全审计结果的准确性。

#### 复杂需求 (L3-L5) - 分阶段执行

按照以下阶段依次执行并汇总结果：

**阶段 1: 环境准备**
- 验证 AWS CLI 已安装并配置
- 验证 `devops-readonly` Profile 凭证有效
- 确认目标区域参数（如未设置则默认 ap-southeast-1）
- 验证所需权限是否具备
- **确定脚本文件路径**

```bash
# 验证环境
aws sts get-caller-identity --profile devops-readonly
aws configure list --profile devops-readonly

# 检测技能安装目录（按优先级）
if [ -n "$SKILL_BASE_DIR" ] && [ -f "$SKILL_BASE_DIR/scripts/query_alb_listener_rules.sh" ]; then
  SCRIPT_DIR="$SKILL_BASE_DIR/scripts"
elif [ -f ~/.claude/skills/aws-ask/scripts/query_alb_listener_rules.sh ]; then
  SCRIPT_DIR="$HOME/.claude/skills/aws-ask/scripts"
elif [ -f .claude/skills/aws-ask/scripts/query_alb_listener_rules.sh ]; then
  SCRIPT_DIR=".claude/skills/aws-ask/scripts"
elif [ -f "./scripts/query_alb_listener_rules.sh" ]; then
  SCRIPT_DIR="./scripts"
else
  echo "未找到预制脚本，将使用标准 AWS CLI 命令执行"
  SCRIPT_DIR=""
fi

[ -n "$SCRIPT_DIR" ] && echo "使用脚本目录: $SCRIPT_DIR"
```

**阶段 2: 资源发现**
- 查询主资源列表
- 获取基础数据
- 保存到临时文件

**阶段 3: 关联查询**
- 根据依赖关系查询关联资源
- 使用 jq 处理数据流转
- 合并关联数据

**阶段 4: 数据处理**
- 应用过滤条件
- 转换数据格式
- 统计聚合

**阶段 5: 报告生成**
- 汇总所有结果
- 应用诊断规则（如适用）
- 生成结构化报告


**执行示例**：
```bash
# 阶段 1: 环境准备
aws sts get-caller-identity --profile devops-readonly

# 阶段 2: 资源发现
aws ec2 describe-instances \
  --filters "Name=vpc-id,Values=vpc-xxx" \
  --profile devops-readonly \
  --region ap-southeast-1 \
  > aws_memos/tmp/ec2_list.json

# 阶段 3: 关联查询
for instance_id in $(jq -r '.Reservations[].Instances[].InstanceId' aws_memos/tmp/ec2_list.json); do
  aws ec2 describe-volumes \
    --filters "Name=attachment.instance-id,Values=$instance_id" \
    --profile devops-readonly \
    --region ap-southeast-1
done > aws_memos/tmp/volumes_list.json

# 阶段 4: 数据处理
jq -s '{ec2: .[0], volumes: .[1]}' aws_memos/tmp/ec2_list.json aws_memos/tmp/volumes_list.json > aws_memos/tmp/result.json

# 阶段 5: 报告生成
jq '.' aws_memos/tmp/result.json
```


### Step 5: 返回结果

#### 简单需求结果格式

```markdown
## 查询结果

**查询类型**: SIMPLE_QUERY
**状态**: ✅ 成功
**Region**: ap-southeast-1

### 查询数据

| 实例ID | 类型 | 状态 | 私网IP |
|--------|------|------|--------|
| i-0123456789abcdef0 | t3.medium | running | 10.0.1.100 |

### 关键信息
- **实例ID**: i-0123456789abcdef0
- **实例类型**: t3.medium (2vCPU/4GB RAM)
- **状态**: running（运行中）
- **私网IP**: 10.0.1.100
- **公网IP**: 54.123.45.67
```

#### 复杂需求结果格式

```markdown
## 查询报告

**任务类型**: ASSOCIATION_QUERY + COMPOUND_QUERY
**状态**: ✅ 成功
**Region**: ap-southeast-1

### 执行摘要
- **查询区域**: ap-southeast-1
- **发现资源**: 15个EC2实例, 3个RDS实例
- **关联关系**: 已建立

### 详细结果

#### 1. EC2实例列表

| 实例ID | 名称 | 状态 | 类型 | VPC |
|--------|------|------|------|-----|
| i-001 | web-01 | running | t3.medium | vpc-xxx |
| i-002 | web-02 | running | t3.medium | vpc-xxx |

#### 2. RDS实例列表

| 实例ID | 名称 | 状态 | 引擎 | VPC |
|--------|------|------|------|-----|
| db-master | prod-db | available | mysql | vpc-xxx |

#### 3. 资源关联关系

VPC (vpc-xxx)
├── EC2实例
│   ├── i-001 (web-01) → RDS (db-master)
│   └── i-002 (web-02) → RDS (db-master)
└── RDS实例
    └── db-master (prod-db)

### 诊断结论
- ✅ 所有资源状态正常
- ✅ 网络连通性正常
- ⚠️ 建议：EC2实例 i-002 CPU使用率较高（85%）
```


### Step 6: 结果确认

询问用户是否已按需求实现查询结果，请"确认"已完成任务并结束流程？

### 结果保存功能

如果用户需要保存结果，在项目目录下的 `aws_memos/<日期>/` 目录下生成 `aws_<查询服务>_output_<时分>.md` 文件（例如：`aws_ec2_output_1430.md`），包含：

- 原始查询需求
- 执行的任务清单
- 查询结果汇总

**目录处理**：如果 `aws_memos/<日期>` 目录不存在，使用 Bash tool 创建该目录。

#### 历史对比功能

当用户明确提出"对比"需求时：

1. 使用 Glob tool 查找 `aws_memos` 目录下所有的 `aws_*_output_*.md` 文件
2. 读取历史查询结果文件
3. 将当前查询结果与历史结果进行差异对比
4. 输出对比结果，重点标注变化部分（如新增/删除的资源、状态变化、数值变化等）

继续询问直到用户确认任务完成。

### Step 7: 结束流程与自动保存

当用户"确认"已完成任务并结束整个流程时：

1. 自动总结当前会话中的所有查询结果
2. 在 `aws_memos/<日期>/` 目录下生成 `<日期>/aws_output_<时分>.md` 目录与文件
3. 文件内容包含：
   - 会话时间戳
   - 原始查询需求
   - 执行的任务清单
   - 完整的查询结果汇总
   - 关键发现与结论（如有）

**注意**：此自动保存操作仅在用户明确确认任务完成时执行，避免在中间执行过程中产生冗余文件。

## 执行过程临时文件保存

执行过程中查询临时文件或生成的临时执行脚本文件将保存在 `aws_memos/tmp/` 目录下。

**重要**：临时文件需要保存，不要自动清理和删除。



### 错误处理

**执行错误时**：
1. 捕获错误信息
2. 分析错误类型（认证、参数、权限、限流、区域）
3. 提供解决方案
4. 建议重试或调整参数

**常见 AWS CLI 错误及处理**：

| 错误类型 | 错误特征 | 处理建议 |
|---------|---------|---------|
| 认证错误 | `NoCredentialsError`, `InvalidClientTokenId` | 检查 `devops-readonly` profile 配置是否正确 |
| 权限不足 | `AccessDenied`, `UnauthorizedOperation` | 提示用户该操作超出 devops-readonly 权限范围 |
| 区域错误 | `AuthFailure`, `InvalidAction` | 检查 `--region` 参数是否正确 |
| 参数错误 | `ValidationError`, `InvalidParameterValue` | 检查参数格式，参考 AWS 文档 |
| 限流 | `ThrottlingException`, `RequestLimitExceeded` | 添加 `sleep 1` 降低请求频率 |
| 资源不存在 | `InvalidInstanceID.NotFound`, `DBInstanceNotFound` | 确认资源 ID 和区域是否正确 |

### 特殊查询注意事项

#### EC2 实例查询

EC2 使用 Reservations 嵌套结构，获取实例需要双层展开：
```bash
# 正确的 jq 路径
aws ec2 describe-instances --profile devops-readonly --region ap-southeast-1 \
  | jq '.Reservations[].Instances[] | {InstanceId, State: .State.Name}'

# 获取 Name 标签（注意标签是数组）
aws ec2 describe-instances --profile devops-readonly --region ap-southeast-1 \
  | jq '.Reservations[].Instances[] | {
      InstanceId,
      Name: (.Tags // [] | map(select(.Key == "Name")) | first | .Value // "N/A"),
      State: .State.Name,
      Type: .InstanceType
    }'
```

#### S3 查询

S3 查询通常无需指定 `--region`，但某些操作需要：
```bash
# 列出所有 bucket（全局）
aws s3 ls --profile devops-readonly

# 列出特定 bucket 内容
aws s3 ls s3://my-bucket/ --profile devops-readonly

# 获取 bucket 策略（需要指定具体操作）
aws s3api get-bucket-policy --bucket my-bucket --profile devops-readonly

# 获取 bucket 位置（区域）
aws s3api get-bucket-location --bucket my-bucket --profile devops-readonly
```

#### IAM 查询

IAM 是全局服务，不需要 `--region`：
```bash
# 列出所有用户
aws iam list-users --profile devops-readonly

# 列出用户的策略
aws iam list-attached-user-policies --user-name <username> --profile devops-readonly

# 列出角色
aws iam list-roles --profile devops-readonly
```

#### ELB vs ELBv2

AWS 有两代负载均衡，需要注意区别：
- **经典 ELB**（Classic LB）：使用 `aws elb` 命令
- **ALB/NLB/GLB**（Application/Network/Gateway LB）：使用 `aws elbv2` 命令

```bash
# 经典 ELB
aws elb describe-load-balancers --profile devops-readonly --region ap-southeast-1

# ALB/NLB（推荐，大多数场景）
aws elbv2 describe-load-balancers --profile devops-readonly --region ap-southeast-1
```

#### CloudWatch 指标查询

查询监控数据需要指定时间范围和统计方式：
```bash
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name CPUUtilization \
  --dimensions Name=InstanceId,Value=i-0123456789abcdef0 \
  --start-time 2025-01-01T00:00:00Z \
  --end-time 2025-01-01T01:00:00Z \
  --period 300 \
  --statistics Average \
  --profile devops-readonly \
  --region ap-southeast-1
```

#### EKS 查询

EKS 查询需要注意 kubeconfig 配置：
```bash
# 查询集群列表
aws eks list-clusters --profile devops-readonly --region ap-southeast-1

# 查询集群详情
aws eks describe-cluster --name my-cluster --profile devops-readonly --region ap-southeast-1

# 查询节点组
aws eks list-nodegroups --cluster-name my-cluster --profile devops-readonly --region ap-southeast-1
```

#### 安全组规则查询

```bash
# 查询安全组列表
aws ec2 describe-security-groups --profile devops-readonly --region ap-southeast-1

# 查询特定安全组规则
aws ec2 describe-security-groups \
  --group-ids sg-0123456789abcdef0 \
  --profile devops-readonly \
  --region ap-southeast-1 \
  | jq '.SecurityGroups[].IpPermissions[] | {
      Protocol: .IpProtocol,
      FromPort,
      ToPort,
      Ranges: .IpRanges[].CidrIp
    }'
```

#### Route53 查询

Route53 是全局服务，Hosted Zone 与区域无关：
```bash
# 列出所有 Hosted Zone
aws route53 list-hosted-zones --profile devops-readonly

# 查询特定 Hosted Zone 的记录
aws route53 list-resource-record-sets \
  --hosted-zone-id Z1234567890ABC \
  --profile devops-readonly

# 通过域名查询
aws route53 list-hosted-zones-by-name \
  --dns-name example.com \
  --profile devops-readonly
```

## 支持的 AWS 服务

- **计算**: EC2, Lambda, ECS, EKS, Fargate, Batch, Auto Scaling
- **数据库**: RDS, DynamoDB, ElastiCache, DocumentDB, Aurora
- **网络**: VPC, ELB/ALBv2, Route53, CloudFront, Direct Connect
- **存储**: S3, EBS, EFS, FSx, Glacier
- **消息**: SQS, SNS, EventBridge, Kinesis, MSK (Managed Kafka)
- **监控**: CloudWatch, CloudTrail, X-Ray, Config
- **安全**: IAM, KMS, Secrets Manager, Security Hub, GuardDuty
- **容器**: ECR, ECS, EKS
- **其他**: ACM (证书管理), Organizations, Cost Explorer

完整服务 API 映射见 [API操作映射库.md](references/API操作映射库.md)。

## 常见查询场景

| 场景描述 | 主意图 | 执行方式 | 脚本支持 |
|---------|-------|---------|---------|
| 查看所有EC2实例 | SIMPLE_QUERY | 直接执行并返回表格 | - |
| 查询EC2实例的安全组规则 | ASSOCIATION_QUERY | 分阶段执行 | - |
| 查询VPC下所有资源 | COMPOUND_QUERY | 分阶段执行并返回汇总 | - |
| 检查安全组是否有高危端口暴露 | DIAGNOSTIC_QUERY | 使用脚本扫描 | ✅ batch_query_sg_rules.sh |
| 全区域安全组高危规则审计 | DIAGNOSTIC_QUERY | 使用脚本（--all-regions） | ✅ batch_query_sg_rules.sh |
| 查询S3 Bucket列表及配置 | SIMPLE_QUERY | 直接执行并返回表格 | - |
| 查询RDS实例状态和连接信息 | SIMPLE_QUERY | 直接执行并返回表格 | - |
| 查询 ALB 监听规则及后端健康状态 | ASSOCIATION_QUERY | 使用脚本 | ✅ query_alb_listener_rules.sh |
| 查询Lambda函数列表及配置 | SIMPLE_QUERY | 直接执行 | - |
| 诊断EC2实例网络连通性 | DIAGNOSTIC_QUERY | 分阶段执行并返回诊断报告 | - |
| 查询 IAM Role 的所有权限和策略 | ASSOCIATION_QUERY | 使用脚本 | ✅ query_iam_role_policies.sh |
| 审计 IAM Role 是否有高危权限 | DIAGNOSTIC_QUERY | 使用脚本（含诊断规则） | ✅ query_iam_role_policies.sh |
| 查询哪些 EC2 实例有公网 IP | COMPOUND_QUERY | 使用脚本 | ✅ batch_query_ec2_eip.sh |
| 查询哪些 EC2 实例绑定了 EIP | ASSOCIATION_QUERY | 使用脚本 | ✅ batch_query_ec2_eip.sh |
| 批量查询多区域资源 | COMPOUND_QUERY | 遍历区域执行并汇总 | - |
| 查询CloudWatch告警状态 | SIMPLE_QUERY | 直接执行 | - |

**说明**:
- ✅ 标记表示有预制脚本支持，**优先使用脚本执行**
- 脚本执行效率更高（缓存优化、错误处理完善、诊断规则内置）
- **批量查询**: 查询多个资源时，使用 `batch_query_*` 脚本更高效
