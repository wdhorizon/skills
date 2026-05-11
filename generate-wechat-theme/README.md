# generate-wechat-theme

`generate-wechat-theme` 用于根据自然语言需求生成微信公众号排版 CSS 主题。

## Use Cases

- 生成适配微信公众号编辑器的主题 CSS。
- 根据文章调性定制标题、引用、代码块、分割线、表格等样式。
- 为 `wenyan-cli` 或同类 Markdown 转公众号工具准备自定义主题。

## Rules

- 所有 CSS 选择器必须以 `#wenyan` 开头。
- 不主动设置 `font-family`，避免破坏微信内默认字体兼容性。
- 不使用本地图片路径；需要图形装饰时优先使用 Data URI 或 HTTPS 资源。
- 输出应是可保存为 `.css` 的完整样式。

## Example

```text
帮我生成一个适合技术周报的微信公众号 CSS 主题，要求标题克制、代码块清晰、引用块突出。
```

## Files

```text
generate-wechat-theme/
└── SKILL.md
```
