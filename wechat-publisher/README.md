# wechat-publisher

`wechat-publisher` 用于把 Markdown 文章发布到微信公众号草稿箱，底层基于 `wenyan-cli`。

## Features

- Markdown 转微信公众号格式。
- 上传本地或网络图片到微信图床。
- 支持 wenyan 主题和代码高亮主题。
- 支持发布到公众号草稿箱。

## Requirements

安装 `wenyan-cli`：

```bash
npm install -g @wenyan-md/cli
wenyan --help
```

配置微信公众号凭证：

```bash
export WECHAT_APP_ID=your_wechat_app_id
export WECHAT_APP_SECRET=your_wechat_app_secret
```

还需要确保当前 IP 已加入微信公众号后台白名单。

## Markdown Frontmatter

文章顶部需要包含 wenyan 所需 frontmatter：

```markdown
---
title: 文章标题
cover: ./assets/cover.jpg
author: 作者
source_url: https://example.com
---
```

`title` 和 `cover` 建议始终填写，避免发布阶段失败。

## Usage

```bash
wenyan publish -f article.md -t lapis -h solarized-light
```

## Security

不要把 `WECHAT_APP_ID`、`WECHAT_APP_SECRET`、cookie、草稿缓存或未发布文章内容提交到仓库。
