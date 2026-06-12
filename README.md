# study-code-output-standard · Skill v3.5

**一个 AI agent 技能**，通过读代码整理出系统的存量历史资料。
v3.0 串行 7 步法 | v3.5 并行 4 阶段管线 + 4 Worker 认知变体

[![CI](https://github.com/qianminjian/study-code-output-standard/actions/workflows/ci.yml/badge.svg)](https://github.com/qianminjian/study-code-output-standard/actions/workflows/ci.yml)

## Deployment Status

| Target | Status |
|--------|:-----:|
| **个人使用** (macOS/Linux) | ✅ 生产级 (9/10) |
| **通用化** (all platforms) | ✅ 基本就绪 (8/10) |

## Model Versions

| Mode | Project Size | Agent Count | Cross-Asset Insight | Verified |
|------|-------------|:-----------:|---------------------|:--------:|
| **v3.0** | < 100k LOC | 1 (single agent) | No | Multi-project |
| **v3.5** | > 100k LOC | 1 orchestrator + 4 workers | **6 integration debts** | 1 full run (2026-06-12) |

## Quick Start

```bash
git clone git@github.com:qianminjian/study-code-output-standard.git
cd study-code-output-standard
bash scripts/init-asset-docs.sh <target-project>
bash scripts/check-all.sh   # verify output
bash tests/run-all.sh        # run test suite
```

## Skill Structure

```
SKILL.md                  ← orchestrator doc (624 lines)
references/
├── parallel-mode.md      ← v3.5 implementation detail (116 lines)
├── 02-infer-mode.md      ← DDL-less table inference guide (new)
├── methodology/           ← methodology docs
└── prompts/               ← per-asset AI prompts
assets/                   ← 14 .md.tmpl templates
scripts/                  ← 8 .sh + 4 .ps1 (PS1 untested: needs Windows)
tests/                    ← 4 test suites
docs/
└── design/v3.5-parallel-architecture.md (47KB)
```

## v3.5 Verified Evidence (2026-06-12)

| Metric | v3.0 baseline | v3.5 | Delta |
|--------|:----------:|:----------:|:-----:|
| 02 Data Model | 183 lines | 222 lines | +21% |
| 03 Controller | 198 lines | ~400 lines | +102% |
| 10 Workflow | 282 lines / 77 refs | 577 lines / 194 refs | +105% / +152% |
| P1 Risks | 17 | 52 | +206% |
| Integration debts | 0 (v3.0 concept absent) | **6** | v3.5 exclusive |

## Known Limitations

| Limitation | Impact | Mitigation |
|---|---|---|
| `.ps1` scripts syntax-validated but untested on Windows | 4 PowerShell scripts (181-213 lines each) pass brace-matching/param/error-handling checks but lack Windows CI verification | Use `.sh` scripts via WSL/Git Bash; Windows CI gate pending (see `references/troubleshooting.md §11`) |
| 1-project verification (v3.5) | Statistical confidence low | Documented in CHANGELOG; more projects welcome |
| `${VAR}` refs in yml scan trigger false positives | Extra human review lines | Head-limited to 15 lines; review scope bounded |

## License

MIT
