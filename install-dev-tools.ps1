# ===========================================================
# Windows Sandbox 개발 환경 자동 설치 스크립트
# Repository: https://github.com/moozuknet/WSBManager
# Raw URL: https://raw.githubusercontent.com/moozuknet/WSBManager/main/scripts/install-dev-tools.ps1
# 대상 도구: Git, Python 3.12, Node.js LTS, VS Code
# ===========================================================

# 1. 콘솔 및 스트림 UTF-8 강제 활성화 (한글 깨짐 방지)
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
chcp 65001 | Out-Null

$ErrorActionPreference = "Continue"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Clear-Host
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host " Windows Sandbox 개발 환경 자동 프로비저닝 시작" -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan

# 2. 샌드박스 부팅 직후 네트워크 활성화 대기 (최대 30초)
Write-Host "`n[*] 네트워크 연결 상태 확인 중..." -ForegroundColor Cyan
$maxRetry = 30
$connected = $false

for ($i = 1; $i -le $maxRetry; $i++) {
    try {
        $testReq = [System.Net.HttpWebRequest]::Create("https://www.google.com")
        $testReq.Timeout = 2000
        $testRes = $testReq.GetResponse()
        $testRes.Close()
        $connected = $true
        Write-Host "  [+] 네트워크 연결 성공 ($i 초 소요)" -ForegroundColor Green
        break
    }
    catch {
        Write-Host "  -> 인터넷 연결 대기 중... ($i/$maxRetry 초)" -ForegroundColor DarkGray
        Start-Sleep -Seconds 1
    }
}

if (-not $connected) {
    Write-Host "  [-] 네트워크 연결 실패. 설치를 중단합니다." -ForegroundColor Red
    Read-Host "엔터를 누르면 종료됩니다..."
    exit
}

$t = $env:TEMP
$programsDir = "$env:LOCALAPPDATA\Programs"
if (-not (Test-Path $programsDir)) { New-Item -ItemType Directory -Path $programsDir -Force | Out-Null }

function Download-SafeFile($url, $targetPath, $label) {
    Write-Host "  -> [다운로드 중] $label..." -ForegroundColor Yellow
    $req = [System.Net.HttpWebRequest]::Create($url)
    $req.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
    $req.Timeout = 300000
    $res = $req.GetResponse()
    $stream = $res.GetResponseStream()
    $fs = New-Object System.IO.FileStream($targetPath, [System.IO.FileMode]::Create)
    $stream.CopyTo($fs)
    $fs.Close()
    $stream.Close()
    $res.Close()
    Write-Host "  -> [다운로드 완료] $label" -ForegroundColor DarkGreen
}

# 3. 탐색기 확장자 및 다크 모드 설정
Write-Host "`n[1/5] 탐색기 확장자 표시 및 다크 모드 설정 중..." -ForegroundColor Cyan
try {
    Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'HideFileExt' -Value 0 -Force
    Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name 'AppsUseLightTheme' -Value 0 -Force
    Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name 'SystemUsesLightTheme' -Value 0 -Force
    Write-Host "  [+] 탐색기 및 다크 모드 설정 완료" -ForegroundColor Green
}
catch {
    Write-Host "  [-] 설정 오류: $($_.Exception.Message)" -ForegroundColor Red
}

# 4. Git for Windows 설치
Write-Host "`n[2/5] Git for Windows 설치 중..." -ForegroundColor Cyan
$g = Join-Path $t "GitSetup.exe"
try {
    Download-SafeFile "https://github.com/git-for-windows/git/releases/download/v2.44.0.windows.1/Git-2.44.0-64-bit.exe" $g "Git Setup"
    Write-Host "  -> 백그라운드 무음 설치 실행 중..." -ForegroundColor Yellow
    Start-Process -FilePath $g -ArgumentList '/VERYSILENT /NORESTART /NOCANCEL /SP- /CLOSEAPPLICATIONS /RESTARTAPPLICATIONS' -Wait
    Remove-Item $g -Force -ErrorAction SilentlyContinue
    Write-Host "  [+] Git 설치 완료" -ForegroundColor Green
}
catch {
    Write-Host "  [-] Git 설치 실패: $($_.Exception.Message)" -ForegroundColor Red
}

# 5. Python 3.12 & PIP 배포
Write-Host "`n[3/5] Python 3.12 및 PIP 배포 중..." -ForegroundColor Cyan
$pyDir = Join-Path $programsDir "Python312"
$pyZip = Join-Path $t "python-embed.zip"
try {
    if (-not (Test-Path $pyDir)) { New-Item -ItemType Directory -Path $pyDir -Force | Out-Null }
    Download-SafeFile "https://www.python.org/ftp/python/3.12.4/python-3.12.4-embed-amd64.zip" $pyZip "Python 3.12 Standalone"
    
    Write-Host "  -> 패키지 압축 해제 중..." -ForegroundColor Yellow
    Expand-Archive -Path $pyZip -DestinationPath $pyDir -Force
    Remove-Item $pyZip -Force -ErrorAction SilentlyContinue

    $pthFile = Get-ChildItem -Path $pyDir -Filter "*._pth" | Select-Object -First 1
    if ($pthFile) {
        $pthContent = Get-Content $pthFile.FullName | Where-Object { $_ -ne 'import site' }
        $pthContent += 'import site'
        Set-Content -Path $pthFile.FullName -Value $pthContent -Force
    }

    $getPip = Join-Path $t "get-pip.py"
    Download-SafeFile "https://bootstrap.pypa.io/get-pip.py" $getPip "get-pip.py"
    Write-Host "  -> PIP 모듈 구성 실행 중..." -ForegroundColor Yellow
    Start-Process -FilePath "$pyDir\python.exe" -ArgumentList "`"$getPip`" --no-warn-script-location" -Wait
    Remove-Item $getPip -Force -ErrorAction SilentlyContinue
    Write-Host "  [+] Python 3.12 및 PIP 배포 완료" -ForegroundColor Green
}
catch {
    Write-Host "  [-] Python 배포 실패: $($_.Exception.Message)" -ForegroundColor Red
}

# 6. Node.js LTS & NPM 배포
Write-Host "`n[4/5] Node.js LTS 및 NPM 배포 중..." -ForegroundColor Cyan
$nodeDir = Join-Path $programsDir "nodejs"
$nodeZip = Join-Path $t "node-win.zip"
$nodeTemp = Join-Path $t "node-temp"
try {
    if (-not (Test-Path $nodeDir)) { New-Item -ItemType Directory -Path $nodeDir -Force | Out-Null }
    if (Test-Path $nodeTemp) { Remove-Item $nodeTemp -Recurse -Force -ErrorAction SilentlyContinue }
    
    Download-SafeFile "https://nodejs.org/dist/v20.13.1/node-v20.13.1-win-x64.zip" $nodeZip "Node.js LTS 패키지"
    
    Write-Host "  -> 패키지 압축 해제 중..." -ForegroundColor Yellow
    Expand-Archive -Path $nodeZip -DestinationPath $nodeTemp -Force
    
    $extractedFolder = Get-ChildItem -Path $nodeTemp -Directory | Select-Object -First 1
    Copy-Item -Path "$($extractedFolder.FullName)\*" -Destination $nodeDir -Recurse -Force
    
    Remove-Item $nodeZip -Force -ErrorAction SilentlyContinue
    Remove-Item $nodeTemp -Recurse -Force -ErrorAction SilentlyContinue
    
    Write-Host "  [+] Node.js LTS 및 NPM 배포 완료" -ForegroundColor Green
}
catch {
    Write-Host "  [-] Node.js 배포 실패: $($_.Exception.Message)" -ForegroundColor Red
}

# 7. Visual Studio Code 설치
Write-Host "`n[5/5] Visual Studio Code 설치 중..." -ForegroundColor Cyan
$v = Join-Path $t "VSCodeSetup.exe"
try {
    Download-SafeFile "https://update.code.visualstudio.com/latest/win32-x64-user/stable" $v "VS Code 인스톨러"
    Write-Host "  -> 백그라운드 무음 설치 실행 중..." -ForegroundColor Yellow
    Start-Process -FilePath $v -ArgumentList '/VERYSILENT /NORESTART /MERGETASKS=!runcode,addcontextmenufiles,addcontextmenufolders,associatewithfiles,addtopath' -Wait
    Remove-Item $v -Force -ErrorAction SilentlyContinue
    Write-Host "  [+] VS Code 설치 완료" -ForegroundColor Green
}
catch {
    Write-Host "  [-] VS Code 설치 실패: $($_.Exception.Message)" -ForegroundColor Red
}

# 8. 환경 변수(PATH) 영구 등록 및 현재 세션 즉시 바인딩
Write-Host "`n[*] 환경 변수(PATH) 영구 등록 및 동기화 중..." -ForegroundColor Cyan
$addPaths = @(
    "$programsDir\Python312",
    "$programsDir\Python312\Scripts",
    "$programsDir\nodejs",
    "C:\Program Files\Git\cmd",
    "$programsDir\Microsoft VS Code\bin"
)

$currentUserPath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User)
$pathList = if ($currentUserPath) { $currentUserPath -split ';' } else { @() }
foreach ($pathItem in $addPaths) {
    if ($pathList -notcontains $pathItem) { $pathList += $pathItem }
}
$newPath = ($pathList | Where-Object { $_ -ne '' }) -join ';'
[Environment]::SetEnvironmentVariable("Path", $newPath, [EnvironmentVariableTarget]::User)

$env:Path = "$newPath;" + [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::Machine) + ";$env:Path"

# 9. 최종 버전 검증 출력
Write-Host "`n========================================================" -ForegroundColor Yellow
Write-Host " [설치 상태 및 버전 검증]" -ForegroundColor Yellow
Write-Host "========================================================" -ForegroundColor Yellow

if (Get-Command git -ErrorAction SilentlyContinue) { git --version }    else { Write-Host "Git: 확인 불가" -ForegroundColor Red }
if (Get-Command python -ErrorAction SilentlyContinue) { python --version } else { Write-Host "Python: 확인 불가" -ForegroundColor Red }
if (Get-Command pip -ErrorAction SilentlyContinue) { pip --version }    else { Write-Host "PIP: 확인 불가" -ForegroundColor Red }
if (Get-Command node -ErrorAction SilentlyContinue) { node --version }   else { Write-Host "Node: 확인 불가" -ForegroundColor Red }
if (Get-Command npm -ErrorAction SilentlyContinue) { npm --version }    else { Write-Host "NPM: 확인 불가" -ForegroundColor Red }
if (Get-Command code -ErrorAction SilentlyContinue) { code --version }   else { Write-Host "VS Code: 확인 불가" -ForegroundColor Red }

Write-Host "`n[+] 모든 개발 환경 구성이 완료되었습니다." -ForegroundColor Green
