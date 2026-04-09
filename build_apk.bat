@echo off

echo === AI人生记录器 - APK构建脚本 ===
echo.

rem 设置JAVA_HOME环境变量
echo 1. 设置JAVA_HOME环境变量...
set JAVA_HOME=e:\phpstudy_pro\WWW\ys\jdk17\jdk-17.0.17+10
set PATH=%JAVA_HOME%\bin;%PATH%
echo   ✓ JAVA_HOME已设置: %JAVA_HOME%
echo.

rem 清理Kotlin守护进程
echo 2. 清理Kotlin守护进程...
rd /s /q "C:\Users\16636\AppData\Local\kotlin\daemon" 2>nul
echo   ✓ Kotlin守护进程已清理
echo.

rem 清理构建缓存
echo 3. 清理构建缓存...
e:\phpstudy_pro\WWW\life_recorder\flutter\bin\flutter.bat clean
echo   ✓ 构建缓存已清理
echo.

rem 获取依赖
echo 4. 获取项目依赖...
e:\phpstudy_pro\WWW\life_recorder\flutter\bin\flutter.bat pub get
echo   ✓ 依赖获取完成
echo.

rem 构建APK
echo 5. 构建APK...
e:\phpstudy_pro\WWW\life_recorder\flutter\bin\flutter.bat build apk --release
echo   ✓ APK构建完成
echo.

rem 显示APK位置
echo 6. APK文件位置:
echo   build\app\outputs\flutter-apk\app-release.apk
echo.

echo === 构建脚本执行完成 ===
echo 请在设备上安装APK文件进行测试。
echo.
pause
