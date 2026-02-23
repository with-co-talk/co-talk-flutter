# Google Play Console 오류 해결 가이드

## 발생한 오류들

1. **"앱의 APK 또는 Android App Bundle을 업로드해야 합니다."**
2. **"기존 사용자가 새롭게 추가된 App Bundle로 업그레이드하지 못하므로 이 버전은 출시할 수 없습니다."**
3. **"이 버전은 App Bundle을 추가하거나 삭제하지 않습니다."**
4. **"계정에 문제가 있으므로 변경사항을 앱에 게시하거나 검토를 위해 전송할 수 없습니다."**

---

## 🔍 오류 분석 및 해결 방법

### 1. "앱의 APK 또는 Android App Bundle을 업로드해야 합니다."

#### 원인
- 파일이 제대로 업로드되지 않았거나
- 잘못된 형식의 파일을 업로드했거나
- 파일 크기가 너무 크거나
- 업로드 중 네트워크 오류 발생

#### 해결 방법

**Step 1: AAB 파일 확인**
```bash
cd co-talk-flutter
flutter build appbundle --release
```

빌드된 파일 위치 확인:
```
build/app/outputs/bundle/release/app-release.aab
```

**Step 2: 파일 크기 확인**
- AAB 파일 크기가 150MB 이하여야 합니다
- 초과 시 Android App Bundle의 기능 분할을 사용해야 합니다

**Step 3: 수동 업로드**
1. Google Play Console → 앱 → 프로덕션 (또는 내부 테스트)
2. 새 버전 만들기
3. "App Bundle 업로드" 클릭
4. `build/app/outputs/bundle/release/app-release.aab` 파일 선택

---

### 2. "기존 사용자가 새롭게 추가된 App Bundle로 업그레이드하지 못하므로 이 버전은 출시할 수 없습니다."

#### 원인
- **이전에 APK로 출시했다가 App Bundle(AAB)로 전환하려고 할 때 발생**
- Google Play는 한 번 APK로 출시한 앱을 AAB로 변경할 수 없습니다
- 기존 사용자들이 업그레이드할 수 없기 때문입니다

#### 해결 방법

**옵션 A: APK로 계속 출시 (권장하지 않음)**
- APK로 계속 출시할 수 있지만, Google Play는 AAB를 권장합니다
- APK 빌드: `flutter build apk --release`

**옵션 B: 새 앱으로 등록 (권장)**
- 새로운 패키지 이름으로 새 앱을 등록
- `pubspec.yaml`의 `applicationId` 변경 필요

**옵션 C: 기존 앱에서 APK 제거 후 AAB 추가 (복잡)**
1. Google Play Console에서 기존 APK 버전들을 모두 비활성화
2. 새 AAB 버전 업로드
3. **주의**: 이 방법은 기존 사용자에게 영향을 줄 수 있습니다

**가장 안전한 방법:**
```bash
# 1. pubspec.yaml에서 applicationId 변경
# 예: com.cotalk.co_talk_flutter → com.cotalk.co_talk_flutter_v2

# 2. AndroidManifest.xml의 package도 변경
# android/app/src/main/AndroidManifest.xml

# 3. 새 앱으로 빌드 및 업로드
flutter build appbundle --release
```

---

### 3. "이 버전은 App Bundle을 추가하거나 삭제하지 않습니다."

#### 원인
- Google Play Console에서 App Bundle 설정이 올바르지 않거나
- 이전 버전과 다른 형식(APK ↔ AAB)을 혼용하려고 할 때 발생

#### 해결 방법

**Step 1: 앱 형식 확인**
1. Google Play Console → 앱 → 프로덕션 → 출시
2. 이전에 업로드한 파일 형식 확인 (APK인지 AAB인지)

**Step 2: 일관된 형식 사용**
- 이전에 APK로 출시했다면 → 계속 APK 사용
- 이전에 AAB로 출시했다면 → 계속 AAB 사용
- 처음 출시하는 경우 → **AAB 사용 권장**

**Step 3: 올바른 빌드 명령어 사용**
```bash
# AAB 빌드 (권장)
flutter build appbundle --release

# APK 빌드 (필요한 경우만)
flutter build apk --release
```

---

### 4. "계정에 문제가 있으므로 변경사항을 앱에 게시하거나 검토를 위해 전송할 수 없습니다."

#### 원인
- Google Play Console 계정 권한 문제
- 결제 정보 미완성
- 개발자 계정 상태 문제
- 앱 서명 키 문제

#### 해결 방법

**Step 1: 계정 상태 확인**
1. Google Play Console → 설정 → 계정 세부정보
2. 다음 항목 확인:
   - ✅ 개발자 계정 상태가 "활성"인지
   - ✅ 결제 정보가 완료되었는지
   - ✅ 개발자 계약이 수락되었는지

**Step 2: 앱 서명 확인**
1. Google Play Console → 앱 → 출시 → 설정 → 앱 서명
2. Google Play 앱 서명이 활성화되어 있는지 확인
3. 업로드 키 인증서가 올바른지 확인

**Step 3: 권한 확인**
- 계정에 앱을 업데이트할 권한이 있는지 확인
- 팀 계정인 경우 관리자에게 권한 요청

**Step 4: 앱 서명 키 재생성 (필요한 경우)**
```bash
# 키스토어 생성 (이미 있다면 스킵)
keytool -genkey -v -keystore ~/co-talk-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias co-talk

# key.properties 파일 생성/업데이트
# android/key.properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=co-talk
storeFile=/path/to/co-talk-release.jks
```

---

## 📋 체크리스트

업로드 전 확인사항:

- [ ] AAB 파일이 올바르게 빌드되었는가?
- [ ] 파일 크기가 150MB 이하인가?
- [ ] 이전 버전과 동일한 형식(APK/AAB)을 사용하는가?
- [ ] 버전 코드가 이전 버전보다 큰가? (`versionCode` 확인)
- [ ] 앱 서명이 올바른가?
- [ ] Google Play Console 계정 상태가 정상인가?
- [ ] 개발자 계약이 완료되었는가?

---

## 🚀 올바른 업로드 절차

### 방법 1: Fastlane 사용 (자동화)

```bash
cd co-talk-flutter

# 1. AAB 빌드
flutter build appbundle --release

# 2. Fastlane으로 업로드
cd fastlane
bundle exec fastlane upload_android track:internal
```

### 방법 2: 수동 업로드

```bash
# 1. AAB 빌드
cd co-talk-flutter
flutter build appbundle --release

# 2. Google Play Console에서 수동 업로드
# - Google Play Console 접속
# - 앱 선택 → 내부 테스트 (또는 프로덕션)
# - 새 버전 만들기
# - App Bundle 업로드
# - build/app/outputs/bundle/release/app-release.aab 선택
```

---

## 🔧 빌드 설정 확인

### build.gradle.kts 확인
```kotlin
// android/app/build.gradle.kts
defaultConfig {
    applicationId = "com.cotalk.co_talk_flutter"  // 패키지 이름 확인
    versionCode = flutter.versionCode             // 버전 코드 확인
    versionName = flutter.versionName             // 버전 이름 확인
}
```

### pubspec.yaml 확인
```yaml
version: 1.0.0+2  # +2는 versionCode, 1.0.0은 versionName
```

**중요**: 새 버전 업로드 시 `versionCode`는 반드시 이전 버전보다 커야 합니다.

---

## 💡 추가 팁

### 버전 코드 자동 증가
```bash
# 현재 버전 코드 확인
grep versionCode android/app/build.gradle.kts

# pubspec.yaml에서 버전 코드 증가
# version: 1.0.0+2 → version: 1.0.0+3
```

### AAB 파일 검증
```bash
# bundletool을 사용하여 AAB 검증 (선택사항)
# bundletool build-apks --bundle=app-release.aab --output=app.apks
```

### 로그 확인
- Google Play Console → 앱 → 출시 → 내부 테스트 → 출시 상태
- 오류 메시지와 상세 정보 확인

---

## 📞 추가 도움

문제가 계속되면:
1. Google Play Console의 "도움말" 섹션 확인
2. Google Play Developer Support에 문의
3. 프로젝트의 `.github/workflows/build-android.yml` 확인 (CI/CD 설정)

---

## ⚠️ 주의사항

1. **APK → AAB 전환 불가**: 한 번 APK로 출시한 앱은 AAB로 변경할 수 없습니다
2. **버전 코드 필수 증가**: 새 버전은 반드시 이전 버전보다 큰 versionCode를 가져야 합니다
3. **앱 서명 일관성**: 같은 키스토어로 서명해야 합니다
4. **계정 상태**: 개발자 계정이 활성 상태여야 합니다
