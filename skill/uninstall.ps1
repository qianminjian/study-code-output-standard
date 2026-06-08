# uninstall.ps1 — Windows 卸载
# 用法：powershell -ExecutionPolicy Bypass -File uninstall.ps1

$candidates = @(
    "$env:USERPROFILE\.claude\skills\study-code-output-standard",
    (Get-Location).Path + "\.claude\skills\study-code-output-standard"
)

$found = $false
foreach ($c in $candidates) {
    if (Test-Path $c) {
        $found = $true
        if ((Get-Item $c).Attributes -band [IO.FileAttributes]::ReparsePoint) {
            Remove-Item -Force $c
            Write-Host "✓ 已删除符号链接: $c"
        } else {
            Remove-Item -Recurse -Force $c
            Write-Host "✓ 已删除目录: $c"
        }
    }
}

if (-not $found) {
    Write-Host "未找到安装，跳过"
}
