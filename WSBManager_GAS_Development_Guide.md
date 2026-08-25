# WSB Manager (Google Apps Script Web App 버전) 개발 계획서 & 기술 명세서

> **프로젝트 개요**: Nia-TN1012의 C#/UWP 기반 오픈소스 프로젝트인 **WSBManager**를 Google Apps Script(GAS) 기반의 경량 웹 애플리케이션으로 포팅하여, 웹 GUI 환경에서 Windows Sandbox(`.wsb`) 설정 프리셋을 관리하고 즉시 다운로드하여 실행할 수 있도록 하는 시스템 개발 문서입니다.

---

## 1. 프로젝트 개요 및 배경

### 1.1 배경 및 목적
* **기존 문제점**: 기존 C#/UWP 기반 `WSBManager`는 스토어 배포 중단 및 빌드 바이너리 미제공으로 로컬 설치/유지보수가 번거로움.
* **해결 방안**: 별도 설치가 필요 없는 서버리스 Web App(Google Apps Script + HTML Service)으로 전환.
* **핵심 목표**:
  1. 웹 UI에서 Windows Sandbox의 모든 스펙(vGPU, 네트워크, Mapped Folders, LogonCommand, 메모리 할당, 디바이스 리디렉션 등)을 GUI로 설정.
  2. Google Drive / Google Sheets / User Properties(또는 브라우저 LocalStorage)와 연동하여 프리셋 저장/불러오기.
  3. 설정 완료 후 클릭 한 번으로 `.wsb` (XML) 설정 파일을 생성하여 즉시 로컬 PC로 다운로드.

### 1.2 개발 환경 (Antigravity IDE & Clasp)
* **개발 IDE**: Antigravity IDE (VS Code 기반)
* **GAS 배포 도구**: `@google/clasp` (Command Line Apps Script Projects)
* **언어 및 프레임워크**:
  * **Backend**: Google Apps Script (JavaScript ES6+ / V8 Runtime)
  * **Frontend**: Vanilla HTML5, Modern CSS (Tailwind CSS CDN 활용 권장), Modern JS (ES6+)

---

## 2. Windows Sandbox (`.wsb`) XML 규격 명세

Windows Sandbox 설정 파일은 표준 XML 포맷으로 구성됩니다. GAS 웹 앱은 사용자의 입력을 받아 아래 구조의 `.wsb` XML 문자열을 생성해야 합니다.

```xml
<Configuration>
  <!-- 1. 가상 GPU 활성화 여부: Enable, Disable, Default -->
  <VGpu>Enable</VGpu>

  <!-- 2. 네트워크 연결: Default, Disable -->
  <Networking>Default</Networking>

  <!-- 3. 매핑 폴더 목록 -->
  <MappedFolders>
    <MappedFolder>
      <HostFolder>C:\Users\Public\Downloads</HostFolder>
      <SandboxFolder>C:\Users\WDAGUtilityAccount\Desktop\Downloads</SandboxFolder>
      <ReadOnly>true</ReadOnly>
    </MappedFolder>
  </MappedFolders>

  <!-- 4. 시작 시 자동 실행 명령 (cmd / powershell 등) -->
  <LogonCommand>
    <Command>cmd.exe /c start https://google.com</Command>
  </LogonCommand>

  <!-- 5. 메모리 할당량 (MB 단위, 미설정 시 기본값) -->
  <MemoryInMB>4096</MemoryInMB>

  <!-- 6. 하드웨어 및 장치 리디렉션 -->
  <AudioInput>Enable</AudioInput>
  <VideoInput>Disable</VideoInput>
  <ProtectedClient>Enable</ProtectedClient>
  <PrinterRedirection>Disable</PrinterRedirection>
  <ClipboardRedirection>Default</ClipboardRedirection>
</Configuration>
```

---

## 3. 시스템 아키텍처 및 디렉토리 구조

### 3.1 프로젝트 구조 (Antigravity / Clasp 기반)

```text
wsbmanager-gas/
├── .clasp.json             # Clasp 설정 파일 (scriptId, rootDir)
├── appsscript.json         # Apps Script 매니페스트 파일
├── src/
│   ├── Code.js             # 백엔드 진입점 (doGet, API 함수)
│   ├── StorageService.js   # 프리셋 저장/조회 로직 (Google Drive/Sheets 연동)
│   ├── WsbGenerator.js     # XML 빌더 모듈
│   ├── index.html          # 메인 웹 UI 템플릿
│   ├── css.html            # 스타일시트 분리 파일
│   └── js.html             # 프론트엔드 인터랙션 & 다운로드 로직
└── README.md
```

### 3.2 데이터 흐름 (Data Flow)
1. **[사용자 접속]** Google Apps Script Web App URL로 접속 (`doGet()` 호출 -> `index.html` 렌더링)
2. **[프리셋 관리]**
   * 저장된 프리셋 목록 불러오기 (서버 `StorageService` 또는 클라이언트 `localStorage`)
   * 프리셋 선택 시 Form에 필드 자동 채움
3. **[설정 입력]**
   * vGPU, 메모리(MB), Mapped Folders (추가/삭제 동적 UI), Logon Script 설정
4. **[파일 생성 및 다운로드]**
   * 클라이언트 측에서 즉시 Blob 생성(`new Blob([xmlContent], {type: 'application/xml'})`) 후 `<a download="config.wsb">` 트리거로 로컬 PC 다운로드 (서버 트래픽 절약 및 즉각 응답).
   * 필요 시 서버 Drive에 백업 저장 가능.

---

## 4. 상세 모듈 설계 및 코드 명세

### 4.1 Backend (`src/Code.js`)
```javascript
/**
 * Web App 진입점
 */
function doGet(e) {
  return HtmlService.createTemplateFromFile('index')
    .evaluate()
    .setTitle('WSB Manager Web - Windows Sandbox Configurator')
    .addMetaTag('viewport', 'width=device-width, initial-scale=1.0')
    .setXFrameOptionsMode(HtmlService.XFrameOptionsMode.ALLOWALL);
}

/**
 * HTML 내 서브 파일 Include 헬퍼
 */
function include(filename) {
  return HtmlService.createHtmlOutputFromFile(filename).getContent();
}

/**
 * 프리셋 저장 (UserProperties 또는 Drive)
 */
function savePresetToCloud(presetName, configData) {
  try {
    const userProps = PropertiesService.getUserProperties();
    let presets = JSON.parse(userProps.getProperty('WSB_PRESETS') || '{}');
    presets[presetName] = configData;
    userProps.setProperty('WSB_PRESETS', JSON.stringify(presets));
    return { success: true, message: '프리셋이 성공적으로 저장되었습니다.' };
  } catch (err) {
    return { success: false, error: err.toString() };
  }
}

/**
 * 프리셋 목록 조회
 */
function getPresetsFromCloud() {
  const userProps = PropertiesService.getUserProperties();
  return JSON.parse(userProps.getProperty('WSB_PRESETS') || '{}');
}
```

### 4.2 Frontend Layout (`src/index.html`)
* 다크 모드 / 라이트 모드 지원 (Tailwind CSS 기반)
* 2단 레이아웃 (왼쪽: 프리셋 목록 및 관리, 오른쪽: 샌드박스 세부 파라미터 폼)

```html
<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8">
  <script src="https://cdn.tailwindcss.com"></script>
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
  <?!= include('css'); ?>
</head>
<body class="bg-slate-900 text-slate-100 min-h-screen p-6 font-sans">
  <div class="max-w-6xl mx-auto space-y-6">
    <!-- 헤더 -->
    <header class="flex justify-between items-center border-b border-slate-800 pb-4">
      <div>
        <h1 class="text-2xl font-bold text-sky-400 flex items-center gap-2">
          <i class="fa-solid fa-box-open"></i> WSB Manager Web
        </h1>
        <p class="text-sm text-slate-400">Windows Sandbox (.wsb) 설정 관리 및 원클릭 빌더</p>
      </div>
      <div class="flex gap-2">
        <button onclick="exportWsbFile()" class="bg-emerald-600 hover:bg-emerald-500 text-white px-4 py-2 rounded-lg font-semibold flex items-center gap-2 shadow-lg transition">
          <i class="fa-solid fa-download"></i> .wsb 다운로드
        </button>
      </div>
    </header>

    <!-- 메인 컨텐츠 그리드 -->
    <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
      <!-- 좌측: 프리셋 관리 카드 -->
      <div class="bg-slate-800/80 p-5 rounded-xl border border-slate-700/60 shadow-md">
        <div class="flex justify-between items-center mb-4">
          <h2 class="font-bold text-slate-200"><i class="fa-solid fa-list mr-2"></i>프리셋 목록</h2>
          <button onclick="createNewPreset()" class="text-xs bg-sky-600 hover:bg-sky-500 px-2 py-1 rounded text-white">신규 추가</button>
        </div>
        <ul id="presetList" class="space-y-2 max-h-[500px] overflow-y-auto pr-1">
          <!-- JS 렌더링 -->
        </ul>
      </div>

      <!-- 우측: 설정 파라미터 입력 폼 -->
      <div class="md:col-span-2 bg-slate-800/80 p-6 rounded-xl border border-slate-700/60 shadow-md space-y-6">
        <form id="wsbForm" onsubmit="event.preventDefault();">
          <!-- 기본 하드웨어 설정 -->
          <h3 class="text-lg font-semibold text-sky-300 border-b border-slate-700 pb-2 mb-4">
            <i class="fa-solid fa-microchip mr-2"></i>기본 하드웨어 & 기능
          </h3>
          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="block text-xs text-slate-400 mb-1">가상 GPU (vGPU)</label>
              <select id="vGpu" class="w-full bg-slate-900 border border-slate-700 rounded p-2 text-sm">
                <option value="Enable">Enable (활성화)</option>
                <option value="Disable">Disable (비활성화)</option>
                <option value="Default">Default</option>
              </select>
            </div>
            <div>
              <label class="block text-xs text-slate-400 mb-1">네트워크 (Networking)</label>
              <select id="networking" class="w-full bg-slate-900 border border-slate-700 rounded p-2 text-sm">
                <option value="Default">Default (허용)</option>
                <option value="Disable">Disable (차단)</option>
              </select>
            </div>
            <div>
              <label class="block text-xs text-slate-400 mb-1">메모리 제한 (MB, 0은 기본값)</label>
              <input type="number" id="memoryInMB" placeholder="예: 4096 (4GB)" class="w-full bg-slate-900 border border-slate-700 rounded p-2 text-sm">
            </div>
            <div>
              <label class="block text-xs text-slate-400 mb-1">클립보드 공유</label>
              <select id="clipboard" class="w-full bg-slate-900 border border-slate-700 rounded p-2 text-sm">
                <option value="Default">Default (양방향)</option>
                <option value="Disable">Disable</option>
              </select>
            </div>
          </div>

          <!-- Mapped Folders -->
          <div class="mt-6">
            <div class="flex justify-between items-center border-b border-slate-700 pb-2 mb-3">
              <h3 class="text-lg font-semibold text-sky-300"><i class="fa-solid fa-folder-tree mr-2"></i>폴더 매핑 (Mapped Folders)</h3>
              <button type="button" onclick="addFolderRow()" class="text-xs bg-slate-700 hover:bg-slate-600 px-2 py-1 rounded text-slate-200">+ 폴더 추가</button>
            </div>
            <div id="folderContainer" class="space-y-2">
              <!-- 동적 생성 행 -->
            </div>
          </div>

          <!-- Logon Command -->
          <div class="mt-6">
            <h3 class="text-lg font-semibold text-sky-300 border-b border-slate-700 pb-2 mb-3">
              <i class="fa-solid fa-terminal mr-2"></i>시작 스크립트 (Logon Command)
            </h3>
            <textarea id="logonCommand" rows="3" placeholder="예: powershell.exe -ExecutionPolicy Bypass -File C:\Users\WDAGUtilityAccount\Desktop\init.ps1" class="w-full bg-slate-900 border border-slate-700 rounded p-2 text-sm font-mono"></textarea>
          </div>
        </form>
      </div>
    </div>
  </div>

  <?!= include('js'); ?>
</body>
</html>
```

### 4.3 Client-Side Logic & XML Exporter (`src/js.html`)
```javascript
<script>
// XML 문자열 생성 및 다운로드 로직
function generateWsbXml(formData) {
  let xml = `<Configuration>\n`;
  if (formData.vGpu) xml += `  <VGpu>${formData.vGpu}</VGpu>\n`;
  if (formData.networking) xml += `  <Networking>${formData.networking}</Networking>\n`;
  
  // Mapped Folders
  if (formData.mappedFolders && formData.mappedFolders.length > 0) {
    xml += `  <MappedFolders>\n`;
    formData.mappedFolders.forEach(folder => {
      if (folder.hostFolder) {
        xml += `    <MappedFolder>\n`;
        xml += `      <HostFolder>${escapeXml(folder.hostFolder)}</HostFolder>\n`;
        if (folder.sandboxFolder) {
          xml += `      <SandboxFolder>${escapeXml(folder.sandboxFolder)}</SandboxFolder>\n`;
        }
        xml += `      <ReadOnly>${folder.readOnly ? 'true' : 'false'}</ReadOnly>\n`;
        xml += `    </MappedFolder>\n`;
      }
    });
    xml += `  </MappedFolders>\n`;
  }

  // Logon Command
  if (formData.logonCommand && formData.logonCommand.trim() !== '') {
    xml += `  <LogonCommand>\n`;
    xml += `    <Command>${escapeXml(formData.logonCommand.trim())}</Command>\n`;
    xml += `  </LogonCommand>\n`;
  }

  // Memory
  if (formData.memoryInMB && parseInt(formData.memoryInMB) > 0) {
    xml += `  <MemoryInMB>${formData.memoryInMB}</MemoryInMB>\n`;
  }

  if (formData.clipboard) xml += `  <ClipboardRedirection>${formData.clipboard}</ClipboardRedirection>\n`;
  xml += `</Configuration>`;
  return xml;
}

function escapeXml(unsafe) {
  return unsafe.replace(/[<>&'"]/g, function (c) {
    switch (c) {
      case '<': return '&lt;';
      case '>': return '&gt;';
      case '&': return '&amp;';
      case ''': return '&apos;';
      case '"': return '&quot;';
    }
  });
}

// 브라우저에서 직접 .wsb 파일 다운로드
function exportWsbFile() {
  const formData = collectFormData();
  const xmlContent = generateWsbXml(formData);
  const blob = new Blob([xmlContent], { type: 'text/xml;charset=utf-8;' });
  const filename = (formData.presetName || 'sandbox_config') + '.wsb';

  const link = document.createElement('a');
  link.href = URL.createObjectURL(blob);
  link.download = filename;
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
}
</script>
```

---

## 5. 단계별 개발 및 배포 가이드 (Antigravity & Clasp)

### Step 1: 프로젝트 초기화
```bash
# 디렉토리 생성 및 clasp 로그인
mkdir wsbmanager-gas && cd wsbmanager-gas
npm init -y
npm install -g @google/clasp

# Google 계정 로그인
clasp login

# 신규 GAS 프로젝트 생성 (Web App)
clasp create --title "WSBManager-Web" --type webapp --rootDir ./src
```

### Step 2: 코드 작성 및 동기화
1. `src/` 폴더 내 `Code.js`, `index.html`, `css.html`, `js.html` 작성.
2. 로컬 코드 GAS 클라우드로 푸시:
   ```bash
   clasp push --watch
   ```

### Step 3: 원클릭 자동 배포 및 재배포 규정 (Automated Deployment Rule)

> ⚠️ **원클릭 자동 재배포 규칙**: 새 배포를 진행할 때는 구글 앱스 스크립트에 구 버전 배포가 누적되어 엉키지 않도록 **항상 기존 배포 목록을 전량 삭제(`clasp undeploy --all`)** 한 후 소스 코드를 동기화하고 새 배포를 생성합니다.

1. **자동 배포 명령어 (npm script 활용)**:
   `package.json`에 정의된 원클릭 자동 배포 명령어를 수행합니다.
   ```bash
   npm run deploy
   ```
   *(내부 수행 과정: `clasp undeploy --all` -> `clasp push -f` -> `clasp deploy --description "Automated Web App Release"`)*

2. **단계별 수동 명령어 세부 정보**:
   ```bash
   # 1. 기존 배포 일괄 삭제
   clasp undeploy --all

   # 2. 로컬 소스 코드 강제 클라우드 동기화
   clasp push -f

   # 3. 신규 프로덕션 배포 생성
   clasp deploy --description "Automated Web App Release"
   ```

3. **배포 URL 확인 및 권한**:
   * 터미널에 출력된 Web App URL (`https://script.google.com/macros/s/.../exec`) 확인.
   * 실행 권한 설정: **"Anyone" (누구나 접속 가능)**.

---

## 6. 특화 기능 및 로드맵

1. **원클릭 스타터 스크립트 프리셋 라이브러리**:
   * Winget 설치 스크립트 템플릿 제공 (`winget install -e --id Google.Chrome`)
   * VS Code, 7-Zip, Notepad++ 등 개발/테스트 필수 도구 자동 설치 스니펫
2. **Google Drive 연동 백업 지정 폴더 저장**:
   * Google Drive의 최상위 루트가 아닌, GAS 스크립트가 전용으로 위치한 지정 폴더 (`1W0jr7VODpb3NTLzdU0nxBO59A7_J7PUq`)에 백업 JSON 파일 자동 저장/동기화 (`StorageService.getDestinationFolder()`)
3. **QR코드 / 단축 URL**:
   * 다른 PC에서 바로 설정 다운로드 가능하도록 지원
