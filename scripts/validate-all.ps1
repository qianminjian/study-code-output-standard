# validate-all.ps1 — 一键跑所有校验（Windows）
# 用法：powershell -ExecutionPolicy Bypass -File validate-all.ps1 [-TargetDir <dir>]
#
# 策略：复用同目录下的 bash 脚本（需先安装 Git Bash）
# 配套：validate-all.sh（Mac / Linux / Git Bash）

[CmdletBinding()]
param(
    [string]$TargetDir = $null
)

$ErrorActionPreference = "Stop"

# 1. 解析 TargetDir
if ([string]::IsNullOrEmpty($TargetDir)) {
    $TargetDir = (Get-Location).Path
}

$AssetDir = Join-Path $TargetDir "asset-docs"
if (-not (Test-Path $AssetDir)) {
    Write-Host "ERROR: $AssetDir 不存在" -ForegroundColor Red
    Write-Host "  请先运行 init-asset-docs.ps1"
    exit 1
}

# 2. 检查 bash 可用
$bashPath = (Get-Command bash -ErrorAction SilentlyContinue)
if ($null -eq $bashPath) {
    Write-Host "ERROR: bash 不可用" -ForegroundColor Red
    Write-Host "  Windows 上需先安装 Git for Windows（含 Git Bash）：https://git-scm.com/download/win"
    exit 1
}

# 3. 顺序跑 4 类校验
Write-Host "================================"
Write-Host " 1/4 元信息头校验"
Write-Host "================================"
& bash "$AssetDir\scripts\check-meta.sh"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host ""
Write-Host "================================"
Write-Host " 2/4 严重度校验"
Write-Host "================================"
& bash "$AssetDir\scripts\check-severity.sh"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host ""
Write-Host "================================"
Write-Host " 3/4 一致性校验"
Write-Host "================================"
$env:SRC_DIR = Join-Path $TargetDir "src"
& bash "$AssetDir\scripts\check-consistency.sh"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host ""
Write-Host "================================"
Write-Host " 4/4 反模式扫描"
Write-Host "================================"
$env:SRC_DIR = Join-Path $TargetDir "src"
$env:XML_DIR = Join-Path $TargetDir "src\main\resources\mybatis"
& bash "$AssetDir\scripts\scan-antipatterns.sh"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host ""
Write-Host "==> 全部校验通过"
