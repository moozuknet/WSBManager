/**
 * WSB Manager Web - Storage Service (UserProperties & Google Drive)
 */

var StorageService = (function() {
  var STORAGE_KEY = 'WSB_PRESETS_V1';
  var STORAGE_ORDER_KEY = 'WSB_PRESET_ORDER_V1';

  /**
   * 신규 사용자용 초기 기본 프리셋 3종
   */
  function _getDefaultPresets() {
    return {
      "기본 샌드박스 (Default)": {
        presetName: "기본 샌드박스 (Default)",
        presetDescription: "표준 Windows Sandbox 기본 설정",
        vGpu: "Default",
        networking: "Default",
        memoryInMB: "",
        clipboard: "Default",
        audioInput: "Default",
        videoInput: "Default",
        protectedClient: "Default",
        printerRedirection: "Default",
        mappedFolders: [
          { hostFolder: "C:\\Users\\Public\\Downloads", sandboxFolder: "C:\\Users\\WDAGUtilityAccount\\Desktop\\Downloads", readOnly: true }
        ],
        logonCommand: "",
        updatedAt: new Date(Date.now() - 60000).toISOString()
      },
      "🚀 풀 개발자 팩 (Git + Python + Node.js + VS Code)": {
        presetName: "🚀 풀 개발자 팩 (Git + Python + Node.js + VS Code)",
        presetDescription: "GitHub 저장소(install-dev-tools.ps1) 원스톱 자동 설치 (Git, Python 3.12, Node.js LTS, VS Code, 다크 테마)",
        vGpu: "Enable",
        networking: "Default",
        memoryInMB: "8192",
        clipboard: "Default",
        audioInput: "Default",
        videoInput: "Default",
        protectedClient: "Default",
        printerRedirection: "Default",
        mappedFolders: [
          { hostFolder: "C:\\Users\\Public\\Downloads", sandboxFolder: "C:\\Users\\WDAGUtilityAccount\\Desktop\\Downloads", readOnly: false }
        ],
        logonCommand: 'cmd.exe /c start "Dev Auto Setup" powershell.exe -NoExit -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol = 3072; iex ((New-Object Net.WebClient).DownloadString(\'https://raw.githubusercontent.com/moozuknet/WSBManager/main/scripts/install-dev-tools.ps1\'))"',
        updatedAt: new Date().toISOString()
      },
      "🇰🇷 식탁보 (TableCloth 보안 샌드박스)": {
        presetName: "🇰🇷 식탁보 (TableCloth 보안 샌드박스)",
        presetDescription: "공공기관 및 인터넷 뱅킹 전용 Standalone TableCloth 샌드박스 환경 (init-tablecloth.ps1)",
        vGpu: "Default",
        networking: "Default",
        memoryInMB: "4096",
        clipboard: "Default",
        audioInput: "Default",
        videoInput: "Default",
        protectedClient: "Default",
        printerRedirection: "Default",
        mappedFolders: [
          { hostFolder: "C:\\Users\\Public\\Downloads", sandboxFolder: "C:\\Users\\WDAGUtilityAccount\\Desktop\\Downloads", readOnly: true }
        ],
        logonCommand: 'cmd.exe /c start "TableCloth Auto Setup" powershell.exe -NoExit -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol = 3072; iex ((New-Object Net.WebClient).DownloadString(\'https://raw.githubusercontent.com/moozuknet/WSBManager/main/scripts/init-tablecloth.ps1\'))"',
        updatedAt: new Date().toISOString()
      }
    };
  }

  /**
   * 저장소에서 전체 프리셋 JSON 파싱 후 반환 (비어있으면 기본 프리셋 자동 생성)
   */
  function _loadPresets() {
    try {
      var userProps = PropertiesService.getUserProperties();
      var data = userProps.getProperty(STORAGE_KEY);
      if (data) {
        var parsed = JSON.parse(data);
        if (parsed && typeof parsed === 'object' && Object.keys(parsed).length > 0) {
          return parsed;
        }
      }
      // 초기 기본 프리셋 생성 및 저장
      var defaults = _getDefaultPresets();
      _savePresetsMap(defaults);
      return defaults;
    } catch (e) {
      Logger.log('Error loading presets: ' + e.toString());
      return _getDefaultPresets();
    }
  }

  /**
   * 프리셋 정렬 순서 조회
   */
  function _loadPresetOrder() {
    try {
      var userProps = PropertiesService.getUserProperties();
      var data = userProps.getProperty(STORAGE_ORDER_KEY);
      return data ? JSON.parse(data) : [];
    } catch (e) {
      Logger.log('Error loading preset order: ' + e.toString());
      return [];
    }
  }

  /**
   * 프리셋 전체 저장
   */
  function _savePresetsMap(presetsMap) {
    var userProps = PropertiesService.getUserProperties();
    userProps.setProperty(STORAGE_KEY, JSON.stringify(presetsMap));
  }

  /**
   * 프리셋 정렬 순서 저장
   */
  function _savePresetOrder(orderArray) {
    var userProps = PropertiesService.getUserProperties();
    userProps.setProperty(STORAGE_ORDER_KEY, JSON.stringify(orderArray || []));
  }

  return {
    /**
     * 기본 프리셋 제공 함수 (외부 노출)
     */
    getDefaultPresets: _getDefaultPresets,

    /**
     * 프리셋 저장/수정
     */
    savePreset: function(presetName, configData) {
      try {
        if (!presetName || typeof presetName !== 'string') {
          return { success: false, error: '유효한 프리셋 이름을 입력해주세요.' };
        }
        var presets = _loadPresets();
        configData.updatedAt = new Date().toISOString();
        presets[presetName] = configData;
        _savePresetsMap(presets);
        return { success: true, message: '\'' + presetName + '\' 프리셋이 저장되었습니다.' };
      } catch (err) {
        return { success: false, error: err.toString() };
      }
    },

    /**
     * 모든 프리셋 및 순서 목록 가져오기
     */
    getPresets: function() {
      try {
        var presets = _loadPresets();
        var order = _loadPresetOrder();
        return { success: true, data: presets, order: order };
      } catch (err) {
        return { success: false, error: err.toString(), data: {}, order: [] };
      }
    },

    /**
     * 프리셋 순서 저장
     */
    savePresetOrder: function(orderArray) {
      try {
        _savePresetOrder(orderArray);
        return { success: true, message: '프리셋 순서가 저장되었습니다.' };
      } catch (err) {
        return { success: false, error: err.toString() };
      }
    },

    /**
     * 프리셋 일괄 저장 (JSON 가져오기 등)
     */
    saveAllPresets: function(presetsMap, orderArray) {
      try {
        if (!presetsMap || typeof presetsMap !== 'object') {
          return { success: false, error: '유효하지 않은 프리셋 데이터입니다.' };
        }
        _savePresetsMap(presetsMap);
        if (orderArray && Array.isArray(orderArray)) {
          _savePresetOrder(orderArray);
        }
        return { success: true, message: '프리셋이 성공적으로 저장되었습니다.' };
      } catch (err) {
        return { success: false, error: err.toString() };
      }
    },

    /**
     * 특정 프리셋 삭제
     */
    deletePreset: function(presetName) {
      try {
        var presets = _loadPresets();
        if (presets[presetName]) {
          delete presets[presetName];
          _savePresetsMap(presets);

          // 순서 배열에서도 제거
          var order = _loadPresetOrder();
          var updatedOrder = order.filter(function(name) { return name !== presetName; });
          _savePresetOrder(updatedOrder);

          return { success: true, message: '\'' + presetName + '\' 프리셋이 삭제되었습니다.' };
        } else {
          return { success: false, error: '삭제할 프리셋을 찾을 수 없습니다.' };
        }
      } catch (err) {
        return { success: false, error: err.toString() };
      }
    },

    /**
     * 모든 프리셋 삭제
     */
    clearAllPresets: function() {
      try {
        var userProps = PropertiesService.getUserProperties();
        userProps.removeProperty(STORAGE_KEY);
        userProps.removeProperty(STORAGE_ORDER_KEY);
        return { success: true, message: '모든 프리셋이 삭제되었습니다.' };
      } catch (err) {
        return { success: false, error: err.toString() };
      }
    },

    /**
     * GAS 스크립트가 위치한 구글 드라이브 폴더 또는 지정 폴더 객체 조회
     */
    getDestinationFolder: function() {
      var TARGET_FOLDER_ID = '1W0jr7VODpb3NTLzdU0nxBO59A7_J7PUq';
      
      // 1. 지정된 폴더 ID로 조회 시도
      try {
        if (TARGET_FOLDER_ID) {
          return DriveApp.getFolderById(TARGET_FOLDER_ID);
        }
      } catch (e) {
        Logger.log('Folder ID lookup failed, fallback to script parent folder: ' + e.toString());
      }

      // 2. 스크립트 파일의 부모 폴더 자동 감지 시도
      try {
        var scriptId = ScriptApp.getScriptId();
        if (scriptId) {
          var file = DriveApp.getFileById(scriptId);
          var parents = file.getParents();
          if (parents.hasNext()) {
            return parents.next();
          }
        }
      } catch (e) {
        Logger.log('Script parent folder lookup failed: ' + e.toString());
      }

      // 3. 최상위 루트 폴더 Fallback
      return DriveApp.getRootFolder();
    },

    /**
     * Google Drive에 JSON 백업 파일 생성 (스크립트 전용 폴더에 저장)
     */
    exportToDrive: function() {
      try {
        var presets = _loadPresets();
        var content = JSON.stringify(presets, null, 2);
        var filename = 'wsb_presets_backup_' + Utilities.formatDate(new Date(), Session.getScriptTimeZone(), 'yyyyMMdd_HHmmss') + '.json';
        
        var targetFolder = this.getDestinationFolder();
        var file = targetFolder.createFile(filename, content, MimeType.PLAIN_TEXT);
        
        return {
          success: true,
          fileName: file.getName(),
          fileUrl: file.getUrl(),
          folderName: targetFolder.getName(),
          message: '\'' + targetFolder.getName() + '\' 폴더에 백업 파일이 생성되었습니다: ' + file.getName()
        };
      } catch (err) {
        return { success: false, error: 'Google Drive 백업 실패: ' + err.toString() };
      }
    }
  };
})();
