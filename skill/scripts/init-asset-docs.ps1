# init-asset-docs.ps1 — 在项目根创建 asset-docs/ 骨架
# 用法：powershell -ExecutionPolicy Bypass -File init-asset-docs.ps1 [-TargetDir <dir>] [-Force]
#
# 效果：创建 <TargetDir>\asset-docs\ 含 12 篇资产 + 12 模板 + 12 Prompt + 5 脚本 + 3 references
# 跨平台：Windows PowerShell 5.1+ / PowerShell 7+
# 配套：init-asset-docs.sh（Mac / Linux / Git Bash）

[CmdletBinding()]
param(
    [string]$TargetDir = $null,
    [switch]$Force
)

$ErrorActionPreference = "Stop"

# 1. 推断方法论根目录
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

if (-not (Test-Path "$ScriptDir\..\SKILL.md")) {
    # 退化：从当前工作目录向上找
    $cur = (Get-Location).Path
    for ($i = 0; $i -lt 5; $i++) {
        if (Test-Path "$cur\SKILL.md") {
            $ScriptDir = $cur
            break
        }
        $cur = Split-Path -Parent $cur
    }
}

if (-not (Test-Path "$ScriptDir\SKILL.md")) {
    Write-Host "ERROR: 找不到 SKILL.md，方法论根目录不正确: $ScriptDir" -ForegroundColor Red
    exit 1
}

# 2. 解析 TargetDir
if ([string]::IsNullOrEmpty($TargetDir)) {
    $TargetDir = (Get-Location).Path
}
if (-not (Test-Path $TargetDir)) {
    Write-Host "ERROR: 目标目录不存在: $TargetDir" -ForegroundColor Red
    exit 1
}

$MethodologyDir = $ScriptDir
$OutputDir = Join-Path $TargetDir "asset-docs"

Write-Host "==> 方法论根目录: $MethodologyDir"
Write-Host "==> 资产输出目录: $OutputDir"
Write-Host ""

# 3. 检测已有
if (Test-Path $OutputDir) {
    Write-Host "WARN: $OutputDir 已存在" -ForegroundColor Yellow
    if ($Force) {
        Write-Host "  -Force 模式：覆盖"
        Remove-Item -Recurse -Force $OutputDir
    } elseif ([Environment]::UserInteractive) {
        $yn = Read-Host "  是否覆盖？[y/N]"
        if ($yn -notin @("y", "Y")) {
            Write-Host "已取消"
            exit 1
        }
        Remove-Item -Recurse -Force $OutputDir
    } else {
        # 非交互模式非 -Force：保留已有
        Write-Host "  非交互模式：保留已有内容，跳过"
        Write-Host ""
        Write-Host "==> 完成（已有 asset-docs/）"
        exit 0
    }
}

# 4. 创建目录结构
Write-Host "==> 创建目录结构"
New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $OutputDir "templates") -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $OutputDir "ai-prompts") -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $OutputDir "references") -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $OutputDir "scripts") -Force | Out-Null

# 5. 复制 12 篇资产占位（带 frontmatter）
Write-Host "==> 复制 12 份资产占位"
$templatesDir = Join-Path $MethodologyDir "docs\templates"
$skipPattern = "^(CLAUDE|CHANGELOG)"

Get-ChildItem -Path $templatesDir -Filter "*.md.tmpl" | ForEach-Object {
    $name = $_.BaseName  # 去后缀 .md.tmpl
    if ($name -notmatch $skipPattern) {
        $target = Join-Path $OutputDir "$name.md"
        Copy-Item -Path $_.FullName -Destination $target -Force
        Write-Host "  + $name.md"
    }
}

# 6. 复制 templates/
Write-Host "==> 复制 templates\"
Copy-Item -Path (Join-Path $templatesDir "*") `
          -Destination (Join-Path $OutputDir "templates") `
          -Recurse -Force

# 7. 复制 ai-prompts/
Write-Host "==> 复制 ai-prompts\"
$aiPromptsDir = Join-Path $MethodologyDir "docs\ai-prompts"
if (Test-Path $aiPromptsDir) {
    Copy-Item -Path (Join-Path $aiPromptsDir "*") `
              -Destination (Join-Path $OutputDir "ai-prompts") `
              -Recurse -Force
}

# 8. 复制校验脚本
Write-Host "==> 复制 scripts\"
$scriptsSrcDir = Join-Path $MethodologyDir "docs\scripts"
$scriptsDstDir = Join-Path $OutputDir "scripts"
$scripts = @("check-meta.sh", "check-severity.sh", "check-consistency.sh", "scan-antipatterns.sh", "validate-all.sh")
foreach ($s in $scripts) {
    $src = Join-Path $scriptsSrcDir $s
    if (Test-Path $src) {
        Copy-Item -Path $src -Destination (Join-Path $scriptsDstDir $s) -Force
    }
}

# 9. 复制 references/
Write-Host "==> 复制 references\"
$referencesDir = Join-Path $MethodologyDir "skill\references"
if (Test-Path $referencesDir) {
    Copy-Item -Path (Join-Path $referencesDir "*") `
              -Destination (Join-Path $OutputDir "references") `
              -Recurse -Force
}

# 10. 创建资产变更日志
$date = Get-Date -Format "yyyy-MM-dd"
$changelog = @"
# Asset Docs Changelog

## [1.0.0] - $date
### 全部
- 初版：12 篇资产 + 12 模板 + 12 Prompt + 5 脚本 + 3 references
"@
Set-Content -Path (Join-Path $OutputDir "CHANGELOG.md") -Value $changelog -Encoding UTF8

# 11. 创建资产说明 README
$readme = @"
# Asset Docs — 反向阅读产出

> 由 `study-code-output-standard` skill 生成。
> 整理时间：$date
> 目标项目：$TargetDir

## 校验

``````powershell
bash scripts/validate-all.sh
``````

(Windows 上需先安装 Git Bash)

## 目录结构

```
asset-docs/
├── 00-文档索引.md
├── ... (01-12)
├── CHANGELOG.md
├── templates\      ← 12 份可填充模板
├── ai-prompts\     ← 12 份 AI Prompt
├── references\     ← 方法论摘要
└── scripts\        ← 5 个校验脚本
```
"@
Set-Content -Path (Join-Path $OutputDir "README.md") -Value $readme -Encoding UTF8

Write-Host ""
Write-Host "==> 完成！"
Write-Host ""
Write-Host "下一步："
Write-Host "  1. 在 Claude Code 中调用 /study-code-output-standard 继续抽取"
Write-Host "  2. 或手动填充各 .md 文件"
Write-Host "  3. 跑校验：bash $OutputDir\scripts\validate-all.sh"
