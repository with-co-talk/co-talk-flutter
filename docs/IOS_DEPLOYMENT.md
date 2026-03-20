# iOS 배포 가이드

Co-Talk Flutter의 iOS 앱을 TestFlight와 App Store에 배포하는 전체 프로세스입니다.

## 목차
- [개요](#개요)
- [필수 사전 조건](#필수-사전-조건)
- [GitHub Secrets 설정](#github-secrets-설정)
- [로컬 배포 (Local Deployment)](#로컬-배포-local-deployment)
- [CI/CD 자동 배포](#cicd-자동-배포)
- [Fastlane Lanes 레퍼런스](#fastlane-lanes-레퍼런스)
- [트러블슈팅](#트러블슈팅)

---

## 개요

Co-Talk Flutter는 iOS 앱 배포를 위해 다음 도구들을 사용합니다:

| 도구 | 용도 | 환경 |
|------|------|------|
| GitHub Actions | CI/CD 파이프라인 | `.github/workflows/build-ios.yml` |
| Fastlane | 빌드, 코드 서명, TestFlight 업로드 | `fastlane/Fastfile` |
| App Store Connect API Key | 자동화된 배포 인증 | API 기반 (보안) |
| ExportOptions.plist | IPA 빌드 설정 | `ios/ExportOptions.plist` |

### 배포 흐름도

```
Main 브랜치에 Push
    ↓
GitHub Actions 워크플로우 시작 (build-ios.yml)
    ↓
테스트 & 정적 분석 (test.yml)
    ↓
iOS 빌드
  - 인증서/프로비저닝 프로필 설정
  - CocoaPods 설치
  - flutter build ipa --release
    ↓
Fastlane을 통한 TestFlight 업로드
    ↓
Artifact 저장 (30일)
```

---

## 필수 사전 조건

### 개발 머신에서의 로컬 배포

```bash
# 1. Xcode 설치 (App Store)
# 2. Apple ID로 로그인
open -a Xcode  # 서명 계정 설정

# 3. Fastlane 설치
cd co-talk-flutter
bundle install  # Gemfile에서 fastlane 설치

# 4. 환경 설정 복사
cp fastlane/.env.example fastlane/.env
# fastlane/.env 파일 수정 (아래 참고)

# 5. API 키 파일 배치
# App Store Connect에서 .p8 파일 다운로드
# → fastlane/keys/AuthKey_XXXX.p8로 저장
```

### Apple Developer Program 가입 필수

- [Apple Developer Program](https://developer.apple.com/programs/)에 가입 (연 $99)
- Team ID 확인: https://developer.apple.com/account → Membership
- App Store Connect 접근: https://appstoreconnect.apple.com

---

## GitHub Secrets 설정

GitHub Actions에서 자동 배포를 위해 다음 Secrets를 설정합니다:

### Secret 설정 경로

1. GitHub 저장소 → Settings → Secrets and variables → Actions
2. "New repository secret" 클릭
3. 아래 테이블의 Secret 추가

### 필수 Secrets

| Secret | 설명 | 획득 방법 |
|--------|------|----------|
| **BUILD_CERTIFICATE_BASE64** | App Store Distribution 인증서 (.p12) base64 인코딩 | Keychain Access에서 내보내기 → `base64 -i cert.p12 \| pbcopy` |
| **P12_PASSWORD** | Distribution 인증서 내보내기 시 설정한 비밀번호 | 인증서 내보낼 때 입력한 패스워드 |
| **BUILD_PROVISION_PROFILE_BASE64** | App Store 프로비저닝 프로필 (.mobileprovision) base64 | Apple Developer Portal → Certificates, Identifiers & Profiles → Profiles → App Store 프로필 다운로드 → `base64 -i profile.mobileprovision \| pbcopy` |
| **KEYCHAIN_PASSWORD** | CI 빌드용 임시 키체인 비밀번호 | 임의의 강력한 랜덤 문자열 (예: `$(openssl rand -base64 20)`) |
| **APP_STORE_CONNECT_API_KEY_BASE64** | App Store Connect API Key (.p8) base64 인코딩 | App Store Connect → Users and Access → Keys → 새 키 생성 → `base64 -i AuthKey_XXXX.p8 \| pbcopy` |
| **APP_STORE_CONNECT_API_KEY_KEY_ID** | API Key ID (예: `8N38RQ4QKG`) | App Store Connect → Keys 페이지에서 Key ID 확인 |
| **APP_STORE_CONNECT_API_KEY_ISSUER_ID** | App Store Connect Issuer ID (UUID) | App Store Connect → Keys 페이지 상단 "Issuer ID" 확인 |
| **GOOGLE_SERVICE_INFO_PLIST_BASE64** | Firebase iOS 설정 파일 (.plist) base64 | Firebase Console → iOS 앱 → `GoogleService-Info.plist` 다운로드 → `base64 -i GoogleService-Info.plist \| pbcopy` |

### Secret 생성 상세 가이드

#### 1. Distribution 인증서 (BUILD_CERTIFICATE_BASE64)

```bash
# 1. Keychain Access 열기
open -a Keychain\ Access

# 2. "My Certificates" 선택
# 3. "Apple Distribution: [Company Name] ([Team ID])" 우클릭
# 4. "Export [인증서]" 클릭
# 5. cert.p12로 저장
# 6. 내보내기 비밀번호 설정 (P12_PASSWORD로 사용할 값)

# 7. Base64 인코딩
base64 -i cert.p12 | pbcopy
# → 클립보드에 복사됨 → GitHub Secret에 붙여넣기
```

#### 2. 프로비저닝 프로필 (BUILD_PROVISION_PROFILE_BASE64)

```bash
# 1. Apple Developer Portal 접속
# https://developer.apple.com/account/resources/profiles

# 2. "App Store" 프로필 선택
# 3. "Download" 클릭 (profile.mobileprovision 다운로드)

# 4. Base64 인코딩
base64 -i profile.mobileprovision | pbcopy
# → GitHub Secret에 붙여넣기
```

#### 3. App Store Connect API Key (APP_STORE_CONNECT_API_KEY_BASE64)

```bash
# 1. App Store Connect 접속
# https://appstoreconnect.apple.com/access/api

# 2. "Keys" 탭에서 "+" 클릭
# 3. Name: "GitHub Actions CI" (임의의 이름)
# 4. Access: "Admin" 선택
# 5. "Generate" 클릭

# 6. AuthKey_XXXX.p8 파일 다운로드
# KEY_ID와 ISSUER_ID 메모

# 7. Base64 인코딩
base64 -i AuthKey_XXXX.p8 | pbcopy
# → GitHub Secret에 붙여넣기

# 8. KEY_ID와 ISSUER_ID를 별도 Secret으로 추가
```

#### 4. Firebase GoogleService-Info.plist (GOOGLE_SERVICE_INFO_PLIST_BASE64)

```bash
# 1. Firebase Console 접속
# https://console.firebase.google.com

# 2. 프로젝트 선택 → iOS 앱 설정
# 3. GoogleService-Info.plist 다운로드

# 4. Base64 인코딩
base64 -i GoogleService-Info.plist | pbcopy
# → GitHub Secret에 붙여넣기
```

---

## 로컬 배포 (Local Deployment)

개발 머신에서 직접 TestFlight에 배포합니다.

### 사전 준비

```bash
cd co-talk-flutter

# 1. 환경 설정 파일 생성
cp fastlane/.env.example fastlane/.env

# 2. fastlane/.env 수정 (아래 예시)
cat fastlane/.env
```

#### fastlane/.env 설정 예시

```bash
# Apple Developer 계정
APPLE_ID=your-email@example.com
TEAM_ID=YOUR_TEAM_ID         # https://developer.apple.com/account → Membership
ITC_TEAM_ID=YOUR_ITC_TEAM_ID # https://appstoreconnect.apple.com → Users and Access

# App Store Connect API Key
APP_STORE_CONNECT_API_KEY_KEY_ID=8N38RQ4QKG
APP_STORE_CONNECT_API_KEY_ISSUER_ID=12345678-1234-1234-1234-123456789abc
APP_STORE_CONNECT_API_KEY_KEY_FILEPATH=./fastlane/keys/AuthKey_8N38RQ4QKG.p8
```

### API 키 파일 배치

```bash
# 1. App Store Connect에서 .p8 파일 다운로드
# https://appstoreconnect.apple.com/access/api → "+" 생성 → Download

# 2. 파일 이동
mkdir -p fastlane/keys
mv ~/Downloads/AuthKey_XXXX.p8 fastlane/keys/
```

### 배포 방법

#### 방법 1: 전체 빌드 + 업로드 (권장)

```bash
cd co-talk-flutter/fastlane

# iOS 빌드 + TestFlight 업로드
bundle exec fastlane deploy_ios

# 또는 전체 플랫폼 (iOS + macOS)
bundle exec fastlane deploy_all
```

**실행 내용:**
- 빌드 번호 자동 증가
- `flutter build ipa --release` 실행
- Fastlane으로 TestFlight 업로드
- 소요 시간: 약 15-20분

#### 방법 2: 빌드만 (업로드 X)

```bash
cd co-talk-flutter

# Flutter로 IPA 빌드
flutter build ipa --release --dart-define=ENVIRONMENT=prod \
  --export-options-plist=ios/ExportOptions.plist
```

그 후 TestFlight 업로드:

```bash
cd fastlane
bundle exec fastlane deploy_ios_quick
```

#### 방법 3: 수동 단계별 실행

```bash
cd co-talk-flutter

# 1단계: IPA 빌드
flutter build ipa --release --dart-define=ENVIRONMENT=prod \
  --export-options-plist=ios/ExportOptions.plist

# 2단계: TestFlight 업로드
cd fastlane
bundle exec fastlane upload_ios
```

### 코드 서명 설정

로컬에서 IPA 빌드 시 Xcode의 자동 코드 서명 사용:

1. Xcode 열기:
   ```bash
   open ios/Runner.xcworkspace
   ```

2. Runner 프로젝트 선택
3. Signing & Capabilities 탭
4. Team 선택 (Apple ID 계정)
5. Bundle ID: `com.cotalk.coTalkFlutter`
6. Provisioning Profile: 자동 선택

### 환경 변수 설정

빌드 환경 지정 (dev/prod):

```bash
# Production 빌드 (기본값)
flutter build ipa --release --dart-define=ENVIRONMENT=prod

# Development 빌드
flutter build ipa --release --dart-define=ENVIRONMENT=dev
```

---

## CI/CD 자동 배포

GitHub Actions를 통한 자동 배포입니다.

### 워크플로우 파일

`.github/workflows/build-ios.yml` 참고

### 자동 배포 트리거

#### 1. Main 브랜치에 Push (자동)

```bash
git push origin main
```

**자동 실행:**
- `test.yml` 실행 (테스트 & 정적 분석)
- `build-ios.yml` 실행 (iOS 빌드 + TestFlight 업로드)
- 소요 시간: 약 40-50분

**조건:**
- Markdown 파일 제외 (`**.md`, `docs/**`)
- 모든 테스트 통과 필요

#### 2. Manual Dispatch (수동)

GitHub Actions 페이지에서 "Run workflow" 클릭:

```
Workflow: Build & Deploy iOS
  - skip_upload: (선택) TestFlight 업로드 스킵
  - environment: (선택) dev 또는 prod
```

**예시:**
```
skip_upload: false (기본값, 업로드함)
environment: prod (기본값)
```

### 워크플로우 단계

1. **저장소 체크아웃**
2. **Flutter 설정** (v3.32.2)
3. **의존성 설치**
4. **테스트 & 정적 분석** (test.yml 호출)
5. **API Key 설정**
   - `APP_STORE_CONNECT_API_KEY_BASE64` → `AuthKey.p8` 복원
6. **Firebase 설정**
   - `GOOGLE_SERVICE_INFO_PLIST_BASE64` → `GoogleService-Info.plist` 복원
7. **코드 서명**
   - 임시 키체인 생성
   - Distribution 인증서 설치
   - 프로비저닝 프로필 설치
8. **CocoaPods 설치**
   - 캐시 활용 (Podfile.lock 기준)
9. **IPA 빌드**
   - `flutter build ipa --release`
   - `ios/ExportOptions.plist` 사용
   - Build number = GitHub run number
10. **Artifact 저장**
    - 30일 보관
11. **TestFlight 업로드**
    - Fastlane `upload_ios` lane 실행
    - 조건: `HAS_API_KEY == true` && (자동 배포 또는 skip_upload != true)

### 워크플로우 환경 변수

| 환경 변수 | 설정 | 예시 |
|-----------|------|------|
| `FLUTTER_VERSION` | Flutter 버전 (고정) | `3.32.2` |
| `HAS_API_KEY` | API Key 사용 가능 여부 | `true` (Secret 설정 시) |
| `HAS_FIREBASE` | Firebase 설정 사용 가능 여부 | `true` (Secret 설정 시) |

### 키체인 자동 정리

CI 빌드 완료 후 임시 키체인 자동 삭제 (`always` 단계):
```bash
security delete-keychain build.keychain
```

---

## Fastlane Lanes 레퍼런스

### iOS 전용 Lanes

#### deploy_ios
```bash
bundle exec fastlane deploy_ios
```

**설명:** iOS 빌드 + TestFlight 업로드

**동작:**
- 빌드 번호 자동 증가
- `flutter build ipa --release` 실행
- TestFlight 업로드

**옵션:**
- `skip_bump=true` → 빌드 번호 유지
- `skip_build=true` → 이미 빌드된 IPA 사용

**예시:**
```bash
# 기본 (빌드 번호 증가)
bundle exec fastlane deploy_ios

# 빌드 스킵 (이미 빌드된 경우)
bundle exec fastlane deploy_ios skip_build:true
```

#### deploy_ios_quick (alias)
```bash
bundle exec fastlane deploy_ios_quick
```

**설명:** 빌드 스킵하고 업로드만 (빌드된 IPA가 존재할 때)

**동작:**
- 빌드 번호 자동 증가
- TestFlight 업로드만 수행

**소요 시간:** 약 5-10분

#### build_ios
```bash
bundle exec fastlane build_ios
```

**설명:** iOS 빌드만 (업로드 X)

**동작:**
- CocoaPods 설치
- `flutter build ipa --release` 실행

**소요 시간:** 약 10-15분

#### upload_ios
```bash
bundle exec fastlane upload_ios
```

**설명:** 빌드된 IPA를 TestFlight에 업로드

**전제 조건:**
- `build/ios/ipa/*.ipa` 파일 존재

**동작:**
- App Store Connect API Key로 인증
- 빌드 처리 완료 대기 스킵
- 자동 제출 스킵

#### bump_build
```bash
bundle exec fastlane bump_build
```

**설명:** iOS + macOS 빌드 번호 동시 증가

**옵션:**
- `build=123` → 명시적 빌드 번호 지정

**예시:**
```bash
# 자동 증가
bundle exec fastlane bump_build

# 명시적 지정
bundle exec fastlane bump_build build:100
```

### 통합 Lanes (iOS + macOS)

#### deploy_all
```bash
bundle exec fastlane deploy_all
```

**설명:** iOS + macOS 모두 빌드 + 업로드

**동작:**
- 빌드 번호 한 번만 증가
- iOS 빌드 + 업로드
- macOS 빌드 + 업로드

**소요 시간:** 약 30-40분

#### deploy_all_quick
```bash
bundle exec fastlane deploy_all_quick
```

**설명:** iOS + macOS 업로드만

**전제 조건:**
- iOS IPA와 macOS app이 이미 빌드됨

**소요 시간:** 약 10-15분

#### build_all
```bash
bundle exec fastlane build_all
```

**설명:** iOS + macOS 빌드만

**소요 시간:** 약 20-30분

#### deploy_all_platforms
```bash
bundle exec fastlane deploy_all_platforms
```

**설명:** iOS + macOS + Android 모두 배포 (전체 플랫폼)

### 유틸리티 Lanes

#### status
```bash
bundle exec fastlane status
```

**설명:** 현재 빌드 상태 확인

**출력:**
```
iOS 상태
빌드 번호: 123

macOS 상태
빌드 번호: 123

IPA 파일
/path/to/build/ios/ipa/CoTalk.ipa

macOS 앱
빌드됨
```

---

## 트러블슈팅

### "No IPA found" 오류

**증상:**
```
IPA 파일을 찾을 수 없습니다. 먼저 build_ios를 실행하세요.
```

**해결:**
```bash
# IPA 빌드 실행
cd co-talk-flutter
flutter build ipa --release --dart-define=ENVIRONMENT=prod \
  --export-options-plist=ios/ExportOptions.plist

# 그 후 업로드
cd fastlane
bundle exec fastlane upload_ios
```

### 코드 서명 오류

**증상:**
```
Code signing error: No matching provisioning profiles found
```

**해결:**

1. Keychain Access에서 인증서 확인:
   ```bash
   security find-certificate -c "Apple Distribution"
   ```

2. 프로비저닝 프로필 확인:
   ```bash
   ls ~/Library/MobileDevice/Provisioning\ Profiles/
   ```

3. GitHub Secrets 재설정:
   - `BUILD_CERTIFICATE_BASE64` 재생성
   - `BUILD_PROVISION_PROFILE_BASE64` 재생성
   - `P12_PASSWORD` 확인

4. 로컬 빌드 시 Xcode에서 자동 서명 활성화

### API Key 오류

**증상:**
```
Authentication failed: Invalid API Key
```

**해결:**

1. `.env` 파일 확인:
   ```bash
   cat fastlane/.env
   ```

2. 환경 변수 확인:
   - `APP_STORE_CONNECT_API_KEY_KEY_ID` 올바른지 확인
   - `APP_STORE_CONNECT_API_KEY_ISSUER_ID` 올바른지 확인
   - `APP_STORE_CONNECT_API_KEY_KEY_FILEPATH` 파일 존재 확인

3. API 키 파일 권한 확인:
   ```bash
   ls -la fastlane/keys/AuthKey_*.p8
   # 최소 400 권한 필요
   chmod 400 fastlane/keys/AuthKey_*.p8
   ```

4. App Store Connect에서 API Key 재생성:
   - https://appstoreconnect.apple.com/access/api
   - 기존 Key 삭제 → 새 Key 생성
   - `.p8` 파일 다시 다운로드

### ExportOptions.plist 관련 오류

**증상:**
```
Error: Unable to locate ExportOptions.plist
```

**해결:**

```bash
# 파일 위치 확인
ls -la ios/ExportOptions.plist

# 없으면 생성 (Xcode 또는 수동)
# Xcode: Product → Archive → Export → ExportOptions.plist 저장
```

**ExportOptions.plist 필수 설정:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>destination</key>
    <string>export</string>
    <key>method</key>
    <string>app-store</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
</dict>
</plist>
```

**중요:** `destination`은 `export`이어야 함 (Fastlane과 중복 업로드 방지)

### TestFlight 업로드 실패

**증상:**
```
Upload failed: Invalid IPA file
```

**원인 및 해결:**

1. **Bundle ID 불일치**
   ```
   pubspec.yaml의 package_name vs ios/Runner.pbxproj
   ```
   → 일치하는지 확인

2. **인증서 만료**
   ```bash
   security find-certificate -c "Apple Distribution" -p | openssl x509 -noout -dates
   ```
   → 만료 전 재생성

3. **빌드 번호 중복**
   ```
   같은 버전 + 빌드 번호 이미 업로드됨
   ```
   → 빌드 번호 증가: `fastlane bump_build`

4. **Firebase 설정 누락**
   ```
   ios/Runner/GoogleService-Info.plist 없음
   ```
   → Firebase Console에서 다운로드 → 추가

### GitHub Actions 빌드 실패

**증상:**
```
Error: Flutter iOS build failed
```

**디버깅:**

1. GitHub Actions 로그 확인:
   - 저장소 → Actions → 실패한 워크플로우 클릭
   - "Build iOS" 단계 로그 확인

2. 로컬에서 동일 명령 실행:
   ```bash
   flutter build ipa --release --dart-define=ENVIRONMENT=prod \
     --export-options-plist=ios/ExportOptions.plist
   ```

3. CocoaPods 캐시 문제:
   ```bash
   cd ios
   rm -rf Pods Podfile.lock
   pod install --repo-update
   ```

4. Flutter 캐시 정리:
   ```bash
   flutter clean
   flutter pub get
   ```

5. GitHub Actions에서 수동 다시 실행:
   - Actions 탭 → 실패한 워크플로우 → "Re-run failed jobs"

### 로컬 빌드 중 코드 서명 지연

**원인:** Xcode의 느린 코드 서명

**해결:**
```bash
# 명시적으로 서명 설정
flutter build ipa --release \
  --dart-define=ENVIRONMENT=prod \
  --export-options-plist=ios/ExportOptions.plist \
  -v  # 상세 로그로 진행 상황 확인
```

### Fastlane API Key 캐시 문제

**증상:**
```
API Key already loaded (캐시됨)
```

**해결:**
```bash
# Fastlane 캐시 정리
rm -rf ~/Library/Caches/fastlane
cd fastlane
bundle exec fastlane upload_ios
```

### macOS 배포 관련 오류

macOS 배포는 별도 문서 참고: [`docs/MACOS_DEPLOYMENT.md`](MACOS_DEPLOYMENT.md)

---

## 참고 자료

### Apple Developer

- [Apple Developer Account](https://developer.apple.com/account)
- [App Store Connect](https://appstoreconnect.apple.com)
- [API Keys 생성](https://appstoreconnect.apple.com/access/api)
- [Certificate ID & Identifier 관리](https://developer.apple.com/account/resources/identifiers)

### Flutter

- [Flutter iOS 빌드](https://docs.flutter.dev/deployment/ios)
- [ExportOptions.plist](https://developer.apple.com/documentation/xcode/building-your-app-for-distribution)

### Fastlane

- [Fastlane Documentation](https://docs.fastlane.tools/)
- [Fastlane iOS](https://docs.fastlane.tools/actions/upload_to_testflight/)
- [App Store Connect API](https://docs.fastlane.tools/app_store_connect_api/)

### GitHub Actions

- [GitHub Actions 문서](https://docs.github.com/en/actions)
- [Secrets 관리](https://docs.github.com/en/actions/security-guides/using-secrets-in-github-actions)

### Co-Talk 프로젝트

- [프로젝트 README](../README.md)
- [macOS 배포](MACOS_DEPLOYMENT.md)
- [Android 배포](ANDROID_DEPLOYMENT.md)
- [Fastlane 설정](../fastlane/Fastfile)

---

## FAQ

### Q: 빌드 번호는 어떻게 정해지나요?

**A:** GitHub Actions에서 `github.run_number`를 사용합니다. 각 워크플로우 실행마다 자동으로 증가합니다.

로컬 배포 시:
- `fastlane deploy_ios` → 빌드 번호 +1
- `fastlane deploy_ios_quick` → 빌드 번호 +1
- `fastlane bump_build build:100` → 빌드 번호 100으로 지정

### Q: TestFlight와 App Store의 차이는?

**TestFlight:** 배포 전 테스트 단계
- 최대 10,000명의 테스터 가능
- 최대 90일 유지
- 심사 없음

**App Store:** 공식 배포
- 모든 사용자 대상
- 검수 필요 (약 1-3일)
- 마케팅 가능

현재 Co-Talk는 TestFlight만 자동 배포합니다. App Store 배포는 별도 심사 후 수동 진행.

### Q: API Key는 안전한가요?

**A:** App Store Connect API Key는 username/password보다 안전합니다:
- 특정 권한만 부여 가능 (예: "Admin")
- 언제든 비활성화 가능
- 만료 설정 가능 (Fastlane에서 20분)
- 로그인 기록 추적 가능

### Q: 배포 실패 시 자동 롤백되나요?

**A:** 아니오. 배포 실패 시:
1. TestFlight에 IPA가 업로드되지 않음
2. Artifact는 GitHub에 저장됨 (30일)
3. 오류 수정 후 수동으로 재배포

GitHub Actions 로그에서 오류 원인 확인 후 수정하세요.

### Q: .env 파일을 Git에 커밋해도 되나요?

**A:** 절대 금지. `.env`에는 민감한 정보 포함:
- App Store Connect API Key 경로
- Team ID
- Apple ID

`.gitignore`에 이미 추가되어 있으니 확인하세요:
```bash
grep ".env" .gitignore
```

### Q: 로컬과 CI/CD에서 다른 버전을 빌드할 수 있나요?

**A:** 예. `--dart-define=ENVIRONMENT=dev|prod` 사용:

```bash
# Development 빌드
flutter build ipa --release --dart-define=ENVIRONMENT=dev

# Production 빌드 (기본값)
flutter build ipa --release --dart-define=ENVIRONMENT=prod
```

GitHub Actions에서도 "Manual Dispatch"로 선택 가능합니다.

---

## 변경 이력

| 날짜 | 변경 | 작성자 |
|------|------|--------|
| 2026-02-22 | 초판 작성 | Documentation Team |

## 라이선스

이 문서는 Co-Talk 프로젝트의 일부입니다.
