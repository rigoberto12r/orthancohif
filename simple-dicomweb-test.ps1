# Simple DICOMweb Test Script
Write-Host "=== Simple DICOMweb Test ===" -ForegroundColor Blue

# Test 1: Query all studies
Write-Host "`n1. Querying all studies..." -ForegroundColor Yellow
try {
    $studiesResponse = Invoke-WebRequest -Uri "http://localhost:8042/dicom-web/studies" -Headers @{"Accept"="application/dicom+json"}
    $studies = $studiesResponse.Content | ConvertFrom-Json
    Write-Host "✅ Found $($studies.Count) studies" -ForegroundColor Green
    
    if ($studies.Count -gt 0) {
        $study = $studies[0]
        $studyUID = $study.'0020000D'.Value[0]
        Write-Host "  First study UID: $studyUID" -ForegroundColor Cyan
        
        # Test 2: Query series for this study  
        Write-Host "`n2. Querying series..." -ForegroundColor Yellow
        try {
            $seriesUri = "http://localhost:8042/dicom-web/studies/$studyUID/series"
            $seriesResponse = Invoke-WebRequest -Uri $seriesUri -Headers @{"Accept"="application/dicom+json"}
            $series = $seriesResponse.Content | ConvertFrom-Json
            Write-Host "✅ Found $($series.Count) series" -ForegroundColor Green
            
            if ($series.Count -gt 0) {
                $firstSeries = $series[0]
                $seriesUID = $firstSeries.'0020000E'.Value[0]
                Write-Host "  First series UID: $seriesUID" -ForegroundColor Cyan
                
                # Test 3: Query instances
                Write-Host "`n3. Querying instances..." -ForegroundColor Yellow
                try {
                    $instancesUri = "http://localhost:8042/dicom-web/studies/$studyUID/series/$seriesUID/instances"
                    $instancesResponse = Invoke-WebRequest -Uri $instancesUri -Headers @{"Accept"="application/dicom+json"}
                    $instances = $instancesResponse.Content | ConvertFrom-Json
                    Write-Host "✅ Found $($instances.Count) instances" -ForegroundColor Green
                    
                    if ($instances.Count -gt 0) {
                        $instance = $instances[0]
                        $instanceUID = $instance.'00080018'.Value[0]
                        Write-Host "  First instance UID: $instanceUID" -ForegroundColor Cyan
                        
                        # Test 4: Retrieve metadata
                        Write-Host "`n4. Testing metadata retrieval..." -ForegroundColor Yellow
                        try {
                            $metadataUri = "http://localhost:8042/dicom-web/studies/$studyUID/metadata"
                            $metadataResponse = Invoke-WebRequest -Uri $metadataUri -Headers @{"Accept"="application/dicom+json"}
                            Write-Host "✅ Metadata retrieved successfully" -ForegroundColor Green
                        } catch {
                            Write-Host "❌ Metadata retrieval failed" -ForegroundColor Red
                        }
                        
                        # Test 5: Retrieve instance
                        Write-Host "`n5. Testing instance retrieval..." -ForegroundColor Yellow
                        try {
                            $instanceUri = "http://localhost:8042/dicom-web/studies/$studyUID/series/$seriesUID/instances/$instanceUID"
                            $instanceResponse = Invoke-WebRequest -Uri $instanceUri -Headers @{"Accept"="application/dicom"}
                            Write-Host "✅ Instance retrieved (Size: $($instanceResponse.Content.Length) bytes)" -ForegroundColor Green
                        } catch {
                            Write-Host "❌ Instance retrieval failed" -ForegroundColor Red
                        }
                    }
                } catch {
                    Write-Host "❌ Instance query failed" -ForegroundColor Red
                }
            }
        } catch {
            Write-Host "❌ Series query failed" -ForegroundColor Red
        }
    } else {
        Write-Host "ℹ️  No studies found. Upload DICOM files first." -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Study query failed" -ForegroundColor Red
}

Write-Host "`n=== DICOMweb Endpoints ===" -ForegroundColor Blue
Write-Host "Studies:   http://localhost:8042/dicom-web/studies" -ForegroundColor Green
Write-Host "Series:    http://localhost:8042/dicom-web/studies/{study}/series" -ForegroundColor Green  
Write-Host "Instances: http://localhost:8042/dicom-web/studies/{study}/series/{series}/instances" -ForegroundColor Green
Write-Host "Metadata:  http://localhost:8042/dicom-web/studies/{study}/metadata" -ForegroundColor Green

Write-Host "`n=== Next Steps ===" -ForegroundColor Yellow
Write-Host "1. Access OHIF at: http://localhost"
Write-Host "2. Upload DICOM files via: http://localhost:8042/ui/"
Write-Host "3. View studies in OHIF viewer"
Write-Host "" 