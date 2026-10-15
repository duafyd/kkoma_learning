param([Parameter(ValueFromRemainingArguments=$true)][string[]]$FlutterArguments)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $projectRoot
$taskTemp = Join-Path $projectRoot '.tool_tmp'
New-Item -ItemType Directory -Force -Path $taskTemp | Out-Null
$sdkActual = Join-Path $env:LOCALAPPDATA 'Android\Sdk'
if (!(Test-Path -LiteralPath $sdkActual)) { throw 'Android SDK not found in LOCALAPPDATA/Android/Sdk' }
$sdkAlias = Join-Path $taskTemp 'android-sdk'
if (!(Test-Path -LiteralPath $sdkAlias)) { New-Item -ItemType Junction -Path $sdkAlias -Target $sdkActual | Out-Null }
$env:ANDROID_HOME = $sdkAlias
$env:ANDROID_SDK_ROOT = $sdkAlias
$env:TEMP = $taskTemp
$env:TMP = $taskTemp
flutter @FlutterArguments
exit $LASTEXITCODE
