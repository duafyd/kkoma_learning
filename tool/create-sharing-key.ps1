param([switch]$CreateKey)
$ErrorActionPreference = 'Stop'
if (!$CreateKey) { throw 'Use -CreateKey only with explicit authorization to create a permanent app signing key.' }
$projectRoot = Split-Path -Parent $PSScriptRoot
$keyDirectory = Join-Path $projectRoot 'android\release-signing'
$keyPath = Join-Path $keyDirectory 'kkoma-sharing.p12'
$propertiesPath = Join-Path $projectRoot 'android\key.properties'
if ((Test-Path -LiteralPath $keyPath) -or (Test-Path -LiteralPath $propertiesPath)) {
    throw 'Signing material already exists. Reuse or restore it; this script never overwrites keys.'
}
$keytool = 'C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe'
if (!(Test-Path -LiteralPath $keytool)) { throw 'Android Studio JBR keytool not found.' }
New-Item -ItemType Directory -Force -Path $keyDirectory | Out-Null
$randomBytes = New-Object byte[] 32
$random = [System.Security.Cryptography.RandomNumberGenerator]::Create()
try { $random.GetBytes($randomBytes) } finally { $random.Dispose() }
$password = [Convert]::ToBase64String($randomBytes)
# Environment references keep credentials out of command-line arguments and logs.
$env:KKOMA_SIGNING_PASSWORD = $password
try {
    & $keytool -genkeypair -keystore $keyPath -storetype PKCS12 -alias kkoma-sharing -storepass:env KKOMA_SIGNING_PASSWORD -keypass:env KKOMA_SIGNING_PASSWORD -keyalg RSA -keysize 3072 -sigalg SHA256withRSA -validity 10000 -dname 'CN=Kkoma Learning,OU=APK Sharing,O=Kkoma Learning,C=KR' -noprompt
    if ($LASTEXITCODE -ne 0) { throw "keytool failed with exit code $LASTEXITCODE. Inspect existing material before retrying." }
    [System.IO.File]::WriteAllLines($propertiesPath, @(
        'storeFile=release-signing/kkoma-sharing.p12'
        "storePassword=$password"
        'keyAlias=kkoma-sharing'
        "keyPassword=$password"
    ), [System.Text.Encoding]::ASCII)
} finally {
    Remove-Item Env:KKOMA_SIGNING_PASSWORD -ErrorAction SilentlyContinue
    $password = $null
}
Write-Output 'App signing key and local android/key.properties created. Back up both privately; never upload them.'
