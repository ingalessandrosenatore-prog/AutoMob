# =====================================================================
#  ship.ps1  —  COMMIT + PUSH sicuri
# ---------------------------------------------------------------------
#  Fa commit e push SOLO se verify.ps1 passa (architettura + analyze +
#  test). Se qualcosa e' rosso, si ferma e NON tocca git.
#
#  Uso:   ./tool/ship.ps1 "messaggio di commit"
# =====================================================================

param(
    [Parameter(Mandatory = $true)]
    [string]$Message
)

# 1) Cancello di qualita'
& "$PSScriptRoot/verify.ps1"
if ($LASTEXITCODE -ne 0) {
    Write-Host "Commit annullato: verify fallito." -ForegroundColor Red
    exit 1
}

# 2) Commit
Write-Host ""
Write-Host "==> git add + commit" -ForegroundColor Cyan
git add -A
git commit -m $Message
if ($LASTEXITCODE -ne 0) {
    Write-Host "git commit fallito (forse niente da committare?)." -ForegroundColor Red
    exit 1
}

# 3) Push
Write-Host ""
Write-Host "==> git push" -ForegroundColor Cyan
git push
if ($LASTEXITCODE -ne 0) {
    Write-Host "git push fallito." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "OK  Committato e pushato." -ForegroundColor Green
exit 0
