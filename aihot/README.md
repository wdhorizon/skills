# aihot

`aihot` 用于查询 AI HOT 的中文 AI 资讯、日报、精选动态和分类条目。

## Features

- 查询最新 AI HOT 日报。
- 查询最近 7 天精选或全部 AI 动态。
- 按模型发布、产品发布、行业动态、论文研究、技巧观点等分类过滤。
- 按关键词搜索 OpenAI、Anthropic、Google、Sora、GPT 等相关动态。
- 输出中文 Markdown 简报。

## Requirements

- `curl`
- `jq`
- 可访问 `https://aihot.virxact.com`

调用 `/api/public/*` API 时必须设置浏览器 User-Agent，否则默认 curl UA 可能被 403 拦截。

```bash
UA="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
curl -sH "User-Agent: $UA" "https://aihot.virxact.com/api/public/items?mode=selected&take=20"
```

## Usage

适合这些请求：

```text
今天 AI 圈有什么？
看一下 AI HOT 精选。
最近一周有什么 AI 论文？
OpenAI 最近发布了什么？
给我今天的 AI 日报。
```

## Files

```text
aihot/
└── SKILL.md
```

## Notes

`items` API 最多返回最近 7 天内容。更早日期应查询日报归档或指定日期日报。
