# ===========================================================
# Windows Sandbox 개발 환경 자동 설치 스크립트
# 대상 도구: Git, Python 3.12, Node.js LTS, VS Code
# ===========================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$t = $env:TEMP

function Download-FastFile($url, $targetPath) {
    $req = [System.Net.HttpWebRequest]::Create($url)
    $req.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
    $req.Timeout = 60000
    $res = $req.GetResponse()
    $stream = $res.GetResponseStream()
    $fs = New-Object System.IO.FileStream($targetPath, [System.IO.FileMode]::Create)
    $stream.CopyTo($fs)
    $fs.Close()
    $stream.Close()
    $res.Close()
}

# 1. 탐색기 및 다크 모드
Write-Host "[1/5] 탐색기 확장자 표시 및 다크 모드 적용 중..." -ForegroundColor Cyan
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'HideFileExt' -Value 0 -Force
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name 'AppsUseLightTheme' -Value 0 -Force
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name 'SystemUsesLightTheme' -Value 0 -Force

# 2. Git
Write-Host "`n[2/5] Git 다운로드 및 설치 중..." -ForegroundColor Cyan
$g = Join-Path $t "GitSetup.exe"
Download-FastFile "https://github.com/git-for-windows/git/releases/download/v2.44.0.windows.1/Git-2.44.0-64-bit.exe" $g
Start-Process -FilePath $g -ArgumentList '/VERYSILENT /NORESTART /NOCANCEL /SP- /CLOSEAPPLICATIONS /RESTARTAPPLICATIONS' -Wait
Remove-Item $g -Force -ErrorAction SilentlyContinue
Write-Host "  [+] Git 설치 완료" -ForegroundColor Green

# 3. Python 3.12
Write-Host "`n[3/5] Python 3.12 다운로드 및 설치 중..." -ForegroundColor Cyan
$p = Join-Path $t "PythonSetup.exe"
Download-FastFile "https://www.python.org/ftp/python/3.12.4/python-3.12.4-amd64.exe" $p
Start-Process -FilePath $p -ArgumentList '/quiet InstallAllUsers=0 PrependPath=1 Include_test=0 Include_pip=1 SimpleInstall=1' -Wait
Remove-Item $p -Force -ErrorAction SilentlyContinue
Write-Host "  [+] Python 설치 완료" -ForegroundColor Green

# 4. Node.js LTS
Write-Host "`n[4/5] Node.js LTS 다운로드 및 설치 중..." -ForegroundColor Cyan
$n = Join-Path $t "NodeSetup.msi"
Download-FastFile "https://nodejs.org/dist/v20.13.1/node-v20.13.1-x64.msi" $n
Start-Process msiexec.exe -ArgumentList "/i `"$n`" /qn /norestart" -Wait
Remove-Item $n -Force -ErrorAction SilentlyContinue
Write-Host "  [+] Node.js 설치 완료" -ForegroundColor Green

# 5. VS Code
Write-Host "`n[5/5] VS Code 다운로드 및 설치 중..." -ForegroundColor Cyan
$v = Join-Path $t "VSCodeSetup.exe"
Download-FastFile "https://update.code.visualstudio.com/latest/win32-x64-user/stable" $v
Start-Process -FilePath $v -ArgumentList '/VERYSILENT /NORESTART /MERGETASKS=!runcode,addcontextmenufiles,addcontextmenufolders,associatewithfiles,addtopath' -Wait
Remove-Item $v -Force -ErrorAction SilentlyContinue
Write-Host "  [+] VS Code 설치 완료" -ForegroundColor Green

# 6. 세션 PATH 즉시 동기화
$pyDir = "$env:LOCALAPPDATA\Programs\Python\Python312"
$pyScr = "$env:LOCALAPPDATA\Programs\Python\Python312\Scripts"
$nodeDir = "C:\Program Files\nodejs"
$gitDir = "C:\Program Files\Git\cmd"
$vsDir = "$env:LOCALAPPDATA\Programs\Microsoft VS Code\bin"
$env:Path = "$pyDir;$pyScr;$nodeDir;$gitDir;$vsDir;" + $env:Path

Write-Host "`n=======================================================" -ForegroundColor Yellow
Write-Host " [설치 결과 확인]" -ForegroundColor Yellow
Write-Host "=======================================================" -ForegroundColor Yellow
try { & git --version } catch { Write-Host "Git: 확인 대기" -ForegroundColor DarkGray }
try { & python --version } catch { Write-Host "Python: 확인 대기" -ForegroundColor DarkGray }
try { & node --version } catch { Write-Host "Node: 확인 대기" -ForegroundColor DarkGray }
try { & npm --version } catch { Write-Host "NPM: 확인 대기" -ForegroundColor DarkGray }
try { & code --version } catch { Write-Host "VS Code: 확인 대기" -ForegroundColor DarkGray }
Write-Host "`n[+] 전체 개발 환경 프로비저닝이 완료되었습니다." -ForegroundColor Green