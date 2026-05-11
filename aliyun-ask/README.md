# Aliyun Ask 技能使用指南

## 快速开始

### 安装技能

```bash
# 将技能包复制到 Claude Code 的技能目录
cp aliyun-ask ~/.claude/skills/

# 或使用符号链接
ln -s /path/to/aliyun-ask ~/.claude/skills/
```

### 基本使用

#### 阿里云环境选择

默认使用 Aliyun CLI 当前默认 profile，默认地域为 `cn-beijing`。

当用户提到“钉钉环境 / dingtalk / dingtalk-readonly / 钉钉旗舰版”等关键词时，使用钉钉只读环境：

- Profile: `dingtalk-readonly`
- 默认地域: `cn-zhangjiakou`
- CLI 示例:

```bash
aliyun --profile dingtalk-readonly ecs DescribeInstances --RegionId cn-zhangjiakou
```

预制脚本通过环境变量指定 profile：

```bash
ALIYUN_PROFILE=dingtalk-readonly ./scripts/query_alb_acls.sh alb-xxx
```

#### 1. 简单查询示例

```
用户: 查看ECS实例 i-0x12345678abcdef 的详细信息

Aliyun Ask:
# 快速查询: ECS 实例详情

**查询类型**: SIMPLE_QUERY
**复杂度**: L1
**预估时间**: <100ms

## 执行命令

```bash
aliyun ecs DescribeInstanceAttribute \
  --InstanceId i-0x12345678abcdef
```

## 输出格式

```json
{
  "InstanceId": "i-0x12345678abcdef",
  "InstanceName": "web-server-01",
  "Status": "Running",
  "InstanceType": "ecs.g6.large",
  "Cpu": 2,
  "Memory": 8
}
```

## 结果解读

- **InstanceId**: ECS 实例 ID
- **InstanceName**: 实例名称
- **Status**: 实例状态 (Running/Stopped/Starting)
- **InstanceType**: 实例规格
- **Cpu**: CPU 核数
- **Memory**: 内存大小 (GB)

## 注意事项

1. 确认实例 ID 格式正确（i- 开头）
2. 需要具备 `ecs:DescribeInstanceAttribute` 权限
3. 实例必须存在于当前账号下
```

#### 2. 关联查询示例

```
用户: 查询ALB alb-wzxxjqqmz0083y4vglx13 的ACL配置

Aliyun Ask:
# 快速查询: ALB 监听器 ACL 配置

**查询类型**: ASSOCIATION_QUERY
**复杂度**: L2
**预估时间**: <1秒

## 执行命令

```bash
aliyun alb ListAclRelations \
  --AclIds.1 alb-wzxxjqqmz0083y4vglx13 \
  --RegionId cn-hangzhou
```

## 输出格式

```json
{
  "AclRelations": [
    {
      "AclId": "acl-xxxxx",
      "LoadBalancerId": "alb-wzxxjqqmz0083y4vglx13",
      "ListenerId": "lsn-xxxxx"
    }
  ]
}
```

## 结果解读

- **AclId**: ACL 策略 ID
- **LoadBalancerId**: ALB 实例 ID
- **ListenerId**: 监听器 ID

## 注意事项

1. 确认 ALB ID 格式正确（alb- 开头）
2. 需要具备 `alb:ListAclRelations` 权限
3. 确保地域参数正确
```

#### 3. 复杂查询示例

```
用户: 查询VPC vpc-bp1abcdefg123456 下的所有ECS和RDS实例

Aliyun Ask:
# 任务分析

这是一个 L4 的 ASSOCIATION_QUERY + COMPOUND_QUERY 任务，目标是查询 VPC 下所有 ECS 和 RDS 实例及其关联关系。

## 任务列表

### 阶段 1: 环境准备
- [ ] 1.1 验证阿里云 CLI 已安装并配置 (`aliyun version`)
- [ ] 1.2 验证凭证配置有效 (`aliyun account GetProfile`)
- [ ] 1.3 确认目标地域 ($REGION_ID)，如未指定则使用默认地域
- [ ] 1.4 验证所需权限是否具备 (ecs:Describe*, rds:Describe*)

### 阶段 2: 资源发现
- [ ] 2.1 查询 VPC 详情
      ```bash
      aliyun vpc DescribeVpcAttribute \
        --VpcId vpc-bp1abcdefg123456 \
        --RegionId $REGION_ID
      ```
  输出: 保存到 vpc_detail.json

### 阶段 3: 关联查询
- [ ] 3.1 查询 VPC 下的所有 ECS 实例
      ```bash
      aliyun ecs DescribeInstances \
        --VpcId vpc-bp1abcdefg123456 \
        --RegionId $REGION_ID \
        | jq '.Instances.Instance[] | {InstanceId, InstanceName, Status}'
      ```
  输出: 保存到 ecs_list.json

- [ ] 3.2 查询 VPC 下的所有 RDS 实例
      ```bash
      aliyun rds DescribeDBInstances \
        --VpcId vpc-bp1abcdefg123456 \
        --RegionId $REGION_ID \
        | jq '.Items.DBInstance[] | {DBInstanceId, DBInstanceDescription, Status}'
      ```
  输出: 保存到 rds_list.json

### 阶段 4: 数据处理
- [ ] 4.1 合并 ECS 和 RDS 列表
      ```bash
      jq -s '{ecs: .[0], rds: .[1]}' ecs_list.json rds_list.json > vpc_resources.json
      ```

- [ ] 4.2 生成汇总报告
      ```bash
      jq '.ecs | length' vpc_resources.json  # ECS 实例数量
      jq '.rds | length' vpc_resources.json  # RDS 实例数量
      ```

### 阶段 5: 报告生成
- [ ] 5.1 生成资源清单报告
- [ ] 5.2 验证资源关联关系
- [ ] 5.3 生成可视化拓扑（可选）

## 执行依赖关系图

```
阶段1 → 阶段2 → 阶段3.1 → 阶段4 → 阶段5
              ↓
            阶段3.2 ────────┘
```

## 关键注意事项

1. **权限要求**:
   - ECS: ecs:DescribeInstances, ecs:DescribeInstanceAttribute
   - RDS: rds:DescribeDBInstances, rds:DescribeDBInstanceAttribute
   - VPC: vpc:DescribeVpcAttribute

2. **地域参数**: 必须指定正确的地域 ID

3. **分页处理**:
   - ECS 默认分页大小为 10，如资源超过 10 个需要处理分页
   - RDS 默认分页大小为 30

4. **数据量评估**:
   - 预估 ECS 实例数量，避免查询超时
   - 如实例过多，建议添加过滤条件（如状态、标签）
```

## 支持的查询类型

### 1. 简单查询 (SIMPLE_QUERY)
- 单资源详情查询
- 单属性查询
- 状态检查
- 存在性检查

### 2. 关联查询 (ASSOCIATION_QUERY)
- 直接关联（如 ECS 挂载的磁盘）
- 间接关联（如 ECS 所在的 VPC）
- 层级关系（如 VPC 下包含的资源）
- 多跳关联（如通过 VSwitch 查询 VPC）

### 3. 复合查询 (COMPOUND_QUERY)
- 聚合查询（统计资源总数）
- 分类查询（按地域、类型分组）
- 跨服务查询（ECS 和 RDS）
- 多条件查询（运行中且内存>8G）

### 4. 诊断查询 (DIAGNOSTIC_QUERY)
- 配置诊断（检查安全组配置）
- 安全检查（检查端口暴露）
- 性能诊断（分析性能瓶颈）
- 成本诊断（分析资源浪费）

## 常见问题

### Q1: 技能拒绝执行我的请求？

**A**: 此技能仅支持只读查询操作。如果您尝试执行以下操作，将被拒绝：
- 创建、删除、修改资源
- 变更配置
- 权限修改

如需执行这些操作，请使用阿里云控制台或对应的 API。

### Q2: 如何查看完整的 API 映射？

**A**: 技能包含完整的 API 操作映射库，位于：
```
references/API操作映射库.md
```

### Q3: 如何验证生成的 CLI 命令？

**A**: 使用 Aliyun Help 功能：
```bash
aliyun help                    # 查看所有产品帮助
aliyun <product> help          # 查看特定产品帮助
aliyun <product> <api> help    # 查看特定API帮助
```

### Q4: 复杂查询如何优化？

**A**:
1. 添加过滤条件（如状态、标签）
2. 使用分页查询
3. 并行执行无依赖的查询
4. 使用 jq 处理 JSON 输出

## 技能文件结构

```
aliyun-ask/
├── SKILL.md                    # 技能主文件
├── README.md                   # 使用指南
├── references/                 # 参考资料目录
│   ├── API操作映射库.md        # API 映射（34项服务）
│   ├── 意图分类词典库.md        # 意图分类
│   ├── 实体知识库.md            # 实体定义
│   ├── 关系知识库.md            # 关系定义
│   └── 查询示例samples.md      # 查询示例
├── scripts/                    # 脚本目录
│   ├── batch_query_alb_acls.sh # 批量ALB ACL查询
│   ├── batch_query_slb_acls.sh # 批量SLB ACL查询
│   ├── batch_query_slb_eip.sh  # 批量SLB EIP查询
│   ├── query_alb_acls.sh       # 单个ALB ACL查询
│   ├── query_slb_acls.sh       # 单个SLB ACL查询
│   └── validate_json.py        # JSON 验证脚本
└── assets/                     # 资产目录（空）
```

## 更新日志

### v1.2 (2026-04-03)
- ✅ 新增 13 项阿里云服务支持：CR、ECD、ESS、CEN、VPN、PrivateZone、SSL证书、SMS、DCDN、NAT、Elasticsearch、云安全中心、MSE
- ✅ 服务覆盖从 21 项扩展到 34 项
- ✅ 更新 API操作映射库（新增 22-34 节）
- ✅ 更新实体知识库（实体定义、标识符模式、同义词映射、关联图谱）
- ✅ 更新关系知识库（新增 21-33 节资源关系定义）
- ✅ 更新意图分类词典库（新增服务关键词库和业务场景映射）

### v1.1 (2025-01-29)
- ✅ 合并 aliyun-exec 和 aliyun-planner 技能
- ✅ 精简 SKILL.md（减少 54%）
- ✅ 优化工作流程（从 5 步简化到 3 步）
- ✅ 完善参考资料（保留 5 个核心文件）
- ✅ 强化安全性（只读查询原则）
- ✅ 统一输出格式（CLI 命令和 TODO 清单）
- ✅ 内置查询脚本优先机制


## 贡献与反馈

如有问题或建议，请通过以下方式反馈：
- 提交 Issue
- 发起 Pull Request
- 联系维护者

---

**技能版本**: v1.1.0
**创建日期**: 2025-01-29
**维护者**: XiaoYang
**许可**: Apache 2.0
