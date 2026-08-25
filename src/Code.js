/**
 * WSB Manager Web - Google Apps Script Backend Entry Point
 * 
 * @OnlyCurrentDoc
 */

/**
 * Web App HTTP GET 진입점
 */
function doGet(e) {
  return HtmlService.createTemplateFromFile('index')
    .evaluate()
    .setTitle('WSB Manager Web - Windows Sandbox Configurator')
    .addMetaTag('viewport', 'width=device-width, initial-scale=1.0')
    .setXFrameOptionsMode(HtmlService.XFrameOptionsMode.ALLOWALL);
}

/**
 * HTML 서브 파일 Include 헬퍼 함수
 * @param {string} filename include할 html 파일명 (확장자 제외)
 * @return {string} html 파일 내용
 */
function include(filename) {
  return HtmlService.createHtmlOutputFromFile(filename).getContent();
}

/**
 * 사용자 클라우드(UserProperties)에 프리셋 저장
 * @param {string} presetName 프리셋 이름
 * @param {Object} configData 샌드박스 설정 객체
 * @return {Object} 처리 결과 { success: boolean, message/error: string }
 */
function savePresetToCloud(presetName, configData) {
  return StorageService.savePreset(presetName, configData);
}

/**
 * 사용자 클라우드(UserProperties)에서 전체 프리셋 목록 조회
 * @return {Object} 프리셋 객체 Map
 */
function getPresetsFromCloud() {
  return StorageService.getPresets();
}

/**
 * 사용자 클라우드(UserProperties)에서 특정 프리셋 삭제
 * @param {string} presetName 삭제할 프리셋 이름
 * @return {Object} 처리 결과
 */
function deletePresetFromCloud(presetName) {
  return StorageService.deletePreset(presetName);
}

/**
 * deletePresetFromCloud 호환성 별칭
 */
function deletePresetToCloud(presetName) {
  return StorageService.deletePreset(presetName);
}

/**
 * 사용자 클라우드(UserProperties)의 모든 프리셋 삭제
 */
function clearAllPresetsFromCloud() {
  return StorageService.clearAllPresets();
}

/**
 * Google Drive에 전체 프리셋 JSON 백업 파일 생성
 * @return {Object} 처리 결과 { success: boolean, fileUrl: string, error: string }
 */
function exportPresetsToDrive() {
  return StorageService.exportToDrive();
}

/**
 * 구글 드라이브 및 스크립트 서비스 권한 일괄 승인 헬퍼 함수
 * (스크립트 편집기에서 최초 1회 [실행]하여 [권한 확인]을 허용하면 웹앱 접속 및 모든 버튼 클릭이 100% 정상 작동합니다)
 */
function testAuth() {
  Logger.log('Script ID: ' + ScriptApp.getScriptId());
  var folder = StorageService.getDestinationFolder();
  Logger.log('Target Folder Name: ' + folder.getName());
  var presets = StorageService.getPresets();
  Logger.log('Current Presets count: ' + Object.keys(presets.data || {}).length);
  return 'SUCCESS';
}

/**
 * 전체 프리셋 객체 일괄 저장
 */
function saveAllPresetsToCloud(presetsMap) {
  return StorageService.saveAllPresets(presetsMap);
}

/**
 * Google Drive 폴더 내 저장된 백업 파일 목록 조회
 */
function listDriveBackups() {
  return StorageService.listDriveBackups();
}

/**
 * Google Drive 파일 ID로 백업 복원
 */
function importFromDriveFile(fileId) {
  return StorageService.importFromDriveFile(fileId);
}
