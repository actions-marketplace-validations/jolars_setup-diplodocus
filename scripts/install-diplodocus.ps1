$ErrorActionPreference = 'Stop'

foreach ($name in @('DIPLODOCUS_VERSION', 'DIPLODOCUS_ASSET', 'DIPLODOCUS_INSTALL_DIR')) {
    if (-not [Environment]::GetEnvironmentVariable($name)) {
        throw "Missing required environment variable: $name"
    }
}

$asset = $env:DIPLODOCUS_ASSET
$base = "https://github.com/jolars/diplodocus/releases/download/$env:DIPLODOCUS_VERSION"
$installerDir = Join-Path ([IO.Path]::GetTempPath()) ("diplodocus-install-" + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $installerDir | Out-Null

try {
    $archivePath = Join-Path $installerDir $asset
    $checksumPath = Join-Path $installerDir 'checksum'
    Write-Host "Downloading $asset ($env:DIPLODOCUS_VERSION)..."
    Invoke-WebRequest -Uri "$base/$asset" -OutFile $archivePath
    Invoke-WebRequest -Uri "$base/$asset.sha256" -OutFile $checksumPath

    $expected = $null
    foreach ($line in Get-Content $checksumPath) {
        $parts = $line -split '\s+', 2
        if ($parts.Count -eq 2 -and $parts[1].TrimStart('*').Trim() -eq $asset) {
            if ($expected) { throw "Duplicate SHA256 checksum for $asset" }
            $expected = $parts[0]
        }
    }
    if ($expected -notmatch '^[0-9a-fA-F]{64}$') {
        throw "Missing or invalid SHA256 checksum for $asset"
    }
    $actual = (Get-FileHash -Path $archivePath -Algorithm SHA256).Hash
    if ($actual -ne $expected) { throw "Checksum verification failed for $asset" }
    Write-Host "Verified $asset (sha256)"

    if (Get-Command gh -ErrorAction SilentlyContinue) {
        $attestation = & gh attestation verify $archivePath --repo jolars/diplodocus 2>&1 | Out-String
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Verified $asset provenance (attestation)"
        } elseif ($attestation -match '(?i)no attestation|http 404') {
            Write-Warning 'No provenance attestation for this release; skipping'
            # GitHub propagates the last native exit code when the script ends.
            $global:LASTEXITCODE = 0
        } else {
            throw "Provenance verification failed for ${asset}: $attestation"
        }
    } else {
        Write-Warning 'gh CLI not found; skipping provenance verification'
    }

    Expand-Archive -Path $archivePath -DestinationPath $installerDir -Force
    New-Item -ItemType Directory -Path $env:DIPLODOCUS_INSTALL_DIR -Force | Out-Null
    Copy-Item -Path (Join-Path $installerDir 'diplodocus.exe') -Destination $env:DIPLODOCUS_INSTALL_DIR -Force
    Write-Host "Installed Diplodocus to $(Join-Path $env:DIPLODOCUS_INSTALL_DIR 'diplodocus.exe')"
}
finally {
    Remove-Item -Recurse -Force $installerDir -ErrorAction SilentlyContinue
}
