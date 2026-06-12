# study-code-output-standard · Skill v3.5

**一个 AI agent 技能**，通过读代码整理出系统的存量历史资料。
v3.0 串行 7 步法 | v3.5 并行 4 阶段管线 + 4 Worker 认知变体

## Model Versions

| Mode | Project Size | Agent Count | Cross-Asset Insight | Verified |
|------|-------------|:-----------:|---------------------|:--------:|
| **v3.0** | < 100k LOC | 1 (single agent) | No | Multi-project |
| **v3.5** | > 100k LOC | 1 orchestrator + 4 workers | **6 integration debts** | 1 full run (2026-06-12) |

## Quick Start

```bash
# Init asset skeleton for target project
bash scripts/init-asset-docs.sh <target-project>
# Run skill (v3.0 7-step or v3.5 4-stage pipeline)
# Verify output
bash scripts/check-all.sh
```

## Skill Structure

```
SKILL.md                  ← orchestrator doc (624 lines)
references/
├── parallel-mode.md      ← v3.5 implementation detail (116 lines)
├── methodology/           ← methodology docs
└── prompts/               ← per-asset AI prompts
assets/                   ← 14 .md.tmpl templates
scripts/                  ← 8 .sh + 4 .ps1 verification/scanning
tests/                    ← 4 test suites (all green)
docs/
└── design/v3.5-parallel-architecture.md
```

## v3.5 Verified Evidence (2026-06-12)

| Metric | v3.0 baseline | v3.5 | Delta |
|--------|:----------:|:----------:|:-----:|
| 02 Data Model | 183 lines | 222 lines | +21% |
| 03 Controller | 198 lines | ~400 lines | +102% |
| 10 Workflow | 282 lines / 77 refs | 577 lines / 194 refs | +105% / +152% |
| P1 Risks | 17 | 52 | +206% |
| Integration debts | 0 (v3.0 concept absent) | 6 | v3.5 exclusive |

Real AI end-to-end run on devops-message (125 Java files, 8.6K LOC):
10 fully-produced assets (332KB), 174 file:line references, 14 real security risks found.

## Notes

This is a **skill** (not an app). Installed for Claude Code usage. Production-ready for personal use (~1 week remaining for general deployment).

## License

MIT
