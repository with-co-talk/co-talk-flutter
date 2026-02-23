# Co-Talk CI/CD 설정 가이드

## 개요

Co-Talk 프로젝트는 GitHub Actions를 사용하여 3개 플랫폼(Android, iOS, Windows)에 자동으로 빌드하고 배포합니다.

### 배포 플랫폼
- **Android**: Google Play Store (내부 테스트/알파/베타/프로덕션)
- **iOS**: TestFlight (App Store 사전 배포)
- **Windows**: GitHub Release (MSIX 설치 프로그램)

### 워크플로우 파일
프로젝트는 4개의 GitHub Actions 워크플로우로 구성됩니다:

| 파일 | 설명 | 트리거 |
|------|------|--------|
| `.github/workflows/test.yml` | 재사용 가능한 테스트 워크플로우 | 다른 워크플로우에서 호출 |
| `.github/workflows/build-android.yml` | Android 빌드 + Google Play 업로드 | main 브랜치 push, workflow_dispatch |
| `.github/workflows/build-ios.yml` | iOS 빌드 + TestFlight 업로드 | main 브랜치 push, workflow_dispatch |
| `.github/workflows/build-windows-msix.yml` | Windows MSIX 빌드 + GitHub Release | main 브랜치 push, workflow_dispatch |

---

## 워크플로우 구조

### 실행 흐름

```
main 브랜치 Push
        ↓
┌─────────────────────────────────┐
│  test.yml (재사용 가능)          │
│  - Flutter 분석                 │
│  - 단위 테스트 실행             │
└─────────────────────────────────┘
        ↓
    ┌───┴───────────┬──────────────┬──────────────┐
    ↓               ↓              ↓              ↓
build-android   build-ios    build-windows   (병렬 실행)
    ↓               ↓              ↓
  Google Play  TestFlight   GitHub Release
```

### 각 플랫폼 워크플로우 단계

#### Android 워크플로우 (build-android.yml)
1. **테스트**: test.yml 호출
2. **Java 17 설정**
3. **Flutter 의존성 설치**
4. **Android 서명 키 설정** (ANDROID_KEYSTORE_BASE64)
5. **Firebase 설정** (google-services.json)
6. **AAB 또는 APK 빌드**
7. **빌드 결과물 Artifact 저장** (30일)
8. **Google Play에 업로드** (Fastlane 사용)

#### iOS 워크플로우 (build-ios.yml)
1. **테스트**: test.yml 호출
2. **Ruby 3.3 설정**
3. **Flutter 의존성 설치**
4. **Apple 인증서 및 프로비저닝 프로필 설정**
5. **App Store Connect API Key 설정**
6. **Firebase 설정** (GoogleService-Info.plist)
7. **CocoaPods 캐시 활용**
8. **IPA 빌드**
9. **빌드 결과물 Artifact 저장** (30일)
10. **TestFlight에 업로드** (Fastlane 사용)

#### Windows 워크플로우 (build-windows-msix.yml)
1. **테스트**: test.yml 호출
2. **Flutter 의존성 설치**
3. **MSIX 생성** (자체 서명 또는 공인 인증서)
4. **빌드 결과물 Artifact 저장** (30일)
5. **GitHub Release 생성** (main 브랜치 push 시만)

---

## GitHub Secrets 설정

GitHub Actions에서 민감한 정보를 안전하게 관리하기 위해 Secrets를 사용합니다.

### Secrets 등록 방법

1. GitHub 리포지토리 → **Settings** → **Secrets and variables** → **Actions** 이동
2. **"New repository secret"** 클릭
3. **Name** 필드에 Secret 이름 입력
4. **Value** 필드에 값 입력
5. **"Add secret"** 클릭

### 필수 Secrets (Android)

| Secret 이름 | 설명 | 생성 방법 |
|------------|------|----------|
| `ANDROID_KEYSTORE_BASE64` | 릴리즈 서명용 .jks 키스토어 (base64 인코딩) | 아래의 "Android 설정" 섹션 참고 |
| `ANDROID_KEY_PASSWORD` | 키스토어 비밀번호 | 키스토어 생성 시 설정한 비밀번호 |
| `GOOGLE_SERVICES_JSON` | Firebase Android 설정 파일 | Firebase Console → 프로젝트 설정 → Android 앱 → google-services.json 다운로드 후 파일 전체 내용 복사 |
| `PLAY_STORE_KEY_JSON` | Google Play Console 서비스 계정 API 키 | Google Cloud Console → 서비스 계정 생성 → JSON 키 다운로드 후 전체 내용 복사 |

### 필수 Secrets (iOS)

| Secret 이름 | 설명 | 생성 방법 |
|------------|------|----------|
| `IOS_CERTIFICATE_BASE64` | Apple Distribution 인증서 .p12 (base64 인코딩) | 아래의 "iOS 설정" 섹션 참고 |
| `IOS_CERTIFICATE_PASSWORD` | .p12 내보내기 시 설정한 비밀번호 | 인증서 내보내기 시 입력한 비밀번호 |
| `IOS_PROVISION_PROFILE_BASE64` | App Store 배포용 프로비저닝 프로필 (base64 인코딩) | Apple Developer → Profiles → App Store 프로필 다운로드 후 base64 인코딩 |
| `APP_STORE_CONNECT_API_KEY_BASE64` | App Store Connect API 키 .p8 (base64 인코딩) | App Store Connect → 사용자 및 액세스 → 키 → .p8 파일 다운로드 후 base64 인코딩 |
| `APP_STORE_CONNECT_API_KEY_KEY_ID` | API 키 ID | App Store Connect 키 생성 시 표시되는 Key ID 복사 |
| `APP_STORE_CONNECT_API_KEY_ISSUER_ID` | API 키 Issuer ID | App Store Connect 키 페이지 상단의 Issuer ID 복사 |
| `GOOGLE_SERVICE_INFO_PLIST_BASE64` | Firebase iOS 설정 파일 (base64 인코딩) | Firebase Console → 프로젝트 설정 → iOS 앱 → GoogleService-Info.plist 다운로드 후 base64 인코딩 |

### 선택 Secrets (Windows)

| Secret 이름 | 설명 | 생성 방법 |
|------------|------|----------|
| `WINDOWS_CERTIFICATE_BASE64` | MSIX 서명용 .pfx 인증서 (base64 인코딩) | 공인 인증서 사용 시에만 필요. 자체 서명 인증서 사용 시 불필요 |
| `WINDOWS_CERTIFICATE_PASSWORD` | .pfx 인증서 비밀번호 | 인증서 생성 시 설정한 비밀번호 |

---

## 각 플랫폼별 상세 설정

### Android 설정

#### 1단계: 키스토어 생성 (최초 1회만)

앱에 서명하기 위한 .jks 키스토어 파일을 생성합니다.

```bash
# 키스토어 디렉토리 생성
mkdir -p android/keystore

# 키스토어 생성
keytool -genkey -v -keystore android/keystore/co-talk-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias co-talk \
  -storepass YOUR_PASSWORD \
  -keypass YOUR_PASSWORD
```

**주의사항:**
- `YOUR_PASSWORD`: 강력한 비밀번호로 설정하고 안전하게 보관
- `validity 10000`: 약 27년간 유효 (프로덕션 앱에 적합)
- 키스토어 파일을 **절대 공개 저장소에 커밋하지 마세요**

#### 2단계: 키스토어를 Base64로 인코딩

```bash
# macOS/Linux
base64 -i android/keystore/co-talk-release.jks | pbcopy
# 또는
base64 android/keystore/co-talk-release.jks

# Windows (PowerShell)
[Convert]::ToBase64String([System.IO.File]::ReadAllBytes("android/keystore/co-talk-release.jks")) | Set-Clipboard
```

클립보드에 복사된 내용을 GitHub Secrets에 **ANDROID_KEYSTORE_BASE64**로 저장합니다.

#### 3단계: Firebase 설정

1. [Firebase Console](https://console.firebase.google.com) 접속
2. 프로젝트 선택 → **프로젝트 설정**
3. **Android 앱** 탭에서 앱 선택
4. `google-services.json` 파일 다운로드
5. 파일 내용 전체를 복사하여 GitHub Secrets에 **GOOGLE_SERVICES_JSON**으로 저장

#### 4단계: Google Play Console 서비스 계정 설정

##### 4-1. Google Cloud Console에서 서비스 계정 생성

1. [Google Cloud Console](https://console.cloud.google.com) 접속
2. 프로젝트 선택 (Android 앱의 프로젝트)
3. **APIs & Services** → **Credentials** 이동
4. **Create Credentials** → **Service Account**
5. 서비스 계정 이름 입력 (예: `github-actions-android`)
6. **Create and Continue** 클릭
7. **Grant this service account access to project**에서:
   - **Role**: `Editor` 선택 (또는 `Play Developer` 역할)
8. **Continue** → **Done** 클릭

##### 4-2. 서비스 계정 키 생성

1. 생성한 서비스 계정 클릭
2. **Keys** 탭 → **Add Key** → **Create new key**
3. **Key type**: `JSON` 선택
4. **Create** 버튼 클릭 (자동으로 JSON 파일 다운로드)
5. JSON 파일 내용 전체를 복사하여 GitHub Secrets에 **PLAY_STORE_KEY_JSON**으로 저장

##### 4-3. Google Play Console에서 API 액세스 권한 부여

1. [Google Play Console](https://play.google.com/console) 접속
2. **Settings** → **API access** 이동
3. **Service accounts** 섹션에서 **Grant access** 클릭
4. 위에서 생성한 서비스 계정 선택
5. **Permissions** 섹션에서:
   - **App releases**: `Release manager` (프로덕션 제외)
   - **Analytics**: `View` (옵션)
6. **Grant access** 클릭

---

### iOS 설정

#### 사전 요구사항
- Apple Developer Program 멤버십 필수
- Xcode 설치 및 Apple ID 로그인 필수

#### 1단계: Apple Distribution 인증서 생성

##### 1-1. Certificate Signing Request (CSR) 생성

```bash
# Mac에서 Keychain Access 열기
open /Applications/Utilities/Keychain\ Access.app
```

1. Keychain Access → **Keychain Access** → **Certificate Assistant** → **Request a Certificate from a Certificate Authority**
2. **User Email Address**: Apple Developer 계정 이메일
3. **Common Name**: 이름 (예: `Co-Talk Distribution`)
4. **Request is**: `Saved to disk` 선택
5. CSR 파일을 저장

##### 1-2. Apple Developer에서 인증서 발급

1. [Apple Developer Certificates](https://developer.apple.com/account/resources/certificates/list) 이동
2. **(+)** 버튼 클릭
3. **Apple Distribution** 선택 → **Continue**
4. 위에서 생성한 CSR 파일 업로드
5. **Download** 클릭하여 인증서 다운로드 (.cer 파일)
6. 더블클릭하여 Keychain에 설치

##### 1-3. 인증서와 개인키를 .p12 파일로 내보내기

1. Keychain Access 열기
2. **Certificates** 탭에서 "Apple Distribution" 인증서 찾기
3. 인증서 + 개인키(**▼** 화살표 확장) 선택 (Ctrl+클릭)
4. **Export 2 items...** 클릭
5. 파일명: `Certificates` (확장자 `.p12`)
6. 비밀번호 설정하고 저장

##### 1-4. .p12를 Base64로 인코딩

```bash
# macOS/Linux
base64 -i Certificates.p12 | pbcopy

# Windows (PowerShell)
[Convert]::ToBase64String([System.IO.File]::ReadAllBytes("Certificates.p12")) | Set-Clipboard
```

GitHub Secrets에 **IOS_CERTIFICATE_BASE64**로 저장하고, **IOS_CERTIFICATE_PASSWORD**에 .p12 내보내기 시 설정한 비밀번호 저장

#### 2단계: App Store 프로비저닝 프로필 생성

1. [Apple Developer Profiles](https://developer.apple.com/account/resources/profiles/list) 이동
2. **(+)** 버튼 클릭
3. **App Store Connect** 선택 → **Continue**
4. **App ID**: `com.cotalk.coTalkFlutter` 선택
5. **Certificates**: 위에서 생성한 Apple Distribution 인증서 선택
6. **Provisioning Profile Name**: 원하는 이름 입력 (예: `CoTalk AppStore`)
7. **Generate** 클릭
8. 프로필 다운로드 (.mobileprovision 파일)

#### 2단계: 프로비저닝 프로필을 Base64로 인코딩

```bash
# macOS/Linux
base64 -i CoTalk\ AppStore.mobileprovision | pbcopy

# Windows (PowerShell)
[Convert]::ToBase64String([System.IO.File]::ReadAllBytes("CoTalk AppStore.mobileprovision")) | Set-Clipboard
```

GitHub Secrets에 **IOS_PROVISION_PROFILE_BASE64**로 저장

#### 3단계: App Store Connect API 키 생성

##### 3-1. API 키 생성

1. [App Store Connect](https://appstoreconnect.apple.com) 접속
2. **Users and Access** → **Keys** → **App Store Connect API**
3. **(+)** 버튼 클릭
4. **Name**: API 키 이름 입력 (예: `GitHub Actions`)
5. **Role**: `App Manager` 선택
6. **Generate** 클릭
7. **Key ID** 메모 (나중에 필요)
8. **Issuer ID** 메모 (페이지 상단)
9. **.p8 파일** 다운로드 (최초 1회만 가능!)

##### 3-2. .p8를 Base64로 인코딩

```bash
# macOS/Linux
base64 -i AuthKey_XXXXXXXX.p8 | pbcopy

# Windows (PowerShell)
[Convert]::ToBase64String([System.IO.File]::ReadAllBytes("AuthKey_XXXXXXXX.p8")) | Set-Clipboard
```

GitHub Secrets에 다음을 저장:
- **APP_STORE_CONNECT_API_KEY_BASE64**: .p8 파일 base64 인코딩
- **APP_STORE_CONNECT_API_KEY_KEY_ID**: Key ID
- **APP_STORE_CONNECT_API_KEY_ISSUER_ID**: Issuer ID

#### 4단계: Firebase iOS 설정

1. [Firebase Console](https://console.firebase.google.com) 접속
2. 프로젝트 선택 → **프로젝트 설정**
3. **iOS 앱** 탭에서 앱 선택
4. `GoogleService-Info.plist` 파일 다운로드

```bash
# macOS/Linux
base64 -i GoogleService-Info.plist | pbcopy

# Windows (PowerShell)
[Convert]::ToBase64String([System.IO.File]::ReadAllBytes("GoogleService-Info.plist")) | Set-Clipboard
```

GitHub Secrets에 **GOOGLE_SERVICE_INFO_PLIST_BASE64**로 저장

---

### Windows 설정

Windows MSIX 빌드는 기본적으로 **자체 서명 인증서**를 사용하므로 추가 설정이 없습니다.

#### 선택: 공인 인증서로 서명하기

공인 인증서로 서명하려면 다음 단계를 따르세요:

##### 1단계: 공인 인증서 획득

Windows 공인 인증서 발급 업체에서 .pfx 형식의 인증서를 획득합니다.

##### 2단계: 인증서를 Base64로 인코딩

```powershell
# Windows PowerShell
[Convert]::ToBase64String([System.IO.File]::ReadAllBytes("mycert.pfx")) | Set-Clipboard
```

GitHub Secrets에 저장:
- **WINDOWS_CERTIFICATE_BASE64**: .pfx 파일 base64 인코딩
- **WINDOWS_CERTIFICATE_PASSWORD**: 인증서 비밀번호

##### 3단계: workflow_dispatch로 빌드 실행

GitHub Actions에서 **Build Windows MSIX** 워크플로우를 수동으로 실행할 때:
1. **environment**: `prod` 선택
2. **certificate_sign**: `true` 체크

---

## 빌드 번호 관리

### 자동 버전 관리

프로젝트는 `github.run_number`를 사용하여 자동 버전 관리를 구현합니다:

```yaml
flutter build appbundle --release --build-number=${{ github.run_number }}
```

| 요소 | 출처 | 수동 변경 |
|------|------|----------|
| **앱 버전** (예: 1.0.0) | `pubspec.yaml`의 `version` 필드 | 필요 시 수동 수정 |
| **빌드 번호** (versionCode/CFBundleVersion) | `github.run_number` | 자동 증가 |

### 버전 올리기

새 버전으로 릴리스하려면:

```bash
# pubspec.yaml 수정
version: 1.1.0+1

# 파일 변경 사항 커밋 및 푸시
git add pubspec.yaml
git commit -m "chore: 버전 업데이트 1.1.0"
git push origin main
```

워크플로우가 자동으로 실행되고, `github.run_number`가 빌드 번호가 됩니다.

---

## 수동 실행 (workflow_dispatch) 옵션

### GitHub에서 수동으로 워크플로우 실행하기

1. 리포지토리 → **Actions** 탭
2. 원하는 워크플로우 선택
3. **Run workflow** 드롭다운 클릭
4. 옵션 설정 후 **Run workflow** 클릭

### Android 옵션

| 옵션 | 설명 | 기본값 | 선택지 |
|------|------|--------|--------|
| `skip_upload` | Google Play 업로드 스킵 (빌드만) | `false` | true/false |
| `track` | 배포 트랙 | `internal` | internal, alpha, beta, production |
| `build_type` | 빌드 타입 | `appbundle` | appbundle, apk |
| `environment` | 빌드 환경 | `prod` | dev, prod |

**사용 예:**
- 내부 테스트용 AAB 빌드: `skip_upload=false`, `track=internal`, `build_type=appbundle`
- 개발 환경 APK 빌드만: `skip_upload=true`, `build_type=apk`, `environment=dev`

### iOS 옵션

| 옵션 | 설명 | 기본값 | 선택지 |
|------|------|--------|--------|
| `skip_upload` | TestFlight 업로드 스킵 (빌드만) | `false` | true/false |
| `environment` | 빌드 환경 | `prod` | dev, prod |

**사용 예:**
- TestFlight에 배포: `skip_upload=false`
- 로컬 테스트용 빌드: `skip_upload=true`, `environment=dev`

### Windows 옵션

| 옵션 | 설명 | 기본값 | 선택지 |
|------|------|--------|--------|
| `environment` | 빌드 환경 | `prod` | dev, prod |
| `certificate_sign` | 공인 인증서 서명 여부 | `false` | true/false |

**사용 예:**
- 자체 서명 MSIX 빌드: `certificate_sign=false`
- 공인 인증서 서명: `certificate_sign=true` (WINDOWS_CERTIFICATE_BASE64 필수)

---

## Artifact 다운로드

각 빌드의 결과물은 GitHub Actions의 **Artifacts** 섹션에 30일간 보관됩니다.

### Artifact 다운로드 방법

1. 리포지토리 → **Actions** 탭
2. 완료된 워크플로우 클릭
3. **Artifacts** 섹션에서 다운로드

### Artifact 이름 형식

| 플랫폼 | AAB | APK | IPA | MSIX |
|--------|-----|-----|-----|------|
| **이름** | `CoTalk-Android-AAB-v{버전}-{빌드번호}` | `CoTalk-Android-APK-v{버전}-{빌드번호}` | `CoTalk-iOS-v{버전}-{빌드번호}` | `CoTalk-Windows-v{버전}-{빌드번호}` |
| **예** | CoTalk-Android-AAB-v1.0.0-123 | CoTalk-Android-APK-v1.0.0-123 | CoTalk-iOS-v1.0.0-123 | CoTalk-Windows-v1.0.0-123 |

---

## Secrets 미설정 시 동작

일부 Secrets이 설정되지 않아도 빌드는 성공하지만, 일부 단계가 자동으로 스킵됩니다:

### Android

| Secret 미설정 | 결과 |
|-------------|------|
| `ANDROID_KEYSTORE_BASE64` | 서명되지 않은 APK/AAB 빌드 |
| `GOOGLE_SERVICES_JSON` | Firebase 기능 미포함 |
| `PLAY_STORE_KEY_JSON` | Google Play 업로드 스킵 |

### iOS

| Secret 미설정 | 결과 |
|-------------|------|
| `IOS_CERTIFICATE_BASE64` | 코드 서명 실패 (빌드 실패) |
| `IOS_PROVISION_PROFILE_BASE64` | 프로비저닝 프로필 없음 (빌드 실패) |
| `APP_STORE_CONNECT_API_KEY_BASE64` | TestFlight 업로드 스킵 |
| `GOOGLE_SERVICE_INFO_PLIST_BASE64` | Firebase 기능 미포함 |

### Windows

| Secret 미설정 | 결과 |
|-------------|------|
| `WINDOWS_CERTIFICATE_BASE64` | 자체 서명 인증서 사용 |
| `WINDOWS_CERTIFICATE_PASSWORD` | 필요 없음 (자체 서명 사용 시) |

---

## 트러블슈팅

### iOS 빌드 실패

#### 문제: "Code Signing Error"

**원인:**
- 인증서가 만료됨
- 프로비저닝 프로필이 인증서와 연결되지 않음
- Bundle ID 불일치

**해결책:**

```bash
# 1. 인증서 만료 확인
security find-certificate -c "Apple Distribution" ~/Library/Keychains/login.keychain-db

# 2. 인증서 갱신이 필요하면 Apple Developer에서 새 인증서 발급
# 3. 프로비저닝 프로필도 함께 갱신
# 4. GitHub Secrets 업데이트

# 인증서 내용 확인 (필수)
openssl x509 -in certificate.cer -text -noout
```

#### 문제: "Provisioning profile not found"

**원인:**
- `IOS_PROVISION_PROFILE_BASE64` Secret이 설정되지 않음
- 프로비저닝 프로필이 손상됨

**해결책:**
1. Apple Developer에서 새 프로비저닝 프로필 생성
2. 다시 base64 인코딩하여 Secret 업데이트

```bash
base64 -i profile.mobileprovision > encoded.txt
# encoded.txt 내용을 GitHub Secrets에 저장
```

### Android 빌드 실패

#### 문제: "Keystore was tampered with, or password was incorrect"

**원인:**
- `ANDROID_KEYSTORE_BASE64`가 올바르게 인코딩되지 않음
- `ANDROID_KEY_PASSWORD`가 잘못됨

**해결책:**

```bash
# 1. 키스토어 검증
keytool -list -v -keystore android/keystore/co-talk-release.jks \
  -storepass YOUR_PASSWORD \
  -keypass YOUR_PASSWORD

# 2. 올바르게 인코딩되었는지 확인
base64 -D <<< "YOUR_ENCODED_STRING" > decoded.jks
keytool -list -v -keystore decoded.jks
```

#### 문제: "google-services.json 파일을 찾을 수 없음"

**원인:**
- `GOOGLE_SERVICES_JSON` Secret이 설정되지 않음
- JSON 파일이 손상됨

**해결책:**
1. Firebase Console에서 새로 google-services.json 다운로드
2. 파일 내용을 정확히 복사하여 Secret 업데이트

### Windows MSIX 빌드 실패

#### 문제: "MSIX file not found"

**원인:**
- msix 플러그인이 설치되지 않음
- pubspec.yaml에서 msix_config이 없음

**해결책:**

```bash
# pubspec.yaml 확인
grep -A 10 "msix_config:" pubspec.yaml

# 필수 설정 확인
# - display_name
# - identity_name
# - logo_path (assets/icons/app_icon.png)
# - architecture (x64)
```

#### 문제: "Logo file not found"

**원인:**
- `assets/icons/app_icon.png` 파일이 없음

**해결책:**
```bash
# 로고 파일 확인
ls -la assets/icons/app_icon.png

# 파일이 없으면 생성 (최소 200x200 권장)
# PNG 파일을 assets/icons/app_icon.png로 저장
```

### Google Play 업로드 실패

#### 문제: "Invalid JSON key"

**원인:**
- `PLAY_STORE_KEY_JSON` Secret이 손상됨
- 서비스 계정이 Google Play API 액세스 권한이 없음

**해결책:**

```bash
# 1. 서비스 계정 JSON 검증
cat << 'EOF' | python3 -m json.tool
{
  "파일내용"
}
EOF

# 2. Google Cloud Console에서 API 확인
# - Google Play Android Developer API가 활성화되었는지 확인
# - 서비스 계정 역할이 'Editor' 이상인지 확인

# 3. Google Play Console에서 권한 확인
# - Settings → API access → 서비스 계정에 액세스 권한이 있는지 확인
```

#### 문제: "Package com.xxx not found"

**원인:**
- google-services.json의 package_name이 잘못됨
- Google Play에 앱이 등록되지 않음

**해결책:**

```bash
# 1. google-services.json 확인
grep "package_name" google-services.json

# 2. 필요하면 Google Play Console에서 앱 생성
# - Google Play Console → 새 앱 → 패키지명 입력
# 패키지명: com.cotalk.co_talk_flutter
```

### 테스트 실패

#### 문제: "flutter test 실패"

**원인:**
- 단위 테스트 코드 오류
- 의존성 버전 불일치

**해결책:**

```bash
# 1. 로컬에서 테스트 실행
flutter test

# 2. 테스트 커버리지 확인
flutter test --coverage

# 3. 실패한 테스트 파일 확인
# coverage/lcov.info에서 커버리지 상세 확인
```

---

## Fastlane 설정

iOS와 Android 배포는 **Fastlane**을 사용합니다.

### Fastlane 설치 (로컬 개발용)

```bash
# Ruby 3.3 이상 필요
ruby --version

# Bundler 설치
sudo gem install bundler

# 프로젝트 디렉토리에서 Fastlane 설치
bundle install
```

### Fastlane 레인 (Lane)

| Lane | 설명 |
|------|------|
| `fastlane upload_android track:internal` | Android 내부 테스트에 업로드 |
| `fastlane upload_android track:alpha` | Android 비공개 테스트에 업로드 |
| `fastlane upload_android track:beta` | Android 공개 테스트에 업로드 |
| `fastlane upload_android track:production` | Android 프로덕션에 업로드 |
| `fastlane upload_ios` | iOS TestFlight에 업로드 |

### Fastlane 로컬 실행 예

```bash
# iOS TestFlight 업로드
export APP_STORE_CONNECT_API_KEY_KEY_ID="XXXX"
export APP_STORE_CONNECT_API_KEY_ISSUER_ID="YYYY"
export APP_STORE_CONNECT_API_KEY_KEY_FILEPATH="./fastlane/keys/AuthKey.p8"
bundle exec fastlane upload_ios

# Android 내부 테스트 업로드
bundle exec fastlane upload_android track:internal
```

---

## 체크리스트: CI/CD 초기 설정

새 프로젝트에서 CI/CD를 처음 설정할 때 확인하세요:

### GitHub 리포지토리 설정
- [ ] 리포지토리 생성
- [ ] `main` 브랜치 생성
- [ ] `.github/workflows/` 디렉토리에 4개 워크플로우 파일 추가
  - [ ] `test.yml`
  - [ ] `build-android.yml`
  - [ ] `build-ios.yml`
  - [ ] `build-windows-msix.yml`

### GitHub Secrets 설정
- [ ] Android
  - [ ] `ANDROID_KEYSTORE_BASE64`
  - [ ] `ANDROID_KEY_PASSWORD`
  - [ ] `GOOGLE_SERVICES_JSON` (선택)
  - [ ] `PLAY_STORE_KEY_JSON` (선택)
- [ ] iOS
  - [ ] `IOS_CERTIFICATE_BASE64`
  - [ ] `IOS_CERTIFICATE_PASSWORD`
  - [ ] `IOS_PROVISION_PROFILE_BASE64`
  - [ ] `APP_STORE_CONNECT_API_KEY_BASE64`
  - [ ] `APP_STORE_CONNECT_API_KEY_KEY_ID`
  - [ ] `APP_STORE_CONNECT_API_KEY_ISSUER_ID`
  - [ ] `GOOGLE_SERVICE_INFO_PLIST_BASE64` (선택)
- [ ] Windows (선택)
  - [ ] `WINDOWS_CERTIFICATE_BASE64` (선택)
  - [ ] `WINDOWS_CERTIFICATE_PASSWORD` (선택)

### 플랫폼별 설정
- [ ] Android: 키스토어 생성 및 Google Play 설정
- [ ] iOS: Apple Distribution 인증서, 프로비저닝 프로필, API 키 생성
- [ ] Windows: MSIX 설정 확인

### 로컬 테스트
- [ ] `flutter test` 성공
- [ ] `flutter analyze` 경고 없음
- [ ] 모든 플랫폼에서 `flutter build` 성공

### 첫 배포
- [ ] main 브랜치에 커밋
- [ ] GitHub Actions 워크플로우 실행 확인
- [ ] 각 플랫폼의 배포 성공 확인

---

## 추가 리소스

### 공식 문서
- [Flutter Build Configuration](https://docs.flutter.dev/deployment)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Fastlane Documentation](https://docs.fastlane.tools)
- [Google Play Console API](https://developer.android.com/google-play/api/ref)
- [App Store Connect API](https://developer.apple.com/app-store-connect/api)

### 관련 파일
- 워크플로우: `.github/workflows/`
- Fastlane 설정: `fastlane/Fastfile`
- Flutter 설정: `pubspec.yaml`
- Android 설정: `android/app/build.gradle`, `android/build.gradle`
- iOS 설정: `ios/Runner.xcodeproj`, `ios/Podfile`
- Windows 설정: `windows/CMakeLists.txt`

---

## FAQ

### Q: Secrets 값을 확인할 수 있나요?

**A:** 아니요. GitHub Secrets는 보안상 이유로 조회 불가능합니다. 필요하면 새로운 값으로 Secret을 업데이트하세요.

### Q: 여러 앱 버전을 동시에 배포할 수 있나요?

**A:** 가능합니다. 각 버전마다 별도의 branch를 만들거나 tag를 사용하여 워크플로우를 실행하세요.

### Q: Firebase는 반드시 필요한가요?

**A:** 필수는 아닙니다. Firebase가 없어도 앱은 빌드되지만 FCM 푸시 알림을 사용할 수 없습니다.

### Q: 로컬에서 빌드와 배포를 테스트할 수 있나요?

**A:** 가능합니다. Fastlane을 로컬에서 실행할 수 있습니다:
```bash
bundle exec fastlane upload_ios
bundle exec fastlane upload_android track:internal
```

### Q: 빌드 번호를 수동으로 조정할 수 있나요?

**A:** 워크플로우에서 `--build-number` 옵션을 변경하거나 수동으로 Xcode/Android Studio에서 수정할 수 있습니다.

### Q: GitHub Release를 iOS나 Android에도 만들 수 있나요?

**A:** 가능합니다. 워크플로우에서 `action-gh-release` action을 추가하면 됩니다.

---

**마지막 업데이트:** 2026년 2월

**문의:** 문제가 발생하면 GitHub Issues에서 보고해주세요.
