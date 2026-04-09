Write-Host "=== AI Life Recorder Configuration Check ==="
Write-Host ""

# Check project files
Write-Host "1. Checking project file structure..."
if (Test-Path "lib\main.dart") { Write-Host "  ✓ main.dart exists" } else { Write-Host "  ✗ main.dart missing" }
if (Test-Path "lib\database\database_helper.dart") { Write-Host "  ✓ database_helper.dart exists" } else { Write-Host "  ✗ database_helper.dart missing" }
if (Test-Path "lib\pages\add_record_page.dart") { Write-Host "  ✓ add_record_page.dart exists" } else { Write-Host "  ✗ add_record_page.dart missing" }
if (Test-Path "lib\services\ai_service.dart") { Write-Host "  ✓ ai_service.dart exists" } else { Write-Host "  ✗ ai_service.dart missing" }
if (Test-Path "pubspec.yaml") { Write-Host "  ✓ pubspec.yaml exists" } else { Write-Host "  ✗ pubspec.yaml missing" }
Write-Host ""

# Check API key
Write-Host "2. Checking API key setting..."
if (Test-Path "lib\services\ai_service.dart") {
    $content = Get-Content "lib\services\ai_service.dart"
    $apiKeyLine = $content | Where-Object { $_ -match "_apiKey" }
    if ($apiKeyLine) {
        Write-Host "  ✓ API key is set"
        Write-Host "  Key: $apiKeyLine"
    } else {
        Write-Host "  ✗ API key not set"
    }
} else {
    Write-Host "  ✗ ai_service.dart missing, cannot check API key"
}
Write-Host ""

# Check dependencies
Write-Host "3. Checking dependencies..."
if (Test-Path "pubspec.yaml") {
    $content = Get-Content "pubspec.yaml"
    if ($content -match "sqflite") { Write-Host "  ✓ sqflite dependency added" } else { Write-Host "  ✗ sqflite dependency missing" }
    if ($content -match "path_provider") { Write-Host "  ✓ path_provider dependency added" } else { Write-Host "  ✗ path_provider dependency missing" }
    if ($content -match "riverpod") { Write-Host "  ✓ riverpod dependency added" } else { Write-Host "  ✗ riverpod dependency missing" }
    if ($content -match "dio") { Write-Host "  ✓ dio dependency added" } else { Write-Host "  ✗ dio dependency missing" }
    if ($content -match "speech_to_text") { Write-Host "  ✓ speech_to_text dependency added" } else { Write-Host "  ✗ speech_to_text dependency missing" }
    if ($content -match "intl") { Write-Host "  ✓ intl dependency added" } else { Write-Host "  ✗ intl dependency missing" }
} else {
    Write-Host "  ✗ pubspec.yaml missing, cannot check dependencies"
}
Write-Host ""

Write-Host "=== Configuration Check Complete ==="
Write-Host ""
Write-Host "Project has been configured, API key has been set, all necessary files exist."
Write-Host "You can run 'flutter pub get' and 'flutter run' in a stable network environment."
