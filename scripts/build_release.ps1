# Co-Talk Windows 릴리즈 빌드 스크립트
# 이 스크립트는 프로젝트 루트에서 실행해야 합니다.

$ErrorActionPreference = "Stop"
$AppName = "Co-Talk"
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

Set-Location $ProjectRoot

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "       $AppName Windows 릴리즈 빌드" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# 1. Flutter 빌드
Write-Host "[1/4] Flutter Windows 빌드 중..." -ForegroundColor Yellow
flutter build windows --release --dart-define=ENVIRONMENT=prod

if ($LASTEXITCODE -ne 0) {
    Write-Host "Flutter 빌드 실패!" -ForegroundColor Red
    exit 1
}

Write-Host "[1/4] Flutter 빌드 완료!" -ForegroundColor Green

# 2. MSIX 패키지 생성
Write-Host ""
Write-Host "[2/4] MSIX 패키지 생성 중..." -ForegroundColor Yellow
flutter pub run msix:create

if ($LASTEXITCODE -ne 0) {
    Write-Host "MSIX 생성 실패!" -ForegroundColor Red
    exit 1
}

Write-Host "[2/4] MSIX 패키지 생성 완료!" -ForegroundColor Green

# 3. 배포 폴더 생성
Write-Host ""
Write-Host "[3/4] 배포 패키지 생성 중..." -ForegroundColor Yellow

$releaseDir = Join-Path $ProjectRoot "release"
$distDir = Join-Path $releaseDir "CoTalk-Windows"

# 기존 폴더 삭제
if (Test-Path $distDir) {
    Remove-Item $distDir -Recurse -Force
}

New-Item -ItemType Directory -Path $distDir -Force | Out-Null

# MSIX 파일 찾기 및 복사
$msixFiles = Get-ChildItem -Path (Join-Path $ProjectRoot "build\windows\x64\runner\Release") -Filter "*.msix" -Recurse -ErrorAction SilentlyContinue

if ($msixFiles.Count -eq 0) {
    # 다른 경로에서도 찾기
    $msixFiles = Get-ChildItem -Path $ProjectRoot -Filter "*.msix" -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.DirectoryName -notlike "*release*" }
}

if ($msixFiles.Count -eq 0) {
    Write-Host "MSIX 파일을 찾을 수 없습니다!" -ForegroundColor Red
    exit 1
}

$msixPath = $msixFiles[0].FullName
Copy-Item $msixPath -Destination $distDir

# 설치 스크립트 복사
$installerDir = Join-Path $ProjectRoot "installer"
Copy-Item (Join-Path $installerDir "install.ps1") -Destination $distDir
Copy-Item (Join-Path $installerDir "Co-Talk 설치.bat") -Destination $distDir
Copy-Item (Join-Path $installerDir "Co-Talk 제거.bat") -Destination $distDir

Write-Host "[3/4] 배포 패키지 생성 완료!" -ForegroundColor Green

# 4. 버전 정보 추출 및 README 생성
Write-Host ""
Write-Host "[4/4] README 생성 중..." -ForegroundColor Yellow

$pubspec = Get-Content (Join-Path $ProjectRoot "pubspec.yaml") -Raw
if ($pubspec -match 'version:\s*(\d+\.\d+\.\d+)') {
    $version = $Matches[1]
} else {
    $version = "1.0.0"
}

$readme = @"
# $AppName v$version - Windows 설치 가이드

## 설치 방법

1. **'Co-Talk 설치.bat'** 파일을 **더블클릭**하세요.
2. 관리자 권한 요청 창이 나타나면 **'예'**를 클릭하세요.
3. 설치가 완료되면 시작 메뉴에서 **'Co-Talk'**을 검색하여 실행하세요.

## 제거 방법

1. **'Co-Talk 제거.bat'** 파일을 **더블클릭**하세요.
2. 관리자 권한 요청 창이 나타나면 **'예'**를 클릭하세요.

## 포함된 파일

- **CoTalk.msix** - 앱 패키지
- **Co-Talk 설치.bat** - 설치 스크립트
- **Co-Talk 제거.bat** - 제거 스크립트
- **install.ps1** - PowerShell 설치 스크립트
- **README.txt** - 이 파일

## 시스템 요구사항

- Windows 10 버전 1809 (빌드 17763) 이상
- x64 아키텍처

## 문제 해결

설치 중 문제가 발생하면:
1. Windows를 최신 버전으로 업데이트하세요.
2. 바이러스 백신 프로그램을 일시적으로 비활성화해보세요.
3. 다른 사용자 계정으로 설치를 시도해보세요.

---
빌드 날짜: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
"@

$readme | Out-File -FilePath (Join-Path $distDir "README.txt") -Encoding UTF8

Write-Host "[4/4] README 생성 완료!" -ForegroundColor Green

# 완료 메시지
Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host "       빌드 및 패키징 완료!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""
Write-Host "배포 폴더: $distDir" -ForegroundColor Cyan
Write-Host ""
Write-Host "포함된 파일:" -ForegroundColor Yellow
Get-ChildItem $distDir | ForEach-Object { Write-Host "  - $($_.Name)" }
Write-Host ""

# ZIP 파일 생성 여부 확인
$createZip = Read-Host "ZIP 파일로 압축하시겠습니까? (Y/N)"
if ($createZip -eq "Y" -or $createZip -eq "y") {
    $zipPath = Join-Path $releaseDir "CoTalk-Windows-v$version.zip"
    if (Test-Path $zipPath) {
        Remove-Item $zipPath -Force
    }
    Compress-Archive -Path "$distDir\*" -DestinationPath $zipPath
    Write-Host ""
    Write-Host "ZIP 파일 생성 완료: $zipPath" -ForegroundColor Green
}

Write-Host ""
Read-Host "아무 키나 눌러 종료하세요"
