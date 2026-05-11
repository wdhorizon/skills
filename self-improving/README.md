# self-improving

`self-improving` 是一个个人工作流 skill，用于记录纠错、偏好、反思和长期记忆。

## Use Cases

- 用户纠正 agent 输出时，记录可复用的改进点。
- 完成复杂任务后进行简短复盘。
- 把重复出现的偏好和工作方式沉淀到长期记忆。
- 维护 `~/self-improving/` 下的个人记忆结构。

## Requirements

- 不需要额外二进制依赖。
- 默认会读写 `~/self-improving/`。
- 可选地把项目级规则写入 `AGENTS.md`、`SOUL.md` 或 `HEARTBEAT.md`。

## Files

```text
self-improving/
├── SKILL.md
├── setup.md
├── memory-template.md
├── heartbeat-rules.md
├── heartbeat-state.md
├── learning.md
├── operations.md
├── corrections.md
└── ...
```

## Security

这个 skill 处理的是个人偏好和工作记忆。不要把密钥、token、账号凭证、客户数据或其他敏感信息写入记忆文件。
