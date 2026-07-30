# =====================================================================
#  verify.ps1  —  CANCELLO DI QUALITA'
# ---------------------------------------------------------------------
#  Esegue, in ordine, tutti i controlli. Se UNO fallisce -> exit 1,
#  cosi' chi lo usa (es. ship.ps1) NON committa.
#
#  Uso:   ./tool/verify.ps1
# =====================================================================

$verifyRepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path

function Invoke-VerifyGit {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$GitArguments)

    & git -c "safe.directory=$verifyRepoRoot" @GitArguments
}

function Get-VerifyChangedContentPaths {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$DiffArguments)

    $statusLines = @(Invoke-VerifyGit diff --name-status --find-renames @DiffArguments)
    foreach ($statusLine in $statusLines) {
        $parts = $statusLine -split "`t"
        $status = $parts[0]

        if ($status -match '^[AM]$') {
            $parts[1]
        } elseif ($status -match '^[RC](\d+)$' -and [int]$Matches[1] -lt 100) {
            $parts[2]
        }
    }
}

Write-Host ""
Write-Host "==> 1/7  File vietati e configurazione locale" -ForegroundColor Cyan
$trackedFiles = @(
    Invoke-VerifyGit ls-files --cached --others --exclude-standard |
        Where-Object { Test-Path $_ }
)
if ($LASTEXITCODE -ne 0) {
    Write-Host "STOP: impossibile leggere i file tracciati da Git." -ForegroundColor Red
    exit 1
}
$forbiddenFiles = @(
    $trackedFiles | Where-Object {
        ($_ -match '(^|/)\.env($|\.)' -and $_ -notmatch '(^|/)\.env\.example$') -or
        $_ -match '(^|/)supabase/\.temp/' -or
        $_ -match 'service-account.*\.json$' -or
        $_ -match '\.jks$' -or
        $_ -match '(^|/)key\.properties$'
    }
)
if ($forbiddenFiles.Count -gt 0) {
    Write-Host "STOP: file locali/segreti tracciati da Git:" -ForegroundColor Red
    $forbiddenFiles | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
    exit 1
}

Write-Host ""
Write-Host "==> 2/7  Formattazione Dart dei file modificati" -ForegroundColor Cyan
$repoRoot = (Invoke-VerifyGit rev-parse --show-toplevel).Trim()
if ($LASTEXITCODE -ne 0) {
    Write-Host "STOP: repository Git non trovato." -ForegroundColor Red
    exit 1
}

$changedPaths = @()
$hasBaseRef = $false
if ($env:VERIFY_BASE_REF -and $env:VERIFY_BASE_REF -notmatch '^0+$') {
    Invoke-VerifyGit cat-file -e "$env:VERIFY_BASE_REF^{commit}" *> $null
    $hasBaseRef = $LASTEXITCODE -eq 0
}

if ($hasBaseRef) {
    $changedPaths += Get-VerifyChangedContentPaths "$env:VERIFY_BASE_REF...HEAD"
} else {
    Invoke-VerifyGit rev-parse --verify HEAD *> $null
    $hasHead = $LASTEXITCODE -eq 0
    if ($hasHead) {
        $changedPaths += Get-VerifyChangedContentPaths HEAD
    } else {
        $changedPaths += Get-VerifyChangedContentPaths --cached
    }
    $changedPaths += Invoke-VerifyGit ls-files --others --exclude-standard
}

$projectRoot = (Get-Location).Path
$dartFiles = @(
    $changedPaths |
        Sort-Object -Unique |
        Where-Object { $_ -like "*.dart" } |
        ForEach-Object {
            $fullPath = Join-Path $repoRoot $_
            if (
                $fullPath.StartsWith($projectRoot, [System.StringComparison]::OrdinalIgnoreCase) -and
                (Test-Path $fullPath)
            ) {
                $fullPath.Replace("$projectRoot\", '')
            }
        }
)

if ($dartFiles.Count -gt 0) {
    $formatBatchSize = 25
    for ($offset = 0; $offset -lt $dartFiles.Count; $offset += $formatBatchSize) {
        $lastIndex = [Math]::Min(
            $offset + $formatBatchSize - 1,
            $dartFiles.Count - 1
        )
        $formatBatch = @($dartFiles[$offset..$lastIndex])

        dart format --output=none --set-exit-if-changed @formatBatch
        if ($LASTEXITCODE -ne 0) {
            Write-Host "STOP: formatta i file Dart modificati." -ForegroundColor Red
            exit 1
        }
    }
}

Write-Host ""
Write-Host "==> 3/7  Architettura (tool/check_architecture.dart)" -ForegroundColor Cyan
dart run tool/check_architecture.dart
if ($LASTEXITCODE -ne 0) {
    Write-Host "STOP: violazioni architetturali. Niente commit." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "==> 4/7  Copertura strutturale test" -ForegroundColor Cyan
dart run tool/check_test_coverage.dart
if ($LASTEXITCODE -ne 0) {
    Write-Host "STOP: c'e' logica nuova senza test (TDD). Niente commit." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "==> 5/7  flutter analyze --fatal-infos" -ForegroundColor Cyan
flutter analyze --fatal-infos
if ($LASTEXITCODE -ne 0) {
    Write-Host "STOP: 'flutter analyze' ha trovato problemi. Niente commit." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "==> 6/7  flutter test" -ForegroundColor Cyan
flutter test
if ($LASTEXITCODE -ne 0) {
    Write-Host "STOP: test falliti. Niente commit." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "==> 7/7  Test Edge Functions Deno" -ForegroundColor Cyan
if (Test-Path "supabase/functions/tests") {
    $denoTests = @(Get-ChildItem "supabase/functions/tests" -File -Filter "*test.ts")
    foreach ($denoTest in $denoTests) {
        npx --yes deno test $denoTest.FullName
        if ($LASTEXITCODE -ne 0) {
            Write-Host "STOP: test Deno falliti. Niente commit." -ForegroundColor Red
            exit 1
        }
    }
}

Write-Host ""
Write-Host "OK  Tutto verde: file + format + architettura + test coverage + analyze + test Flutter/Deno." -ForegroundColor Green
exit 0
