import orthanc
import json
import os
import logging
from datetime import datetime

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

def OnChange(changeType, level, resource):
    """
    Callback function that gets triggered on any change in Orthanc
    """
    try:
        if changeType == orthanc.ChangeType.STABLE_STUDY:
            logger.info(f"Study {resource} is now stable")
            
            # Get study information
            study_info = orthanc.RestApiGet(f"/studies/{resource}")
            study_data = json.loads(study_info)
            
            # Log study details
            logger.info(f"Study ID: {study_data.get('ID', 'Unknown')}")
            logger.info(f"Patient ID: {study_data.get('PatientMainDicomTags', {}).get('PatientID', 'Unknown')}")
            logger.info(f"Study Description: {study_data.get('MainDicomTags', {}).get('StudyDescription', 'Unknown')}")
            
            # Auto-routing example (configure modalities in orthanc.json)
            # Uncomment and configure as needed
            # auto_route_study(resource)
            
        elif changeType == orthanc.ChangeType.NEW_INSTANCE:
            logger.info(f"New instance received: {resource}")
            
        elif changeType == orthanc.ChangeType.DELETED:
            logger.info(f"Resource deleted: {resource}")
            
    except Exception as e:
        logger.error(f"Error in OnChange callback: {str(e)}")

def auto_route_study(study_id):
    """
    Automatically route studies to configured modalities
    """
    try:
        # Example: Send to a PACS modality named 'PACS'
        # orthanc.RestApiPost(f"/modalities/PACS/store", study_id)
        logger.info(f"Auto-routing study {study_id} would be executed here")
    except Exception as e:
        logger.error(f"Error auto-routing study {study_id}: {str(e)}")

def OnStoredInstance(dicom, instanceId):
    """
    Callback triggered when a new DICOM instance is stored
    """
    try:
        # Get instance information
        instance_info = orthanc.RestApiGet(f"/instances/{instanceId}")
        instance_data = json.loads(instance_info)
        
        # Log instance details
        sop_instance_uid = instance_data.get('MainDicomTags', {}).get('SOPInstanceUID', 'Unknown')
        modality = instance_data.get('MainDicomTags', {}).get('Modality', 'Unknown')
        
        logger.info(f"Stored instance: {sop_instance_uid}, Modality: {modality}")
        
        # Custom processing based on modality
        if modality == 'CT':
            logger.info("Processing CT image...")
        elif modality == 'MR':
            logger.info("Processing MR image...")
        elif modality == 'US':
            logger.info("Processing Ultrasound image...")
            
    except Exception as e:
        logger.error(f"Error in OnStoredInstance callback: {str(e)}")

def OnReceivedInstanceFilter(dicom, origin, info):
    """
    Filter for incoming DICOM instances
    """
    try:
        # Example: Accept all instances by default
        # You can add custom filtering logic here
        return True
    except Exception as e:
        logger.error(f"Error in OnReceivedInstanceFilter: {str(e)}")
        return True

def OnIncomingCStoreRequest(dicom, origin):
    """
    Handle incoming C-STORE requests
    """
    try:
        logger.info(f"Incoming C-STORE request from {origin}")
        # Return True to accept the instance
        return True
    except Exception as e:
        logger.error(f"Error in OnIncomingCStoreRequest: {str(e)}")
        return False

def WorklistCallback(query, issuerAet, calledAet):
    """
    Modality Worklist callback
    """
    try:
        logger.info(f"Worklist query from {issuerAet} to {calledAet}")
        
        # Return an empty list for now
        # In a real implementation, you would query your RIS/HIS system
        worklist_items = []
        
        # Example worklist item structure:
        # worklist_item = {
        #     'PatientID': 'PAT001',
        #     'PatientName': 'DOE^JOHN',
        #     'PatientBirthDate': '19800101',
        #     'PatientSex': 'M',
        #     'StudyInstanceUID': '1.2.3.4.5.6.7.8.9',
        #     'AccessionNumber': 'ACC001',
        #     'StudyDescription': 'CT CHEST',
        #     'ScheduledProcedureStepStartDate': datetime.now().strftime('%Y%m%d'),
        #     'ScheduledProcedureStepStartTime': datetime.now().strftime('%H%M%S'),
        #     'Modality': 'CT',
        #     'ScheduledStationAETitle': calledAet,
        #     'ScheduledProcedureStepDescription': 'CT CHEST ROUTINE'
        # }
        # worklist_items.append(worklist_item)
        
        return worklist_items
        
    except Exception as e:
        logger.error(f"Error in WorklistCallback: {str(e)}")
        return []

def OnRestApiGet(output, uri, **request):
    """
    Handle custom REST API GET requests
    """
    if uri == '/custom/status':
        output.AnswerBuffer(json.dumps({
            'status': 'running',
            'timestamp': datetime.now().isoformat(),
            'message': 'Orthanc server is running with custom extensions'
        }), 'application/json')
        return True
    elif uri == '/custom/statistics':
        try:
            # Get system statistics
            system_info = orthanc.RestApiGet('/system')
            stats = json.loads(system_info)
            
            output.AnswerBuffer(json.dumps({
                'system': stats,
                'custom_timestamp': datetime.now().isoformat()
            }), 'application/json')
            return True
        except Exception as e:
            output.AnswerBuffer(json.dumps({
                'error': str(e)
            }), 'application/json')
            return True
    
    return False

def OnRestApiPost(output, uri, body, **request):
    """
    Handle custom REST API POST requests
    """
    if uri == '/custom/process':
        try:
            data = json.loads(body)
            
            # Process the incoming data
            result = {
                'processed': True,
                'received_data': data,
                'timestamp': datetime.now().isoformat()
            }
            
            output.AnswerBuffer(json.dumps(result), 'application/json')
            return True
        except Exception as e:
            output.AnswerBuffer(json.dumps({
                'error': str(e)
            }), 'application/json')
            return True
    
    return False

# Register callbacks
orthanc.RegisterOnChangeCallback(OnChange)
orthanc.RegisterOnStoredInstanceCallback(OnStoredInstance)
orthanc.RegisterReceivedInstanceFilter(OnReceivedInstanceFilter)
orthanc.RegisterIncomingCStoreRequestFilter(OnIncomingCStoreRequest)
orthanc.RegisterWorklistCallback(WorklistCallback)
orthanc.RegisterRestCallback('/custom/(.*)', OnRestApiGet)
orthanc.RegisterRestCallback('/custom/(.*)', OnRestApiPost)

logger.info("Python plugin initialized successfully")
logger.info("Available custom endpoints:")
logger.info("  GET /custom/status")
logger.info("  GET /custom/statistics")
logger.info("  POST /custom/process") 