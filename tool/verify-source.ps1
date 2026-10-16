$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $projectRoot

# Inspect both the index and new, non-ignored files before any build/test work.
# Print paths only; never print credential contents.
$sourcePaths = @(git -c core.quotepath=false ls-files --cached --others --exclude-standard)
if ($LASTEXITCODE -ne 0) { throw 'Unable to inspect Git source files.' }
$privateFiles = @($sourcePaths | Where-Object {
    $_ -match '(^|/)(key\.properties|\.env(\..*)?)$|\.(jks|keystore|p12|pfx|pem|key|apk|aab)$'
})
if ($privateFiles.Count -gt 0) {
    $privateFiles | ForEach-Object { Write-Output "Excluded source material found: $_" }
    throw 'Remove private keys, credentials and install packages from the Git index/source candidates.'
}

# These generators are local only. No voice API or publication command is run.
$reports = @(
    'docs/content_audit.json',
    'docs/audio/voice_scripts.json',
    'docs/audio/voice_scripts.csv',
    'docs/audio/story_studio.json',
    'docs/review/content_review.json',
    'docs/review/quiz_review.csv'
)
$before = @{}
foreach ($path in $reports) {
    if (!(Test-Path -LiteralPath $path -PathType Leaf)) { throw "Missing source report: $path" }
    $before[$path] = [IO.File]::ReadAllText((Join-Path $projectRoot $path)).Replace("`r`n", "`n")
}

& powershell -NoProfile -ExecutionPolicy Bypass -File tool/test.ps1
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$commands = @(
    @('run', 'tool/prepare_recordings.dart', '--check'),
    @('run', 'tool/export_voice_scripts.dart'),
    @('run', 'tool/export_story_studio.dart'),
    @('run', 'tool/export_content_review.dart'),
    @('run', 'tool/audit_content.dart')
)
foreach ($arguments in $commands) {
    & dart @arguments
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}
$stale = @($reports | Where-Object {
    [IO.File]::ReadAllText((Join-Path $projectRoot $_)).Replace("`r`n", "`n") -cne $before[$_]
})
if ($stale.Count -gt 0) {
    $stale | ForEach-Object { Write-Output "Regenerated report: $_" }
    throw 'Reports were stale. Review the regenerated files, then run verification again.'
}

git -c core.autocrlf=false -c core.whitespace=cr-at-eol diff --check
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
git -c core.autocrlf=false -c core.whitespace=cr-at-eol diff --cached --check
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Write-Output 'Source verification passed. Audio production, expert review and physical-device testing remain separate.'
exit 0
