# Simple verification script for Orthanc + OHIF
Write-Host "=== Orthanc + OHIF Status Check ===" -ForegroundColor Blue

# Check containers
Write-Host "`nChecking containers..." -ForegroundColor Yellow
docker-compose ps

# Check Orthanc system
Write-Host "`nChecking Orthanc system..." -ForegroundColor Yellow
try {
    $system = Invoke-RestMethod -Uri "http://localhost:8042/system" -TimeoutSec 5
    Write-Host "✅ Orthanc is running - Version: $($system.Version)" -ForegroundColor Green
} catch {
    Write-Host "❌ Orthanc is not responding" -ForegroundColor Red
}

# Check plugins
Write-Host "`nChecking plugins..." -ForegroundColor Yellow
try {
    $plugins = Invoke-RestMethod -Uri "http://localhost:8042/plugins" -TimeoutSec 5
    Write-Host "✅ Found $($plugins.Count) plugins loaded" -ForegroundColor Green
    Write-Host "Main plugins: dicom-web, stone-webviewer, ohif, gdcm, worklists" -ForegroundColor Cyan
} catch {
    Write-Host "❌ Could not retrieve plugins" -ForegroundColor Red
}

# Check DICOMweb
Write-Host "`nChecking DICOMweb..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8042/dicom-web/studies" -TimeoutSec 5
    Write-Host "✅ DICOMweb endpoint is working" -ForegroundColor Green
} catch {
    Write-Host "❌ DICOMweb endpoint not responding" -ForegroundColor Red
}

# Check OHIF
Write-Host "`nChecking OHIF..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:3000" -TimeoutSec 5
    Write-Host "✅ OHIF is responding" -ForegroundColor Green
} catch {
    Write-Host "❌ OHIF is not responding" -ForegroundColor Red
}

# Check Nginx
Write-Host "`nChecking Nginx proxy..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost" -TimeoutSec 5
    Write-Host "✅ Nginx proxy is working" -ForegroundColor Green
} catch {
    Write-Host "❌ Nginx proxy not responding" -ForegroundColor Red
}

Write-Host "`n=== Access URLs ===" -ForegroundColor Blue
Write-Host "OHIF Viewer:      http://localhost" -ForegroundColor Green
Write-Host "Orthanc Explorer: http://localhost:8042" -ForegroundColor Green
Write-Host "Plugins List:     http://localhost:8042/plugins" -ForegroundColor Green
Write-Host "System Status:    http://localhost:8042/system" -ForegroundColor Green

Write-Host "`n=== Quick Troubleshooting ===" -ForegroundColor Yellow
Write-Host "View logs:        docker-compose logs" 
Write-Host "Restart:          docker-compose restart"
Write-Host "Stop all:         docker-compose down" 