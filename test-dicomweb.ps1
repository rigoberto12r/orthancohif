# DICOMweb Testing Script
# Tests QIDO-RS, WADO-RS, and WADO-URI endpoints

Write-Host "=== DICOMweb Testing Script ===" -ForegroundColor Blue
Write-Host ""

# Function to format JSON output
function Show-JsonResponse {
    param($response)
    try {
        $json = $response.Content | ConvertFrom-Json
        return $json | ConvertTo-Json -Depth 3
    } catch {
        return $response.Content
    }
}

# 1. QIDO-RS - Query Information Object
Write-Host "1. QIDO-RS - Querying Studies..." -ForegroundColor Yellow
try {
    $studiesResponse = Invoke-WebRequest -Uri "http://localhost:8042/dicom-web/studies" -Headers @{"Accept"="application/dicom+json"}
    $studies = $studiesResponse.Content | ConvertFrom-Json
    Write-Host "✅ Found $($studies.Count) study(ies)" -ForegroundColor Green
    
    if ($studies.Count -gt 0) {
        Write-Host "`nFirst study details:" -ForegroundColor Cyan
        $firstStudy = $studies[0]
        $studyUID = $firstStudy.'0020000D'.Value[0]
        $patientName = if ($firstStudy.'00100010') { $firstStudy.'00100010'.Value[0] } else { "Unknown" }
        $studyDate = if ($firstStudy.'00080020') { $firstStudy.'00080020'.Value[0] } else { "Unknown" }
        
        Write-Host "  Study UID: $studyUID"
        Write-Host "  Patient: $patientName"
        Write-Host "  Date: $studyDate"
        
        # Query series for this study
        Write-Host "`n2. QIDO-RS - Querying Series for first study..." -ForegroundColor Yellow
        try {
            $seriesResponse = Invoke-WebRequest -Uri "http://localhost:8042/dicom-web/studies/$studyUID/series" -Headers @{"Accept"="application/dicom+json"}
            $series = $seriesResponse.Content | ConvertFrom-Json
            Write-Host "✅ Found $($series.Count) series in this study" -ForegroundColor Green
            
            if ($series.Count -gt 0) {
                $firstSeries = $series[0]
                $seriesUID = $firstSeries.'0020000E'.Value[0]
                $modality = if ($firstSeries.'00080060') { $firstSeries.'00080060'.Value[0] } else { "Unknown" }
                
                Write-Host "  First series UID: $seriesUID"
                Write-Host "  Modality: $modality"
                
                # Query instances
                Write-Host "`n3. QIDO-RS - Querying Instances..." -ForegroundColor Yellow
                try {
                    $instancesResponse = Invoke-WebRequest -Uri "http://localhost:8042/dicom-web/studies/$studyUID/series/$seriesUID/instances" -Headers @{"Accept"="application/dicom+json"}
                    $instances = $instancesResponse.Content | ConvertFrom-Json
                    Write-Host "✅ Found $($instances.Count) instance(s) in this series" -ForegroundColor Green
                    
                    if ($instances.Count -gt 0) {
                        $firstInstance = $instances[0]
                        $instanceUID = $firstInstance.'00080018'.Value[0]
                        Write-Host "  First instance UID: $instanceUID"
                        
                        # Test WADO-RS - Retrieve study
                        Write-Host "`n4. WADO-RS - Testing retrieve endpoints..." -ForegroundColor Yellow
                        
                        # Test study metadata
                        try {
                            $metadataResponse = Invoke-WebRequest -Uri "http://localhost:8042/dicom-web/studies/$studyUID/metadata" -Headers @{"Accept"="application/dicom+json"}
                            Write-Host "✅ Study metadata retrieved successfully" -ForegroundColor Green
                        } catch {
                            Write-Host "❌ Study metadata retrieval failed" -ForegroundColor Red
                        }
                        
                        # Test instance retrieval
                        try {
                            $instanceResponse = Invoke-WebRequest -Uri "http://localhost:8042/dicom-web/studies/$studyUID/series/$seriesUID/instances/$instanceUID" -Headers @{"Accept"="application/dicom; transfer-syntax=*"}
                            Write-Host "✅ Instance retrieved successfully (Size: $($instanceResponse.Content.Length) bytes)" -ForegroundColor Green
                        } catch {
                            Write-Host "❌ Instance retrieval failed" -ForegroundColor Red
                        }
                        
                        # Test WADO-URI (legacy)
                        Write-Host "`n5. WADO-URI - Testing legacy endpoint..." -ForegroundColor Yellow
                        try {
                            $wadoUri = "http://localhost:8042/dicom-web?requestType=WADO&studyUID=$studyUID&seriesUID=$seriesUID&objectUID=$instanceUID&contentType=application/dicom"
                            $wadoResponse = Invoke-WebRequest -Uri $wadoUri
                            Write-Host "✅ WADO-URI retrieval successful (Size: $($wadoResponse.Content.Length) bytes)" -ForegroundColor Green
                        } catch {
                            Write-Host "❌ WADO-URI retrieval failed" -ForegroundColor Red
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
        Write-Host "ℹ️  No studies found. Upload some DICOM files first." -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Study query failed" -ForegroundColor Red
}

# Test STOW-RS capabilities
Write-Host "`n6. STOW-RS - Testing capabilities..." -ForegroundColor Yellow
try {
    $stowResponse = Invoke-WebRequest -Uri "http://localhost:8042/dicom-web/studies" -Method Options
    Write-Host "✅ STOW-RS endpoint is available for uploading" -ForegroundColor Green
} catch {
    Write-Host "❌ STOW-RS endpoint test failed" -ForegroundColor Red
}

Write-Host "`n=== DICOMweb Test Summary ===" -ForegroundColor Blue
Write-Host "QIDO-RS (Query):     http://localhost:8042/dicom-web/studies" -ForegroundColor Cyan
Write-Host "WADO-RS (Retrieve):  http://localhost:8042/dicom-web/studies/{study-uid}" -ForegroundColor Cyan
Write-Host "WADO-URI (Legacy):   http://localhost:8042/dicom-web?requestType=WADO..." -ForegroundColor Cyan
Write-Host "STOW-RS (Store):     http://localhost:8042/dicom-web/studies" -ForegroundColor Cyan

Write-Host "`n=== Common QIDO-RS Queries ===" -ForegroundColor Green
Write-Host "All studies:         GET /dicom-web/studies"
Write-Host "Studies by patient:  GET /dicom-web/studies?PatientName=DOE^JOHN"
Write-Host "Studies by date:     GET /dicom-web/studies?StudyDate=20240101-20241231"
Write-Host "Studies by modality: GET /dicom-web/studies?ModalitiesInStudy=CT"
Write-Host "" 