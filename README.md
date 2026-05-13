# AndyWah Personal Codex Skills

这是我的个人[AndyWah] Codex/Claude Skills 仓库，用来沉淀日常高频工作流、云资源只读查询、内容发布、热点监控和技能安全审查等能力。

仓库目标：

- 每个 skill 都可以独立复制或软链接到本地 skills 目录使用。
- 结构统一，便于开源、审查和持续维护。
- 对涉及云资源、账号凭证和外部命令的 skill 明确安全边界。
- 尽量保持轻依赖，脚本和参考资料随 skill 一起分发。

## Skills

| Skill | 用途 | 备注 | 公众号文章 |
| --- | --- | --- | --- |
| `aliyun-ask` | 通过自然语言只读查询阿里云资源 | 依赖 `aliyun` CLI、`jq` | [公众号文章](https://mp.weixin.qq.com/s/EpWssPZfuJCwYkjjMVSrVQ?scene=1) |
| `aws-ask` | 通过自然语言只读查询 AWS 云资源 | 依赖 `aws` CLI、`jq` | [公众号文章](https://mp.weixin.qq.com/s/EpWssPZfuJCwYkjjMVSrVQ?scene=1) |
| `tencent-ask` | 通过自然语言只读查询腾讯云资源 | 依赖 `tccli`、`coscli`、`jq` | [公众号文章](https://mp.weixin.qq.com/s/EpWssPZfuJCwYkjjMVSrVQ?scene=1) |
| `aihot` | 查询 AI HOT 中文 AI 资讯、日报和精选动态 | 依赖 `curl`、`jq` | - |
| `hot-monitor` | 热点监控、趋势搜索和报告生成 | 可选 Python 依赖见 skill 内说明 | - |
| `generate-wechat-theme` | 生成微信公众号排版 CSS 主题 | 输出 CSS | - |
| `khazix-writer` | 按「数字生命卡兹克」风格写公众号长文 | 个人写作风格 skill | - |
| `neat-freak` | 会话结束时同步项目文档、规则和记忆 | 知识库清理 skill | - |
| `wechat-publisher` | 发布 Markdown 到微信公众号草稿箱 | 依赖 wenyan 相关工具 | - |
| `skill-vetter` | 安装第三方 skill 前做安全审查 | 安全辅助 skill | - |
| `self-improving` | 自我反思、纠错和长期记忆工作流 | 个人工作流 skill | - |

## Repository Layout

```text
.
├── <skill-name>/
│   ├── SKILL.md              # 必需：skill 入口和主指令
│   ├── README.md             # 推荐：面向人的使用说明
│   ├── references/           # 可选：知识库、映射表、示例
│   ├── scripts/              # 可选：skill 使用的辅助脚本
│   └── _meta.json            # 可选：发布平台元数据
├── docs/
│   └── skill-structure.md    # 新增/维护 skill 的结构规范
├── scripts/
│   └── validate-skills.py    # 仓库静态校验脚本
└── .github/workflows/
    └── validate.yml          # GitHub Actions 校验
```

## Install

这些 skill 都是独立目录，安装时只需要把某个 `<skill-name>/` 放到你所用 Agent 的 skills 目录里即可。

### 方式一：让 Agent 从 GitHub 安装

在 Claude Code、Codex、OpenClaw、OpenCode 等支持 Skill 的 Agent 里，可以直接说：

```text
帮我安装这个 skill：https://github.com/wdhorizon/skills/tree/main/<skill-name>
```

把 `<skill-name>` 换成你想安装的目录名，例如：

```text
帮我安装这个 skill：https://github.com/wdhorizon/skills/tree/main/aliyun-ask
帮我安装这个 skill：https://github.com/wdhorizon/skills/tree/main/neat-freak
帮我安装这个 skill：https://github.com/wdhorizon/skills/tree/main/aihot
```

仓库地址：

- HTTPS：`https://github.com/wdhorizon/skills.git`
- SSH：`git@github.com-wdhorizon:wdhorizon/skills.git`

### 方式二：使用 `npx skills` 安装

如果本机有 Node.js，也可以使用 Vercel Labs 的 `skills` CLI 安装和管理 skill。这个方式适合同时支持 Codex、Claude Code、Cursor、OpenCode 等多个 Agent 的场景。

查看仓库中有哪些 skill：

```bash
npx skills add https://github.com/wdhorizon/skills --list
```

安装指定 skill 到 Codex 全局目录：

```bash
npx skills add https://github.com/wdhorizon/skills \
  --skill aliyun-ask \
  -g \
  -a codex
```

安装本地仓库中的指定 skill：

```bash
npx skills add . \
  --skill aliyun-ask \
  -g \
  -a codex
```

一次安装本仓库全部 skill 到 Codex：

```bash
npx skills add . \
  --skill '*' \
  -g \
  -a codex
```

常用参数：

| 参数 | 说明 |
| --- | --- |
| `-g`, `--global` | 安装到用户全局 skills 目录 |
| `-a`, `--agent <agent>` | 指定目标 Agent，例如 `codex`、`claude-code`、`cursor` |
| `-s`, `--skill <skill>` | 指定安装某个 skill |
| `--list` | 只列出可安装 skill，不执行安装 |
| `--copy` | 复制文件，而不是软链接 |
| `-y`, `--yes` | 跳过确认，适合脚本化安装 |

不加 `-g` 时通常安装到当前项目的 Agent skills 目录；加 `-g` 时安装到用户全局目录。以 Codex 为例，项目级通常是 `.agents/skills/`，全局级通常是 `~/.codex/skills/`。

### 方式三：本地软链接安装（推荐开发时使用）

软链接适合自己维护这个仓库时使用。以后在本仓库更新 skill，Agent 侧会直接读到最新版本。

```bash
git clone https://github.com/wdhorizon/skills.git
cd skills

mkdir -p ~/.codex/skills
ln -s "$(pwd)/aliyun-ask" ~/.codex/skills/aliyun-ask
```

安装多个：

```bash
mkdir -p ~/.codex/skills
for skill in aliyun-ask aws-ask tencent-ask aihot neat-freak khazix-writer; do
  ln -s "$(pwd)/$skill" "$HOME/.codex/skills/$skill"
done
```

### 方式四：复制安装

复制适合只想固定使用某个版本，不希望本仓库后续改动立刻影响 Agent 的情况。

```bash
mkdir -p ~/.codex/skills
cp -R aliyun-ask ~/.codex/skills/
```

### 常见 Skills 目录

不同工具的目录可能不同，以下是常见约定：

| Agent | 目录示例 |
| --- | --- |
| Codex | `~/.codex/skills/` |
| Claude Code | `~/.claude/skills/` |
| OpenClaw | `~/.openclaw/skills/` |
| 其他兼容 Agent | 以对应工具文档为准 |

如果不确定路径，优先使用“方式一”，让 Agent 根据自己的运行环境安装。

## Validate

本仓库提供一个轻量校验脚本，用于检查每个 skill 是否包含 `SKILL.md`、frontmatter 是否有 `name` 和 `description`、目录名和 skill name 是否一致，以及脚本 shebang/权限是否合理。

```bash
python3 scripts/validate-skills.py
```

GitHub Actions 会在 push 和 pull request 时自动运行同一校验。

## Security

云资源查询类 skill 默认只读。涉及 AWS、阿里云、腾讯云的 skill 均应拒绝创建、删除、修改、启停、授权、解绑等变更类操作。

本仓库不应提交任何真实凭证、账号密钥、访问令牌、查询结果缓存或包含敏感资源信息的临时文件。更多约定见 [SECURITY.md](SECURITY.md)。

## Contributing

新增或修改 skill 前请先阅读 [docs/skill-structure.md](docs/skill-structure.md) 和 [CONTRIBUTING.md](CONTRIBUTING.md)。个人仓库也建议保持 pull request 或本地变更审查习惯，尤其是包含 shell 脚本、云 CLI 命令、网络访问和文件写入的 skill。

## License

本仓库使用 MIT License。详见 [LICENSE](LICENSE)。
