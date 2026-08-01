$ErrorActionPreference = 'Stop'

Write-Host ""
Write-Host "==> Formattazione app meccanico" -ForegroundColor Cyan
dart format --output=none --set-exit-if-changed lib test
if ($LASTEXITCODE -ne 0) { exit 1 }

Write-Host ""
Write-Host "==> Analisi app meccanico" -ForegroundColor Cyan
flutter analyze --fatal-infos
if ($LASTEXITCODE -ne 0) { exit 1 }

Write-Host ""
Write-Host "==> Test app meccanico" -ForegroundColor Cyan
flutter test
if ($LASTEXITCODE -ne 0) { exit 1 }

Write-Host "OK  app meccanico verde." -ForegroundColor Green
