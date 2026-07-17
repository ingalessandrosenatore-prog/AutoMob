$repoRoot = git rev-parse --show-toplevel
if ($LASTEXITCODE -ne 0) {
    Write-Host "Repository Git non trovato." -ForegroundColor Red
    exit 1
}

Push-Location $repoRoot
try {
    git config core.hooksPath .githooks
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Impossibile configurare core.hooksPath." -ForegroundColor Red
        exit 1
    }
} finally {
    Pop-Location
}

Write-Host "Hook Git installati: ogni commit eseguira' tool/verify.ps1." -ForegroundColor Green
