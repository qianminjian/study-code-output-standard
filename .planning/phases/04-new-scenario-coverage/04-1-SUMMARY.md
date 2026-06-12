---
phase: 4
plan: 1
subsystem: smoke-test
type: verification
autonomous: true
wave: 1
tags: [smoke-test, v35-pipeline, quality-compare, agent-watchdog, test-coverage]
depends_on: [phase-3]
requires: [v35-pipeline.sh, quality-compare.sh, agent-watchdog.sh]
provides: [phase-4-smoke-coverage, test-gap-documentation]
affects: [_proc-use/_test-state/test-coverage.md]
tech-stack:
  added: []
  patterns: [bash-smoke-testing, stall-detection, quality-comparison]
key-files:
  created:
    - _proc-use/_test-state/test-coverage.md
  modified: []
decisions:
  - Phase 4 smoke tests executed against 2 real Java projects (demo-hello small, devops-task medium)
  - Frontend/TypeScript/Python testing deferred due to no available test projects
  - agent-watchdog.sh verified working with 1s interval / 3s threshold on macOS
metrics:
  duration: ~3min
  completed_date: 2026-06-12
---

# Phase 4 Plan 1: 新场景覆盖 烟雾测试 总结

**一句话：** v35-pipeline.sh + quality-compare.sh + agent-watchdog.sh 三大脚本在真实 Java 项目上烟雾测试全部通过，前端/TypeScript/Python 测试因缺素材记录为已知缺口。

---

## 任务执行

### Task 4.1 — v35-pipeline.sh + quality-compare.sh 烟雾测试

**v35-pipeline.sh (demo-hello, 7 Java / 218 行)**

- Step -1 规模检测：正确识别 java-maven，4 个 Java 文件 → v3.0/small 模式路由
- Step 0 启动确认：正确提取 Java / Maven / Spring Boot 技术栈
- Step 1 勘探：Controller=2, Service=0, Mapper=0
- Step 2 分类：前端检测到 1 个 HTML 文件，7 个 Phase 1 Worker，10a/10b 不拆分
- `.phase-facts.md` 正确生成，包含完整的规模/技术栈/勘探/分类/Pipeline 状态表格

**quality-compare.sh (devops-task, 123 Java / 9K 行)**

- 成功从 `01-系统总览.md` §7 提取：Ctrl=6, Svc=1, Mapper=5, Entity=1055, DB表=45, 端点=39
- 输出有效 Markdown 对比表（模块名/语言/框架/ORM/各项数字）
- P0 风险排序正确：0 个 Bug → 0.00% 密度 → 绿色低风险
- 聚合统计正确：模块总数、各项合计

### Task 4.2 — agent-watchdog.sh 失速检测验证

- 创建哑进程模拟 stall（写 2 行后永久休眠）
- 以 `WATCHDOG_INTERVAL=1 WATCHDOG_THRESHOLD=3` 参数运行
- 3 秒内正确检测到文件大小无变化
- JSON stall event 完整输出（event/timestamp/file_size/pid_killed/action/watchdog 诊断）
- SIGTERM → 进程成功终止
- **支持的参数**：通过环境变量 `WATCHDOG_INTERVAL` / `WATCHDOG_THRESHOLD` 控制间隔和阈值（非 CLI flag）

### Task 4.3 — 测试覆盖缺口文档

- 创建 `_proc-use/_test-state/test-coverage.md`
- 记录已验证项：tests/ 下 3 个套件（16 项）全部通过 + Phase 4 新增 3 个烟雾测试
- 记录已知缺口：前端/TypeScript/Python 项目测试（无素材）、.ps1 Windows CI（无环境）、多模块聚合（待准备）
- 记录 quality-compare.sh 已知限制：不支持 project-root/asset-docs/ 直接布局

---

## 成功标准

| 标准 | 状态 |
|------|:----:|
| v35-pipeline.sh Step -1/0/1/2 全部完成 | PASS |
| v35-pipeline.sh 规模路由决策正确（v3.0/small） | PASS |
| quality-compare.sh 生成有效 Markdown 对比表 | PASS |
| agent-watchdog.sh 失速检测触发（3s 内） | PASS |
| agent-watchdog.sh JSON event 输出正确 | PASS |
| agent-watchdog.sh 进程终止成功 | PASS |
| tests/run-all.sh 全部通过 | PASS |
| 无 SKILL.md 修改 | PASS |

---

## 偏离计划

无 — 计划按预期执行。所有三个任务按规范完成。

---

## 已知桩（Stubs）

无 — 所有脚本功能已完整实现并验证。

---

## 威胁标记

无新增安全表面 — 本次执行仅验证现有脚本，未添加新端点/认证路径/文件访问模式。

---

## 自检查

- [x] `_proc-use/_test-state/test-coverage.md` 存在
- [x] tests/run-all.sh 全部通过
- [x] v35-pipeline.sh 输出验证通过
- [x] quality-compare.sh 输出验证通过
- [x] agent-watchdog.sh 失速检测验证通过
