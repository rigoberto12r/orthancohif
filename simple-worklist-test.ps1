# Simple Worklist Test Script
Write-Host "=== Worklist Test ===" -ForegroundColor Blue

# Create worklist directory
$worklistDir = "worklist-samples"
if (!(Test-Path $worklistDir)) {
    New-Item -ItemType Directory -Path $worklistDir
    Write-Host "Created directory: $worklistDir" -ForegroundColor Green
}

# Create a simple worklist file
$worklistContent = @"
(0008,0005) CS [ISO_IR 100]
(0008,0050) SH [ACC001]
(0010,0010) PN [DOE^JOHN]
(0010,0020) LO [PAT001]
(0010,0030) DA [19800101]
(0010,0040) CS [M]
(0020,000d) UI [1.2.826.0.1.3680043.8.498.12345]
(0040,0100) SQ
(fffe,e000) na
(0008,0060) CS [CT]
(0040,0001) AE [ORTHANC]
(0040,0002) DA [20241201]
(0040,0003) TM [120000]
(0040,0007) LO [CT CHEST ROUTINE]
(0040,0009) SH [SCHEDULED]
(fffe,e00d) na
(fffe,e0dd) na
(0040,1001) SH [SCHEDULED]
"@

$fileName = "sample_worklist.wl"
$filePath = Join-Path $worklistDir $fileName
$worklistContent | Out-File -FilePath $filePath -Encoding UTF8

Write-Host "Created worklist file: $fileName" -ForegroundColor Green

# Copy to Docker container
try {
    docker exec orthanc-server mkdir -p /var/lib/orthanc/worklists
    docker cp $filePath orthanc-server:/var/lib/orthanc/worklists/$fileName
    Write-Host "Copied to Orthanc container" -ForegroundColor Green
} catch {
    Write-Host "Failed to copy to container" -ForegroundColor Red
}

# Check if worklist plugin is loaded
Write-Host "`nChecking worklist plugin..." -ForegroundColor Yellow
try {
    $plugins = Invoke-RestMethod -Uri "http://localhost:8042/plugins"
    if ($plugins -contains "worklists") {
        Write-Host "✅ Worklist plugin is loaded" -ForegroundColor Green
    } else {
        Write-Host "❌ Worklist plugin not found" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Cannot check plugins" -ForegroundColor Red
}

Write-Host "`n=== How to Test Worklist ===" -ForegroundColor Blue
Write-Host "1. Use a DICOM tool like findscu from DCMTK:"
Write-Host "   findscu -v -S -k 0008,0050 -aec ORTHANC localhost 4242"
Write-Host ""
Write-Host "2. Configure a DICOM modality to query:"
Write-Host "   AE Title: ORTHANC"
Write-Host "   Host: localhost"  
Write-Host "   Port: 4242"
Write-Host ""
Write-Host "3. The worklist contains:"
Write-Host "   Patient: DOE^JOHN (PAT001)"
Write-Host "   Procedure: CT CHEST ROUTINE"
Write-Host "   Accession: ACC001"
Write-Host "" 