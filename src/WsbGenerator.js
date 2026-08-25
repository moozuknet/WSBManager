/**
 * WSB Manager Web - Windows Sandbox XML Generator Helper (Backend)
 */

var WsbGenerator = (function() {
  /**
   * XML 문자 이스케이프
   */
  function escapeXml(unsafe) {
    if (!unsafe) return '';
    return String(unsafe).replace(/[<>&'"]/g, function(c) {
      switch (c) {
        case '<': return '&lt;';
        case '>': return '&gt;';
        case '&': return '&amp;';
        case '\'': return '&apos;';
        case '"': return '&quot;';
        default: return c;
      }
    });
  }

  return {
    /**
     * JS 객체로부터 Windows Sandbox XML (.wsb) 규격 문자열 생성
     * @param {Object} config
     * @return {string} XML 포맷 텍스트
     */
    generateXml: function(config) {
      var xml = '<!--\n';
      xml += '  WSB Manager Web Generated Configuration\n';
      xml += '  Preset Name : ' + escapeXml(config.presetName || 'Custom Sandbox') + '\n';
      if (config.presetDescription && config.presetDescription.trim() !== '') {
        xml += '  Description : ' + escapeXml(config.presetDescription.trim()) + '\n';
      }
      xml += '  Generated At: ' + Utilities.formatDate(new Date(), Session.getScriptTimeZone(), 'yyyy-MM-dd HH:mm:ss') + '\n';
      xml += '-->\n';
      xml += '<Configuration>\n';

      // 1. vGPU
      if (config.vGpu) {
        xml += '  <VGpu>' + escapeXml(config.vGpu) + '</VGpu>\n';
      }

      // 2. Networking
      if (config.networking) {
        xml += '  <Networking>' + escapeXml(config.networking) + '</Networking>\n';
      }

      // 3. MappedFolders
      if (config.mappedFolders && Array.isArray(config.mappedFolders) && config.mappedFolders.length > 0) {
        var validFolders = config.mappedFolders.filter(function(f) { return f && f.hostFolder && f.hostFolder.trim() !== ''; });
        if (validFolders.length > 0) {
          xml += '  <MappedFolders>\n';
          validFolders.forEach(function(folder) {
            xml += '    <MappedFolder>\n';
            xml += '      <HostFolder>' + escapeXml(folder.hostFolder.trim()) + '</HostFolder>\n';
            if (folder.sandboxFolder && folder.sandboxFolder.trim() !== '') {
              xml += '      <SandboxFolder>' + escapeXml(folder.sandboxFolder.trim()) + '</SandboxFolder>\n';
            }
            xml += '      <ReadOnly>' + (folder.readOnly ? 'true' : 'false') + '</ReadOnly>\n';
            xml += '    </MappedFolder>\n';
          });
          xml += '  </MappedFolders>\n';
        }
      }

      // 4. LogonCommand
      if (config.logonCommand && config.logonCommand.trim() !== '') {
        xml += '  <LogonCommand>\n';
        xml += '    <Command>' + escapeXml(config.logonCommand.trim()) + '</Command>\n';
        xml += '  </LogonCommand>\n';
      }

      // 5. MemoryInMB
      if (config.memoryInMB && parseInt(config.memoryInMB, 10) > 0) {
        xml += '  <MemoryInMB>' + parseInt(config.memoryInMB, 10) + '</MemoryInMB>\n';
      }

      // 6. Device Redirections
      if (config.audioInput) {
        xml += '  <AudioInput>' + escapeXml(config.audioInput) + '</AudioInput>\n';
      }
      if (config.videoInput) {
        xml += '  <VideoInput>' + escapeXml(config.videoInput) + '</VideoInput>\n';
      }
      if (config.protectedClient) {
        xml += '  <ProtectedClient>' + escapeXml(config.protectedClient) + '</ProtectedClient>\n';
      }
      if (config.printerRedirection) {
        xml += '  <PrinterRedirection>' + escapeXml(config.printerRedirection) + '</PrinterRedirection>\n';
      }
      if (config.clipboard) {
        xml += '  <ClipboardRedirection>' + escapeXml(config.clipboard) + '</ClipboardRedirection>\n';
      }

      xml += '</Configuration>';
      return xml;
    }
  };
})();
