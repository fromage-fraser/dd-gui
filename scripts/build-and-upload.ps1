[CmdletBinding()]
param(
    [switch]$SkipBuild
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$credentialFile = Join-Path $projectRoot ".dd-gui-ftp.netrc"
$ftpHost = "nosferatu.smihilist.com"
$remoteDirectory = "var/www/smihilist.com/dd4/web/main/gui"
$packageFiles = @("DD_GUI.mpackage", "DD_GUI.xml")

if (-not (Test-Path -LiteralPath $credentialFile -PathType Leaf)) {
    throw "Missing local FTP credentials at $credentialFile."
}

if (-not $SkipBuild) {
    Push-Location $projectRoot
    try {
        & muddle
        if ($LASTEXITCODE -ne 0) {
            throw "muddle failed with exit code $LASTEXITCODE."
        }
    }
    finally {
        Pop-Location
    }
}

foreach ($packageFile in $packageFiles) {
    $localFile = Join-Path $projectRoot "build/$packageFile"
    if (-not (Test-Path -LiteralPath $localFile -PathType Leaf)) {
        throw "Expected build artifact not found: $localFile"
    }

    # A double slash selects the server's absolute path rather than the FTP-root-relative path.
    $remoteUrl = "ftp://$ftpHost//$remoteDirectory/$packageFile"
    & curl.exe --fail --silent --show-error --netrc --netrc-file $credentialFile --ftp-create-dirs --upload-file $localFile $remoteUrl
    if ($LASTEXITCODE -ne 0) {
        throw "FTP upload failed for $packageFile with exit code $LASTEXITCODE."
    }
}
