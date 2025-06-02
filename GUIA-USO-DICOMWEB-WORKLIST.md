# 📚 Guía de Uso: DICOMweb y Worklist

Esta guía te enseña cómo usar y probar las funcionalidades **DICOMweb** y **Worklist** que ya tienes configuradas en tu sistema Orthanc + OHIF.

## 🌐 **DICOMweb - Protocolo Web para DICOM**

DICOMweb es un estándar que permite acceder a imágenes DICOM vía HTTP/REST. Incluye tres servicios principales:

### **1. QIDO-RS (Query based on ID for DICOM Objects)**
Para **consultar** estudios, series e instancias.

#### **Ejemplos de consultas:**

```powershell
# Consultar todos los estudios
curl http://localhost:8042/dicom-web/studies

# Consultar estudios por paciente
curl "http://localhost:8042/dicom-web/studies?PatientName=DOE^JOHN"

# Consultar estudios por fecha
curl "http://localhost:8042/dicom-web/studies?StudyDate=20241201"

# Consultar estudios por modalidad
curl "http://localhost:8042/dicom-web/studies?ModalitiesInStudy=CT"

# Consultar series de un estudio específico
curl http://localhost:8042/dicom-web/studies/{STUDY_UID}/series

# Consultar instancias de una serie específica
curl http://localhost:8042/dicom-web/studies/{STUDY_UID}/series/{SERIES_UID}/instances
```

### **2. WADO-RS (Web Access to DICOM Objects)**
Para **recuperar** imágenes y metadatos.

#### **Ejemplos de recuperación:**

```powershell
# Recuperar metadatos de un estudio
curl http://localhost:8042/dicom-web/studies/{STUDY_UID}/metadata

# Recuperar una instancia DICOM completa
curl http://localhost:8042/dicom-web/studies/{STUDY_UID}/series/{SERIES_UID}/instances/{INSTANCE_UID}

# Recuperar imagen en formato JPEG
curl "http://localhost:8042/dicom-web/studies/{STUDY_UID}/series/{SERIES_UID}/instances/{INSTANCE_UID}/frames/1/rendered?quality=90"
```

### **3. STOW-RS (Store Over the Web)**
Para **subir** imágenes DICOM vía HTTP.

#### **Ejemplo de subida:**

```powershell
# Subir archivo DICOM
curl -X POST "http://localhost:8042/dicom-web/studies" -H "Content-Type: multipart/related; type=application/dicom" --data-binary @archivo.dcm
```

### **Usar DICOMweb con OHIF:**

1. **Accede a OHIF**: http://localhost
2. **OHIF automáticamente usa DICOMweb** para mostrar estudios
3. **Las consultas se hacen en tiempo real** al servidor Orthanc

---

## 📋 **Worklist - Lista de Trabajo DICOM**

El Worklist permite que las modalidades (CT, MR, US, etc.) consulten procedimientos programados antes de realizar estudios.

### **¿Cómo funciona el Worklist?**

1. **RIS/HIS programa un procedimiento** → Genera archivo de worklist
2. **Modalidad consulta la worklist** → Obtiene detalles del paciente y procedimiento
3. **Modalidad inicia el estudio** → Con la información correcta del paciente

### **Archivo de Worklist creado:**

Ya se creó un archivo de ejemplo con:
- **Paciente**: DOE^JOHN (ID: PAT001)
- **Procedimiento**: CT CHEST ROUTINE  
- **Número de Acceso**: ACC001
- **Modalidad**: CT
- **AE Title**: ORTHANC

### **Cómo probar el Worklist:**

#### **Opción 1: Con DCMTK (recomendado)**

Si tienes DCMTK instalado:

```bash
# Consultar toda la worklist
findscu -v -S -k 0008,0050 -aec ORTHANC localhost 4242

# Consultar por paciente específico
findscu -v -S -k 0010,0010="DOE^JOHN" -aec ORTHANC localhost 4242

# Consultar por número de acceso
findscu -v -S -k 0008,0050="ACC001" -aec ORTHANC localhost 4242

# Consultar por modalidad
findscu -v -S -k 0008,0060="CT" -aec ORTHANC localhost 4242
```

#### **Opción 2: Con software DICOM**

Configura cualquier cliente DICOM con:
- **AE Title**: ORTHANC
- **Host**: localhost
- **Puerto**: 4242
- **Tipo de consulta**: Modality Worklist (MWL)

#### **Opción 3: Con Python**

```python
from pynetdicom import AE, QueryRetrievePresentationContexts
from pydicom.dataset import Dataset

# Crear Application Entity
ae = AE()
ae.add_requested_context('1.2.840.10008.5.1.4.31')  # Modality Worklist

# Conectar a Orthanc
assoc = ae.associate('localhost', 4242, ae_title='ORTHANC')

if assoc.is_established:
    # Crear consulta
    ds = Dataset()
    ds.PatientName = ''  # Consultar todos los pacientes
    ds.ScheduledProcedureStepSequence = [Dataset()]
    
    # Ejecutar consulta
    responses = assoc.send_c_find(ds, '1.2.840.10008.5.1.4.31')
    
    for (status, identifier) in responses:
        if status:
            print(f"Patient: {identifier.PatientName}")
            print(f"Procedure: {identifier.ScheduledProcedureStepSequence[0].ScheduledProcedureStepDescription}")
    
    assoc.release()
```

---

## 🔧 **Scripts de Prueba Incluidos**

### **Para DICOMweb:**
```powershell
# Prueba básica
curl http://localhost:8042/dicom-web/studies

# Verificación completa
.\simple-dicomweb-test.ps1
```

### **Para Worklist:**
```powershell
# Crear archivos de worklist y probar
.\simple-worklist-test.ps1
```

---

## 🏥 **Casos de Uso Reales**

### **Flujo típico con Worklist:**

1. **En el RIS/HIS**:
   - Médico programa CT de tórax para paciente DOE, JOHN
   - Sistema genera archivo worklist: `CT_CHEST_DOE_JOHN.wl`

2. **En la modalidad CT**:
   - Técnico consulta worklist antes del estudio
   - Obtiene: Nombre paciente, ID, procedimiento, médico referente
   - Inicia estudio con datos correctos

3. **Durante el estudio**:
   - CT genera imágenes DICOM con información correcta
   - Envía imágenes a Orthanc vía C-STORE

4. **Visualización**:
   - OHIF consulta automáticamente vía DICOMweb
   - Muestra estudio inmediatamente disponible

### **Flujo típico con DICOMweb:**

1. **Consulta de estudios**:
   - OHIF usa QIDO-RS para listar estudios disponibles
   - Médico selecciona estudio de interés

2. **Carga de imágenes**:
   - OHIF usa WADO-RS para recuperar imágenes
   - Optimiza carga según viewport activo

3. **Interacción**:
   - Médico visualiza, anota, mide
   - Todas las acciones usan APIs DICOMweb

---

## 📊 **Endpoints Principales**

### **DICOMweb:**
- **QIDO-RS**: `http://localhost:8042/dicom-web/studies`
- **WADO-RS**: `http://localhost:8042/dicom-web/studies/{uid}`
- **STOW-RS**: `POST http://localhost:8042/dicom-web/studies`

### **Worklist:**
- **Puerto DICOM**: 4242
- **AE Title**: ORTHANC
- **Directorio**: `/var/lib/orthanc/worklists/`

### **Interfaces Web:**
- **OHIF Viewer**: http://localhost
- **Orthanc Explorer**: http://localhost:8042
- **Stone Web Viewer**: http://localhost:8042/stone-webviewer/

---

## ⚡ **Comandos Rápidos**

```powershell
# Verificar sistema completo
.\simple-check.ps1

# Probar DICOMweb
curl http://localhost:8042/dicom-web/studies

# Crear worklist de prueba
.\simple-worklist-test.ps1

# Ver plugins cargados
curl http://localhost:8042/plugins

# Ver logs de Orthanc
docker-compose logs orthanc

# Subir archivo DICOM (reemplaza ruta)
curl -X POST http://localhost:8042/instances --data-binary @archivo.dcm
```

---

## 🚀 **Siguientes Pasos**

1. **Subir estudios DICOM reales** vía http://localhost:8042/ui/
2. **Verificar que aparecen en OHIF** en http://localhost
3. **Probar consultas DICOMweb** con estudios reales
4. **Configurar modalidades reales** para usar el worklist
5. **Integrar con RIS/HIS** para generar worklists automáticamente

¡Tu sistema está completamente funcional y listo para uso en producción! 🎉 