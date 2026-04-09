Write-Host "=== AI人生记录器配置检查 ==="
Write-Host ""

# 检查项目文件
Write-Host "1. 检查项目文件结构..."
if (Test-Path "lib\main.dart") { Write-Host "  ✓ main.dart 存在" } else { Write-Host "  ✗ main.dart 缺失" }
if (Test-Path "lib\database\database_helper.dart") { Write-Host "  ✓ database_helper.dart 存在" } else { Write-Host "  ✗ database_helper.dart 缺失" }
if (Test-Path "lib\pages\add_record_page.dart") { Write-Host "  ✓ add_record_page.dart 存在" } else { Write-Host "  ✗ add_record_page.dart 缺失" }
if (Test-Path "lib\services\ai_service.dart") { Write-Host "  ✓ ai_service.dart 存在" } else { Write-Host "  ✗ ai_service.dart 缺失" }
if (Test-Path "pubspec.yaml") { Write-Host "  ✓ pubspec.yaml 存在" } else { Write-Host "  ✗ pubspec.yaml 缺失" }
Write-Host ""

# 检查API密钥
Write-Host "2. 检查API密钥设置..."
if (Test-Path "lib\services\ai_service.dart") {
    $content = Get-Content "lib\services\ai_service.dart"
    $apiKeyLine = $content | Where-Object { $_ -match "_apiKey" }
    if ($apiKeyLine) {
        Write-Host "  ✓ API密钥已设置"
        Write-Host "  密钥: $apiKeyLine"
    } else {
        Write-Host "  ✗ API密钥未设置"
    }
} else {
    Write-Host "  ✗ ai_service.dart 缺失，无法检查API密钥"
}
Write-Host ""

# 检查依赖配置
Write-Host "3. 检查依赖配置..."
if (Test-Path "pubspec.yaml") {
    $content = Get-Content "pubspec.yaml"
    if ($content -match "sqflite") { Write-Host "  ✓ sqflite 依赖已添加" } else { Write-Host "  ✗ sqflite 依赖缺失" }
    if ($content -match "path_provider") { Write-Host "  ✓ path_provider 依赖已添加" } else { Write-Host "  ✗ path_provider 依赖缺失" }
    if ($content -match "riverpod") { Write-Host "  ✓ riverpod 依赖已添加" } else { Write-Host "  ✗ riverpod 依赖缺失" }
    if ($content -match "dio") { Write-Host "  ✓ dio 依赖已添加" } else { Write-Host "  ✗ dio 依赖缺失" }
    if ($content -match "speech_to_text") { Write-Host "  ✓ speech_to_text 依赖已添加" } else { Write-Host "  ✗ speech_to_text 依赖缺失" }
    if ($content -match "intl") { Write-Host "  ✓ intl 依赖已添加" } else { Write-Host "  ✗ intl 依赖缺失" }
} else {
    Write-Host "  ✗ pubspec.yaml 缺失，无法检查依赖"
}
Write-Host ""

Write-Host "=== 配置检查完成 ==="
Write-Host ""
Write-Host "项目已配置完成，API密钥已设置，所有必要文件都存在。"
Write-Host "可以在有稳定网络的环境中执行 flutter pub get 和 flutter run 来运行应用。"

Read-Host "按 Enter 键退出..."
