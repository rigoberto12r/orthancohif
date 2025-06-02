# Verification script for Orthanc + OHIF setup
# This script checks if plugins are loaded and services are working

function Write-Info { param($Message) Write-Host "[INFO] $Message" -ForegroundColor Blue }
function Write-Success { param($Message) Write-Host "[SUCCESS] $Message" -ForegroundColor Green }
function Write-Warning { param($Message) Write-Host "[WARNING] $Message" -ForegroundColor Yellow }
function Write-Error { param($Message) Write-Host "[ERROR] $Message" -ForegroundColor Red }

Write-Host ""
Write-Host "=============================================" -ForegroundColor Blue
Write-Host "    Orthanc + OHIF Setup Verification" -ForegroundColor Blue
Write-Host "=============================================" -ForegroundColor Blue
Write-Host ""

# Check if services are running
Write-Info "Checking if Docker containers are running..."
try {
    $containers = docker-compose ps --services --filter "status=running"
    if ($containers -contains "orthanc" -and $containers -contains "ohif" -and $containers -contains "nginx") {
        Write-Success "All Docker containers are running"
    } else {
        Write-Error "Some containers are not running. Run 'docker-compose ps' to check status"
        exit 1
    }
} catch {
    Write-Error "Failed to check container status: $($_.Exception.Message)"
    exit 1
}

# Check Orthanc system
Write-Info "Checking Orthanc system status..."
try {
    $orthancSystem = Invoke-RestMethod -Uri "http://localhost:8042/system" -Method Get -TimeoutSec 10
    Write-Success "Orthanc system is responding"
    Write-Info "Orthanc Version: $($orthancSystem.Version)"
    Write-Info "Database Version: $($orthancSystem.DatabaseVersion)"
} catch {
    Write-Error "Failed to connect to Orthanc system endpoint"
}

# Check Orthanc plugins
Write-Info "Checking installed Orthanc plugins..."
try {
    $plugins = Invoke-RestMethod -Uri "http://localhost:8042/plugins" -Method Get -TimeoutSec 10
    if ($plugins.Count -gt 0) {
        Write-Success "Found $($plugins.Count) plugin(s) installed:"
        foreach ($plugin in $plugins) {
            $pluginInfo = Invoke-RestMethod -Uri "http://localhost:8042/plugins/$plugin" -Method Get -TimeoutSec 5
            Write-Host "  - $plugin (v$($pluginInfo.Version))" -ForegroundColor Green
        }
    } else {
        Write-Warning "No plugins found. This might be normal for some Orthanc distributions."
    }
} catch {
    Write-Warning "Failed to retrieve plugin information: $($_.Exception.Message)"
}

# Check DICOMweb endpoints
Write-Info "Checking DICOMweb endpoints..."
try {
    $studies = Invoke-WebRequest -Uri "http://localhost:8042/dicom-web/studies" -Method Get -TimeoutSec 10
    Write-Success "DICOMweb QIDO-RS endpoint is working"
} catch {
    Write-Error "DICOMweb QIDO-RS endpoint is not responding"
}

# Check OHIF
Write-Info "Checking OHIF viewer..."
try {
    $ohif = Invoke-WebRequest -Uri "http://localhost:3000" -Method Get -TimeoutSec 10
    Write-Success "OHIF viewer is responding"
} catch {
    Write-Error "OHIF viewer is not responding"
}

# Check Nginx proxy
Write-Info "Checking Nginx proxy..."
try {
    $nginx = Invoke-WebRequest -Uri "http://localhost" -Method Get -TimeoutSec 10
    Write-Success "Nginx proxy is working"
} catch {
    Write-Error "Nginx proxy is not responding"
}

# Check OHIF configuration
Write-Info "Checking OHIF configuration..."
try {
    $ohifConfig = Invoke-WebRequest -Uri "http://localhost:3000/config/default.js" -Method Get -TimeoutSec 10
    if ($ohifConfig.Content -match "modes.*@ohif/mode-viewer") {
        Write-Success "OHIF modes are configured correctly"
    } else {
        Write-Warning "OHIF modes configuration might be missing"
    }
} catch {
    Write-Warning "Could not verify OHIF configuration"
}

# Check specific Orthanc endpoints
Write-Info "Checking additional Orthanc endpoints..."

# Stone Web Viewer
try {
    $stone = Invoke-WebRequest -Uri "http://localhost:8042/stone-webviewer/" -Method Get -TimeoutSec 5
    Write-Success "Stone Web Viewer is available"
} catch {
    Write-Info "Stone Web Viewer not available (this is normal if plugin is not installed)"
}

# WebDAV
try {
    $webdav = Invoke-WebRequest -Uri "http://localhost:8042/webdav/" -Method Get -TimeoutSec 5
    Write-Success "WebDAV endpoint is available"
} catch {
    Write-Info "WebDAV endpoint not available"
}

Write-Host ""
Write-Host "=============================================" -ForegroundColor Blue
Write-Host "Verification complete!" -ForegroundColor Blue
Write-Host ""
Write-Host "📱 Access URLs:" -ForegroundColor Blue
Write-Host "  🔍 OHIF Viewer:      http://localhost" -ForegroundColor Green
Write-Host "  ⚙️  Orthanc Explorer:  http://localhost:8042" -ForegroundColor Green
Write-Host "  🌐 Nginx Proxy:      http://localhost" -ForegroundColor Green
Write-Host "  📊 System Status:    http://localhost:8042/system" -ForegroundColor Green
Write-Host "  🔧 Plugins:          http://localhost:8042/plugins" -ForegroundColor Green
Write-Host ""

# Additional troubleshooting info
Write-Host "🔧 Troubleshooting:" -ForegroundColor Yellow
Write-Host "  - If OHIF shows 'No modes defined': Check config/ohif/default.js"
Write-Host "  - If no plugins visible: Check docker-compose logs orthanc"
Write-Host "  - For CORS issues: Check nginx/nginx.conf"
Write-Host "  - View logs: docker-compose logs -f"
Write-Host "" 