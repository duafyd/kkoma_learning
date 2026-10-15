param([switch]$CreateDevelopmentKey)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $projectRoot
$javaDir = 'C:\Program Files\Android\Android Studio\jbr'
$env:JAVA_HOME = $javaDir
$keyDirectory = Join-Path $projectRoot 'android\validation-signing'
$keyPath = Join-Path $keyDirectory 'debug-validation.keystore'
$apkPath = Join-Path $projectRoot 'build\app\outputs\flutter-apk\app-release.apk'
$signedPath = Join-Path $projectRoot 'build\app\outputs\flutter-apk\app-validation.apk'
if (!(Test-Path -LiteralPath $apkPath)) { throw 'Build the release APK first.' }
if (!(Test-Path -LiteralPath $keyPath)) {
  if (!$CreateDevelopmentKey) { throw 'Key generation requires explicit permission. Use -CreateDevelopmentKey only after approval.' }
  New-Item -ItemType Directory -Force -Path $keyDirectory | Out-Null
  & (Join-Path $javaDir 'bin\keytool.exe') -genkeypair -keystore $keyPath -alias androiddebugkey -storepass android -keypass android -keyalg RSA -keysize 2048 -validity 3650 -dname 'CN=Android Debug,O=Android,C=US' -noprompt
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}
$signer = Join-Path $env:LOCALAPPDATA 'Android\Sdk\build-tools\36.0.0\apksigner.bat'
& $signer sign --ks $keyPath --ks-key-alias androiddebugkey --ks-pass pass:android --key-pass pass:android --out $signedPath $apkPath
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& $signer verify --verbose $signedPath
exit $LASTEXITCODE
