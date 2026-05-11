# Contributing

这个仓库主要服务个人日常使用，但按开源项目方式维护。任何新增 skill 都应保持结构清晰、依赖明确、安全边界可审查。

## Add A Skill

1. 新建 kebab-case 目录，例如 `my-skill/`。
2. 添加 `SKILL.md`，并写好 frontmatter 中的 `name` 和 `description`。
3. 如有外部命令、网络访问、云 API 或文件写入，补充 `README.md`。
4. 把参考资料放入 `references/`，辅助脚本放入 `scripts/`。
5. 运行校验：

```bash
python3 scripts/validate-skills.py
```

## Review Checklist

提交前检查：

- `SKILL.md` 是否能独立说明何时使用、如何使用、有什么限制。
- 是否误提交了密钥、token、profile、账号 ID、查询结果或缓存。
- 脚本是否有 shebang 和用法说明。
- 云资源相关脚本是否严格只读。
- README 中的安装命令、依赖和示例是否仍然准确。

## Style

- 文档可使用中文，命令、文件名和 API 名称保持原文。
- 优先使用 Markdown 表格和短示例，避免大段重复说明。
- 参考资料可以详细，但主 `SKILL.md` 应保持工作流清楚、规则明确。
- 不引入不必要的依赖；能用标准库完成的校验脚本优先用标准库。

## Sensitive Data

不要提交：

- 云厂商 Access Key、Secret Key、session token。
- `.env`、本地 profile、临时 credential 文件。
- 含业务资源名称、账号 ID、IP、域名、Bucket、实例 ID 的查询结果。
- 发布工具的 cookie、token 或草稿内容缓存。

发现敏感信息已进入历史时，不要只删除当前文件，应重写历史并轮换相关凭证。
