# hot-monitor

`hot-monitor` 用于搜索和分析中文、英文多个来源的热点内容，并生成结构化报告。

## Features

- 国际来源：Bing、Google、DuckDuckGo、HackerNews。
- 中文来源：搜狗、Bilibili、微博。
- 可选 Twitter/X 搜索。
- 支持把 JSON 搜索结果整理为 Markdown 报告。

## Requirements

推荐 Python 3.12 或 3.13。

```bash
pip install -r scripts/requirements.txt
```

Twitter/X 搜索需要额外配置：

```bash
export TWITTER_API_KEY=your_key
```

## Usage

```bash
python3 scripts/search_web.py "AI programming" --sources bing,hackernews
python3 scripts/search_china.py "AI编程" --sources sogou,bilibili
python3 scripts/search_twitter.py "OpenAI"  # optional
```

生成报告：

```bash
python3 scripts/search_web.py "AI programming" | python3 scripts/generate_report.py
```

## Files

```text
hot-monitor/
├── SKILL.md
├── references/
│   ├── analysis-guide.md
│   └── search-sources.md
└── scripts/
    ├── generate_report.py
    ├── requirements.txt
    ├── search_china.py
    ├── search_twitter.py
    └── search_web.py
```

## Notes

脚本会访问外部搜索源。运行前请确认网络环境、频率限制和 API key 使用方式符合你的要求。
