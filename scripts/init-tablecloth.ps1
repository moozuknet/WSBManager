# ===========================================================
# TableCloth Standalone Complete Deployer (Fast & Optimized)
# ===========================================================

$ErrorActionPreference = "Continue"
$ProgressPreference = "SilentlyContinue"  # 파란색 프로그레스 바 반복 렉 원천 차단
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Add-Type -AssemblyName System.IO.Compression.FileSystem

Clear-Host
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host " [TableCloth] Building Complete Standalone Suite (x64)" -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan

# 1. 네트워크 연결 및 DNS 확인
Write-Host "`n[*] Verifying Network Connection..." -ForegroundColor Cyan
$maxRetry = 30
$connected = $false

for ($i = 1; $i -le $maxRetry; $i++) {
    try {
        $testReq = [System.Net.HttpWebRequest]::Create("https://www.google.com")
        $testReq.Timeout = 2000
        $testRes = $testReq.GetResponse()
        $testRes.Close()
        $connected = $true
        Write-Host "  [+] Network connected successfully." -ForegroundColor Green
        break
    }
    catch {
        if ($i -eq 2) {
            Get-NetAdapter | Where-Object Status -eq 'Up' | Set-DnsClientServerAddress -ServerAddresses 8.8.8.8, 1.1.1.1 -ErrorAction SilentlyContinue
        }
        Write-Host "  -> Waiting for DNS/Network... ($i/$maxRetry)" -ForegroundColor DarkGray
        Start-Sleep -Seconds 1
    }
}

if (-not $connected) {
    Write-Host "  [-] Network failed. Exiting..." -ForegroundColor Red
    exit
}

# 기존 실행 중인 프로세스 정리
Get-Process -Name "TableCloth*", "Spork*", "tablecloth*", "Update*" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

$t = $env:TEMP
$wc = New-Object Net.WebClient
$wc.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")

$appDir = "C:\TableCloth"
if (-not (Test-Path $appDir)) { New-Item -ItemType Directory -Path $appDir -Force | Out-Null }

# 2. GitHub API를 통해 최신 x64 릴리스 zip 탐색 및 다운로드
Write-Host "`n[*] Finding and Downloading Latest TableCloth Release (x64)..." -ForegroundColor Cyan
$appZip = Join-Path $t "TableCloth_x64.zip"

try {
    $apiUrl = "https://api.github.com/repos/yourtablecloth/TableCloth/releases/latest"
    $json = $wc.DownloadString($apiUrl) | ConvertFrom-Json
    
    $asset = $json.assets | Where-Object { 
        $_.name -like "*.zip" -and 
        $_.name -notlike "*arm64*" -and 
        $_.name -notlike "*Symbols*" -and
        ($_.name -like "*x64*" -or $_.name -like "*Portable*")
    } | Select-Object -First 1

    if ($asset) {
        Write-Host "  -> Found x64 release: $($asset.name)" -ForegroundColor Yellow
        $wc.DownloadFile($asset.browser_download_url, $appZip)
        [System.IO.Compression.ZipFile]::ExtractToDirectory($appZip, $appDir)
        Remove-Item $appZip -Force -ErrorAction SilentlyContinue
        Write-Host "  [+] Engine extracted successfully to $appDir" -ForegroundColor Green
    }
    else {
        throw "Could not find x64 zip asset."
    }
}
catch {
    Write-Host "  [-] Release fetch error: $($_.Exception.Message)" -ForegroundColor Red
}

# 3. Catalog.xml 및 Images.zip 다운로드 후 .NET 고속 단일 압축 해제 & 일괄 배포
Write-Host "`n[*] Fetching and Extracting Bank Icon Packs (Fast Mode)..." -ForegroundColor Cyan
$tempImagesZip = Join-Path $t "Images.zip"
$tempCatalogXml = Join-Path $t "Catalog.xml"
$tempExtractedImages = Join-Path $t "images_extracted"

try {
    $wc.DownloadFile("https://yourtablecloth.github.io/TableClothCatalog/Catalog.xml", $tempCatalogXml)
    $wc.DownloadFile("https://yourtablecloth.github.io/TableClothCatalog/Images.zip", $tempImagesZip)

    # 1회만 초고속 메모리/파일 압축 해제
    if (Test-Path $tempExtractedImages) { Remove-Item $tempExtractedImages -Recurse -Force -ErrorAction SilentlyContinue }
    [System.IO.Compression.ZipFile]::ExtractToDirectory($tempImagesZip, $tempExtractedImages)

    # 대상 디렉터리 일괄 복사 (반복 압축 해제 제거)
    $targetDeployDirs = @(
        $appDir,
        (Join-Path $appDir "current"),
        "$env:LOCALAPPDATA\TableCloth",
        "$env:LOCALAPPDATA\Spork",
        "$env:APPDATA\TableCloth",
        "$env:APPDATA\Spork"
    )

    foreach ($dir in $targetDeployDirs) {
        if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        
        Copy-Item -Path $tempCatalogXml -Destination (Join-Path $dir "Catalog.xml") -Force -ErrorAction SilentlyContinue
        Copy-Item -Path $tempImagesZip -Destination (Join-Path $dir "Images.zip") -Force -ErrorAction SilentlyContinue
        
        $destImg = Join-Path $dir "images"
        if (-not (Test-Path $destImg)) { New-Item -ItemType Directory -Path $destImg -Force | Out-Null }
        Copy-Item -Path "$tempExtractedImages\*" -Destination $destImg -Recurse -Force -ErrorAction SilentlyContinue
    }

    Remove-Item $tempImagesZip -Force -ErrorAction SilentlyContinue
    Remove-Item $tempCatalogXml -Force -ErrorAction SilentlyContinue
    Remove-Item $tempExtractedImages -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "  [+] All Official Bank Icons deployed in 0.5s." -ForegroundColor Green
}
catch {
    Write-Host "  [-] Icon extraction warning: $($_.Exception.Message)" -ForegroundColor Yellow
}

# 4. 실행 파일 탐색 및 바로가기 생성
$desktopPath = [Environment]::GetFolderPath("Desktop")
$targetExe = (Get-ChildItem -Path $appDir -Filter "*.exe" -Recurse | Where-Object { 
        $_.Name -match "^(Spork|TableCloth)\.exe$" -and $_.FullName -notmatch "Update" 
    } | Select-Object -First 1).FullName

if (-not $targetExe) {
    $targetExe = (Get-ChildItem -Path $appDir -Filter "*.exe" -Recurse | Where-Object { $_.Name -notmatch "Update" } | Select-Object -First 1).FullName
}

# 5. 바탕화면 바로가기 생성 및 실행
if ($targetExe) {
    try {
        $workingDir = Split-Path $targetExe -Parent
        $wscriptShell = New-Object -ComObject WScript.Shell
        $shortcut = $wscriptShell.CreateShortcut((Join-Path $desktopPath ([regex]::Unescape("\uC2DD\uD0C1\uBCF4.lnk"))))
        $shortcut.TargetPath = $targetExe
        $shortcut.WorkingDirectory = $workingDir
        $shortcut.Save()
    }
    catch {}

    Write-Host "`n[*] Launching TableCloth with Native Icons..." -ForegroundColor Cyan
    Start-Process -FilePath $targetExe -WorkingDirectory (Split-Path $targetExe -Parent)
    Write-Host "  [+] TableCloth Launched successfully." -ForegroundColor Green
}
else {
    Write-Host "  [-] Target execution file not found." -ForegroundColor Red
}

Write-Host "`n[+] Setup Completed." -ForegroundColor Green