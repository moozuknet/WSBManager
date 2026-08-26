# WSB Manager (Google Apps Script Web App 버전) 개발 가이드 및 기술 명세서

> **프로젝트 개요**: Nia-TN1012의 C#/UWP 기반 오픈소스 프로젝트인 **WSBManager**를 Google Apps Script(GAS) 기반의 서버리스 웹 애플리케이션으로 전면 포팅 및 고도화 개발한 프로젝트입니다.  
> 🌐 **Permanent Web App URL**: [https://script.google.com/macros/s/AKfycbyjwICUGj0U3OK_jFHjs1DxgVDFJIrNVlslDlSXAr7vw_vQ8FfTwI7EuTPzt2HU90DC/exec](https://script.google.com/macros/s/AKfycbyjwICUGj0U3OK_jFHjs1DxgVDFJIrNVlslDlSXAr7vw_vQ8FfTwI7EuTPzt2HU90DC/exec)  
> 🔗 **GitHub Repository**: [https://github.com/moozuknet/WSBManager](https://github.com/moozuknet/WSBManager)

---

## 🖼️ 메인 UI 스크린샷 (UI Preview)

![WSB Manager Web UI](docs/images/wsb_manager_main.png)

---

## 1. 프로젝트 아키텍처 및 배포 명세

### 1.1 핵심 자산 식별 정보
* **GAS Script ID**: `1M5KcU6aMjfuIrwRxwnSmGPOR4VQxqE0p475M_vn5bOZhYjBhzwqfJ_Xd`
* **Google Drive 백업 전용 폴더 ID**: `1W0jr7VODpb3NTLzdU0nxBO59A7_J7PUq` (`sandbox` 폴더)
* **Permanent Deployment ID**: `AKfycbyjwICUGj0U3OK_jFHjs1DxgVDFJIrNVlslDlSXAr7vw_vQ8FfTwI7EuTPzt2HU90DC`
* **웹 앱 실행 URL**: `https://script.google.com/macros/s/AKfycbyjwICUGj0U3OK_jFHjs1DxgVDFJIrNVlslDlSXAr7vw_vQ8FfTwI7EuTPzt2HU90DC/exec`
* **최신 배포 버전**: `v1.5.5-CMD-START-NOEXIT`

### 1.2 기술 스택
* **Backend**: Google Apps Script (JavaScript ES6+ / V8 Runtime)
* **Frontend**: HTML5, Vanilla CSS, Tailwind CSS CDN, FontAwesome 6
* **DevOps**: `@google/clasp`, Git / GitHub (`moozuknet/WSBManager`)

---

## 2. 핵심 구현 기능 및 기술 명세

### 2.1 이중 엔진 XML 파서 (Dual-Engine XML Parser)
- 기존 `.wsb` 파일 또는 XML 텍스트 업로드 시 `DOMParser`를 1차 시도하고, 인코딩 오류나 `&` 미이그젝트 이스케이프 구문이 발견될 경우 `Regex Extractor` 파서로 자동 전환되어 100% 신뢰할 수 있는 구문 분석을 보장합니다.

### 2.2 GitHub 저장소 연동 커스텀 스크립트 (`scripts/*.ps1`)
- GitHub repository 내 `scripts/` 폴더의 스크립트를 raw URL(`https://raw.githubusercontent.com/moozuknet/WSBManager/main/scripts/install-dev-tools.ps1`)로 실시간 호출합니다.
- **LogonCommand 실행 패턴**:
  ```powershell
  cmd.exe /c start "Dev Auto Setup" powershell.exe -NoExit -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol = 3072; iex ((New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/moozuknet/WSBManager/main/scripts/install-dev-tools.ps1'))"
  ```
- 부팅 후 독립된 PowerShell 창이 열려 실시간 로그를 표출하며, `-NoExit`를 통해 설치 후 버전 검증(`git`, `python`, `pip`, `node`, `npm`, `code`)을 유지합니다.

### 2.3 모달 내부 클립보드 복사 피드백 (In-Modal Copy Feedback)
- XML 미리보기 팝업 모달창 내부의 복사 버튼 클릭 시 버튼 텍스트가 `✓ 복사 완료!`로 변경되고, 우측에 `✓ 복사되었습니다!` 네온 뱃지가 생성되어 상단 토스트 알림의 가림 현상을 완전히 해소하였습니다.

### 2.4 ESC 키 & 백드롭 모달 바인딩
- 전역 `ESC` 키 핫키 이벤트 및 어두운 배경 영역 클릭 이벤트를 바인딩하여 모든 팝업 모달창을 빠르게 닫을 수 있습니다.

### 2.5 스마트 클라우드 병합 (Smart Cloud Sync)
- 웹 앱 최초 로딩 또는 새로고침 시 클라우드 프리셋 데이터를 로컬 스토리지에 `Object.assign()`으로 안전하게 머지하여 기존 저장된 프리셋이 유실되지 않습니다.

---

## 3. 디렉토리 구조

```text
WSBManager/
├── .clasp.json                   # Clasp CLI 설정 파일 (scriptId 및 rootDir 지정)
├── package.json                  # 자동 배포 스크립트 모음
├── README.md                     # 프로젝트 설명 및 개발 가이드
├── WSBManager_GAS_Development_Guide.md  # 구글 Apps Script 개발 가이드 문서
├── docs/
│   └── images/
│       └── wsb_manager_main.png  # 메인 UI 스크린샷 이미지
├── scripts/
│   └── install-dev-tools.ps1     # GitHub Raw 원격 다운로드용 커스텀 설치 스크립트 모듈
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

## 4. 버전 이력 (Release History)

| 버전 배지 | 주요 변경 사항 | 배포 ID |
| :--- | :--- | :--- |
| `v1.5.5-CMD-START-NOEXIT` | `cmd.exe start -NoExit` 실행 패턴 적용 및 스크립트 버전 검증 보강 | `@91` |
| `v1.5.0-FAST-SCRIPT` | `Download-SafeFile` 고속 스트림 다운로더 및 세션 PATH 동기화 적용 | `@89` |
| `v1.4.5-IN-MODAL-COPY-FEEDBACK` | XML 미리보기 모달 내부 복사 버튼 상태 변경 및 인라인 뱃지 피드백 | `@87` |
| `v1.4.0-COPY-TOAST-ENHANCED` | 클립보드 복사 Fallback (`document.execCommand`) 이중화 | `@85` |
| `v1.3.5-CLEANED-SCRIPTS` | GitHub 커스텀 스크립트 및 식탁보 중심 스크립트 템플릿 정돈 | `@83` |
| `v1.3.0-GITHUB-SCRIPTS` | GitHub `scripts/install-dev-tools.ps1` 연동 및 원클릭 템플릿 추가 | `@81` |
| `v1.2.5-ESC-KEY-SUPPORT` | 전역 ESC 키 및 모달 백드롭 클릭 창 닫기 추가 | `@79` |
| `v1.2.0-WSB-FILE-DRAGDROP` | `.wsb` 파일 선택 / 창 전체 드래그 앤 드롭 파서 보강 | `@77` |
| `v1.1.0-CLOUD-SYNC-FIX` | 로컬 스토리지 & GAS 클라우드 스마트 프리셋 머지 로직 적용 | `@75` |
| `v1.0.0-INITIAL` | 최초 프로덕션 배포 | `@70` |

---

## 5. 원클릭 배포 명령어

```bash
# GAS 푸시, 버저닝 및 고정 영구 배포(Permanent ID) 원클릭 대규모 업데이트
npm run deploy
```
