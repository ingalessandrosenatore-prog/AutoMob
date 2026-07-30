# =====================================================================
#  ship.ps1  —  COMMIT + PUSH sicuri
# ---------------------------------------------------------------------
#  Stage, verifica e committa lo stesso snapshot. Se qualcosa e' rosso,
#  si ferma prima del commit.
#
#  Uso:   ./tool/ship.ps1 "messaggio di commit"
# =====================================================================

param(
    [Parameter(Mandatory = $true)]
    [string]$Message
)

# 1) Stage: verify deve controllare esattamente cio' che verra' committato.
Write-Host ""
Write-Host "==> git add" -ForegroundColor Cyan
git add -A
if ($LASTEXITCODE -ne 0) {
    Write-Host "git add fallito." -ForegroundColor Red
    exit 1
}

# 2) Cancello di qualita'
& "$PSScriptRoot/verify.ps1"
if ($LASTEXITCODE -ne 0) {
    Write-Host "Commit annullato: verify fallito." -ForegroundColor Red
    exit 1
}

# 3) Nessun file deve essere cambiato dai controlli dopo lo stage.
git diff --quiet
if ($LASTEXITCODE -ne 0) {
    Write-Host "Commit annullato: il worktree e' cambiato dopo lo stage." -ForegroundColor Red
    exit 1
}

# 4) Commit
Write-Host ""
Write-Host "==> git commit" -ForegroundColor Cyan
git commit -m $Message
if ($LASTEXITCODE -ne 0) {
    Write-Host "git commit fallito (forse niente da committare?)." -ForegroundColor Red
    exit 1
}

# 5) Push
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
