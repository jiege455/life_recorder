@echo off
chcp 65001 >nul
echo ========================================
echo   AI 人生记录器 - 提交代码到 GitHub
echo ========================================
echo.

cd /d %~dp0

echo 1. 检查 Git 状态...
git status --porcelain
if %errorlevel% neq 0 (
    echo 错误：Git 未安装或不在 PATH 中
    pause
    exit /b 1
)

echo.
echo 2. 添加所有文件到暂存区...
git add .
echo    [完成] 文件已添加

echo.
echo 3. 提交更改...
git commit -m "修复每日提醒、隐私锁和生物识别功能"
if %errorlevel% equ 0 (
    echo    [成功] 提交完成
) else (
    echo    [提示] 没有新更改需要提交
)

echo.
echo 4. 推送到 GitHub...
echo    请稍候，这可能需要几分钟...
git push -u origin main

if %errorlevel% equ 0 (
    echo.
    echo ========================================
    echo   [成功] 代码推送成功！
    echo ========================================
    echo.
    echo GitHub Actions 将自动开始构建
    echo.
    echo 下一步操作:
    echo 1. 访问 GitHub 仓库查看构建进度
    echo    https://github.com/jiege455/life_recorder/actions
    echo.
    echo 2. 等待构建完成（约 5-15 分钟）
    echo.
    echo 3. 在 Actions 页面下载 APK 文件
    echo.
    echo 4. 安装到手机测试所有修复的功能
    echo.
) else (
    echo.
    echo ========================================
    echo   [失败] 推送失败
    echo ========================================
    echo.
    echo 请检查网络连接和 GitHub 认证
    echo.
)

pause
