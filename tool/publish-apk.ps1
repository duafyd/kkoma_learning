param([ValidateRange(1, 2100000000)][int]$BuildNumber)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $projectRoot
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Invoke-GitChecked([string[]]$GitArguments) {
    & git @GitArguments
    if ($LASTEXITCODE -ne 0) { throw "Git operation failed: $($GitArguments[0])" }
}
function Invoke-NativeChecked([string]$Executable, [string[]]$NativeArguments) {
    $savedPreference = $ErrorActionPreference
    try {
        # Native tools emit harmless warnings to stderr; trust their exit code.
        $ErrorActionPreference = 'Continue'
        & $Executable @NativeArguments
        $nativeResult = $LASTEXITCODE
    } finally { $ErrorActionPreference = $savedPreference }
    if ($nativeResult -ne 0) { throw "Native command failed: $Executable (exit $nativeResult)" }
}
if (@(git status --porcelain).Length -ne 0) { throw 'Commit your source changes first. Release requires a clean working tree.' }
if ((git branch --show-current) -ne 'main') { throw 'Switch to main before publishing.' }
if ((git remote get-url origin) -ne 'https://github.com/duafyd/kkoma_learning.git') { throw 'Unexpected origin repository.' }
if (!(Test-Path -LiteralPath 'android/key.properties') -or !(Test-Path -LiteralPath 'android/release-signing/kkoma-sharing.p12')) {
    throw 'Restore your original private signing key and android/key.properties first.'
}
$trackedSecrets = @(git ls-files -- '*.p12' '*.keystore' '*.jks' '*key.properties')
if ($trackedSecrets.Length -ne 0) { throw 'Private signing files are tracked by Git. Publishing stopped.' }
$versionMatch = [regex]::Match([IO.File]::ReadAllText((Join-Path $projectRoot 'pubspec.yaml')), '(?m)^version:\s*([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+)\s*$')
if (!$versionMatch.Success) { throw 'Expected pubspec version: x.y.z+build.' }
$version = $versionMatch.Groups[1].Value
if (!$BuildNumber) {
    # Seconds since 2020 keep Android versionCode increasing without editing source.
    $BuildNumber = [int]([DateTimeOffset]::UtcNow.ToUnixTimeSeconds() - 1577836800)
}
if ($BuildNumber -lt [int]$versionMatch.Groups[2].Value) { throw 'Build number is below pubspec versionCode.' }
$tag = "apk-$version-$BuildNumber"
$apiBase = 'https://api.github.com/repos/duafyd/kkoma_learning'
$headers = $null
try {
    # Use the existing Windows Git Credential Manager login; never print/store its token.
    $credentialLines = @("protocol=https`nhost=github.com`n`n" | git -c credential.interactive=always credential fill)
    if ($LASTEXITCODE -ne 0) { throw 'GitHub authentication failed.' }
    $passwordLine = $credentialLines | Where-Object { $_.StartsWith('password=') }
    if (!$passwordLine) { throw 'Git Credential Manager did not return a GitHub token.' }
    $headers = @{
        Authorization = 'Bearer ' + $passwordLine.Substring(9)
        Accept = 'application/vnd.github+json'
        'User-Agent' = 'kkoma-local-apk-publisher'
        'X-GitHub-Api-Version' = '2022-11-28'
    }
    $credentialLines = $null
    $passwordLine = $null
    $releases = @(Invoke-RestMethod -Uri "$apiBase/releases?per_page=100" -Headers $headers)
    if ($releases | Where-Object { $_.tag_name -eq $tag }) { throw "Release $tag already exists; it will not be overwritten." }
    foreach ($existing in $releases) {
        $existingVersion = [regex]::Match([string]$existing.tag_name, '^apk-\d+\.\d+\.\d+-(\d+)$')
        if ($existingVersion.Success -and [long]$existingVersion.Groups[1].Value -ge $BuildNumber) {
            throw 'Build number must exceed previous APK releases.'
        }
    }
    Invoke-GitChecked -GitArguments @('fetch', 'origin')
    & git merge-base --is-ancestor origin/main HEAD
    if ($LASTEXITCODE -ne 0) { throw 'origin/main has changes not in HEAD. Pull and resolve before publishing.' }
    $commit = git rev-parse HEAD
    Write-Output "Testing source $commit ..."
    Invoke-NativeChecked -Executable powershell -NativeArguments @('-ExecutionPolicy','Bypass','-File','tool/test.ps1')
    Invoke-NativeChecked -Executable powershell -NativeArguments @('-ExecutionPolicy','Bypass','-File','tool/android.ps1','build','apk','--release','--build-number',"$BuildNumber")
    $apk = Join-Path $projectRoot 'build/app/outputs/flutter-apk/app-release.apk'
    $env:JAVA_HOME = 'C:\Program Files\Android\Android Studio\jbr'
    $signer = Join-Path $env:LOCALAPPDATA 'Android/Sdk/build-tools/36.0.0/apksigner.bat'
    Invoke-NativeChecked -Executable $signer -NativeArguments @('verify','--verbose',$apk)
    if (@(git status --porcelain).Length -ne 0 -or (git rev-parse HEAD) -ne $commit) { throw 'Source changed during build. Commit and rerun.' }
    $hash = (Get-FileHash -LiteralPath $apk -Algorithm SHA256).Hash.ToLowerInvariant()
    Invoke-GitChecked -GitArguments @('-c', 'credential.interactive=always', 'push', 'origin', 'HEAD:main')
    $notes = "APK sharing build (educational/device review pending).`n`nVersion: $version ($BuildNumber)`nSource: $commit`nSHA256: $hash`n`nInstall the APK asset on Android. Signing keys are kept on the developer PC."
    $body = @{ tag_name=$tag; target_commitish=$commit; name="Kkoma $version ($BuildNumber)"; body=$notes; draft=$true; prerelease=$false } | ConvertTo-Json
    $release = Invoke-RestMethod -Method Post -Uri "$apiBase/releases" -Headers $headers -ContentType 'application/json' -Body ([Text.Encoding]::UTF8.GetBytes($body))
    Write-Output "Draft release created: $tag. Uploading verified APK ..."
    $assetName = "kkoma-$version-$BuildNumber.apk"
    $uploadUrl = $release.upload_url.Split('{')[0] + '?name=' + [Uri]::EscapeDataString($assetName)
    $asset = Invoke-RestMethod -Method Post -Uri $uploadUrl -Headers $headers -ContentType 'application/vnd.android.package-archive' -InFile $apk
    if ($asset.state -ne 'uploaded' -or $asset.size -ne (Get-Item -LiteralPath $apk).Length) { throw "Upload verification failed; draft $tag was left unpublished." }
    if ($asset.digest -and $asset.digest -ne "sha256:$hash") { throw "Remote hash mismatch; draft $tag was left unpublished." }
    $published = Invoke-RestMethod -Method Patch -Uri "$apiBase/releases/$($release.id)" -Headers $headers -ContentType 'application/json' -Body '{"draft":false,"make_latest":"true"}'
    if ($published.draft) { throw "Release $tag is still a draft." }
    # Draft asset URLs use a temporary untagged path; refresh after publication.
    $publishedAssets = @(Invoke-RestMethod -Uri "$apiBase/releases/$($release.id)/assets" -Headers $headers)
    $publishedAsset = $publishedAssets | Where-Object { $_.name -eq $assetName }
    if (!$publishedAsset) { throw 'Published release asset could not be confirmed.' }
    Write-Output "RELEASE_URL=$($published.html_url)"
    Write-Output "APK_URL=$($publishedAsset.browser_download_url)"
    Write-Output "APK_SHA256=$hash"
    Write-Output "ANDROID_BUILD_NUMBER=$BuildNumber"
} finally {
    if ($headers) { $headers.Clear() }
    $credentialLines = $null
    $passwordLine = $null
}
