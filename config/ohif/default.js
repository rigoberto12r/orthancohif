window.config = {
  routerBasename: '/',
  extensions: [
    '@ohif/extension-default',
    '@ohif/extension-cornerstone',
    '@ohif/extension-measurement-tracking',
    '@ohif/extension-cornerstone-dicom-sr',
    '@ohif/extension-cornerstone-dicom-seg',
    '@ohif/extension-cornerstone-dicom-rt',
    '@ohif/extension-dicom-pdf',
    '@ohif/extension-dicom-video',
    '@ohif/extension-test'
  ],
  modes: [
    '@ohif/mode-viewer'
  ],
  showStudyList: true,
  maxNumberOfWebWorkers: 3,
  omitQuotationForMultipartRequest: true,
  showWarningMessageForCrossOrigin: false,
  showCPUFallbackMessage: false,
  showLoadingIndicator: true,
  strictZSpacingForVolumeViewport: true,
  maxNumRequests: {
    interaction: 100,
    thumbnail: 75,
    prefetch: 25,
  },
  whiteLabeling: {
    createLogoComponentFn: function(React) {
      return React.createElement(
        'a',
        {
          target: '_self',
          rel: 'noopener noreferrer',
          className: 'text-purple-600 line-through',
          href: '/',
        },
        React.createElement('img', {
          src: './assets/customLogo.svg',
          className: 'w-8 h-8',
        })
      );
    },
  },
  hotkeys: [
    {
      commandName: 'incrementActiveViewport',
      label: 'Next Viewport',
      keys: ['right'],
    },
    {
      commandName: 'decrementActiveViewport',
      label: 'Previous Viewport',
      keys: ['left'],
    },
    { commandName: 'rotateViewportCW', label: 'Rotate Right', keys: ['r'] },
    { commandName: 'rotateViewportCCW', label: 'Rotate Left', keys: ['l'] },
    { commandName: 'invertViewport', label: 'Invert', keys: ['i'] },
    {
      commandName: 'flipViewportVertical',
      label: 'Flip Horizontally',
      keys: ['h'],
    },
    {
      commandName: 'flipViewportHorizontal',
      label: 'Flip Vertically',
      keys: ['v'],
    },
    { commandName: 'scaleUpViewport', label: 'Zoom In', keys: ['+'] },
    { commandName: 'scaleDownViewport', label: 'Zoom Out', keys: ['-'] },
    { commandName: 'fitViewportToWindow', label: 'Zoom to Fit', keys: ['='] },
    { commandName: 'resetViewport', label: 'Reset', keys: ['space'] },
    { commandName: 'nextImage', label: 'Next Image', keys: ['down'] },
    { commandName: 'previousImage', label: 'Previous Image', keys: ['up'] },
    {
      commandName: 'previousViewportDisplaySet',
      label: 'Previous Series',
      keys: ['pagedown'],
    },
    {
      commandName: 'nextViewportDisplaySet',
      label: 'Next Series',
      keys: ['pageup'],
    },
    {
      commandName: 'setToolActive',
      commandOptions: { toolName: 'Zoom' },
      label: 'Zoom',
      keys: ['z'],
    },
    {
      commandName: 'setToolActive',
      commandOptions: { toolName: 'WindowLevel' },
      label: 'Window Level',
      keys: ['w'],
    },
    {
      commandName: 'setToolActive',
      commandOptions: { toolName: 'Pan' },
      label: 'Pan',
      keys: ['p'],
    },
    {
      commandName: 'setToolActive',
      commandOptions: { toolName: 'Capture' },
      label: 'Capture',
      keys: ['c'],
    },
    {
      commandName: 'setToolActive',
      commandOptions: { toolName: 'Layout' },
      label: 'Layout',
      keys: ['m'],
    },
    {
      commandName: 'setToolActive',
      commandOptions: { toolName: 'Crosshairs' },
      label: 'Crosshairs',
      keys: ['x'],
    },
    {
      commandName: 'setToolActive',
      commandOptions: { toolName: 'AnnotateText' },
      label: 'Annotate',
      keys: ['t'],
    },
  ],
  cornerstoneExtensionConfig: {
    tools: {
      hidden: [
        {
          name: 'CalibrationLine',
        },
        {
          name: 'Magnify',
        },
      ],
      enabled: [
        {
          name: 'WindowLevel',
          configuration: {
            volumeSync: false,
          },
        },
        {
          name: 'Pan',
          configuration: {
            volumeSync: false,
          },
        },
        {
          name: 'Zoom',
          configuration: {
            volumeSync: false,
          },
        },
        {
          name: 'StackScrollMouseWheel',
          configuration: {
            volumeSync: false,
          },
        },
        {
          name: 'PlanarRotate',
          configuration: {
            volumeSync: false,
          },
        },
      ],
      active: [
        {
          name: 'WindowLevel',
          bindings: [
            {
              mouseButton: 1,
            },
          ],
        },
        {
          name: 'Pan',
          bindings: [
            {
              mouseButton: 2,
            },
          ],
        },
        {
          name: 'Zoom',
          bindings: [
            {
              mouseButton: 3,
            },
          ],
        },
        {
          name: 'StackScrollMouseWheel',
          bindings: [
            {
              mouseButton: 4,
            },
          ],
        },
      ],
    },
  },
  dataSources: [
    {
      namespace: '@ohif/extension-default.dataSourcesModule.dicomweb',
      sourceName: 'dicomweb',
      configuration: {
        friendlyName: 'Orthanc DICOM Server',
        name: 'ORTHANC',
        wadoUriRoot: 'http://192.168.0.10:8042/dicom-web',
        qidoRoot: 'http://192.168.0.10:8042/dicom-web',
        wadoRoot: 'http://192.168.0.10:8042/dicom-web',
        qidoSupportsIncludeField: true,
        imageRendering: 'wadors',
        thumbnailRendering: 'wadors',
        enableStudyLazyLoad: true,
        supportsFuzzyMatching: false,
        supportsWildcard: false,
        supportsReject: false,
        staticWado: true,
        singlepart: 'bulkdata,video,pdf',
        acceptHeader: 'multipart/related; type="application/octet-stream"; transfer-syntax=*',
        bulkDataURI: {
          enabled: true,
          relativeResolution: 'studies',
        },
        omitQuotationForMultipartRequest: true,
        requestOptions: {
          requestCredentials: 'omit',
          auth: '',
          headers: {
            'Accept': 'application/dicom+json,application/json,multipart/related;type=application/dicom;transfer-syntax=*'
          }
        },
      },
    },
  ],
  defaultDataSourceName: 'dicomweb',
  hangingProtocolSettings: {
    protocolId: '@ohif/mnGrid',
    stage: 'default',
    activeStudyUID: '',
    stageOptions: {
      showEmpty: true,
      allowEmptyDisplaySets: true
    }
  },
  investigationalUseDialog: {
    option: 'never',
  },
  enableServiceWorker: false,
  useSharedArrayBuffer: 'AUTO',
  useNorm16Texture: false,
  preferSizeOverAccuracy: false,
  useWebWorkers: true,
  strictZSpacingForVolumeViewport: false,
}; 