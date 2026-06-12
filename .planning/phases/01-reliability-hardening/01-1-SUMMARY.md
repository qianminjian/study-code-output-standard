---
phase: "01"
plan: "1"
subsystem: "skill-infra"
tags: ["reliability", "cross-module", "semantic-checks", "aggregation"]
requires: []
provides: ["cross-module-aggregation-protocol", "cross-asset-semantic-checks"]
affects: ["references/", "scripts/check-consistency.sh"]
tech-stack:
  added: []
  patterns: ["INFO/WARN non-blocking checks", "cross-asset semantic validation"]
key-files:
  created: ["references/cross-module-aggregation.md"]
  modified: ["scripts/check-consistency.sh"]
decisions:
  - "4 项新增检查全部设为 INFO/WARN 级别，不阻塞 CI，与 v2.5 风格一致"
  - "00-CROSS-SECURITY.md 仅在多模块或有 P0 风险时产出，单模块无风险跳过"
  - "check-consistency.sh 新增检查使用与现有检查一致的 grep/awk 模式，保持 v2.5 风格"
metrics:
  duration: ""
  task_count: 2
  file_count: 2
  completed_date: "2026-06-12"
---

# Phase 1 Plan 1: 可靠性加固 Summary

> 跨模块一致性协议 + 语义检查全覆盖，为多模块项目提供跨资产自动校验能力。

## Execution Summary

2 个任务全部完成，0 处偏离。在同一波次中原子化提交。

**目标**：为多模块项目建立跨资产一致性校验机制——定义编排者聚合阶段的产出规范，同时扩展 check-consistency.sh 脚本新增 4 项跨资产语义检查。

---

## Task 1.1: cross-module-aggregation.md

**产出**：`references/cross-module-aggregation.md`（359 行）

定义了编排者在所有 worker 完成后的聚合阶段产出规范：

- **聚合触发条件**：模块数 >= 2，Phase 1-4 全部完成
- **聚合输入**：必读全部上游资产（01-13）
- **产物 A — 00-CROSS-MODULE.md**：全局技术栈汇总 + 安全风险 Top 10 + Feign 调用链矩阵 + 反模式去重 + 全局安全评级 + 跨模块一致性校验清单
- **产物 B — 00-CROSS-SECURITY.md**：全局威胁面 + 鉴权覆盖矩阵 + 跨模块认证一致性 + SQL 注入风险汇总 + 合规检查清单（仅多模块/有 P0 时产出）
- **编排者执行流程**：完整流程图 + 质量门禁清单

与现有 `parallel-mode.md` §D 变体 D（Aggregate）一脉相承，提供具体模板而非仅给原则。

**Commit**：`dc43183`

---

## Task 1.2: check-consistency.sh 扩展

**产出**：`scripts/check-consistency.sh`（269 行，+123 行）

在已有 6 项检查基础上新增 4 项跨资产语义检查（v2.7）：

| # | 检查项 | 级别 | 涉及资产 |
|---|--------|:---:|------|
| 7 | 03 端点路径 → 05 Service 方法引用映射 | INFO/WARN | 03, 05 |
| 8 | 02 ⚠️ No DDL 表 → 05 业务逻辑说明 | INFO/WARN | 02, 05 |
| 9 | 04 SQL 注入标记 → 06 §7 风险条目收录 | INFO/WARN | 04, 06 |
| 10 | 03 公开端点数 ↔ 06 无鉴权端点引用一致性 | INFO/WARN | 03, 06 |

**设计决策**：
- 全部 INFO/WARN 级别，不阻塞（与 v2.5 风格一致）
- 资产文件缺失时优雅跳过（不报错）
- 覆盖率 < 70% 时输出 WARN 及具体未覆盖项
- 使用与现有检查一致的 grep/awk 模式

**Commit**：`36b79f8`

---

## Verification

```bash
bash tests/run-all.sh
```

```
  通过: 3
  失败: 0
==> tests/run-all.sh: 全部 3 个测试套件通过
```

- `init-validate.test.sh`：8/8 通过
- `secrets.test.sh`：4/4 通过
- `no-leak-path.test.sh`：4/4 通过

`bash -n scripts/check-consistency.sh` 语法检查通过，无语法错误。

---

## Deviations from Plan

None — plan executed exactly as written.

---

## Threat Flags

None — no new network endpoints, auth paths, file access patterns, or trust boundary changes introduced.

---

## Known Stubs

None — all content is substantive, no placeholders or TODO markers.

---

## Self-Check

| Item | Status | Evidence |
|------|:------:|------|
| `references/cross-module-aggregation.md` | PASSED | 359 lines, git commit dc43183 |
| `scripts/check-consistency.sh` (modified) | PASSED | 269 lines, git commit 36b79f8 |
| `tests/run-all.sh` | PASSED | 3/3 test suites pass |
| `bash -n` syntax check | PASSED | No errors |
