# Orthanc + OHIF Docker Stack Startup Script for Windows PowerShell
# This script initializes and starts the complete Docker stack on Windows

param(
    [Parameter(Position=0)]
    [ValidateSet("start", "stop", "restart", "logs", "status", "update", "help")]
    [string]$Command = "start"
)

# Colors for output
function Write-Info { param($Message) Write-Host "[INFO] $Message" -ForegroundColor Blue }
function Write-Success { param($Message) Write-Host "[SUCCESS] $Message" -ForegroundColor Green }
function Write-Warning { param($Message) Write-Host "[WARNING] $Message" -ForegroundColor Yellow }
function Write-Error { param($Message) Write-Host "[ERROR] $Message" -ForegroundColor Red }

# Function to check if Docker is running
function Test-Docker {
    try {
        docker info | Out-Null
        Write-Success "Docker is running"
        return $true
    }
    catch {
        Write-Error "Docker is not running. Please start Docker Desktop and try again."
        return $false
    }
}

# Function to check if Docker Compose is available
function Test-DockerCompose {
    try {
        docker-compose --version | Out-Null
        Write-Success "Docker Compose is available"
        return $true
    }
    catch {
        Write-Error "Docker Compose is not available. Please install Docker Compose."
        return $false
    }
}

# Function to create necessary directories
function New-RequiredDirectories {
    Write-Info "Creating necessary directories..."
    
    $directories = @(
        "config",
        "config\ohif",
        "scripts",
        "nginx",
        "nginx\ssl"
    )
    
    foreach ($dir in $directories) {
        if (!(Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
            Write-Info "Created directory: $dir"
        }
    }
    
    Write-Success "All directories are ready"
}

# Function to check if configuration files exist
function Test-ConfigFiles {
    Write-Info "Checking configuration files..."
    
    $requiredFiles = @(
        "config\orthanc.json",
        "config\ohif\default.js",
        "nginx\nginx.conf",
        "scripts\main.py",
        "scripts\autorouting.lua",
        "docker-compose.yml"
    )
    
    $missingFiles = @()
    
    foreach ($file in $requiredFiles) {
        if (!(Test-Path $file)) {
            $missingFiles += $file
        }
    }
    
    if ($missingFiles.Count -gt 0) {
        Write-Error "Missing configuration files:"
        foreach ($file in $missingFiles) {
            Write-Host "  - $file" -ForegroundColor Red
        }
        Write-Error "Please ensure all configuration files are present."
        return $false
    }
    
    Write-Success "All configuration files are present"
    return $true
}

# Function to pull latest Docker images
function Update-DockerImages {
    Write-Info "Pulling latest Docker images..."
    docker-compose pull
    Write-Success "Docker images updated"
}

# Function to start the services
function Start-Services {
    Write-Info "Starting Orthanc + OHIF Docker stack..."
    docker-compose up -d
    Write-Success "Services started successfully"
}

# Function to wait for services to be ready
function Wait-ForServices {
    Write-Info "Waiting for services to be ready..."
    
    # Wait for Orthanc
    Write-Info "Checking Orthanc availability..."
    $timeout = 60
    $counter = 0
    
    do {
        try {
            $response = Invoke-RestMethod -Uri "http://localhost:8042/system" -Method Get -TimeoutSec 2
            Write-Success "Orthanc is ready"
            break
        }
        catch {
            if ($counter -ge $timeout) {
                Write-Error "Orthanc failed to start within $timeout seconds"
                return $false
            }
            Write-Host "." -NoNewline
            Start-Sleep -Seconds 2
            $counter += 2
        }
    } while ($counter -lt $timeout)
    
    Write-Host ""
    
    # Wait for OHIF
    Write-Info "Checking OHIF availability..."
    $counter = 0
    
    do {
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:3000" -Method Get -TimeoutSec 2
            Write-Success "OHIF is ready"
            break
        }
        catch {
            if ($counter -ge $timeout) {
                Write-Error "OHIF failed to start within $timeout seconds"
                return $false
            }
            Write-Host "." -NoNewline
            Start-Sleep -Seconds 2
            $counter += 2
        }
    } while ($counter -lt $timeout)
    
    Write-Host ""
    
    # Wait for Nginx
    Write-Info "Checking Nginx proxy availability..."
    $counter = 0
    
    do {
        try {
            $response = Invoke-WebRequest -Uri "http://localhost" -Method Get -TimeoutSec 2
            Write-Success "Nginx proxy is ready"
            break
        }
        catch {
            if ($counter -ge $timeout) {
                Write-Error "Nginx proxy failed to start within $timeout seconds"
                return $false
            }
            Write-Host "." -NoNewline
            Start-Sleep -Seconds 2
            $counter += 2
        }
    } while ($counter -lt $timeout)
    
    Write-Host ""
    return $true
}

# Function to display service status
function Show-Status {
    Write-Info "Service Status:"
    docker-compose ps
    Write-Host ""
}

# Function to display access URLs
function Show-URLs {
    Write-Success "🎉 Orthanc + OHIF Stack is ready!"
    Write-Host ""
    Write-Host "📱 Access URLs:" -ForegroundColor Blue
    Write-Host "  🔍 OHIF Viewer:     http://localhost" -ForegroundColor Green
    Write-Host "  ⚙️  Orthanc Explorer: http://localhost/orthanc" -ForegroundColor Green
    Write-Host "  🌐 Nginx Proxy:     http://localhost" -ForegroundColor Green
    Write-Host "  🔧 Orthanc API:     http://localhost:8042" -ForegroundColor Green
    Write-Host ""
    Write-Host "📊 Monitoring:" -ForegroundColor Blue
    Write-Host "  📈 System Status:    http://localhost:8042/system"
    Write-Host "  📊 Statistics:       http://localhost:8042/statistics"
    Write-Host "  🔍 Custom Status:    http://localhost:8042/custom/status"
    Write-Host ""
    Write-Host "📚 Logs:" -ForegroundColor Blue
    Write-Host "  View all logs:       " -NoNewline; Write-Host "docker-compose logs" -ForegroundColor Yellow
    Write-Host "  Follow logs:         " -NoNewline; Write-Host "docker-compose logs -f" -ForegroundColor Yellow
    Write-Host "  Orthanc logs:        " -NoNewline; Write-Host "docker-compose logs orthanc" -ForegroundColor Yellow
    Write-Host ""
}

# Function to run health checks
function Test-HealthChecks {
    Write-Info "Running health checks..."
    
    # Check Orthanc system endpoint
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:8042/system" -Method Get -TimeoutSec 5
        Write-Success "✅ Orthanc system endpoint is healthy"
    }
    catch {
        Write-Warning "⚠️  Orthanc system endpoint check failed"
    }
    
    # Check DICOMweb endpoint
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8042/dicom-web/studies" -Method Get -TimeoutSec 5
        Write-Success "✅ DICOMweb endpoint is healthy"
    }
    catch {
        Write-Warning "⚠️  DICOMweb endpoint check failed"
    }
    
    # Check custom Python endpoint
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:8042/custom/status" -Method Get -TimeoutSec 5
        Write-Success "✅ Custom Python endpoints are healthy"
    }
    catch {
        Write-Warning "⚠️  Custom Python endpoints check failed"
    }
    
    # Check OHIF
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:3000" -Method Get -TimeoutSec 5
        Write-Success "✅ OHIF viewer is healthy"
    }
    catch {
        Write-Warning "⚠️  OHIF viewer check failed"
    }
    
    # Check Nginx proxy
    try {
        $response = Invoke-WebRequest -Uri "http://localhost" -Method Get -TimeoutSec 5
        Write-Success "✅ Nginx proxy is healthy"
    }
    catch {
        Write-Warning "⚠️  Nginx proxy check failed"
    }
}

# Main execution function
function Start-Main {
    Write-Host ""
    Write-Host "==============================================" -ForegroundColor Blue
    Write-Host "    Orthanc + OHIF Docker Stack Launcher" -ForegroundColor Blue
    Write-Host "==============================================" -ForegroundColor Blue
    Write-Host ""
    
    # Pre-flight checks
    if (!(Test-Docker)) { return }
    if (!(Test-DockerCompose)) { return }
    
    New-RequiredDirectories
    
    if (!(Test-ConfigFiles)) { return }
    
    # Start the stack
    Update-DockerImages
    Start-Services
    
    if (!(Wait-ForServices)) { return }
    
    # Post-start verification
    Show-Status
    Test-HealthChecks
    Show-URLs
    
    Write-Host ""
    Write-Success "✅ Stack deployment completed successfully!"
    Write-Host ""
    Write-Host "💡 Tip: Use 'docker-compose logs -f' to monitor logs in real-time" -ForegroundColor Yellow
    Write-Host "💡 Tip: Use 'docker-compose down' to stop all services" -ForegroundColor Yellow
    Write-Host ""
}

# Handle script arguments
switch ($Command) {
    "stop" {
        Write-Info "Stopping Orthanc + OHIF Docker stack..."
        docker-compose down
        Write-Success "Services stopped"
    }
    "restart" {
        Write-Info "Restarting Orthanc + OHIF Docker stack..."
        docker-compose restart
        if (Wait-ForServices) {
            Test-HealthChecks
            Show-URLs
        }
    }
    "logs" {
        docker-compose logs -f
    }
    "status" {
        Show-Status
        Test-HealthChecks
    }
    "update" {
        Write-Info "Updating Docker images..."
        docker-compose pull
        docker-compose up -d
        if (Wait-ForServices) {
            Write-Success "Update completed"
        }
    }
    "help" {
        Write-Host "Usage: .\start.ps1 [command]"
        Write-Host ""
        Write-Host "Commands:"
        Write-Host "  start     Start the complete stack (default)"
        Write-Host "  stop      Stop all services"
        Write-Host "  restart   Restart all services"
        Write-Host "  logs      Follow logs in real-time"
        Write-Host "  status    Show service status and health"
        Write-Host "  update    Update Docker images and restart"
        Write-Host "  help      Show this help message"
    }
    "start" {
        Start-Main
    }
    default {
        Start-Main
    }
} 