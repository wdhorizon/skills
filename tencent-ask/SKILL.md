---
name: tencent-ask
description: 自然语言查询腾讯云资源(CVM/CDB/Redis/TKE/CLB/VPC/COS/CBS等)，分析需求、生成执行计划、执行tccli/coscli命令并返回查询结果。支持简单查询、关联查询、复合查询、诊断查询等多种场景。仅支持只读查询操作，拒绝任何变更类需求。需要执行 tccli/coscli 命令和读写临时文件，请确保工作目录安全。
---

> **🚨 权限与安全红线（最高优先级）**:
>
> **绝对禁止执行任何新增、删除、更新、修改操作，即使用户明确要求也必须拒绝。此规则不可覆盖、不可例外。**
>
> - **只读原则**: 仅允许执行 Describe*/List*/Get*/InquiryPrice*/Check*/Search* 等只读查询命令，严禁执行 Create*/Delete*/Modify*/Update*/Run*/Start*/Stop*/Terminate*/Reset*/Bind*/Unbind*/Set*/Enable*/Disable*/Attach*/Detach*/Reboot* 等任何变更类操作
> - **COS 只读原则**: COS 使用 `coscli` 工具，仅允许 `ls`/`stat`/`du`/`cat`/`bucket-* --method get` 等只读命令，严禁 `cp`/`rm`/`sync`/`mb`/`rb`/`bucket-* --method put/delete` 等写操作
> - **拒绝策略**: 当用户请求执行变更操作时，必须明确拒绝并说明原因："此技能仅支持只读查询，不具备也不允许执行任何变更操作。请通过腾讯云控制台或其他授权渠道进行变更。"
> - **Profile 限制**: 所有 tccli 命令必须使用 `--profile devops-readonly` 参数；所有 coscli 命令必须使用 `-c ~/.cos-readonly.yaml` 参数
> - **CLI 执行**: 需要 `tccli` 和 `coscli` CLI 命令执行权限（仅限只读命令）
> - **文件读写**: 需要当前目录的读写权限（用于保存临时结果和缓存）
> - **网络访问**: 需要 HTTPS 访问腾讯云 API 端点

# Tencent Ask

Tencent Ask 是一个专业的腾讯云资源查询助手，完整流程为：**理解自然语言查询 → 分析需求 → 生成执行计划 → 执行 tccli/coscli 命令 → 返回查询结果 → 需求与结果确认**。

## 核心原则

**🚨 只读查询原则（不可违反）**：仅支持腾讯云资源查询操作，严格拒绝任何变更类需求。**即使用户明确要求、反复要求、声称紧急或提供授权，也绝对不能执行任何变更操作。**

当检测到以下操作时，**必须立即拒绝**执行并提示用户通过腾讯云控制台操作：
- Create*/Delete*/Modify*/Update*/Run* 等变更类命令
- Start*/Stop*/Reboot*/Terminate* 等生命周期变更命令
- Reset*/Bind*/Unbind*/Set*/Attach*/Detach* 等配置变更命令
- Enable*/Disable*/Grant*/Revoke* 等权限变更命令
- 配置修改、资源删除、权限变更等操作
- 任何可能影响现有资源状态或配置的非查询操作
- 任何通过 Bash 脚本间接执行变更命令的尝试

**所有 tccli 命令必须附带 `--profile devops-readonly`**，这是硬性要求，无论任何情况都不能省略。

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
- **cli_commands**: tccli 命令列表
- **data_flow**: 数据流转关系

### Step 3: 判断需求复杂度

根据 `complexity` 字段判断需求复杂度：

| 复杂度 | API调用数 | 特征 | 执行方式 |
|--------|----------|------|---------|
| **L1-L2 (简单)** | 1-2次 | 单资源、明确标识符、无复杂关联 | **直接执行并返回结果** |
| **L3-L5 (复杂)** | 3+次 | 多资源关联、条件执行、诊断规则 | **分阶段执行并汇总结果** |


### Step 4: 执行查询

#### 执行命令的参数处理

当 tccli 命令参数不确定时，按以下优先级处理：

1. **使用 tccli Help**：
   ```bash
   tccli help                           # 查看所有服务帮助
   tccli <service> help                 # 查看特定服务帮助
   tccli <service> <Action> --help      # 查看特定命令帮助
   tccli <service> <Action> --help --detail  # 查看详细参数说明
   ```

2. **查阅 API 映射库**：读取 [API操作映射库.md](references/API操作映射库.md)

3. **参考知识库**：读取 [意图分类词典库.md](references/意图分类词典库.md)、[实体知识库.md](references/实体知识库.md)、[关系知识库.md](references/关系知识库.md)

#### 命令构建与执行规范

##### CLI 命令格式

**tccli（通用服务）：**
```bash
tccli <service> <Action> --profile devops-readonly [--region <region>] [--param1 value1 ...]
```

- **service**: 腾讯云服务代码（如 cvm, cdb, redis, vpc, clb）
- **Action**: API 操作名称（PascalCase，如 DescribeInstances）
- **参数格式**: `--ParameterName value`（注意 PascalCase）
- **必须附加**: `--profile devops-readonly`
- **区域参数**: `--region` 默认值 `ap-beijing`，用户指定时使用用户指定值

**coscli（COS 对象存储专用）：**
```bash
coscli <command> [cos://<BucketName-AppId>/[prefix]] -c ~/.cos-readonly.yaml
```

- **必须附加**: `-c ~/.cos-readonly.yaml`（只读凭证配置文件）
- **Bucket URI 格式**: `cos://<BucketName>-<AppId>/`，如 `cos://my-bucket-1250000000/`
- **只读命令**: `ls`、`stat`、`du`、`cat`、`bucket-versioning --method get`、`bucket-encryption --method get`、`bucket-acl --method get`、`bucket-tagging --method get`
- **禁止命令**: `cp`、`rm`、`sync`、`mb`、`rb` 以及任何 `--method put/delete` 操作

##### 参数替换规则

| 变量格式 | 说明 | 示例 |
|---------|------|------|
| `$REGION` | 腾讯云地域，需用户指定或使用默认值 ap-beijing | `ap-beijing` |
| `$.field` | JSONPath 引用上一步输出结果 | `$.InstanceSet[*].InstanceId` |

##### 常用地域参数说明

| 腾讯云服务 | 区域参数 | 说明 |
|---------|---------|------|
| cvm, cdb, redis, vpc, clb 等 | `--region` | 必须指定地域 |
| cam, billing | 全局服务，无需 `--region` | - |
| cdn, scf | 全局服务，通常无需 `--region` | 部分操作需要 |
| sts | `--region` 可选 | 用于获取账号信息 |

##### 输出处理

使用 jq 进行 JSON 输出处理：

```bash
tccli cvm DescribeInstances --profile devops-readonly --region ap-beijing \
  | jq '.InstanceSet[] | {InstanceId, InstanceName: .InstanceName, State: .InstanceState.State, PrivateIp: .PrivateIpAddresses[0]}'
```

##### 分页处理

tccli 大多数 Describe* 接口支持 `--Offset` 和 `--Limit` 参数：

```bash
# 使用 --Limit 控制返回数量（最大100）
tccli cvm DescribeInstances --profile devops-readonly --region ap-beijing --Limit 100 --Offset 0

# 循环获取所有数据（通过检查 TotalCount）
OFFSET=0; LIMIT=100
while true; do
  RESULT=$(tccli cvm DescribeInstances --profile devops-readonly --region ap-beijing --Offset $OFFSET --Limit $LIMIT)
  TOTAL=$(echo $RESULT | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('TotalCount',0))")
  echo "$RESULT"
  OFFSET=$((OFFSET + LIMIT))
  if [ $OFFSET -ge $TOTAL ]; then break; fi
done
```

#### 简单需求 (L1-L2) - 直接执行

1. **验证环境**：检查 tccli 是否已配置
2. **执行 tccli 命令**：直接运行 tccli 命令
3. **处理输出**：使用 jq 或 python3 提取和格式化结果
4. **返回结果**：展示查询结果并解读关键信息

**执行示例**：
```bash
# 1. 验证环境
tccli sts GetCallerIdentity --profile devops-readonly

# 2. 执行查询
tccli cvm DescribeInstances \
  --profile devops-readonly \
  --region ap-beijing \
  --InstanceIds '["ins-xxxxxxxx"]'

# 3. 处理输出
tccli cvm DescribeInstances \
  --profile devops-readonly \
  --region ap-beijing \
  --InstanceIds '["ins-xxxxxxxx"]' \
  | jq '.InstanceSet[0] | {InstanceId, InstanceType, State: .InstanceState.State, PrivateIpAddress: .PrivateIpAddresses[0], PublicIpAddress: .PublicIpAddresses[0]}'

# 4. 返回结果
{
  "InstanceId": "ins-xxxxxxxx",
  "InstanceType": "S5.MEDIUM4",
  "State": "RUNNING",
  "PrivateIpAddress": "10.0.0.100",
  "PublicIpAddress": "101.123.45.67"
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
| batch_query_cvm.sh | CVM | 批量查询多地域CVM实例列表 | - | ✅ 原生支持多地域 | L2 → L3 |
| batch_query_cvm_eip.sh | CVM/EIP | 查询CVM与EIP绑定关系 | ✅ 支持 | ✅ 原生支持 | L2 → L3 |
| batch_query_sg_rules.sh | VPC/SG | 批量查询安全组规则 | ✅ 支持 | ✅ 原生支持 | L3 → L4 |
| query_clb_listeners.sh | CLB | 查询CLB监听器规则及后端健康状态 | ✅ 支持 | - | L3 → L4 |
| query_cam_role_policies.sh | CAM | 查询CAM角色及绑定权限策略 | ✅ 支持 | - | L3 |
| query_tke_cluster.sh | TKE | 查询TKE集群详情、节点池及节点状态 | ✅ 支持 | - | L3 |
| query_cdb_detail.sh | CDB | 查询CDB MySQL详情、参数、备份、慢查询 | ✅ 支持 | - | L3 |
| query_redis_detail.sh | Redis | 查询Redis实例详情、内存使用、Top命令 | ✅ 支持 | - | L3 |

**说明**:
- **单资源查询脚本**（`query_*`）: 设计为查询单个资源，可通过遍历调用实现批量查询
- **批量查询脚本**（`batch_query_*`）: 原生支持批量或多地域查询，一次调用处理多个资源
- **优先使用**: 批量查询多个资源时，优先使用 `batch_query_*` 脚本，效率更高

### 脚本优先策略

当查询场景匹配脚本功能时，**优先使用预制脚本**而非标准 tccli 命令。

#### 脚本优势

- **错误处理**: 统一的错误处理和重试机制，单资源失败不影响批量任务
- **格式化输出**: 标准化 JSON 输出，保存到 `./tencent_memos/tmp/`，便于后续 jq 处理
- **参数验证**: 自动验证资源ID格式
- **批量处理**: 自动分批查询，避免 API 限流
- **多步聚合**: 内置多步骤数据聚合逻辑（如CLB监听器→后端→健康状态）

#### 脚本匹配规则

**自动匹配场景**:
1. **精确匹配**: 服务 + 资源类型 + 关系类型完全匹配
2. **模糊匹配**: 服务 + 关键词（如 "安全组"、"CLB监听器"、"CAM权限"、"EIP"）
3. **场景匹配**: 业务场景描述匹配（如 "安全审计"、"网络诊断"、"权限审计"）

**示例匹配**:
```
用户查询: "查询 CLB lb-abc12345 的监听器转发规则和后端健康状态"
↓ 匹配到关键词: CLB + 监听器 / 后端 / 健康状态
脚本: query_clb_listeners.sh
↓ 优先使用脚本执行

用户查询: "检查所有安全组是否有高危端口对 0.0.0.0/0 开放"
↓ 匹配到关键词: 安全组 + 高危 / 开放 / 公网
脚本: batch_query_sg_rules.sh
↓ 优先使用脚本执行

用户查询: "查询 CAM 角色 eks-node-role 的所有绑定权限"
↓ 匹配到关键词: CAM + 角色 + 权限 / 策略
脚本: query_cam_role_policies.sh
↓ 优先使用脚本执行

用户查询: "哪些 CVM 实例绑定了 EIP？"
↓ 匹配到关键词: CVM + EIP / 公网 IP
脚本: batch_query_cvm_eip.sh
↓ 优先使用脚本执行
```

### 脚本使用示例

#### 查询 CLB 监听器及后端健康状态

```bash
# 使用脚本（支持 CLB 实例ID输入）
"$SCRIPT_DIR/query_clb_listeners.sh" lb-abc12345 ap-beijing

# 输出示例
======================================================
  CLB 监听器与后端查询
  实例ID: lb-abc12345 | 地域: ap-beijing
======================================================

[1/3] CLB 基本信息...
  名称: prod-clb-01
  类型: OPEN（公网）
  VIP: 101.123.45.67

[2/3] 监听器列表...
  找到 2 个监听器

[3/3] 后端服务器健康状态...
  ✅ HTTPS:443 后端: 3/3 健康
  ⚠️ HTTP:80 后端: 2/3 健康

📊 统计信息:
  监听器总数: 2
  后端总数: 6
  ⚠ 存在不健康的后端: 1 个

输出文件: ./tencent_memos/tmp/clb_listeners_lb-abc12345_20260401_143000.json
```

#### 安全组规则批量扫描

```bash
# 扫描指定地域所有安全组
"$SCRIPT_DIR/batch_query_sg_rules.sh" ap-beijing

# 扫描指定安全组
"$SCRIPT_DIR/batch_query_sg_rules.sh" ap-beijing sg-aaa111 sg-bbb222

# 输出示例
======================================================
  安全组规则批量查询
  地域: ap-beijing
======================================================

[1/2] 获取安全组列表...
  找到 35 个安全组

[2/2] 分析规则...
  ⚠ web-sg (sg-aaa111): 2 条高危规则（22端口对0.0.0.0/0开放）
  ⚠ default (sg-bbb222): 1 条高危规则

📊 统计:
  安全组总数: 35
  ⚠ 高危安全组: 2 个

输出文件: ./tencent_memos/tmp/sg_audit_ap-beijing_20260401_143000.json
```

#### CAM 角色权限查询

```bash
# 查询角色完整策略
"$SCRIPT_DIR/query_cam_role_policies.sh" CVM_QCSRole

# 输出示例
======================================================
  CAM 角色及策略查询
======================================================

[1/2] 查询角色列表...
  共 28 个角色

[2/2] 查询角色 'CVM_QCSRole' 的绑定策略...
  角色 CVM_QCSRole 共绑定 2 个策略:

  [系统策略] QcloudCVMInstanceConnectRole (ID: 123456)
    描述: 腾讯云主机直连角色

输出文件: ./tencent_memos/20260401/
```

#### CVM 与 EIP 批量查询

```bash
# 查询地域内所有 CVM 实例的 EIP 情况
"$SCRIPT_DIR/batch_query_cvm_eip.sh" ap-beijing

# 输出示例
======================================================
  CVM 与 EIP 绑定关系查询
  地域: ap-beijing
======================================================

[1/3] 获取 CVM 实例列表...
  找到 24 个实例

[2/3] 获取 EIP 列表...
  找到 5 个 EIP

[3/3] 匹配绑定关系...

📊 统计信息:
  实例总数: 24
  绑定 EIP（固定公网IP）: 5
  仅有临时公网IP: 3
  无公网IP（纯内网）: 16

输出文件: ./tencent_memos/tmp/cvm_eip_ap-beijing_20260401_143000.json
```

**批量查询脚本优势**：
- **效率提升**: 一次调用完成地域内所有资源扫描，无需逐一查询
- **统一输出**: 所有结果汇总到一个 JSON 文件
- **错误隔离**: 单个资源查询失败不影响其他资源
- **统计报告**: 自动生成汇总统计信息
- **临时文件管理**: 结果自动保存到 `./tencent_memos/tmp/` 目录

### 复杂需求中的脚本使用

即使是 L3-L5 的复杂需求，如果某个阶段的子任务有预制脚本支持，也应该**优先使用脚本**。

**关键原则**:
- **单资源查询子任务**: 优先使用单资源查询脚本（`query_*`）
- **批量资源查询**: 优先使用批量查询脚本（`batch_query_*`），效率更高
- **脚本不可用**: 回退到标准 tccli 命令

**示例 1: 批量审计所有 CLB 的监听器及后端健康状态**

```markdown
## 阶段 2: 资源发现
- [ ] 2.1 查询所有 CLB 实例
      ```bash
      tccli clb DescribeLoadBalancers \
        --profile devops-readonly --region $REGION \
        | jq -r '.LoadBalancerSet[].LoadBalancerId' \
        > ./tencent_memos/tmp/clb_ids.txt
      ```

## 阶段 3: 关联查询
- [ ] 3.1 使用脚本逐个查询各 CLB 监听器和后端健康状态
      ```bash
      while IFS= read -r clb_id; do
        echo "查询 CLB: $clb_id"
        "$SCRIPT_DIR/query_clb_listeners.sh" "$clb_id" "$REGION"
        sleep 0.5
      done < ./tencent_memos/tmp/clb_ids.txt
      ```
- [ ] 3.2 汇总所有不健康后端
      ```bash
      LATEST=$(ls -t ./tencent_memos/tmp/clb_listeners_*.json 2>/dev/null | head -1)
      jq '.Backends[] | select(.HealthStatus != "HEALTHY")' "$LATEST"
      ```
```

**示例 2: 全地域安全组合规审计**

```markdown
## 阶段 1: 环境准备
- [ ] 1.1 验证脚本可用性
      ```bash
      chmod +x "$SCRIPT_DIR/batch_query_sg_rules.sh"
      ```

## 阶段 3: 关联查询（使用批量脚本）
- [ ] 3.1 各地域扫描高危安全组规则
      ```bash
      for REGION in ap-beijing ap-beijing ap-shanghai; do
        echo "=== 扫描地域: $REGION ==="
        "$SCRIPT_DIR/batch_query_sg_rules.sh" "$REGION"
        sleep 1
      done
      ```

## 阶段 4: 数据处理
- [ ] 4.1 汇总各地域扫描结果
      ```bash
      for f in ./tencent_memos/tmp/sg_audit_*.json; do
        echo "=== 地域: $(jq -r '.Region' "$f") ==="
        jq '.RiskySecurityGroups[] | {Name: .SecurityGroupName, Id: .SecurityGroupId, RiskCount: .RiskRuleCount}' "$f"
      done
      ```
```

**示例 3: CAM 权限审计（多角色批量）**

```markdown
## 阶段 2: 资源发现
- [ ] 2.1 获取所有 CAM 角色列表
      ```bash
      tccli cam DescribeRoleList \
        --profile devops-readonly \
        --Page 1 --Rp 100 \
        | jq -r '.List[].RoleName' > ./tencent_memos/tmp/role_names.txt
      ```

## 阶段 3: 关联查询
- [ ] 3.1 逐一查询每个角色的绑定策略
      ```bash
      while IFS= read -r role_name; do
        echo "查询角色: $role_name"
        "$SCRIPT_DIR/query_cam_role_policies.sh" "$role_name"
        sleep 0.2  # 避免 CAM API 限流
      done < ./tencent_memos/tmp/role_names.txt
      ```
```

### 批量查询最佳实践

#### 方式一：使用批量查询脚本（推荐）

**适用场景**: 查询多个指定的 CVM/安全组实例，或需要全地域扫描

```bash
# 1. 查询资源列表
tccli cvm DescribeInstances \
  --profile devops-readonly --region $REGION \
  | jq -r '.InstanceSet[].InstanceId' > ./tencent_memos/tmp/cvm_ids.txt

# 2. 使用批量查询脚本（推荐）
"$SCRIPT_DIR/batch_query_cvm_eip.sh" "$REGION"

# 输出文件: ./tencent_memos/tmp/cvm_eip_<region>_<日期时间>.json
```

**优势**:
- ✅ 一次调用处理地域内所有实例
- ✅ 内置 EIP 与临时公网 IP 的区分逻辑
- ✅ 统一的 JSON 输出格式
- ✅ 详细的统计报告
- ✅ 结果自动保存到 `./tencent_memos/tmp/`

#### 方式二：遍历调用单资源查询脚本

**适用场景**: 需要对每个资源单独处理的场景

```bash
# 遍历调用单资源查询脚本
while IFS= read -r resource_id; do
  "$SCRIPT_DIR/query_clb_listeners.sh" "$resource_id" "$REGION"
  sleep 0.5  # 避免 API 限流
done < ./tencent_memos/tmp/clb_ids.txt
```

#### 方式选择建议

| 查询场景 | 推荐方式 | 说明 |
|---------|---------|------|
| 查询地域内所有 CVM 的 EIP | **batch_query_cvm_eip.sh** | 原生支持全地域批量 |
| 安全组高危规则全量扫描 | **batch_query_sg_rules.sh** | 支持多地域扫描 |
| 单个 CLB 的详细规则 | **query_clb_listeners.sh** | 单实例详情+健康状态 |
| 多个 CLB 的规则审计 | 遍历调用 **query_clb_listeners.sh** | 逐个处理，便于控制 |
| CAM 角色权限审计 | 遍历调用 **query_cam_role_policies.sh** | 需要加 sleep 避免限流 |
| TKE 集群节点状态 | **query_tke_cluster.sh** | 包含节点池和节点状态 |
| CDB MySQL 深度诊断 | **query_cdb_detail.sh** | 包含参数、备份、慢查询 |
| Redis 内存使用分析 | **query_redis_detail.sh** | 包含 Top 命令统计 |

#### 复杂需求 (L3-L5) - 分阶段执行

按照以下阶段依次执行并汇总结果：

**阶段 1: 环境准备**
- 验证 tccli 已安装并配置
- 验证 `devops-readonly` Profile 凭证有效
- 确认目标地域参数（如未设置则默认 ap-beijing）
- 验证所需权限是否具备
- **确定脚本文件路径**

```bash
# 验证环境
tccli sts GetCallerIdentity --profile devops-readonly

# 检测技能安装目录（按优先级）
if [ -n "$SKILL_BASE_DIR" ] && [ -f "$SKILL_BASE_DIR/scripts/query_clb_listeners.sh" ]; then
  SCRIPT_DIR="$SKILL_BASE_DIR/scripts"
elif [ -f ~/.claude/skills/tencent-ask/scripts/query_clb_listeners.sh ]; then
  SCRIPT_DIR="$HOME/.claude/skills/tencent-ask/scripts"
elif [ -f .claude/skills/tencent-ask/scripts/query_clb_listeners.sh ]; then
  SCRIPT_DIR=".claude/skills/tencent-ask/scripts"
elif [ -f "./scripts/query_clb_listeners.sh" ]; then
  SCRIPT_DIR="./scripts"
else
  echo "未找到预制脚本，将使用标准 tccli 命令执行"
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
- 使用 jq 或 python3 处理数据流转
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
tccli sts GetCallerIdentity --profile devops-readonly

# 阶段 2: 资源发现
tccli cvm DescribeInstances \
  --profile devops-readonly \
  --region ap-beijing \
  --Filters '[{"Name":"vpc-id","Values":["vpc-xxxxxxxx"]}]' \
  > ./tencent_memos/tmp/cvm_list.json

# 阶段 3: 关联查询
for instance_id in $(jq -r '.InstanceSet[].InstanceId' ./tencent_memos/tmp/cvm_list.json); do
  tccli cbs DescribeDisks \
    --profile devops-readonly \
    --region ap-beijing \
    --Filters "[{\"Name\":\"instance-id\",\"Values\":[\"$instance_id\"]}]"
done > ./tencent_memos/tmp/disks_list.json

# 阶段 4: 数据处理
jq -s '{cvm: .[0], disks: .[1]}' ./tencent_memos/tmp/cvm_list.json ./tencent_memos/tmp/disks_list.json \
  > ./tencent_memos/tmp/result.json

# 阶段 5: 报告生成
jq '.' ./tencent_memos/tmp/result.json
```


### Step 5: 返回结果

#### 简单需求结果格式

```markdown
## 查询结果

**查询类型**: SIMPLE_QUERY
**状态**: ✅ 成功
**Region**: ap-beijing

### 查询数据

| 实例ID | 名称 | 状态 | 规格 | 内网IP |
|--------|------|------|------|--------|
| ins-xxxxxxxx | web-01 | RUNNING | S5.MEDIUM4 | 10.0.0.100 |

### 关键信息
- **实例ID**: ins-xxxxxxxx
- **实例名称**: web-01
- **状态**: RUNNING（运行中）
- **规格**: S5.MEDIUM4 (2核4G)
- **内网IP**: 10.0.0.100
- **公网IP**: 101.123.45.67
```

#### 复杂需求结果格式

```markdown
## 查询报告

**任务类型**: ASSOCIATION_QUERY + COMPOUND_QUERY
**状态**: ✅ 成功
**Region**: ap-beijing

### 执行摘要
- **查询地域**: ap-beijing
- **发现资源**: 15个CVM实例, 3个CDB实例
- **关联关系**: 已建立

### 详细结果

#### 1. CVM实例列表

| 实例ID | 名称 | 状态 | 规格 | VPC |
|--------|------|------|------|-----|
| ins-001 | web-01 | RUNNING | S5.MEDIUM4 | vpc-xxx |
| ins-002 | web-02 | RUNNING | S5.MEDIUM4 | vpc-xxx |

#### 2. CDB实例列表

| 实例ID | 名称 | 状态 | 引擎 | VPC |
|--------|------|------|------|-----|
| cdb-xxxxxxxx | prod-db | Running | MySQL 5.7 | vpc-xxx |

#### 3. 资源关联关系

VPC (vpc-xxx)
├── CVM实例
│   ├── ins-001 (web-01) → CDB (cdb-xxxxxxxx)
│   └── ins-002 (web-02) → CDB (cdb-xxxxxxxx)
└── CDB实例
    └── cdb-xxxxxxxx (prod-db)

### 诊断结论
- ✅ 所有资源状态正常
- ✅ 网络连通性正常
- ⚠️ 建议：CVM实例 ins-002 CPU使用率较高（85%）
```


### Step 6: 结果确认

询问用户是否已按需求实现查询结果，请"确认"已完成任务并结束流程？

### 结果保存功能

如果用户需要保存结果，在项目目录下的 `tencent_memos/<日期>/` 目录下生成 `tencent_<查询服务>_output_<时分>.md` 文件（例如：`tencent_clb_output_1430.md`），包含：

- 原始查询需求
- 执行的任务清单
- 查询结果汇总

**目录处理**：如果 `tencent_memos/<日期>` 目录不存在，使用 Bash tool 创建该目录。

#### 历史对比功能

当用户明确提出"对比"需求时：

1. 使用 Glob tool 查找 `tencent_memos` 目录下所有的 `tencent_*_output_*.md` 文件
2. 读取历史查询结果文件
3. 将当前查询结果与历史结果进行差异对比
4. 输出对比结果，重点标注变化部分（如新增/删除的资源、状态变化、数值变化等）

继续询问直到用户确认任务完成。

### Step 7: 结束流程与自动保存

当用户"确认"已完成任务并结束整个流程时：

1. 自动总结当前会话中的所有查询结果
2. 在 `tencent_memos/<日期>/` 目录下生成 `tencent_output_<时分>.md` 文件
3. 文件内容包含：
   - 会话时间戳
   - 原始查询需求
   - 执行的任务清单
   - 完整的查询结果汇总
   - 关键发现与结论（如有）

**注意**：此自动保存操作仅在用户明确确认任务完成时执行，避免在中间执行过程中产生冗余文件。

## 执行过程临时文件保存

执行过程中查询临时文件或生成的临时执行脚本文件将保存在 `./tencent_memos/tmp/` 目录下。

**重要**：临时文件需要保存，不要自动清理和删除。


### 错误处理

**执行错误时**：
1. 捕获错误信息
2. 分析错误类型（认证、参数、权限、限流、地域）
3. 提供解决方案
4. 建议重试或调整参数

**常见 tccli 错误及处理**：

| 错误类型 | 错误特征 | 处理建议 |
|---------|---------|---------|
| 认证错误 | `AuthFailure`, `InvalidCredential` | 检查 `devops-readonly` profile 配置：`tccli configure list --profile devops-readonly` |
| 权限不足 | `UnauthorizedOperation`, `PermissionDenied` | 提示用户该操作超出 devops-readonly 权限范围 |
| 地域错误 | `InvalidRegion`, `UnsupportedRegion` | 检查 `--region` 参数是否正确 |
| 参数错误 | `InvalidParameter`, `InvalidParameterValue` | 检查参数格式，参考 `tccli <service> <Action> --help --detail` |
| 限流 | `RequestLimitExceeded`, `LimitExceeded` | 添加 `sleep 1` 降低请求频率 |
| 资源不存在 | `InvalidInstanceId.NotFound`, `ResourceNotFound` | 确认资源 ID 和地域是否正确 |
| 内部错误 | `InternalError` | 重试请求，若持续联系腾讯云支持 |

### 特殊查询注意事项

#### CVM 实例查询

```bash
# 查询实例列表，使用 Filters 过滤
tccli cvm DescribeInstances \
  --profile devops-readonly --region ap-beijing \
  --Filters '[{"Name":"instance-state","Values":["RUNNING"]}]'

# 查询实例详情（通过 InstanceIds 指定）
tccli cvm DescribeInstances \
  --profile devops-readonly --region ap-beijing \
  --InstanceIds '["ins-xxxxxxxx"]'

# 获取 Name 标签（tccli 中标签通过 Tags 数组获取）
tccli cvm DescribeInstances \
  --profile devops-readonly --region ap-beijing \
  | jq '.InstanceSet[] | {
      InstanceId,
      Name: (.Tags // [] | map(select(.Key == "Name")) | first | .Value // "N/A"),
      State: .InstanceState.State,
      PrivateIp: .PrivateIpAddresses[0]
    }'
```

#### VPC 安全组规则查询

```bash
# 查询安全组列表
tccli vpc DescribeSecurityGroups \
  --profile devops-readonly --region ap-beijing

# 查询安全组入站/出站规则
tccli vpc DescribeSecurityGroupPolicies \
  --profile devops-readonly --region ap-beijing \
  --SecurityGroupId "sg-xxxxxxxx"
```

#### CAM 查询（全局服务，无需 --region）

```bash
# 列出所有 CAM 用户
tccli cam ListUsers --profile devops-readonly

# 列出所有 CAM 角色
tccli cam DescribeRoleList --profile devops-readonly --Page 1 --Rp 100

# 查询角色绑定策略
tccli cam ListAttachedRolePolicies \
  --profile devops-readonly \
  --RoleName "RoleName" \
  --Page 1 --Rp 50
```

#### CLB 监听器查询

```bash
# 查询 CLB 实例列表
tccli clb DescribeLoadBalancers --profile devops-readonly --region ap-beijing

# 查询监听器列表
tccli clb DescribeListeners \
  --profile devops-readonly --region ap-beijing \
  --LoadBalancerId "lb-xxxxxxxx"

# 查询后端服务器
tccli clb DescribeTargets \
  --profile devops-readonly --region ap-beijing \
  --LoadBalancerId "lb-xxxxxxxx"
```

#### TKE 集群查询

```bash
# 查询集群列表
tccli tke DescribeClusters --profile devops-readonly --region ap-beijing

# 查询集群节点池
tccli tke DescribeClusterNodePools \
  --profile devops-readonly --region ap-beijing \
  --ClusterId "cls-xxxxxxxx"

# 查询集群节点
tccli tke DescribeClusterInstances \
  --profile devops-readonly --region ap-beijing \
  --ClusterId "cls-xxxxxxxx" --Limit 100
```

#### Monitor 云监控查询

```bash
# 查询告警策略列表
tccli monitor DescribeAlarmPolicies \
  --profile devops-readonly --region ap-beijing

# 查询告警历史
tccli monitor DescribeAlarmHistory \
  --profile devops-readonly --region ap-beijing
```

#### CDN 查询（全局服务）

```bash
# 查询 CDN 域名列表
tccli cdn DescribeDomains --profile devops-readonly

# 查询 CDN 访问流量数据
tccli cdn DescribeCdnData \
  --profile devops-readonly \
  --StartTime "2026-04-01T00:00:00+08:00" \
  --EndTime "2026-04-01T01:00:00+08:00" \
  --Metric flux
```

#### CLS 日志查询

```bash
# 查询日志集列表
tccli cls DescribeLogsets --profile devops-readonly --region ap-beijing

# 查询日志主题
tccli cls DescribeTopics --profile devops-readonly --region ap-beijing

# 搜索日志（只读操作）
tccli cls SearchLog \
  --profile devops-readonly --region ap-beijing \
  --TopicId "topic-xxxxxxxx" \
  --From 1680000000000 \
  --To 1680003600000 \
  --Query "level:error" \
  --Limit 20
```

## 支持的腾讯云服务

- **计算**: CVM 云服务器, Lighthouse 轻量应用服务器
- **数据库**: CDB(MySQL), Redis, MongoDB, CDW-Doris
- **网络**: VPC, CLB 负载均衡, EIP, NAT 网关, 私有域 DNS
- **存储**: COS 对象存储, CBS 云硬盘, CFS 文件存储
- **容器/大数据**: TKE 容器服务, EMR 弹性 MapReduce, CKafka
- **安全/运维**: CAM 访问管理, Monitor 云监控, CLS 日志服务
- **CDN/函数**: CDN 内容分发网络, SCF 云函数, TCR 容器镜像服务

完整服务 API 映射见 [API操作映射库.md](references/API操作映射库.md)。

## 常见查询场景

| 场景描述 | 主意图 | 执行方式 | 脚本支持 |
|---------|-------|---------|---------|
| 查看所有CVM实例 | SIMPLE_QUERY | 直接执行并返回表格 | - |
| 查询CVM实例的安全组规则 | ASSOCIATION_QUERY | 分阶段执行 | - |
| 查询VPC下所有资源 | COMPOUND_QUERY | 分阶段执行并返回汇总 | - |
| 检查安全组是否有高危端口暴露 | DIAGNOSTIC_QUERY | 使用脚本扫描 | ✅ batch_query_sg_rules.sh |
| 查询哪些CVM实例有公网IP / 绑定了EIP | COMPOUND_QUERY | 使用脚本 | ✅ batch_query_cvm_eip.sh |
| 全地域CVM资产梳理 | COMPOUND_QUERY | 使用脚本（多地域） | ✅ batch_query_cvm.sh |
| 查询CLB监听规则及后端健康状态 | ASSOCIATION_QUERY | 使用脚本 | ✅ query_clb_listeners.sh |
| 查询CAM角色的所有权限和策略 | ASSOCIATION_QUERY | 使用脚本 | ✅ query_cam_role_policies.sh |
| TKE集群节点状态巡检 | DIAGNOSTIC_QUERY | 使用脚本 | ✅ query_tke_cluster.sh |
| CDB MySQL 慢查询分析 | DIAGNOSTIC_QUERY | 使用脚本（含诊断规则） | ✅ query_cdb_detail.sh |
| Redis 内存使用及热点命令分析 | DIAGNOSTIC_QUERY | 使用脚本 | ✅ query_redis_detail.sh |
| 查询CDB实例状态和连接信息 | SIMPLE_QUERY | 直接执行并返回表格 | - |
| 查询Redis实例列表 | SIMPLE_QUERY | 直接执行并返回表格 | - |
| 批量查询多地域资源 | COMPOUND_QUERY | 遍历地域执行并汇总 | - |
| 查询Monitor告警策略状态 | SIMPLE_QUERY | 直接执行 | - |
| 诊断CVM实例网络连通性 | DIAGNOSTIC_QUERY | 分阶段执行并返回诊断报告 | - |

**说明**:
- ✅ 标记表示有预制脚本支持，**优先使用脚本执行**
- 脚本执行效率更高（错误处理完善、诊断规则内置）
- **批量查询**: 查询多个资源时，使用 `batch_query_*` 脚本更高效
