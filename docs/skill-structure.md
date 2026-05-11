# Skill Structure Guide

本规范用于保持个人 skills 仓库结构一致、易安装、易审查。

## Minimal Skill

每个 skill 至少包含：

```text
<skill-name>/
└── SKILL.md
```

`SKILL.md` 必须以 YAML frontmatter 开头：

```markdown
---
name: skill-name
description: 一句话说明什么时候应该使用这个 skill，以及它会做什么。
---

# Skill Name

...
```

要求：

- 目录名使用小写 kebab-case，例如 `aliyun-ask`。
- `name` 优先和目录名一致。
- `description` 写清触发场景、主要能力和关键依赖。
- 对有风险的能力，在文件顶部明确权限边界。

## Recommended Layout

复杂 skill 推荐使用：

```text
<skill-name>/
├── SKILL.md
├── README.md
├── references/
│   ├── api-map.md
│   └── examples.md
├── scripts/
│   └── helper.sh
└── _meta.json
```

说明：

- `README.md` 面向使用者，写安装、依赖、示例和注意事项。
- `references/` 放静态知识库、映射表、示例，不放敏感查询结果。
- `scripts/` 放可复用脚本。脚本应有 shebang、用法说明和安全检查。
- `_meta.json` 仅放发布平台所需的非敏感元数据。

## Script Rules

脚本应满足：

- Shell 脚本使用 `#!/usr/bin/env bash` 或现有兼容 shebang。
- Python 脚本使用 `#!/usr/bin/env python3`。
- 可直接运行的脚本应设置执行权限。
- 只读查询脚本必须避免调用变更类 API。
- 输出文件默认写入当前工作目录下的临时目录，并确保 `.gitignore` 覆盖。

建议在脚本顶部写明：

```bash
# Usage: ./script.sh <required-id> [region]
# Requires: aws, jq
```

## Security Checklist

新增或修改 skill 时检查：

- 是否会访问网络或云 API。
- 是否会读取本地凭证或 profile。
- 是否会写文件，写入位置是否可控。
- 是否包含创建、删除、修改、启停、授权等变更命令。
- 是否会上传本地文件、剪贴板、图片或文档。
- README 是否写清依赖和权限边界。

## Naming

推荐命名：

- 查询类：`<provider>-ask`，例如 `aws-ask`。
- 发布类：`<target>-publisher`，例如 `wechat-publisher`。
- 生成类：`generate-<thing>`，例如 `generate-wechat-theme`。
- 安全/治理类：`<domain>-vetter`、`<domain>-auditor`。

## Validation

运行：

```bash
python3 scripts/validate-skills.py
```

校验脚本只做静态检查，不会运行各 skill 的业务脚本，也不会访问云 API。
