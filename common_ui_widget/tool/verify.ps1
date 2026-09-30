$ErrorActionPreference = 'Stop'

Write-Host ""
Write-Host "==> Formattazione common_ui_widget" -ForegroundColor Cyan
dart format --output=none --set-exit-if-changed lib test
if ($LASTEXITCODE -ne 0) { exit 1 }

Write-Host ""
Write-Host "==> Analisi common_ui_widget" -ForegroundColor Cyan
flutter analyze --fatal-infos
if ($LASTEXITCODE -ne 0) { exit 1 }

Write-Host ""
Write-Host "==> Test common_ui_widget" -ForegroundColor Cyan
flutter test
if ($LASTEXITCODE -ne 0) { exit 1 }

Write-Host "OK  common_ui_widget verde." -ForegroundColor Green
