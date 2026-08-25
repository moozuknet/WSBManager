/**
 * WSB Manager Web - Storage Service (UserProperties & Google Drive)
 */

var StorageService = (function() {
  var STORAGE_KEY = 'WSB_PRESETS_V1';

  /**
   * 저장소에서 전체 프리셋 JSON 파싱 후 반환
   */
  function _loadPresets() {
    try {
      var userProps = PropertiesService.getUserProperties();
      var data = userProps.getProperty(STORAGE_KEY);
      return data ? JSON.parse(data) : {};
    } catch (e) {
      Logger.log('Error loading presets: ' + e.toString());
      return {};
    }
  }

  /**
   * 프리셋 전체 저장
   */
  function _savePresetsMap(presetsMap) {
    var userProps = PropertiesService.getUserProperties();
    userProps.setProperty(STORAGE_KEY, JSON.stringify(presetsMap));
  }

  return {
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
        return { success: true, message: '\'' + presetName + '\' 프리셋이 클라우드에 저장되었습니다.' };
      } catch (err) {
        return { success: false, error: err.toString() };
      }
    },

    /**
     * 모든 프리셋 가져오기
     */
    getPresets: function() {
      try {
        return { success: true, data: _loadPresets() };
      } catch (err) {
        return { success: false, error: err.toString(), data: {} };
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
        return { success: true, message: '모든 클라우드 프리셋이 삭제되었습니다.' };
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
