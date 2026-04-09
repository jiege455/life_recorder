# AI人生记录器 - GitHub推送脚本

Write-Host "=== 开始推送代码到GitHub ===" -ForegroundColor Green

# 检查git是否安装
$gitCheck = git --version 2>$null
if ($null -eq $gitCheck) {
    Write-Host "错误: 未检测到Git安装" -ForegroundColor Red
    Write-Host "请先安装Git: https://git-scm.com/download/win" -ForegroundColor Yellow
    pause
    exit 1
}

Write-Host "Git版本: $gitCheck" -ForegroundColor Cyan

# 检查是否在项目目录
if (-not (Test-Path "pubspec.yaml")) {
    Write-Host "错误: 未找到pubspec.yaml文件，请确保在项目根目录" -ForegroundColor Red
    pause
    exit 1
}

# 初始化Git仓库（如果不存在）
if (-not (Test-Path ".git")) {
    Write-Host "1. 初始化Git仓库..." -ForegroundColor Yellow
    git init
    git branch -M main
    Write-Host "   ✓ Git仓库初始化完成" -ForegroundColor Green
} else {
    Write-Host "1. Git仓库已存在，跳过初始化" -ForegroundColor Cyan
}

# 添加远程仓库
Write-Host "2. 添加远程仓库..." -ForegroundColor Yellow
$remoteUrl = "https://github.com/jiege455/life_recorder.git"
git remote remove origin 2>$null | Out-Null
git remote add origin $remoteUrl
Write-Host "   ✓ 远程仓库已添加: $remoteUrl" -ForegroundColor Green

# 添加所有文件
Write-Host "3. 添加所有文件到暂存区..." -ForegroundColor Yellow
git add .

# 检查暂存的文件数量
$status = git status --porcelain
if ($status.Count -eq 0) {
    Write-Host "   ⚠ 没有新文件需要提交" -ForegroundColor Yellow
} else {
    Write-Host "   ✓ 已添加 $($status.Count) 个文件" -ForegroundColor Green
}

# 提交代码
Write-Host "4. 提交代码..." -ForegroundColor Yellow
git commit -m "AI人生记录器 - Flutter移动应用"

# 推送代码
Write-Host "5. 推送代码到GitHub..." -ForegroundColor Yellow
git push -u origin main

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "=== ✓ 代码推送成功！===" -ForegroundColor Green
    Write-Host ""
    Write-Host "仓库地址: https://github.com/jiege455/life_recorder" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "下一步:" -ForegroundColor Yellow
    Write-Host "1. 访问 https://codemagic.io 注册/登录账号" -ForegroundColor White
    Write-Host "2. 点击 'Add app' 添加应用，选择GitHub" -ForegroundColor White
    Write-Host "3. 选择 'life_recorder' 仓库" -ForegroundColor White
    Write-Host "4. 点击 'Start new build' 开始构建" -ForegroundColor White
    Write-Host "5. 构建完成后在 'Artifacts' 下载APK" -ForegroundColor White
} else {
    Write-Host ""
    Write-Host "=== ✗ 代码推送失败 ===" -ForegroundColor Red
    Write-Host "请检查网络连接或GitHub认证信息" -ForegroundColor Yellow
}

Write-Host ""
pause
