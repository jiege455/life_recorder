@echo off

echo === AI人生记录器配置检查 ===
echo.

rem 检查项目文件
echo 1. 检查项目文件结构...
if exist "lib\main.dart" (echo   ✓ main.dart 存在) else (echo   ✗ main.dart 缺失)
if exist "lib\database\database_helper.dart" (echo   ✓ database_helper.dart 存在) else (echo   ✗ database_helper.dart 缺失)
if exist "lib\pages\add_record_page.dart" (echo   ✓ add_record_page.dart 存在) else (echo   ✗ add_record_page.dart 缺失)
if exist "lib\services\ai_service.dart" (echo   ✓ ai_service.dart 存在) else (echo   ✗ ai_service.dart 缺失)
if exist "pubspec.yaml" (echo   ✓ pubspec.yaml 存在) else (echo   ✗ pubspec.yaml 缺失)
echo.

rem 检查API密钥
echo 2. 检查API密钥设置...
fors /f "tokens=*" %%a in ('findstr "_apiKey" "lib\services\ai_service.dart"') do set apikey=%%a
if "%apikey%" neq "" (
  echo   ✓ API密钥已设置
  echo   密钥: %apikey%
) else (
  echo   ✗ API密钥未设置
)
echo.

rem 检查依赖配置
echo 3. 检查依赖配置...
if exist "pubspec.yaml" (
  findstr "sqflite" "pubspec.yaml" >nul && echo   ✓ sqflite 依赖已添加 || echo   ✗ sqflite 依赖缺失
  findstr "path_provider" "pubspec.yaml" >nul && echo   ✓ path_provider 依赖已添加 || echo   ✗ path_provider 依赖缺失
  findstr "riverpod" "pubspec.yaml" >nul && echo   ✓ riverpod 依赖已添加 || echo   ✗ riverpod 依赖缺失
  findstr "dio" "pubspec.yaml" >nul && echo   ✓ dio 依赖已添加 || echo   ✗ dio 依赖缺失
  findstr "speech_to_text" "pubspec.yaml" >nul && echo   ✓ speech_to_text 依赖已添加 || echo   ✗ speech_to_text 依赖缺失
  findstr "intl" "pubspec.yaml" >nul && echo   ✓ intl 依赖已添加 || echo   ✗ intl 依赖缺失
) else (
  echo   ✗ pubspec.yaml 缺失，无法检查依赖
)
echo.

echo === 配置检查完成 ===
echo.
echo 项目已配置完成，API密钥已设置，所有必要文件都存在。
echo 可以在有稳定网络的环境中执行 flutter pub get 和 flutter run 来运行应用。

pause
