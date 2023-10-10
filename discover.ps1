# Initialize an array to store certificate information
$certificates = @()

# Error handling function
function Handle-Error {
    param (
        [string]$message
    )
    Write-Host "Error: $message" -ForegroundColor Red
}

# Search for PEM files on the system
function Find-PEMFiles {
    param (
        [string]$searchPath
    )
    $pemFiles = Get-ChildItem -Path $searchPath -Filter "*.pem" -Recurse -File
    $crtFiles = Get-ChildItem -Path $searchPath -Filter "*.crt" -Recurse -File
    return $pemFiles + $crtFiles
}

# Search for JKS files on the system
function Find-JKSFiles {
    param (
        [string]$searchPath
    )
    $jksFiles = Get-ChildItem -Path $searchPath -Filter "*.jks" -Recurse -File
    $p12Files = Get-ChildItem -Path $searchPath -Filter "*.p12" -Recurse -File
    return $jksFiles + $p12Files
}

# Process a PEM file
function Process-PEMFile {
    param (
        [string]$filePath
    )
    if (Test-Path $filePath) {
        Write-Host "Processing PEM file: $filePath"
        $certInfo = Get-Content $filePath | Out-String
        $certificates += $certInfo
    } else {
        Handle-Error "PEM file not found: $filePath"
    }
}

# Process a JKS file
function Process-JKSFile {
    param (
        [string]$filePath
    )
    if (Test-Path $filePath) {
        Write-Host "Processing JKS file: $filePath"
        # Use keytool to list certificates in the keystore
        $keystoreInfo = Invoke-Expression "keytool -list -keystore `"$filePath`" -storepass changeit"
        if ($LASTEXITCODE -eq 0) {
            $certificates += $keystoreInfo
        } else {
            Handle-Error "Failed to list certificates in $filePath"
        }
    } else {
        Handle-Error "JKS file not found: $filePath"
    }
}

# Search for PEM and JKS files and process them
$baseSearchPath = "C:\path\to\search"
$pemFiles = Find-PEMFiles -searchPath $baseSearchPath
$jksFiles = Find-JKSFiles -searchPath $baseSearchPath

foreach ($pemFile in $pemFiles) {
    Process-PEMFile -filePath $pemFile.FullName
}

foreach ($jksFile in $jksFiles) {
    Process-JKSFile -filePath $jksFile.FullName
}

# Output the certificate information in JSON format
if ($certificates.Count -eq 0) {
    Handle-Error "No certificates found"
} else {
    $certificates | ConvertTo-Json | Out-File -FilePath "certificate_inventory.json" -Encoding UTF8

    Write-Host "Certificate inventory has been saved to certificate_inventory.json" -ForegroundColor Green
}
