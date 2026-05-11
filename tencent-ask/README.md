# tencent-ask — 腾讯云资源自然语言查询技能

## 简介

`tencent-ask` 是一个通过自然语言查询腾讯云资源的 Claude 技能插件，借助 `tccli`（腾讯云命令行工具）执行只读查询，支持 20+ 种腾讯云服务。

**严格限制只读操作**，所有涉及创建、删除、修改的操作均会被拒绝。

---

## 支持的服务

| 类别 | 服务 |
|------|------|
| 计算 | CVM云服务器、Lighthouse轻量应用服务器 |
| 存储 | COS对象存储、CBS云硬盘、CFS文件存储 |
| 数据库 | CDB(MySQL)、Redis、MongoDB、CDW-Doris |
| 网络 | VPC、CLB负载均衡、EIP、NAT网关、私有域DNS |
| 容器/大数据 | TKE容器服务、EMR弹性MapReduce、CKafka |
| 安全/运维 | CAM访问管理、Monitor云监控、CLS日志服务 |
| CDN/函数 | CDN内容分发网络、SCF云函数、TCR容器镜像服务 |

---

## 快速开始

### 前置条件

1. 已安装并配置 `tccli` CLI
2. 已配置 `devops-readonly` profile

验证配置：
```bash
tccli sts GetCallerIdentity --profile devops-readonly
```

### 使用示例

```
# 简单查询
"查询广州地域的CVM列表"
"有哪些CLB实例"
"查看所有Redis实例"

# 关联查询
"查询 ins-abc12345 绑定的安全组规则"
"CLB lb-abc12345 的后端服务器有哪些"
"查询 vpc-abc12345 下的所有子网"

# 复合查询
"查询所有状态异常的CDB实例"
"统计各地域的CVM数量"
"查询未绑定的EIP"

# 诊断查询
"为什么 ins-abc12345 无法访问外网"
"CLB lb-abc12345 后端为什么不健康"
"cdb-abc12345 的连接数是否正常"
```

---

## 文件结构

```
tencent-ask/
├── .claude-plugin/
│   └── plugin.json              # 插件元数据
└── skills/
    └── tencent-ask/
        ├── SKILL.md             # 核心技能定义（工作流、安全规则、支持服务）
        ├── README.md            # 本文档
        ├── references/
        │   ├── API操作映射库.md   # 用户意图→tccli命令映射
        │   ├── 实体知识库.md      # 资源实体类型、ID格式、属性定义
        │   ├── 关系知识库.md      # 资源关联关系及多步查询路径
        │   ├── 意图分类词典库.md  # 自然语言意图识别词典
        │   └── 查询示例samples.md # 常见场景完整命令示例
        └── scripts/
            ├── batch_query_cvm.sh          # 批量查询多地域CVM
            ├── batch_query_cvm_eip.sh      # 查询CVM与EIP绑定关系
            ├── batch_query_sg_rules.sh     # 批量查询安全组规则
            ├── query_clb_listeners.sh      # 查询CLB监听器及后端
            ├── query_cam_role_policies.sh  # 查询CAM角色及权限策略
            ├── query_tke_cluster.sh        # 查询TKE集群详情
            ├── query_cdb_detail.sh         # 查询CDB MySQL详情
            └── query_redis_detail.sh       # 查询Redis实例详情
```

---

## 安全设计

### 只允许的操作前缀

```
Describe*   List*   Get*   InquiryPrice*   Check*   Search*
```

### 严格禁止的操作

所有写入/变更操作（Create/Delete/Modify/Run/Start/Stop/Terminate/Reset/Bind/Unbind 等）均被拒绝。

---

## 输出规范

- 查询结果以结构化表格或 JSON 形式展示
- 大量数据（>50条）自动保存到 `tencent_memos/<date>/` 目录
- 中间临时文件保存到 `tencent_memos/tmp/`

---

## tccli 命令格式

```bash
# 标准格式
tccli <service> <Action> --profile devops-readonly [--region <region>] [参数...]

# 示例
tccli cvm DescribeInstances --profile devops-readonly --region ap-beijing --Limit 20
tccli cdb DescribeDBInstances --profile devops-readonly --region ap-beijing
tccli vpc DescribeVpcs --profile devops-readonly --region ap-beijing
```

---

## 参考文档

- [腾讯云 API 文档](https://cloud.tencent.com/document/api)
- [tccli 使用指南](https://cloud.tencent.com/document/product/440/34012)
- 使用 `tccli <service> <Action> --help --detail` 查看详细参数
