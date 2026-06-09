# install.ps1 — Windows PowerShell 安装器
# 用法：
#   powershell -ExecutionPolicy Bypass -File install.ps1 -Personal
#   powershell -ExecutionPolicy Bypass -File install.ps1 -Project
#   powershell -ExecutionPolicy Bypass -File install.ps1 -Path <dir>
#   powershell -ExecutionPolicy Bypass -File install.ps1 -Uninstall
#
# 选项：
#   -Force    覆盖已存在的安装（非交互）

param(
    [switch]$Personal,
    [switch]$Project,
    [string]$Path,
    [switch]$Uninstall,
    [switch]$Force,
    [switch]$Help
)

if ($Help) {
    Write-Host @"
用法：install.ps1 [选项]

选项：
  -Personal    安装到 `$HOME/.claude/skills/study-code-output-standard/
  -Project     安装到当前项目的 .claude/skills/
  -Path <dir>  安装到指定目录
  -Uninstall   卸载
  -Help        显示帮助
"@
    exit 0
}

# 定位 skill 根目录（重构 v2.1：仓库根 = skill 根 = SKILL.md 所在目录）
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$MethodologyDir = $ScriptDir

if (-not (Test-Path "$MethodologyDir\SKILL.md")) {
    Write-Host "ERROR: 找不到 SKILL.md，方法论根目录不正确: $MethodologyDir" -ForegroundColor Red
    exit 1
}

# 卸载
if ($Uninstall) {
    $target = if ($Path) { $Path } else { "$env:USERPROFILE\.claude\skills\study-code-output-standard" }
    if (Test-Path $target) {
        Remove-Item -Recurse -Force $target
        Write-Host "✓ 已卸载: $target"
    } else {
        Write-Host "未找到: $target"
    }
    exit 0
}

# 选择模式
if (-not $Personal -and -not $Project -and -not $Path) {
    Write-Host "请选择安装模式："
    Write-Host "  1) -Personal  安装到 ~/.claude/skills/（个人）"
    Write-Host "  2) -Project   安装到当前项目的 .claude/skills/（项目）"
    Write-Host "  3) -Path DIR  安装到指定目录"
    $choice = Read-Host "选择 [1/2/3]"
    switch ($choice) {
        "1" { $Personal = $true }
        "2" { $Project = $true }
        "3" { $Path = Read-Host "目标目录" }
        default { Write-Host "已取消"; exit 1 }
    }
}

# 计算目标
if ($Personal) {
    $TargetDir = "$env:USERPROFILE\.claude\skills\study-code-output-standard"
} elseif ($Project) {
    $TargetDir = (Get-Location).Path + "\.claude\skills\study-code-output-standard"
} else {
    $TargetDir = $Path
}

# 检查
if (Test-Path $TargetDir) {
    # 修复 P1-09：非交互模式非 -Force 时显式报错
    if ($Force) {
        Write-Host "  -Force 模式：覆盖 $TargetDir"
        Remove-Item -Recurse -Force $TargetDir
    } elseif ([Environment]::UserInteractive) {
        $yn = Read-Host "  $TargetDir 已存在，覆盖？[y/N]"
        if ($yn -notin @("y", "Y")) {
            Write-Host "已取消"
            exit 1
        }
        Remove-Item -Recurse -Force $TargetDir
    } else {
        Write-Host "ERROR: 非交互模式且未指定 -Force，拒绝覆盖" -ForegroundColor Red
        Write-Host "  解决: install.ps1 ... -Force" -ForegroundColor Red
        exit 2
    }
}

# 创建父目录
$parent = Split-Path -Parent $TargetDir
if (-not (Test-Path $parent)) {
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
}

# 尝试创建符号链接（需要开发者模式或管理员）
try {
    New-Item -ItemType SymbolicLink -Path $TargetDir -Target $MethodologyDir -ErrorAction Stop
    Write-Host "✓ 已创建符号链接: $TargetDir -> $MethodologyDir"
} catch {
    # 软链失败：用 copy
    Write-Host "WARN: 符号链接创建失败，改用 copy" -ForegroundColor Yellow
    Copy-Item -Recurse -Path $MethodologyDir -Destination $TargetDir
    Write-Host "✓ 已 copy: $TargetDir"
}

Write-Host ""
Write-Host "==> 安装完成！"
Write-Host ""
Write-Host "下一步："
Write-Host "  1. 重新打开 Claude Code"
Write-Host "  2. 在任意项目根目录运行：claude"
Write-Host "  3. 调用：/study-code-output-standard"
Write-Host ""
Write-Host "卸载：powershell -ExecutionPolicy Bypass -File install.ps1 -Uninstall"
