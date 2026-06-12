# 约束与红线（从 SKILL.md §重要约束 拆分）

> 本文件是 `SKILL.md` `## 重要约束` 的独立版本。保留在 SKILL.md 中的只有章节交叉引用。

## 1. 路径处理

- `${PROJECT_ROOT}` 来自 `--path` 参数或用户当前工作目录
- 跨平台：使用 `${PROJECT_ROOT}` 而非硬编码 `/`
- Windows 路径：脚本内部用 `cygpath` 转换（如 Git Bash 环境）

## 2. 方法论定位

- 优先用 `${SKILL_HOME}`（skill 安装时记录的绝对路径）
- 退化：从当前工作目录向上找 5 层

## 3. 资产输出位置（硬性红线）

- **必须**输出到 `${PROJECT_ROOT}/asset-docs/`（目标项目的资产目录）
- **禁止**输出到 `${SKILL_HOME}/` 下的任何目录（包括 `_proc-use/`、`_test-output/` 等 gitignored 过程目录）
- **禁止**输出到 `/tmp/` 或任何临时目录
- **原因**：本 skill 的核心产出是目标项目的正式补充资料，不是 skill 本身的过程产物。写入 gitignored 目录 = 产出从目标项目丢失。
- **验证**：每个 Phase 完成后，orchestrator 必须跑 `find ${PROJECT_ROOT}/asset-docs -name "*.md" | wc -l` 确认资产数 ≥ 预期
- **例外**：仅当目标项目不存在或无法写入时，降级到 `${PROJECT_ROOT}/../<project>-asset-docs/`（同级目录，并在 CHANGELOG 中标注）

## 4. CLAUDE.md 双文件策略

- `CLAUDE.md` ≤ 80 行（轻量索引 + "按需加载"标注）
- `CLAUDE-ASSET.md` 详细（按需 Read）

## 5. 绝对禁止

- 不写硬编码密钥/密码（用 `<REDACTED>`）
- 不写自定义严重度（统一 P0-P3）
- 不省元信息头
- 不省 frontmatter（6 必填 + 2 可选）
- 不省强制列
- **不将资产写入 gitignored 目录**（`_proc-use/`、`_test-output/`、`.v3.*-test/` 等过程目录）—— 非法输出位置
