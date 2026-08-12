# =====================================================================
#  ship.ps1  —  COMMIT + PUSH sicuri (app meccanico)
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

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$repoRoot = (Resolve-Path (Join-Path $projectRoot "..")).Path
$projectRelativePath = [System.IO.Path]::GetRelativePath($repoRoot, $projectRoot)

function Invoke-ShipGit {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$GitArguments)

    & git -c "safe.directory=$repoRoot" @GitArguments
}

# 1) Stage: verify deve controllare esattamente cio' che verra' committato.
Write-Host ""
Write-Host "==> git add $projectRelativePath" -ForegroundColor Cyan
Invoke-ShipGit add -A -- $projectRelativePath
if ($LASTEXITCODE -ne 0) {
    Write-Host "git add fallito." -ForegroundColor Red
    exit 1
}

# 2) Cancello di qualita'
& (Join-Path $PSScriptRoot "verify.ps1")
if ($LASTEXITCODE -ne 0) {
    Write-Host "Commit annullato: verify fallito." -ForegroundColor Red
    exit 1
}

# 3) Nessun file deve essere cambiato dai controlli dopo lo stage.
Invoke-ShipGit diff --quiet -- $projectRelativePath
if ($LASTEXITCODE -ne 0) {
    Write-Host "Commit annullato: il worktree e' cambiato dopo lo stage." -ForegroundColor Red
    exit 1
}

# 4) Commit
Write-Host ""
Write-Host "==> git commit" -ForegroundColor Cyan
Invoke-ShipGit commit -m $Message
if ($LASTEXITCODE -ne 0) {
    Write-Host "git commit fallito (forse niente da committare?)." -ForegroundColor Red
    exit 1
}

# 5) Push
Write-Host ""
Write-Host "==> git push" -ForegroundColor Cyan
Invoke-ShipGit push
if ($LASTEXITCODE -ne 0) {
    Write-Host "git push fallito." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "OK  Committato e pushato." -ForegroundColor Green
exit 0
