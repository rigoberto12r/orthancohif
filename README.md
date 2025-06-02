# Orthanc + OHIF Docker Stack

Este proyecto proporciona una configuración completa de Docker para ejecutar Orthanc (servidor DICOM) con OHIF Viewer (visor de imágenes médicas) integrado, incluyendo todos los plugins recomendados y funcionalidades avanzadas.

## 🚀 Características

### Orthanc
- **Última versión**: Utiliza la imagen oficial `jodogne/orthanc-plugins:latest` con múltiples plugins
- **DICOMweb habilitado**: Protocolo estándar para acceso web a imágenes DICOM
- **Plugins incluidos**:
  - DICOMweb (WADO-RS, QIDO-RS, STOW-RS)
  - Stone Web Viewer integrado
  - OHIF Plugin nativo de Orthanc
  - GDCM para soporte avanzado de formatos
  - WebDAV para acceso por navegador
  - Transfers para optimización
  - Housekeeper para mantenimiento automático
  - Worklist Plugin para integración con RIS/HIS
  - Delayed Deletion para gestión segura
  - Autorización y conectividad
  - Soporte multi-tenant
  - Y muchos más plugins integrados

### OHIF Viewer
- **Última versión**: Visor web moderno y responsivo
- **Integración completa** con Orthanc vía DICOMweb
- **Modes configurados**: Viewer básico y modo de pruebas
- **Extensions incluidas**: Cornerstone, measurement tracking, SR, SEG, RT
- **Herramientas avanzadas**: Zoom, pan, ventanas, anotaciones
- **Soporte multi-serie y multi-estudio**
- **Configuración optimizada** para Orthanc

### Funcionalidades Avanzadas
- **Multiple plugins activos**: Más de 25 plugins funcionando
- **API REST completa**: Acceso a todas las funcionalidades
- **Proxy Nginx**: Para manejo de CORS y SSL
- **Monitoreo**: Health checks y logging
- **Verificación automática**: Script de comprobación incluido

## 📋 Requisitos

- Docker Engine 20.10+
- Docker Compose 2.0+
- Al menos 4GB RAM libre
- 20GB espacio en disco (para estudios DICOM)

## 🛠️ Instalación y Uso

### 1. Clonar/Descargar el proyecto
```bash
git clone <repository-url>
cd orthanc-ohif-docker
```

### 2. Iniciar los servicios
```bash
# Windows PowerShell
.\start.ps1

# Linux/Mac
./start.sh

# Manual con docker-compose
docker-compose up -d
```

### 3. Verificar el estado
```bash
# Windows PowerShell - Script de verificación
.\check-setup.ps1

# Manual
docker-compose ps
curl http://localhost:8042/system
curl http://localhost:8042/plugins
```

### 4. Acceder a las interfaces

| Servicio | URL | Descripción |
|----------|-----|-------------|
| **OHIF Viewer** | http://localhost | Visor principal de imágenes médicas |
| **Orthanc Explorer** | http://localhost:8042 | Interfaz administrativa de Orthanc |
| **Orthanc Explorer 2** | http://localhost:8042/ui/ | Nueva interfaz administrativa |
| **Stone Web Viewer** | http://localhost:8042/stone-webviewer/ | Visor alternativo |
| **Nginx Proxy** | http://localhost | Punto de acceso unificado |
| **WebDAV** | http://localhost:8042/webdav/ | Acceso por navegador |

## 📁 Estructura del Proyecto

```
orthanc-ohif-docker/
├── docker-compose.yml          # Configuración principal de servicios
├── start.ps1                   # Script de inicio para Windows
├── start.sh                    # Script de inicio para Linux/Mac
├── check-setup.ps1             # Script de verificación
├── config/
│   ├── orthanc.json           # Configuración completa de Orthanc
│   └── ohif/
│       └── default.js         # Configuración de OHIF con modes
├── nginx/
│   └── nginx.conf             # Configuración del proxy Nginx
├── scripts/
│   ├── main.py                # Scripts Python para Orthanc (deshabilitado)
│   └── autorouting.lua        # Scripts Lua para auto-enrutamiento (deshabilitado)
└── README.md                  # Este archivo
```

## ✅ Verificación del Sistema

### Verificar Plugins de Orthanc
```bash
# Ver todos los plugins cargados
curl http://localhost:8042/plugins

# Ver información de un plugin específico
curl http://localhost:8042/plugins/dicom-web
```

### Lista de Plugins Disponibles
El sistema incluye los siguientes plugins activos:
- `dicom-web` - DICOMweb support (QIDO-RS, WADO-RS, STOW-RS)
- `stone-webviewer` - Stone Web Viewer
- `ohif` - OHIF integration plugin
- `gdcm` - Advanced DICOM format support
- `worklists` - Modality worklist support
- `web-viewer` - Basic web viewer
- `serve-folders` - Static file serving
- `housekeeper` - Database maintenance
- `transfers` - Optimized transfers
- `delayed-deletion` - Safe deletion
- `orthanc-explorer-2` - Modern admin interface
- Y muchos más...

### Verificar OHIF
```bash
# Verificar que OHIF responde
curl http://localhost:3000

# Verificar configuración de OHIF
curl http://localhost:3000/config/default.js
```

### Verificar DICOMweb
```bash
# QIDO-RS - Query studies
curl http://localhost:8042/dicom-web/studies

# WADO-RS - Available when you have studies
curl http://localhost:8042/dicom-web/studies/{study-uid}
```

## 🔧 Configuración Avanzada

### Agregar Modalidades DICOM
Edita `config/orthanc.json` en la sección `DicomModalities`:

```json
"DicomModalities": {
  "PACS_HOSPITAL": {
    "AET": "PACS",
    "Host": "192.168.1.100",
    "Port": 4242,
    "Manufacturer": "Generic"
  },
  "CT_SCANNER": {
    "AET": "CT_STATION",
    "Host": "192.168.1.101",
    "Port": 104,
    "Manufacturer": "Generic"
  }
}
```

### Habilitar Autenticación
En `config/orthanc.json`:

```json
"AuthenticationEnabled": true,
"RegisteredUsers": {
  "admin": "password",
  "viewer": "readonly_password"
}
```

### Configurar SSL/HTTPS
1. Coloca tus certificados en `nginx/ssl/`
2. Modifica `nginx/nginx.conf` para habilitar HTTPS
3. Actualiza las URLs en `config/ohif/default.js`

## 📊 Monitoreo y Logs

### Ver logs de servicios
```bash
# Logs de Orthanc
docker-compose logs orthanc

# Logs de OHIF
docker-compose logs ohif

# Logs de Nginx
docker-compose logs nginx

# Todos los logs
docker-compose logs
```

### Endpoints de monitoreo
```bash
# Estado del sistema Orthanc
curl http://localhost:8042/system

# Estadísticas
curl http://localhost:8042/statistics

# Lista de plugins
curl http://localhost:8042/plugins

# Información específica de plugin
curl http://localhost:8042/plugins/dicom-web
```

## 🗂️ Subir Estudios DICOM

### Método 1: Interfaz Web de Orthanc
1. Ir a http://localhost:8042/ui/ (Orthanc Explorer 2)
2. O ir a http://localhost:8042 (Orthanc Explorer clásico)
3. Clic en "Upload"
4. Arrastrar archivos DICOM o carpetas

### Método 2: DICOM C-STORE
```bash
# Usando storescu de DCMTK
storescu -aec ORTHANC -aet MY_AET localhost 4242 study_folder/

# Usando pynetdicom
python -m pynetdicom storescu localhost 4242 -aec ORTHANC study.dcm
```

### Método 3: DICOMweb STOW-RS
```bash
# Usando curl
curl -X POST \
  http://localhost:8042/dicom-web/studies \
  -H 'Content-Type: multipart/related; type="application/dicom"' \
  --data-binary @study.dcm
```

## 🚨 Solución de Problemas

### Error: "No modes are defined! Check your app-config.js"
**Solucionado**: La configuración de OHIF ahora incluye los modes requeridos:
- `@ohif/mode-viewer`
- `@ohif/mode-basic-test-mode`

### No aparecen plugins en Orthanc
**Solucionado**: Ahora usamos `jodogne/orthanc-plugins:latest` que incluye múltiples plugins precompilados.

### Verificar plugins cargados:
```bash
curl http://localhost:8042/plugins
```

### Los servicios no inician
```bash
# Verificar logs
docker-compose logs

# Reiniciar servicios
docker-compose restart

# Reconstruir contenedores
docker-compose down
docker-compose up --build
```

### Problemas de CORS
- Verificar configuración en `nginx/nginx.conf`
- Revisar headers CORS en `config/orthanc.json`

### Problemas de conexión DICOMweb
```bash
# Verificar endpoint DICOMweb
curl http://localhost:8042/dicom-web/studies

# Verificar configuración OHIF
# Revisar config/ohif/default.js
```

### Script de Verificación
Ejecuta el script de verificación para comprobar todo:
```powershell
# Windows
.\check-setup.ps1

# Este script verifica:
# - Estado de contenedores
# - Plugins de Orthanc cargados
# - Endpoints DICOMweb
# - Configuración de OHIF
# - Conectividad general
```

## 🔒 Seguridad

### Recomendaciones de Producción
1. **Habilitar autenticación** en Orthanc
2. **Configurar HTTPS** con certificados válidos
3. **Limitar acceso de red** usando firewall
4. **Configurar backup** regular de la base de datos
5. **Monitorear logs** de acceso y errores
6. **Actualizar regularmente** las imágenes Docker

### Configuración de Firewall
```bash
# Permitir solo puertos necesarios
ufw allow 80/tcp    # HTTP
ufw allow 443/tcp   # HTTPS
ufw allow 4242/tcp  # DICOM (solo desde red interna)
```

## 📈 Rendimiento

### Optimizaciones
- **Compresión GZIP** habilitada en Nginx
- **Caching** de archivos estáticos
- **Pool de conexiones** configurado
- **Timeouts** optimizados
- **Health checks** para alta disponibilidad
- **Múltiples plugins** para funcionalidad extendida

### Métricas de Rendimiento
```bash
# Estadísticas de Orthanc
curl http://localhost:8042/statistics

# Información del sistema
curl http://localhost:8042/system

# Estado de plugins
curl http://localhost:8042/plugins
```

## 🆘 Soporte

Para problemas específicos:
1. Ejecutar el script de verificación: `.\check-setup.ps1`
2. Revisar los logs detallados: `docker-compose logs`
3. Verificar la documentación oficial de [Orthanc](https://orthanc.uclouvain.be/) y [OHIF](https://docs.ohif.org/)
4. Consultar issues en los repositorios oficiales

---

## 📝 Notas de Versión

- **v1.1**: **PROBLEMA SOLUCIONADO** - Error "No modes defined" en OHIF
- **v1.1**: **PROBLEMA SOLUCIONADO** - Plugins no visibles en Orthanc  
- **v1.1**: Migrado a `jodogne/orthanc-plugins:latest` con 25+ plugins
- **v1.1**: Agregada configuración completa de modes y extensions en OHIF
- **v1.1**: Script de verificación `check-setup.ps1` incluido
- **v1.0**: Configuración inicial con Orthanc + OHIF
- Soporte completo para DICOMweb
- Proxy Nginx configurado
- Documentación completa

## 🎉 Estado Actual: ✅ FUNCIONANDO

- ✅ **Orthanc**: 25+ plugins cargados correctamente
- ✅ **OHIF**: Modes configurados, sin errores
- ✅ **DICOMweb**: QIDO-RS, WADO-RS, STOW-RS funcionando
- ✅ **Nginx**: Proxy funcionando con CORS
- ✅ **Plugins**: dicom-web, stone-webviewer, ohif, gdcm, worklists, etc.
- ✅ **Verificación**: Script automático disponible 