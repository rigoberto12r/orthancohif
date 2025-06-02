-- Auto-routing script for Orthanc
-- This script automatically routes studies to different PACS based on rules

function OnStoredInstance(instanceId, tags, metadata, origin)
    -- Get study information
    local studyId = tags['StudyInstanceUID']
    local modality = tags['Modality']
    local stationName = tags['StationName']
    local patientId = tags['PatientID']
    
    -- Log the received instance
    print('Received instance: ' .. instanceId)
    print('Study UID: ' .. studyId)
    print('Modality: ' .. modality)
    print('Station: ' .. (stationName or 'Unknown'))
    print('Patient ID: ' .. patientId)
    
    -- Auto-routing rules
    local routingRules = {
        {
            condition = function(tags)
                return tags['Modality'] == 'CT'
            end,
            destination = 'CT_PACS',
            description = 'Route CT studies to CT PACS'
        },
        {
            condition = function(tags)
                return tags['Modality'] == 'MR'
            end,
            destination = 'MR_PACS',
            description = 'Route MR studies to MR PACS'
        },
        {
            condition = function(tags)
                return tags['Modality'] == 'US'
            end,
            destination = 'US_PACS',
            description = 'Route Ultrasound studies to US PACS'
        },
        {
            condition = function(tags)
                return tags['StationName'] and string.find(tags['StationName'], 'EMERGENCY')
            end,
            destination = 'EMERGENCY_PACS',
            description = 'Route emergency studies to Emergency PACS'
        }
    }
    
    -- Apply routing rules
    for i, rule in ipairs(routingRules) do
        if rule.condition(tags) then
            print('Applying rule: ' .. rule.description)
            
            -- Check if the destination modality exists
            local modalities = RestApiGet('/modalities')
            local modalitiesList = ParseJson(modalities)
            
            local destinationExists = false
            for j, modalityName in ipairs(modalitiesList) do
                if modalityName == rule.destination then
                    destinationExists = true
                    break
                end
            end
            
            if destinationExists then
                -- Send the study to the destination
                local studyInfo = RestApiGet('/instances/' .. instanceId .. '/study')
                local study = ParseJson(studyInfo)
                local studyOrthancId = study['ID']
                
                print('Routing study ' .. studyOrthancId .. ' to ' .. rule.destination)
                
                -- Perform the routing
                local success, response = pcall(function()
                    return RestApiPost('/modalities/' .. rule.destination .. '/store', studyOrthancId)
                end)
                
                if success then
                    print('Successfully routed to ' .. rule.destination)
                else
                    print('Failed to route to ' .. rule.destination .. ': ' .. tostring(response))
                end
            else
                print('Destination modality ' .. rule.destination .. ' not configured')
            end
            
            -- Break after first matching rule (modify if you want multiple rules to apply)
            break
        end
    end
end

function OnStableStudy(studyId, tags, metadata)
    -- This function is called when a study becomes stable
    print('Study ' .. studyId .. ' is now stable')
    
    local modality = tags['Modality']
    local patientId = tags['PatientID']
    local studyDescription = tags['StudyDescription'] or 'Unknown'
    
    print('Stable study details:')
    print('  Patient ID: ' .. patientId)
    print('  Modality: ' .. modality)
    print('  Description: ' .. studyDescription)
    
    -- Additional processing for stable studies
    -- You can add custom logic here for:
    -- - Automatic archiving
    -- - Report generation
    -- - Notification sending
    -- - Quality checks
    
    -- Example: Auto-archive studies older than 30 days
    local studyDate = tags['StudyDate']
    if studyDate then
        local currentDate = os.date('%Y%m%d')
        local daysDiff = tonumber(currentDate) - tonumber(studyDate)
        
        if daysDiff > 30 then
            print('Study is older than 30 days, consider archiving')
            -- Add archiving logic here
        end
    end
end

function OnDeletedStudy(studyId)
    print('Study ' .. studyId .. ' has been deleted')
    -- Add cleanup logic here if needed
end

function OnDeletedSeries(seriesId)
    print('Series ' .. seriesId .. ' has been deleted')
    -- Add cleanup logic here if needed
end

function OnDeletedInstance(instanceId)
    print('Instance ' .. instanceId .. ' has been deleted')
    -- Add cleanup logic here if needed
end

-- Custom routing function that can be called via REST API
function RouteStudyToModality(studyId, modalityName)
    print('Manual routing of study ' .. studyId .. ' to ' .. modalityName)
    
    local success, response = pcall(function()
        return RestApiPost('/modalities/' .. modalityName .. '/store', studyId)
    end)
    
    if success then
        print('Successfully routed study to ' .. modalityName)
        return true
    else
        print('Failed to route study to ' .. modalityName .. ': ' .. tostring(response))
        return false
    end
end

-- Utility function to check if a study should be compressed
function ShouldCompressStudy(tags)
    local modality = tags['Modality']
    local studyDate = tags['StudyDate']
    
    -- Compress older studies or specific modalities
    if studyDate then
        local currentDate = os.date('%Y%m%d')
        local daysDiff = tonumber(currentDate) - tonumber(studyDate)
        
        -- Compress studies older than 7 days
        if daysDiff > 7 then
            return true
        end
    end
    
    -- Always compress ultrasound studies
    if modality == 'US' then
        return true
    end
    
    return false
end

-- Initialize the auto-routing system
print('Auto-routing script loaded successfully')
print('Available routing rules:')
print('  - CT studies → CT_PACS')
print('  - MR studies → MR_PACS')
print('  - US studies → US_PACS')
print('  - Emergency studies → EMERGENCY_PACS') 