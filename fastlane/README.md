fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

### deploy_all

```sh
[bundle exec] fastlane deploy_all
```

iOS와 macOS 모두 빌드 및 TestFlight 업로드

### deploy_all_quick

```sh
[bundle exec] fastlane deploy_all_quick
```

iOS와 macOS 업로드만 (빌드 스킵)

### build_all

```sh
[bundle exec] fastlane build_all
```

iOS와 macOS 모두 빌드만 (업로드 X)

### deploy_ios

```sh
[bundle exec] fastlane deploy_ios
```

iOS 빌드 + TestFlight 업로드

### deploy_ios_quick

```sh
[bundle exec] fastlane deploy_ios_quick
```

iOS 빌드 스킵하고 업로드만 (이미 빌드된 경우)

### build_ios

```sh
[bundle exec] fastlane build_ios
```

iOS 빌드만

### upload_ios

```sh
[bundle exec] fastlane upload_ios
```

iOS TestFlight 업로드 (이미 빌드된 IPA)

### setup_macos_signing

```sh
[bundle exec] fastlane setup_macos_signing
```

macOS 인증서 및 프로비저닝 프로필 설정

### deploy_macos

```sh
[bundle exec] fastlane deploy_macos
```

macOS 빌드 + TestFlight 업로드

### deploy_macos_quick

```sh
[bundle exec] fastlane deploy_macos_quick
```

macOS 빌드 스킵하고 업로드만 (이미 빌드된 경우) - 권장

사용법: flutter build macos --release 후 fastlane deploy_macos_quick

### build_macos

```sh
[bundle exec] fastlane build_macos
```

macOS 빌드만 (서명 없이)

### build_macos_signed

```sh
[bundle exec] fastlane build_macos_signed
```

macOS 빌드 (App Store 서명 포함)

### upload_macos

```sh
[bundle exec] fastlane upload_macos
```

macOS TestFlight 업로드 (이미 빌드된 앱)

### bump_build

```sh
[bundle exec] fastlane bump_build
```

빌드 번호 증가 (iOS + macOS)

### deploy_android

```sh
[bundle exec] fastlane deploy_android
```

Android 빌드 + Google Play 내부 테스트 업로드

### build_android

```sh
[bundle exec] fastlane build_android
```

Android 빌드만

### upload_android

```sh
[bundle exec] fastlane upload_android
```

Android Google Play 업로드 (이미 빌드된 AAB)

옵션: track - internal(내부테스트), alpha(비공개테스트), beta(공개테스트), production(프로덕션)

### deploy_all_platforms

```sh
[bundle exec] fastlane deploy_all_platforms
```

iOS + macOS + Android 모두 배포

### status

```sh
[bundle exec] fastlane status
```

현재 상태 확인

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
