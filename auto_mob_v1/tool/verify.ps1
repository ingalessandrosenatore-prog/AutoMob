# =====================================================================
#  verify.ps1  —  CANCELLO DI QUALITA'
# ---------------------------------------------------------------------
#  Esegue, in ordine, i quattro controlli. Se UNO fallisce -> exit 1,
#  cosi' chi lo usa (es. ship.ps1) NON committa.
#
#  Uso:   ./tool/verify.ps1
# =====================================================================

Write-Host ""
Write-Host "==> 1/4  Architettura (tool/check_architecture.dart)" -ForegroundColor Cyan
dart run tool/check_architecture.dart
if ($LASTEXITCODE -ne 0) {
    Write-Host "STOP: violazioni architetturali. Niente commit." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "==> 2/4  Copertura test (tool/check_test_coverage.dart)" -ForegroundColor Cyan
dart run tool/check_test_coverage.dart
if ($LASTEXITCODE -ne 0) {
    Write-Host "STOP: c'e' logica nuova senza test (TDD). Niente commit." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "==> 3/4  flutter analyze" -ForegroundColor Cyan
flutter analyze
if ($LASTEXITCODE -ne 0) {
    Write-Host "STOP: 'flutter analyze' ha trovato problemi. Niente commit." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "==> 4/4  flutter test" -ForegroundColor Cyan
flutter test
if ($LASTEXITCODE -ne 0) {
    Write-Host "STOP: test falliti. Niente commit." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "OK  Tutto verde: architettura + copertura test + analyze + test. Puoi committare." -ForegroundColor Green
exit 0
