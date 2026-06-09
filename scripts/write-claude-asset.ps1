# write-claude-asset.ps1 — 写 <TargetDir>\CLAUDE-ASSET.md 资产详情
# 用法：powershell -ExecutionPolicy Bypass -File write-claude-asset.ps1 [-TargetDir <dir>]
#
# 策略：CLAUDE-ASSET.md 是 12 篇资产的"详细地图"，按需 Read
# 配套：write-claude-asset.sh（Mac / Linux / Git Bash）

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

$AssetDir = Join-Path $TargetDir "asset-docs"
if (-not (Test-Path $AssetDir)) {
    Write-Host "WARN: $AssetDir 不存在" -ForegroundColor Yellow
    Write-Host "  请先运行 init-asset-docs.ps1"
    exit 1
}

$ProjectName = Split-Path -Leaf $TargetDir
$Output = Join-Path $TargetDir "CLAUDE-ASSET.md"

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

# 3. 扫 12 篇资产状态
$assetStatus = @{}
$assetName = @{}

00..12 | ForEach-Object {
    $n = "{0:D2}" -f $_
    $pattern = Join-Path $AssetDir "$n-*.md"
    $file = Get-ChildItem -Path $pattern -ErrorAction SilentlyContinue | Select-Object -First 1

    if ($null -ne $file) {
        $content = Get-Content $file.FullName -Raw -Encoding UTF8
        $lines = (Get-Content $file.FullName).Count
        $hasMeta = $content -match '"id":'
        $hasPlaceholder = $content -match '<YYYY-MM-DD>|<团队|<项目名|TODO'

        if ($hasPlaceholder -or ($lines -lt 30) -or (-not $hasMeta)) {
            $assetStatus[$n] = "占位"
        } else {
            $assetStatus[$n] = "✓"
        }
        $assetName[$n] = $file.BaseName
    } else {
        $assetStatus[$n] = "缺失"
        $assetName[$n] = ""
    }
}

# 4. 资产编号 → 名称映射
$names = @{
    "00" = "文档索引"
    "01" = "系统总览"
    "02" = "数据模型与表结构"
    "03" = "后端-Controller接口清单"
    "04" = "后端-Mapper操作清单"
    "05" = "后端-服务与业务逻辑"
    "06" = "后端-安全认证"
    "07" = "前端-页面与组件清单"
    "08" = "前端-状态管理与路由"
    "09" = "静态/多端"
    "10" = "业务流图（端到端）"
    "11" = "技术债与遗留项"
    "12" = "修复建议与优先级"
}

# 5. 生成 CLAUDE-ASSET.md
$date = Get-Date -Format "yyyy-MM-dd"

$content = @"
# $ProjectName — 资产详情

> **按需加载**：本文件是 12 篇资产的"详细地图"。
> 配合 `CLAUDE.md`（轻量索引）使用。
> 生成时间：$date

---

## 1. 资产清单（12 篇）

| 编号 | 资产 | 状态 | 文件 |
|:-:|---|:-:|---|
"@

00..12 | ForEach-Object {
    $n = "{0:D2}" -f $_
    $name = $names[$n]
    $status = $assetStatus[$n]
    if ($status -eq "缺失") {
        $content += "`n| $n | $name | 缺失 | — |"
    } else {
        $fileBase = $assetName[$n]
        $content += "`n| $n | $name | $status | [`${fileBase}.md`](asset-docs/${fileBase}.md) |"
    }
}

$content += @"

> 状态说明：✓ 已生成 / 占位 待填充 / 缺失 未生成

---

## 2. 资产-代码强引用关系

> 任何修改必须保持这些引用关系一致。

| 关系 | 检查方式 |
|---|---|
| 02 ↔ 03 | 03 提到 X 实体 → 02 必有 X 表 |
| 02 ↔ 04 | 实体 ↔ Mapper |
| 03 ↔ 05 | API ↔ Service |
| 03 ↔ 06 | API ↔ 鉴权 |
| 07 ↔ 08 | 组件 ↔ 状态/路由 |
| 10 ↔ 02-09 | 业务流 ↔ 各层资产 |
| 11 ↔ 02-10 | 技术债 ↔ 各层资产 |
| 12 ↔ 11 | 修复建议 ↔ 技术债 |

---

## 3. AI 编程喂入策略

| 任务 | 喂入 |
|---|---|
| 简单 CRUD | `01` + `02` + `03`（最小集） |
| 重构 | + `05` + `11`（推荐集） |
| 修 P0 | + `11` + `12` |
| 完整 | 12 篇（可承担新功能/重构/修 Bug） |

---

## 4. 校验

```bash
# Windows 上需先安装 Git Bash：
bash asset-docs/scripts/validate-all.sh
```

包含 5 类校验：
- `check-meta.sh` — 元信息头 7 字段
- `check-severity.sh` — 严重度 P0-P3
- `check-consistency.sh` — 资产-代码一致性
- `scan-antipatterns.sh` — 反模式扫描
- `validate-all.sh` — 一键跑全部

---

## 5. CI 接入

```yaml
# .github/workflows/docs-validate.yml
name: Docs Validate
on:
  pull_request:
    paths:
      - 'asset-docs/**'
      - 'src/**'
jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run all checks
        run: bash asset-docs/scripts/validate-all.sh
```

---

## 6. 模板与 Prompt

- 模板：`asset-docs\templates\`（12 份 .md.tmpl）
- AI Prompt：`asset-docs\ai-prompts\`（12 份 .md）

---

## 7. 元信息

| 字段 | 值 |
|---|---|
| 项目 | $ProjectName |
| 资产版本 | 1.0.0 |
| 生成时间 | $date |
| 配套 | `asset-docs\` + `CLAUDE.md` |
"@

Set-Content -Path $Output -Value $content -Encoding UTF8

Write-Host "✓ 写入: $Output"
Write-Host "  策略：详细资产地图（按需 Read）"
