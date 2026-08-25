/**
 * WSB Manager Web - Storage Service (UserProperties & Google Drive)
 */

var StorageService = (function() {
  var STORAGE_KEY = 'WSB_PRESETS_V1';

  /**
   * 저장소에서 전체 프리셋 JSON 파싱 후 반환 (청크 처리 지원)
   */
  function _loadPresets() {
    try {
      var userProps = PropertiesService.getUserProperties();
      var totalChunksStr = userProps.getProperty(STORAGE_KEY + '_TOTAL_CHUNKS');
      
      if (totalChunksStr) {
        var totalChunks = parseInt(totalChunksStr, 10);
        var jsonStr = '';
        for (var c = 0; c < totalChunks; c++) {
          var chunk = userProps.getProperty(STORAGE_KEY + '_CHUNK_' + c);
          if (chunk) jsonStr += chunk;
        }
        return jsonStr ? JSON.parse(jsonStr) : {};
      }

      // 레거시 단일 속성 하위 호환
      var data = userProps.getProperty(STORAGE_KEY);
      return data ? JSON.parse(data) : {};
    } catch (e) {
      Logger.log('Error loading presets: ' + e.toString());
      return {};
    }
  }

  /**
   * 프리셋 전체 저장 (PropertiesService 9KB 제한 해제를 위한 청크 분할 저장)
   */
  function _savePresetsMap(presetsMap) {
    var userProps = PropertiesService.getUserProperties();
    var jsonStr = JSON.stringify(presetsMap);

    // 기존 단일 및 청크 속성 초기화
    userProps.removeProperty(STORAGE_KEY);
    var keys = userProps.getKeys();
    for (var i = 0; i < keys.length; i++) {
      if (keys[i].indexOf(STORAGE_KEY + '_CHUNK_') === 0) {
        userProps.removeProperty(keys[i]);
      }
    }

    // 8000 자 단위 청크 분할 (안전 범위)
    var chunkSize = 8000;
    var totalChunks = Math.ceil(jsonStr.length / chunkSize);
    userProps.setProperty(STORAGE_KEY + '_TOTAL_CHUNKS', String(totalChunks));

    for (var c = 0; c < totalChunks; c++) {
      var chunk = jsonStr.substring(c * chunkSize, (c + 1) * chunkSize);
      userProps.setProperty(STORAGE_KEY + '_CHUNK_' + c, chunk);
    }
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
     * 전체 프리셋 Map 객체 일괄 클라우드 저장
     */
    saveAllPresets: function(presetsMap) {
      try {
        if (typeof presetsMap !== 'object' || presetsMap === null) {
          return { success: false, error: '유효한 프리셋 데이터가 아닙니다.' };
        }
        _savePresetsMap(presetsMap);
        return { success: true, message: '모든 프리셋이 클라우드에 일괄 저장되었습니다.' };
      } catch (err) {
        return { success: false, error: err.toString() };
      }
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
    },

    /**
     * Google Drive 지정 폴더 내에 저장된 백업 JSON 파일 목록 조회
     */
    listDriveBackups: function() {
      try {
        var targetFolder = this.getDestinationFolder();
        var files = targetFolder.getFiles();
        var list = [];
        while (files.hasNext()) {
          var file = files.next();
          var name = file.getName();
          if (name.indexOf('wsb_presets_backup_') === 0 || name.indexOf('.json') !== -1) {
            list.push({
              id: file.getId(),
              name: file.getName(),
              size: file.getSize(),
              updatedAt: Utilities.formatDate(file.getLastUpdated(), Session.getScriptTimeZone(), 'yyyy-MM-dd HH:mm:ss'),
              url: file.getUrl()
            });
          }
        }
        // 내림차순 정렬 (최신 파일이 위로)
        list.sort(function(a, b) {
          return b.updatedAt.localeCompare(a.updatedAt);
        });
        return { success: true, files: list, folderName: targetFolder.getName() };
      } catch (err) {
        return { success: false, error: 'Drive 백업 목록 조회 실패: ' + err.toString(), files: [] };
      }
    },

    /**
     * Google Drive 파일 ID로부터 JSON 백업 읽어와 프리셋 복원
     */
    importFromDriveFile: function(fileId) {
      try {
        var file = DriveApp.getFileById(fileId);
        var content = file.getBlob().getDataAsString('UTF-8');
        var imported = JSON.parse(content);

        if (typeof imported === 'object' && imported !== null) {
          var currentPresets = _loadPresets();
          var merged = Object.assign({}, currentPresets, imported);
          _savePresetsMap(merged);
          return {
            success: true,
            data: merged,
            fileName: file.getName(),
            message: '\'' + file.getName() + '\' 파일에서 프리셋이 복원되었습니다.'
          };
        } else {
          return { success: false, error: '유효한 프리셋 JSON 파일 포맷이 아닙니다.' };
        }
      } catch (err) {
        return { success: false, error: 'Drive 백업 복원 실패: ' + err.toString() };
      }
    }
  };
})();
