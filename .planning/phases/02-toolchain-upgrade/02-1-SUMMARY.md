---
phase: 2
plan: 2.1
subsystem: toolchain
tags: [refactor, ci, protocol, watchdog]
requires: []
provides: [function-based-scan, ci-smoke, batch-protocol, agent-watchdog]
affects: [scripts/scan-antipatterns.sh, .github/workflows/, SKILL.md, scripts/agent-watchdog.sh]
tech-stack:
  added: []
  patterns: [bash-functions-over-eval, reusable-workflows, state-machine-recovery]
key-files:
  created:
    - scripts/agent-watchdog.sh
    - .github/workflows/_test-smoke.yml
  modified:
    - scripts/scan-antipatterns.sh
    - .github/workflows/ci.yml
    - SKILL.md
decisions:
  - "scan_label 从 eval 改为函数名引用——消除引号转义链（26 个独立函数，每个保持原版正则）"
  - "@secret-yml 从外部 workaround 收敛为正规函数 _scan_secret_yml——无需额外直接 grep 段"
  - "PROJECT_ROOT 查找循环增加 fixed-point guard 防止无限循环（dirname '.' = '.' 场景）"
  - "agent-watchdog 采用 SIGTERM→5s→SIGKILL 两级 kill 策略，支持 macOS/Linux 双平台"
metrics:
  duration: 696s
  completed_date: "2026-06-12T09:19:33Z"
---

# Phase 2 Plan 2.1: 工具链升级 概要

> scan-antipatterns.sh eval→函数式重构 + CI smoke test + turn 边界恢复协议 + agent stall 自动检测

## 执行概要

Phase 2（工具链升级）的 4 个任务全部完成：24 个 scan_label 调用从 eval 字符串转为独立 bash 函数，新增 CI smoke test 管线，SKILL.md 新增多模块批量执行协议，新增 agent stall 自动检测脚本。

## 完成的任务

| # | 任务 | 类型 | 提交 | 文件 |
|---|------|------|------|------|
| 2.1 | scan-antipatterns.sh eval→函数式重构 | refactor | `b21103c` | `scripts/scan-antipatterns.sh` |
| 2.2 | CI smoke test | feat | `07761be` | `.github/workflows/_test-smoke.yml`, `.github/workflows/ci.yml` |
| 2.3 | turn 边界恢复协议 | docs | `cfd2cd9` | `SKILL.md` |
| 2.4 | agent stall 自动检测脚本 | feat | `fa21486` | `scripts/agent-watchdog.sh` |

## 成功条件验证

| 条件 | 状态 |
|------|:----:|
| scan-antipatterns.sh 24 label 全部保持功能等价（函数式，非 eval） | PASS |
| _test-smoke.yml 语法正确、被 ci.yml 引用 | PASS |
| SKILL.md 新增协议段落完整（§多模块批量执行协议） | PASS |
| agent-watchdog.sh 可独立执行（bash -n 语法通过） | PASS |
| bash tests/run-all.sh 通过 | PASS |

## 技术细节

### Task 2.1 — eval→函数式重构

- 26 个 scan 函数定义（`_scan_*`），每个保持与原 eval 字符串**完全相同**的正则逻辑
- `scan_label()` 接受函数名引用（`$func_name`），通过 `$($func_name)` 调用
- @secret-yml 从外部 30 行 workaround 收敛为 `_scan_secret_yml` 正规函数
- 修复 PROJECT_ROOT 查找循环的 fixed-point 无限循环 bug（`dirname '.'` = `'.'`），增加 `[ "$parent" = "$PROJECT_ROOT" ]` 终止条件
- 原版 `scan_grep` 辅助函数保留不变
- 所有 5 个 info-only 标签（@csrf/@null-pointer/@copy-paste/@feature-envy/@shotgun-surgery）的 `total_labels` 递减逻辑保留

### Task 2.2 — CI smoke test

- `_test-smoke.yml` 含 3 个 smoke step：bash -n 全量脚本检查、scan-antipatterns.sh 空跑、init-asset-docs.sh 临时项目端到端
- `ci.yml` ci-status 依赖链扩展为 `[test, lint, secret-scan, smoke-test]`
- ci-status 报告增加 smoke-test 行并将结果纳入失败判定

### Task 2.3 — turn 边界恢复协议

- 新增 §多模块批量执行协议，位于 §目标行为 与 §串行生成模式 之间
- §A 状态文件定义：`.module-status.json`（worker 维护）、`.batch-progress.json`（编排者维护）
- §B Turn 中断恢复协议：stall / context 溢出 / 用户中断 三种场景的恢复流程
- §C 状态一致性约束：单一写入者、幂等恢复、孤儿清理、聚合排他
- §D 恢复验证：jq 交叉校验 batch 与 module 状态一致性

### Task 2.4 — agent-watchdog.sh

- 双平台支持：macOS（`stat -f%z` / `lsof`）和 Linux（`stat -c%s` / `fuser`）
- 两级 kill：SIGTERM → 5s 等待 → SIGKILL
- stall event JSON 输出含 timestamp/output_file/stall_duration_s/file_size_bytes/pid_killed/action/watchdog 元信息
- 可通过 `WATCHDOG_INTERVAL` / `WATCHDOG_THRESHOLD` 环境变量配置
- 120s 超时等待输出文件创建（防止 agent 未启动时无限等待）

## 偏离计划

### 自动修复的问题

**1. [Rule 1 - Bug] 修复 PROJECT_ROOT 查找循环的无限循环（fixed-point guard）**
- **发现于：** Task 2.1
- **问题：** `while [ "$(dirname "$PROJECT_ROOT")" != "/" ]` 在非 Maven 项目中会无限循环——`dirname "."` = `"."`，条件永远为真
- **修复：** 改为 `while true` + 显式 fixed-point guard `[ "$parent" = "$PROJECT_ROOT" ]` + 根目录 guard `[ "$parent" = "/" ]`
- **修改文件：** `scripts/scan-antipatterns.sh`
- **提交：** `b21103c`

## 已知 Stubs

无。所有实现均为完整功能，无占位符或未连线数据源。

## 威胁标志

无。本次改动不新增网络端点、认证路径、文件访问模式或信任边界变更。

## 自检

- [x] `scripts/agent-watchdog.sh` 存在
- [x] `.github/workflows/_test-smoke.yml` 存在
- [x] `b21103c` 存在 (refactor 2-1)
- [x] `07761be` 存在 (feat 2-2)
- [x] `cfd2cd9` 存在 (docs 2-3)
- [x] `fa21486` 存在 (feat 2-4)
- [x] `bash tests/run-all.sh` 全绿

## Self-Check: PASSED
