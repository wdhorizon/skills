# Security Policy

本仓库包含会调用本地 CLI、访问云 API、读写临时文件的 skills。安全默认值是：最小权限、只读优先、敏感信息不入库。

## Supported Use

云资源类 skill 仅用于查询和诊断。任何新增、删除、修改、启停、授权、解绑、发布配置等变更操作都不应放入这些 skill。

## Secrets

不要提交以下内容：

- 云账号 Access Key、Secret、session token。
- CLI profile 配置和 credential 文件。
- `.env`、cookie、refresh token、API key。
- 包含敏感资源信息的查询结果、报告、缓存、截图。

如果误提交了敏感信息：

1. 立即轮换泄露凭证。
2. 从 Git 历史中清理敏感内容。
3. 检查 GitHub Actions、release artifacts 和 forks 是否也暴露了内容。

## Reporting

如果你在本仓库发现安全问题，请通过 GitHub private vulnerability reporting 或私下联系仓库维护者。请不要在公开 issue 中粘贴真实凭证、账号信息或完整云资源清单。

## Local Execution

运行第三方贡献脚本前建议先读代码。尤其关注：

- `curl | sh`、远程脚本执行。
- `rm -rf`、批量删除、覆盖写入。
- 云 CLI 的 create/delete/modify/update/start/stop/authorize/revoke 等命令。
- 上传本地文件、剪贴板、浏览器 cookie 或 SSH key 的逻辑。
