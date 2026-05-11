# skill-vetter

`skill-vetter` 用于安装或运行第三方 skill 前做安全审查。

## Use Cases

- 从 GitHub、ClawdHub 或其他来源安装 skill 前审查内容。
- 检查 skill 是否读取凭证、访问敏感目录或执行高风险命令。
- 评估网络访问、文件读写和依赖安装范围是否合理。

## Review Focus

- 来源是否可信，维护是否活跃。
- 是否包含混淆代码、远程脚本执行或未知二进制。
- 是否读取 `~/.ssh`、云厂商 credentials、浏览器 cookie 等敏感位置。
- 是否调用创建、删除、修改、授权、上传等高风险操作。
- 所需权限是否符合 skill 声称用途。

## Usage

```text
帮我审查这个 GitHub 仓库里的 skill 是否可以安装。
```

审查结果应包含风险等级、发现的问题、所需权限和是否建议安装。

## Files

```text
skill-vetter/
├── SKILL.md
└── _meta.json
```
