# ROADMAP

> study-code-output-standard 路线图
> 最后更新：2026-06-12

## Phase Progress

| Phase | Name | Plans | Completed | Status |
|:-----:|------|:-----:|:---------:|:------:|
| 1 | 可靠性加固 | 2 | 1 | in_progress |
| 2 | 工具链升级 | 4 | 1 | in_progress |
| 3 | 跨平台+文档 | 7 | 1 | in_progress |
| 4 | 新场景覆盖 | 6 | 1 | in_progress |

**Overall**: 4/19 plans completed (21%)

## Phase 1: 可靠性加固

| Plan | Name | Status | Summary |
|:----:|------|:------:|---------|
| 1.1 | 跨模块聚合协议 + check-consistency 语义扩展 | complete | [SUMMARY](phases/01-reliability-hardening/01-1-SUMMARY.md) |

## Phase 2: 工具链升级

| Plan | Name | Status | Summary |
|:----:|------|:------:|---------|
| 2.1 | scan-antipatterns 函数式重构 + CI smoke test + turn 协议 + watchdog | complete | [SUMMARY](phases/02-toolchain-upgrade/02-1-SUMMARY.md) |
| 2.2 | CI smoke test 独立化 | pending | — |
| 2.3 | Turn 边界恢复协议 | pending | — |
| 2.4 | Agent stall 自动检测 | pending | — |

## Phase 3: 跨平台+文档

| Plan | Name | Status | Summary |
|:----:|------|:------:|---------|
| 3.1 | .ps1 Windows 验证 | pending | — |
| 3.2 | troubleshooting.md | complete | included in Plan 3 |
| 3.3 | 06 §7 风险清单格式统一 | pending | — |
| 3.4 | init-asset-docs.sh 路径鲁棒 | pending | — |
| 3.5 | 模块质量对比自动化 | complete | included in Plan 3 |
| 3.6 | v3.5 一键跑脚本 | complete | included in Plan 3 |
| 3.7 | 模块间 P0 去重 | pending | — |

## Phase 4: 新场景覆盖

| Plan | Name | Status | Summary |
|:----:|------|:------:|---------|
| 4.1 | v35-pipeline.sh + quality-compare.sh + agent-watchdog.sh 烟雾测试 + 测试缺口文档 | complete | [SUMMARY](phases/04-new-scenario-coverage/04-1-SUMMARY.md) |
| 4.2 | TypeScript/Node 项目测试 | pending | — |
| 4.3 | Python 项目测试 | pending | — |
| 4.4 | 单体项目测试 | pending | — |
| 4.5 | 100 万行+ 巨项目测试 | pending | — |
| 4.6 | 并发多用户测试 | pending | — |
