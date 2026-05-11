# neat-freak

`neat-freak` 用于在开发阶段结束时做知识库和项目文档清理，确保 README、docs、AGENTS/CLAUDE 规则和 agent 记忆与代码保持一致。

## Use Cases

- 开发阶段收尾。
- 同步项目文档和记忆。
- 清理过期 README、docs、CLAUDE.md、AGENTS.md。
- 给新人、下游项目或下一个 agent 做干净交接。
- 删除或合并重复、过时、相互冲突的知识记录。

## Workflow

1. 盘点项目文档、agent 配置和记忆文件。
2. 检查关键文件大小，优先防止规则文档膨胀。
3. 根据变更影响矩阵判断哪些文档层需要同步。
4. 实际修改 README、docs、AGENTS/CLAUDE 或记忆文件。
5. 自检路径、命令、相对时间、交叉项目影响和文档完整性。

## References

```text
neat-freak/
├── SKILL.md
└── references/
    ├── agent-paths.md
    └── sync-matrix.md
```

## Notes

这个 skill 的重点是编辑和删减，不是简单追加变更日志。项目规则文件只保留下次 agent 写代码时必须看到的信息。
