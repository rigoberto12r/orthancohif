# Worklist Testing Script
# Creates sample worklist files and tests worklist functionality

Write-Host "=== Worklist Testing Script ===" -ForegroundColor Blue
Write-Host ""

# Create worklist directory if it doesn't exist
$worklistDir = "worklist-samples"
if (!(Test-Path $worklistDir)) {
    New-Item -ItemType Directory -Path $worklistDir
    Write-Host "✅ Created worklist samples directory" -ForegroundColor Green
}

# Function to create a sample worklist file
function New-WorklistItem {
    param(
        [string]$PatientID,
        [string]$PatientName,
        [string]$StudyInstanceUID,
        [string]$AccessionNumber,
        [string]$Modality,
        [string]$StudyDescription,
        [string]$FileName
    )
    
    $worklistContent = @"
# Sample DICOM Worklist File
# This file defines a worklist item for a scheduled procedure

(0008,0005) CS [ISO_IR 100]                               # Specific Character Set
(0008,0050) SH [$AccessionNumber]                         # Accession Number
(0008,0090) PN [Referring Physician]                     # Referring Physician Name
(0008,1110) SQ                                           # Referenced Study Sequence
(fffe,e000) na                                           # Item
(0008,1150) UI [1.2.840.10008.5.1.4.1.1.1]            # Referenced SOP Class UID
(0008,1155) UI [$StudyInstanceUID]                       # Referenced SOP Instance UID
(fffe,e00d) na                                           # Item Delimitation
(fffe,e0dd) na                                           # Sequence Delimitation

(0010,0010) PN [$PatientName]                            # Patient Name
(0010,0020) LO [$PatientID]                              # Patient ID
(0010,0030) DA [19800101]                                # Patient Birth Date
(0010,0040) CS [M]                                       # Patient Sex

(0020,000d) UI [$StudyInstanceUID]                       # Study Instance UID

(0032,1032) PN [Requesting Physician]                    # Requesting Physician
(0032,1060) LO [$StudyDescription]                       # Requested Procedure Description

(0040,0100) SQ                                           # Scheduled Procedure Step Sequence
(fffe,e000) na                                           # Item
(0008,0060) CS [$Modality]                               # Modality
(0040,0001) AE [ORTHANC]                                 # Scheduled Station AE Title
(0040,0002) DA [$(Get-Date -Format 'yyyyMMdd')]         # Scheduled Procedure Step Start Date
(0040,0003) TM [$(Get-Date -Format 'HHmmss')]           # Scheduled Procedure Step Start Time
(0040,0006) PN [Performing Physician]                    # Scheduled Performing Physician Name
(0040,0007) LO [$StudyDescription]                       # Scheduled Procedure Step Description
(0040,0009) SH [SCHEDULED]                               # Scheduled Procedure Step ID
(fffe,e00d) na                                           # Item Delimitation
(fffe,e0dd) na                                           # Sequence Delimitation

(0040,1001) SH [SCHEDULED]                               # Requested Procedure ID
"@

    $filePath = Join-Path $worklistDir $FileName
    $worklistContent | Out-File -FilePath $filePath -Encoding UTF8
    return $filePath
}

# Create sample worklist items
Write-Host "1. Creating sample worklist items..." -ForegroundColor Yellow

$samples = @(
    @{
        PatientID = "PAT001"
        PatientName = "DOE^JOHN"
        StudyInstanceUID = "1.2.826.0.1.3680043.8.498.$(Get-Random)"
        AccessionNumber = "ACC001"
        Modality = "CT"
        StudyDescription = "CT CHEST ROUTINE"
        FileName = "worklist_ct_001.wl"
    },
    @{
        PatientID = "PAT002" 
        PatientName = "SMITH^JANE"
        StudyInstanceUID = "1.2.826.0.1.3680043.8.498.$(Get-Random)"
        AccessionNumber = "ACC002"
        Modality = "MR"
        StudyDescription = "MR BRAIN W/WO CONTRAST"
        FileName = "worklist_mr_002.wl"
    },
    @{
        PatientID = "PAT003"
        PatientName = "BROWN^ROBERT"
        StudyInstanceUID = "1.2.826.0.1.3680043.8.498.$(Get-Random)"
        AccessionNumber = "ACC003"
        Modality = "US"
        StudyDescription = "US ABDOMEN COMPLETE"
        FileName = "worklist_us_003.wl"
    }
)

$createdFiles = @()
foreach ($sample in $samples) {
    $filePath = New-WorklistItem @sample
    $createdFiles += $filePath
    Write-Host "  ✅ Created: $($sample.FileName) - $($sample.PatientName) ($($sample.Modality))" -ForegroundColor Green
}

Write-Host "`n2. Copying worklist files to Orthanc..." -ForegroundColor Yellow

# Copy files to the docker container's worklist directory
foreach ($file in $createdFiles) {
    try {
        # Copy to local directory that's mounted in container
        $fileName = Split-Path $file -Leaf
        docker exec orthanc-server mkdir -p /var/lib/orthanc/worklists
        docker cp $file orthanc-server:/var/lib/orthanc/worklists/$fileName
        Write-Host "  ✅ Copied $fileName to Orthanc container" -ForegroundColor Green
    } catch {
        Write-Host "  ❌ Failed to copy $fileName`: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n3. Testing Worklist queries..." -ForegroundColor Yellow

# Test C-FIND worklist query using dcmtk tools (if available)
Write-Host "`nℹ️  To test worklist with DICOM C-FIND, you can use:" -ForegroundColor Cyan
Write-Host "  findscu -v -S -k 0008,0050 -k 0010,0010 -k 0010,0020 -k 0040,0100 -aec ORTHANC localhost 4242" -ForegroundColor Yellow

# Test via Orthanc REST API
Write-Host "`n4. Testing via Orthanc REST API..." -ForegroundColor Yellow
try {
    # Check if worklist plugin is loaded
    $plugins = Invoke-RestMethod -Uri "http://localhost:8042/plugins"
    if ($plugins -contains "worklists") {
        Write-Host "✅ Worklist plugin is loaded" -ForegroundColor Green
        
        # Try to get worklist configuration
        try {
            $system = Invoke-RestMethod -Uri "http://localhost:8042/system"
            Write-Host "✅ Orthanc system accessible - plugins should be working" -ForegroundColor Green
        } catch {
            Write-Host "❌ Cannot access Orthanc system" -ForegroundColor Red
        }
    } else {
        Write-Host "❌ Worklist plugin not found in loaded plugins" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Failed to check plugins: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n5. Manual testing instructions..." -ForegroundColor Yellow
Write-Host "To manually test the worklist:" -ForegroundColor Cyan
Write-Host "1. Use a DICOM viewer/client that supports C-FIND MWL (Modality Worklist)"
Write-Host "2. Configure it to query: AE=ORTHANC, Host=localhost, Port=4242"
Write-Host "3. Perform a Modality Worklist query"
Write-Host "4. You should see the 3 worklist items we created"

Write-Host "`n=== Sample DICOM C-FIND Commands ===" -ForegroundColor Green
Write-Host "Query all worklist items:"
Write-Host "  findscu -v -S -k 0008,0050 -aec ORTHANC localhost 4242"
Write-Host ""
Write-Host "Query by Patient Name:"
Write-Host "  findscu -v -S -k 0010,0010=DOE^JOHN -aec ORTHANC localhost 4242"
Write-Host ""
Write-Host "Query by Modality:"
Write-Host "  findscu -v -S -k 0008,0060=CT -aec ORTHANC localhost 4242"
Write-Host ""
Write-Host "Query by Accession Number:"
Write-Host "  findscu -v -S -k 0008,0050=ACC001 -aec ORTHANC localhost 4242"

Write-Host "`n=== Worklist Files Created ===" -ForegroundColor Blue
foreach ($file in $createdFiles) {
    $fileName = Split-Path $file -Leaf
    Write-Host "📄 $fileName" -ForegroundColor Green
}

Write-Host "`n=== Integration with RIS/HIS ===" -ForegroundColor Magenta
Write-Host "In a real environment, worklist files would be generated by your RIS/HIS system:"
Write-Host "1. RIS schedules a procedure"
Write-Host "2. RIS generates a DICOM worklist file"
Write-Host "3. File is placed in the worklist directory"
Write-Host "4. Modality queries the worklist before scanning"
Write-Host "5. Modality gets procedure details and starts acquisition"
Write-Host "" 