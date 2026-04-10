# AI 人生记录器 - 提交并推送到 GitHub

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  AI 人生记录器 - 提交代码到 GitHub" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 检查是否在项目目录
if (-not (Test-Path "pubspec.yaml")) {
    Write-Host "错误：未找到 pubspec.yaml 文件" -ForegroundColor Red
    Write-Host "请确保在正确的目录运行此脚本" -ForegroundColor Yellow
    pause
    exit 1
}

Write-Host "1. 检查 Git 状态..." -ForegroundColor Yellow
$changes = git status --porcelain
if ($changes.Count -eq 0) {
    Write-Host "   ✓ 没有需要提交的文件更改" -ForegroundColor Green
} else {
    Write-Host "   发现以下更改:" -ForegroundColor Cyan
    git status --short
    Write-Host ""
}

Write-Host "2. 添加所有文件到暂存区..." -ForegroundColor Yellow
git add .
Write-Host "   ✓ 文件已添加" -ForegroundColor Green

Write-Host "3. 提交更改..." -ForegroundColor Yellow
$commitMessage = "修复每日提醒、隐私锁和生物识别功能 - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
git commit -m $commitMessage
if ($LASTEXITCODE -eq 0) {
    Write-Host "   ✓ 提交成功：$commitMessage" -ForegroundColor Green
} else {
    Write-Host "   ⚠ 没有新更改需要提交" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "4. 推送到 GitHub..." -ForegroundColor Yellow
Write-Host "   请稍候，这可能需要几分钟..." -ForegroundColor Cyan
git push -u origin main

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "  ✓✓✓ 代码推送成功！" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "📦 GitHub Actions 将自动开始构建" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "📱 下一步操作:" -ForegroundColor Yellow
    Write-Host "1. 访问 GitHub 仓库查看构建进度" -ForegroundColor White
    Write-Host "   https://github.com/jiege455/life_recorder/actions" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "2. 等待构建完成（约 5-15 分钟）" -ForegroundColor White
    Write-Host ""
    Write-Host "3. 在 Actions 页面下载 APK 文件" -ForegroundColor White
    Write-Host ""
    Write-Host "4. 安装到手机测试所有修复的功能" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "  ✗ 推送失败" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "可能的原因:" -ForegroundColor Yellow
    Write-Host "1. 网络连接问题" -ForegroundColor White
    Write-Host "2. GitHub 认证问题" -ForegroundColor White
    Write-Host "3. 仓库权限问题" -ForegroundColor White
    Write-Host ""
    Write-Host "请检查后重试" -ForegroundColor Cyan
}

Write-Host ""
pause
