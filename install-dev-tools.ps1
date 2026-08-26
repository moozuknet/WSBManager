# ===========================================================
# Windows Sandbox 개발 환경 자동 설치 스크립트
# 도구: Git, Python 3.12, Node.js LTS, VS Code
# ===========================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$w = New-Object Net.WebClient
$w.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")

$t = $env:TEMP

# 1. 시스템 탐색기 및 다크 모드 설정
Write-Host "[*] 시스템 탐색기 및 다크 모드 설정 중..." -ForegroundColor Cyan
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'HideFileExt' -Value 0 -Force
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name 'AppsUseLightTheme' -Value 0 -Force
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name 'SystemUsesLightTheme' -Value 0 -Force

# 2. Git for Windows 설치
Write-Host "`n[*] Git 다운로드 및 설치 중..." -ForegroundColor Cyan
$g = Join-Path $t "GitSetup.exe"
try {
    $w.DownloadFile('https://github.com/git-for-windows/git/releases/download/v2.44.0.windows.1/Git-2.44.0-64-bit.exe', $g)
    Start-Process $g -ArgumentList '/VERYSILENT /NORESTART /NOCANCEL /SP- /CLOSEAPPLICATIONS /RESTARTAPPLICATIONS' -Wait
    Remove-Item $g -Force -ErrorAction SilentlyContinue
    Write-Host "  [+] Git 설치 완료" -ForegroundColor Green
}
catch {
    Write-Host "  [-] Git 설치 실패: $($_.Exception.Message)" -ForegroundColor Red
}

# 3. Python 3.12 설치 (샌드박스 락 방지 옵션 적용)
Write-Host "`n[*] Python 3.12 다운로드 및 설치 중..." -ForegroundColor Cyan
$p = Join-Path $t "PythonSetup.exe"
try {
    $w.DownloadFile('https://www.python.org/ftp/python/3.12.4/python-3.12.4-amd64.exe', $p)
    # InstallAllUsers=0 및 SimpleInstall 옵션으로 UAC 블로킹 차단
    Start-Process -FilePath $p -ArgumentList '/quiet InstallAllUsers=0 PrependPath=1 Include_test=0 Include_pip=1 SimpleInstall=1' -Wait
    Remove-Item $p -Force -ErrorAction SilentlyContinue
    Write-Host "  [+] Python 설치 완료" -ForegroundColor Green
}
catch {
    Write-Host "  [-] Python 설치 실패: $($_.Exception.Message)" -ForegroundColor Red
}

# 4. Node.js LTS 설치
Write-Host "`n[*] Node.js LTS 다운로드 및 설치 중..." -ForegroundColor Cyan
$n = Join-Path $t "NodeSetup.msi"
try {
    $w.DownloadFile('https://nodejs.org/dist/v20.13.1/node-v20.13.1-x64.msi', $n)
    Start-Process msiexec.exe -ArgumentList "/i `"$n`" /qn /norestart" -Wait
    Remove-Item $n -Force -ErrorAction SilentlyContinue
    Write-Host "  [+] Node.js 설치 완료" -ForegroundColor Green
}
catch {
    Write-Host "  [-] Node.js 설치 실패: $($_.Exception.Message)" -ForegroundColor Red
}

# 5. VS Code 설치
Write-Host "`n[*] VS Code 다운로드 및 설치 중..." -ForegroundColor Cyan
$v = Join-Path $t "VSCodeSetup.exe"
try {
    $w.DownloadFile('https://update.code.visualstudio.com/latest/win32-x64-user/stable', $v)
    Start-Process $v -ArgumentList '/VERYSILENT /NORESTART /MERGETASKS=!runcode,addcontextmenufiles,addcontextmenufolders,associatewithfiles,addtopath' -Wait
    Remove-Item $v -Force -ErrorAction SilentlyContinue
    Write-Host "  [+] VS Code 설치 완료" -ForegroundColor Green
}
catch {
    Write-Host "  [-] VS Code 설치 실패: $($_.Exception.Message)" -ForegroundColor Red
}

# 6. 환경변수 즉시 동기화
$machinePath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::Machine)
$userPath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User)
$env:Path = "$machinePath;$userPath;$env:LOCALAPPDATA\Programs\Python\Python312;$env:LOCALAPPDATA\Programs\Python\Python312\Scripts"

Write-Host "`n=======================================================" -ForegroundColor Yellow
Write-Host " [설치 완료 검증]" -ForegroundColor Yellow
Write-Host "=======================================================" -ForegroundColor Yellow

try { & git --version } catch { Write-Host "Git: 확인 대기" -ForegroundColor DarkGray }
try { & python --version } catch { Write-Host "Python: 확인 대기" -ForegroundColor DarkGray }
try { & node --version } catch { Write-Host "Node: 확인 대기" -ForegroundColor DarkGray }
try { & npm --version } catch { Write-Host "NPM: 확인 대기" -ForegroundColor DarkGray }

Write-Host "`n[+] 모든 개발 도구 설치가 완료되었습니다." -ForegroundColor Green