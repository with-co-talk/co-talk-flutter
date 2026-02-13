# Co-Talk 설치 스크립트
# 이 스크립트는 관리자 권한으로 실행해야 합니다.

param(
    [switch]$Uninstall
)

$ErrorActionPreference = "Stop"
$AppName = "Co-Talk"
$Publisher = "CN=Co-Talk"

# 색상 출력 함수
function Write-ColorOutput($ForegroundColor, $Message) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    Write-Output $Message
    $host.UI.RawUI.ForegroundColor = $fc
}

function Write-Info($Message) { Write-ColorOutput "Cyan" "[INFO] $Message" }
function Write-Success($Message) { Write-ColorOutput "Green" "[SUCCESS] $Message" }
function Write-Warning($Message) { Write-ColorOutput "Yellow" "[WARNING] $Message" }
function Write-Error($Message) { Write-ColorOutput "Red" "[ERROR] $Message" }

# 관리자 권한 확인
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# 관리자 권한으로 재실행
if (-not (Test-Administrator)) {
    Write-Warning "관리자 권한이 필요합니다. 관리자 권한으로 재실행합니다..."
    $scriptPath = $MyInvocation.MyCommand.Path
    $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
    if ($Uninstall) { $arguments += " -Uninstall" }
    Start-Process PowerShell -Verb RunAs -ArgumentList $arguments
    exit
}

Write-Output ""
Write-Output "=========================================="
Write-Output "       $AppName 설치 프로그램"
Write-Output "=========================================="
Write-Output ""

# 스크립트 경로 기준으로 MSIX 파일 찾기
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$msixFiles = Get-ChildItem -Path $scriptDir -Filter "*.msix" -ErrorAction SilentlyContinue

if ($msixFiles.Count -eq 0) {
    Write-Error "MSIX 파일을 찾을 수 없습니다."
    Write-Error "이 스크립트와 같은 폴더에 MSIX 파일을 넣어주세요."
    Read-Host "아무 키나 눌러 종료하세요"
    exit 1
}

$msixPath = $msixFiles[0].FullName
Write-Info "MSIX 파일: $($msixFiles[0].Name)"

# 제거 모드
if ($Uninstall) {
    Write-Info "$AppName 제거 중..."
    
    # 앱 패키지 제거
    $packages = Get-AppxPackage | Where-Object { $_.Name -like "*cotalk*" -or $_.Name -like "*co-talk*" }
    foreach ($package in $packages) {
        Write-Info "앱 제거 중: $($package.Name)"
        Remove-AppxPackage -Package $package.PackageFullName
    }
    
    # 인증서 제거
    $certs = Get-ChildItem -Path "Cert:\LocalMachine\Root" | Where-Object { $_.Subject -eq $Publisher }
    foreach ($cert in $certs) {
        Write-Info "인증서 제거 중: $($cert.Thumbprint)"
        Remove-Item -Path "Cert:\LocalMachine\Root\$($cert.Thumbprint)" -Force
    }
    
    Write-Success "$AppName 제거가 완료되었습니다!"
    Read-Host "아무 키나 눌러 종료하세요"
    exit 0
}

# 설치 모드
try {
    # 1. MSIX에서 인증서 추출
    Write-Info "인증서 추출 중..."
    $signature = Get-AuthenticodeSignature -FilePath $msixPath
    
    if ($null -eq $signature.SignerCertificate) {
        Write-Error "MSIX 파일에서 서명을 찾을 수 없습니다."
        Read-Host "아무 키나 눌러 종료하세요"
        exit 1
    }
    
    $cert = $signature.SignerCertificate
    Write-Info "인증서 발급자: $($cert.Subject)"
    Write-Info "인증서 지문: $($cert.Thumbprint)"
    
    # 2. 인증서가 이미 설치되어 있는지 확인
    $existingCert = Get-ChildItem -Path "Cert:\LocalMachine\Root" | Where-Object { $_.Thumbprint -eq $cert.Thumbprint }
    
    if ($existingCert) {
        Write-Info "인증서가 이미 설치되어 있습니다."
    } else {
        # 3. 인증서를 신뢰할 수 있는 루트 인증 기관에 설치
        Write-Info "인증서를 신뢰할 수 있는 루트 인증 기관에 설치 중..."
        
        $certPath = Join-Path $env:TEMP "cotalk_cert.cer"
        Export-Certificate -Cert $cert -FilePath $certPath | Out-Null
        Import-Certificate -FilePath $certPath -CertStoreLocation "Cert:\LocalMachine\Root" | Out-Null
        Remove-Item $certPath -Force -ErrorAction SilentlyContinue
        
        Write-Success "인증서 설치 완료!"
    }
    
    # 4. 기존 앱이 있으면 제거
    Write-Info "기존 설치 확인 중..."
    $existingPackages = Get-AppxPackage | Where-Object { $_.Name -like "*cotalk*" -or $_.Name -like "*co-talk*" }
    
    if ($existingPackages) {
        Write-Info "기존 버전 제거 중..."
        foreach ($package in $existingPackages) {
            Remove-AppxPackage -Package $package.PackageFullName -ErrorAction SilentlyContinue
        }
    }
    
    # 5. MSIX 앱 설치
    Write-Info "$AppName 설치 중..."
    Add-AppxPackage -Path $msixPath
    
    Write-Output ""
    Write-Success "=========================================="
    Write-Success "    $AppName 설치가 완료되었습니다!"
    Write-Success "=========================================="
    Write-Output ""
    Write-Info "시작 메뉴에서 '$AppName'을 검색하여 실행하세요."
    Write-Output ""
    
} catch {
    Write-Output ""
    Write-Error "설치 중 오류가 발생했습니다:"
    Write-Error $_.Exception.Message
    Write-Output ""
}

Read-Host "아무 키나 눌러 종료하세요"
