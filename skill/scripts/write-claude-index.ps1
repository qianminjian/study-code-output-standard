# write-claude-index.ps1 — 写 <TargetDir>\CLAUDE.md 轻量索引
# 用法：powershell -ExecutionPolicy Bypass -File write-claude-index.ps1 [-TargetDir <dir>]
#
# 策略：CLAUDE.md ≤ 80 行，标注"按需加载 CLAUDE-ASSET.md"
# 配套：write-claude-index.sh（Mac / Linux / Git Bash）

[CmdletBinding()]
param(
    [string]$TargetDir = $null
)

$ErrorActionPreference = "Stop"

# 1. 解析 TargetDir
if ([string]::IsNullOrEmpty($TargetDir)) {
    $TargetDir = (Get-Location).Path
}
if (-not (Test-Path $TargetDir)) {
    Write-Host "ERROR: 目标目录不存在: $TargetDir" -ForegroundColor Red
    exit 1
}

$ProjectName = Split-Path -Leaf $TargetDir
$Output = Join-Path $TargetDir "CLAUDE.md"

# 2. 检测已存在
if (Test-Path $Output) {
    if ([Environment]::UserInteractive) {
        $yn = Read-Host "  $Output 已存在，覆盖？[y/N]"
        if ($yn -notin @("y", "Y")) {
            Write-Host "已跳过"
            exit 0
        }
    } else {
        Write-Host "  $Output 已存在（非交互模式：跳过）"
        exit 0
    }
}

# 3. 写入 CLAUDE.md（≤ 80 行）
$date = Get-Date -Format "yyyy-MM-dd"

$content = @"
# $ProjectName — AI 引导（索引）

> 本文件是**轻量索引**（80 行内），按需加载。
> 完整资产清单见 `CLAUDE-ASSET.md`，反向阅读产出见 `asset-docs\`。

## 必读资产（按角色）

| 角色 | 先读 |
|---|---|
| 接手新人 | `asset-docs\00-文档索引.md` → `01-系统总览.md` → `02-数据模型与表结构.md` |
| 写新功能 | `02-数据模型与表结构` + `03-后端-Controller接口清单` + `05-后端-服务与业务逻辑` |
| 修 Bug | `11-技术债与遗留项` + `12-修复建议与优先级` + `10-业务流图` |
| AI 编程 | 喂 `01+02+03`（最小集）或 `+05+11`（推荐集） |

## 项目约束

<!-- TODO: 编辑此段，描述项目特定约束 -->

## 工作流

### 反向阅读（一次性）
```powershell
# 在 Claude Code 中调用：
/study-code-output-standard
```

### 校验资产
```powershell
# Windows 上需先安装 Git Bash 后跑：
bash asset-docs\scripts\validate-all.sh
```

### 喂 AI 写代码
```
请按 asset-docs\01-系统总览.md、02-数据模型与表结构.md、03-后端-Controller接口清单.md
的规范，实现 XXX 接口。
```

## 按需加载

| 需要看 | 加载文件 |
|---|---|
| 12 篇资产详细清单 | `CLAUDE-ASSET.md` |
| 单篇资产详情 | `asset-docs\<NN>-<name>.md` |
| 模板 | `asset-docs\templates\<NN>-<name>.md.tmpl` |
| AI Prompt | `asset-docs\ai-prompts\<NN>-<name>.md` |
| 方法论 | `asset-docs\references\methodology.md` |
| 反模式 | `asset-docs\references\anti-patterns.md` |

## 反模式禁止（来自 11-技术债）

- ❌ 硬编码密钥/密码
- ❌ SQL 字符串拼接 `${}`
- ❌ CORS `allowedOrigins("*")`
- ❌ 明文传输密码
- ❌ 复制粘贴 perms

## 元信息

| 字段 | 值 |
|---|---|
| 项目 | $ProjectName |
| 资产版本 | 1.0.0 |
| 整理时间 | $date |
"@

Set-Content -Path $Output -Value $content -Encoding UTF8

Write-Host "✓ 写入: $Output"
Write-Host "  策略：轻量索引（按需加载）"
