# WSB Manager Web (Google Apps Script Edition)

> **Windows Sandbox (`.wsb`) 설정 프리셋 관리 및 원클릭 빌더 웹 애플리케이션**  
> C#/UWP 기반 오픈소스 `WSBManager`를 Google Apps Script (GAS) 기반 서버리스 웹 앱으로 전면 전환 및 보완 개발한 프로젝트입니다.  
> 🔗 **GitHub Repository**: [https://github.com/moozuknet/WSBManager](https://github.com/moozuknet/WSBManager)

---

## 💡 프로젝트 배경 및 개요

기존 C#/UWP 기반 `WSBManager`는 스토어 배포 중단 및 실행 파일 빌드의 번거로움이 있었습니다.  
**WSB Manager Web**은 설치 없이 웹 브라우저에서 Windows Sandbox의 모든 세부 설정을 GUI 환경에서 조작하고, 프리셋으로 저장/관리하며, 단 한 번의 클릭으로 `.wsb` XML 설정 파일을 생성하고 로컬 PC로 즉시 다운로드할 수 있는 서버리스 솔루션입니다.

---

## ✨ 주요 기능 (Key Features)

1. **완벽한 Windows Sandbox (`.wsb`) XML 스펙 지원**
   - **가상 GPU (`vGPU`)**: Enable, Disable, Default
   - **네트워크 (`Networking`)**: Default (허용), Disable (오프라인)
   - **메모리 할당 (`MemoryInMB`)**: MB 단위 세부 조정 및 빠른 퀵 버터 (2GB / 4GB / 8GB / 16GB)
   - **폴더 매핑 (`MappedFolders`)**: 동적 행 추가/삭제, HostFolder / SandboxFolder 경로 지정, ReadOnly 토글
   - **장치 리디렉션 (5종)**: 클립보드 공유 (양방향/단방향/차단), 오디오(마이크), 비디오(웹캠), RDP 보호 클라이언트, 프린터
   - **시작 스크립트 (`LogonCommand`)**: 샌드박스 시작 시 실행할 명령 또는 스크립트 설정

2. **자동화 스크립트 템플릿 라이브러리 (Winget Snippets)**
   - Winget을 활용한 필수 소프트웨어 자동 설치 스크립트 템플릿 원터치 삽입:
     - Google Chrome
     - Visual Studio Code
     - Git
     - 개발/테스트 필수 팩 (7-Zip + Notepad++ + Chrome)
     - 시작 웹사이트 자동 오픈 및 Desktop 스크립트 실행

3. **이중 프리셋 저장 & 스마트 동기화**
   - **로컬 저장 (Browser LocalStorage)**: 즉각적인 반응성 제공
   - **구글 클라우드 저장 (GAS `PropertiesService`)**: 다른 기기/환경에서도 프리셋 동기화
   - **JSON 백업 / 복원**: 로컬 파일로 프리셋 내보내기/가져오기
   - **Google Drive 자동 백업**: 전체 프리셋 JSON을 구글 드라이브 파일로 백업

4. **사용자 친화적 모던 웹 UI**
   - Tailwind CSS + FontAwesome 기반 슬릭 다크 테마
   - 2단 반응형 레이아웃 (좌: 프리셋 탐색 및 관리 / 우: 설정 폼)
   - 실시간 XML 코드 미리보기 및 클립보드 복사 모달

5. **프리셋 설명/메모 & XML 주석 헤더 자동 기록**
   - 각 프리셋별 사용 목적(설명/메모) 입력 지원
   - 생성되는 `.wsb` XML 파일 상단에 프리셋 이름, 설명 메모 및 생성 일시를 XML 주석(`<!-- ... -->`)으로 자동 표기하여 식별 용이성 제공

---

## 📁 프로젝트 구조

```text
WSBManager/
├── .clasp.json                   # Clasp CLI 설정 파일 (scriptId 및 rootDir 지정)
├── package.json                  # 자동 배포 스크립트 모음
├── README.md                     # 프로젝트 설명 및 개발 가이드
├── WSBManager_GAS_Development_Guide.md  # 구글 Apps Script 개발 가이드 문서
└── src/
    ├── appsscript.json           # Google Apps Script 웹 앱 매니페스트
    ├── Code.js                   # GAS 백엔드 진입점 (doGet 및 Cloud API)
    ├── StorageService.js         # UserProperties & Google Drive 데이터 연동 모듈
    ├── WsbGenerator.js           # 서버 측 XML 생성 보조 모듈
    ├── index.html                # 메인 HTML UI 레이아웃
    ├── css.html                  # Custom CSS 스타일시트
    └── js.html                   # 프론트엔드 인터랙션, 프리셋 관리 및 .wsb 다운로드 로직
```

---

## 🚀 배포 및 설치 가이드 (Google Apps Script + Clasp)

### 사전 준비사항
* Node.js 및 npm 설치
* Google 계정

### 1단계: Clasp 설치 및 로그인
```bash
# clasp 글로벌 설치
npm install -g @google/clasp

# 구글 계정 인증 로그인
clasp login
```

### 2단계: 프로젝트 연결 및 코드 동기화
1. `.clasp.json` 파일의 `scriptId`에 구글 앱스 스크립트 프로젝트 ID 지정.
2. 로컬 소스 코드를 GAS 클라우드로 푸시:
   ```bash
   npm run push
   ```

### 3단계: 원클릭 자동 청소 배포 (Clean Deployment)
> **규정**: 구버전 배포 버전이 엉키지 않도록 **새 배포 시 기존 배포를 항상 전체 삭제(`clasp undeploy --all`) 후 신규 배포**를 수행합니다.

```bash
# 원클릭 자동 배포 (기존 배포 삭제 -> 소스 푸시 -> 신규 배포 생성)
npm run deploy
```

* 배포 완료 후 터미널에 생성된 Web App URL (`https://script.google.com/macros/s/.../exec`) 확인.
* Google Apps Script 관리 콘솔 -> **배포 관리**에서 접근 권한을 **"Anyone (누구나)"**로 설정합니다.

---

## 📄 `.wsb` XML 구조 예시

WSB Manager Web에서 작성 및 생성되는 `.wsb` XML 설정 예시입니다:

```xml
<!-- WSB Manager Web Generated Config -->
<Configuration>
  <VGpu>Enable</VGpu>
  <Networking>Default</Networking>
  <MappedFolders>
    <MappedFolder>
      <HostFolder>C:\Users\Public\Downloads</HostFolder>
      <SandboxFolder>C:\Users\WDAGUtilityAccount\Desktop\Downloads</SandboxFolder>
      <ReadOnly>true</ReadOnly>
    </MappedFolder>
  </MappedFolders>
  <LogonCommand>
    <Command>powershell.exe -ExecutionPolicy Bypass -Command "winget install -e --id Microsoft.VisualStudioCode --accept-package-agreements --accept-source-agreements"</Command>
  </LogonCommand>
  <MemoryInMB>8192</MemoryInMB>
  <AudioInput>Default</AudioInput>
  <VideoInput>Disable</VideoInput>
  <ProtectedClient>Default</ProtectedClient>
  <PrinterRedirection>Disable</PrinterRedirection>
  <ClipboardRedirection>Default</ClipboardRedirection>
</Configuration>
```

---

## 💻 사용 방법

1. **프리셋 선택 또는 신규 작성**: 좌측 프리셋 목록에서 원하는 항목을 클릭하거나 `신규 작성`을 누릅니다.
2. **샌드박스 설정 조작**:
   - vGPU, 네트워크, 메모리(MB) 설정
   - 필요한 호스트 폴더 추가 및 Sandbox 내부 위치/읽기전용 여부 설정
   - 자동 실행할 Logon Command 설정 (템플릿 드롭다운으로 빠르게 선택 가능)
3. **다운로드 또는 클라우드 저장**:
   - `.wsb 다운로드` 버튼 클릭 시 로컬 PC에 `.wsb` 파일이 다운로드됩니다.
   - `프리셋 저장` 버튼으로 현재 설정을 구글 클라우드 및 브라우저에 저장합니다.
4. **실행**: 다운로드받은 `.wsb` 파일을 더블클릭하면 Windows Sandbox가 설정대로 바로 구동됩니다!

---

## 🗺️ 향후 개발 로드맵 (Roadmap)

- [ ] **더 많은 Winget 스니펫 라이브러리 파이프라인**: Python, Docker Desktop, Node.js, Wireshark 등 확장
- [ ] **QR 코드 & 공유 링크 생성**: 설정 프리셋 URL 파라미터 인코딩 공유 기능
- [ ] **다국어 지원 (i18n)**: 한국어 / 영어 전환 지원

---

## 📝 라이선스 (License)

본 프로젝트는 [MIT License](LICENSE)를 따릅니다.
