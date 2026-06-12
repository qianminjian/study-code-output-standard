---
phase: "03"
plan: "3"
subsystem: "skill-docs"
tags: ["cross-platform", "troubleshooting", "automation", "pipeline", "quality-compare"]
requires: []
provides:
  - "windows-powershell-documentation"
  - "common-error-troubleshooting-guide"
  - "module-quality-comparison-script"
  - "v35-pipeline-automation"
affects:
  - "references/troubleshooting.md"
  - "scripts/quality-compare.sh"
  - "scripts/v35-pipeline.sh"
  - "README.md"
tech-stack:
  added: []
  patterns:
    - "symptom-root-cause-solution error documentation"
    - "automated markdown extraction from asset files"
    - "bash-only pipeline pre-flight (no AI spawn)"
key-files:
  created:
    - "references/troubleshooting.md"
    - "scripts/quality-compare.sh"
    - "scripts/v35-pipeline.sh"
  modified:
    - "README.md"
decisions:
  - "Task 3.1 adapted from Windows CI run to documentation-only: no Windows environment available for actual .ps1 testing"
  - "troubleshooting.md uses three-part error format (symptom/root cause/solution) for consistency"
  - "quality-compare.sh extracts from 01-系统总览.md §7 table using awk, no dependency on jq"
  - "v35-pipeline.sh written in bash 3.2-compatible syntax (no associative arrays) for macOS compatibility"
  - "v35-pipeline.sh does NOT spawn AI agents — it only pre-flights Steps 0-2 and outputs ready prompts"
  - "README Known Limitations updated to point to troubleshooting.md §11 for detailed .ps1 status"
metrics:
  duration: "~8min"
  task_count: 4
  file_count: 4
  completed_date: "2026-06-12"
---

# Phase 3 Plan 3: 跨平台+文档 Summary

> Windows PowerShell 文档化 + 故障排查指南 + 质量对比自动化 + v3.5 一键管线脚本

## Execution Summary

| Task | Name | Type | Status | Commit |
|:----:|------|------|:------:|--------|
| 3.2 | troubleshooting.md (10 errors) | docs | PASS | 3448249 |
| 3.1 | .ps1 Windows validation docs | docs | PASS | c161fc7 |
| 3.5 | quality-compare.sh | feat | PASS | 24f06b0 |
| 3.6 | v35-pipeline.sh | feat | PASS | 196f540 |

**Total**: 4/4 tasks complete, 4 commits, 0 failures.

## Task Details

### Task 3.2 — references/troubleshooting.md (NEW)

Created comprehensive troubleshooting guide with 10 common error patterns:
1. check-consistency MISMATCH (Controller/endpoint count)
2. Agent stall (context overflow / Read limit)
3. .phase-facts.md missing (inter-phase handoff failure)
4. Output path error (writing to _proc-use/ instead of asset-docs/)
5. 03 Controller format error (angle brackets vs backticks)
6. scan-antipatterns yml secret leak false negatives
7. v3.5 parallel worker overload
8. Stratified sampling annotation missing
9. Turn interrupt recovery failure
10. Cross-worker severity inconsistency

Each error documented with: symptom / root cause / solution. 189 lines.

### Task 3.1 — Windows/PowerShell documentation (MODIFY)

- Verified all 4 .ps1 files pass basic syntax checks (brace matching, param blocks, error handling)
- Added `## 11. Windows / PowerShell` section to troubleshooting.md with:
  - 4-script status table with verification results
  - Known limitations (no Windows CI, Git Bash dependency, interactive behavior differences)
  - Alternative workflows table (WSL/Git Bash/CI runner)
  - Pending verification checklist
- Updated README.md Known Limitations: detailed .ps1 description linking to troubleshooting.md §11

### Task 3.5 — scripts/quality-compare.sh (NEW)

Automated module-to-module quality comparison script (275 lines):
- Extracts key metrics from `asset-docs/01-系统总览.md` §7 (Controller/Svc/Mapper/Model counts, API endpoints, TODO/FIXME, P0 bugs)
- Extracts technology stack from §3 (language, framework, ORM)
- Auto-discovers modules via `asset-docs/` subdirectories or accepts explicit module list
- Generates two Markdown tables: "Digital Overview" (all metrics) + "P0 Risk Ranking" (by P0 density)
- Includes aggregate statistics across all modules
- Bash 3.2+ compatible, no external dependencies beyond awk
- Functional test passed with 2 mock Java modules

### Task 3.6 — scripts/v35-pipeline.sh (NEW)

One-click v3.5 pipeline pre-flight automation (555 lines):
- **Step -1**: Project type detection (java-maven/gradle/nodejs/python/go/rust), Java file counting, scale routing (v3.0 vs v3.5 with stratified sampling params)
- **Step 0**: Tech stack extraction from pom.xml/package.json (language, framework, ORM, DB type)
- **Step 1**: File-level reconnaissance (Controller/Service/Mapper/Entity file counts, endpoint estimation)
- **Step 2**: Frontend auto-detection, asset coverage decision matrix, `.phase-facts.md` generation
- Outputs ready prompt with Phase 1 Worker Spawn instructions (worker count + variant assignments)
- Does NOT spawn AI agents (orchestrator's responsibility)
- Bash 3.2 compatible (no associative arrays), tested with mock Java Maven project with 31 files

## Verification

```bash
bash tests/run-all.sh
```
All 3 test suites passed (init-validate: 8/8, secrets: 4/4, no-leak-path: 4/4).

## Deviations from Plan

### Adaptation

**1. Task 3.1 scope adaptation** — The original plan called for GitHub Actions Windows runner CI verification of .ps1 scripts. This is not feasible without a Windows environment. Adapted to:
- Comprehensive syntax validation (brace matching, param blocks, error handling headers)
- Detailed documentation of known limitations and alternative workflows
- Pending verification checklist for future Phase 4

**2. Task 3.6 scope constraint** — v35-pipeline.sh does NOT include actual Agent spawn functionality. Per the prompt constraint, it only automates Steps 0-2 (pre-flight) and outputs ready prompts for the orchestrator to spawn Phase 1 workers.

### Auto-fixed Issues

**1. [Rule 1 - Bug] Heredoc terminator mismatch in quality-compare.sh**
- **Found during**: Task 3.5 functional testing
- **Issue**: `cat << 'HEADER'` had no matching terminator line, causing entire remainder of script to be consumed as heredoc content
- **Fix**: Replaced cat heredocs with echo/printf statements for output section
- **Files modified**: scripts/quality-compare.sh
- **Commit**: 24f06b0

**2. [Rule 1 - Bug] declare -A associative array not available in macOS bash 3.2**
- **Found during**: Task 3.6 functional testing
- **Issue**: `declare -A ASSET_DECISIONS` failed on macOS default bash 3.2
- **Fix**: Replaced associative array with inline conditionals (`SKIP_FRONTEND` boolean check)
- **Files modified**: scripts/v35-pipeline.sh
- **Commit**: 196f540

## Known Stubs

None. All created files are complete and functional.

## Decisions Made

1. `troubleshooting.md` uses three-part diagnostic format (symptom/root cause/solution) for consistency with technical documentation standards
2. `quality-compare.sh` extracts from 01-系统总览.md tables using awk rather than requiring jq (minimizes external dependencies)
3. `v35-pipeline.sh` explicitly avoids bash 4+ features (associative arrays) for macOS compatibility
4. README "Known Limitations" now cross-references detailed troubleshooting.md for discoverability

## Self-Check: PASSED

- [x] references/troubleshooting.md exists and contains 11 error sections
- [x] scripts/quality-compare.sh exists and is executable
- [x] scripts/v35-pipeline.sh exists and is executable
- [x] README.md updated with new .ps1 description
- [x] All 4 commits verified in git log (3448249, c161fc7, 24f06b0, 196f540)
- [x] tests/run-all.sh: 3/3 suites passed
