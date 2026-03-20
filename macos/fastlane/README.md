fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## Mac

### mac beta

```sh
[bundle exec] fastlane mac beta
```

TestFlight에 배포 (Flutter 빌드 포함)

### mac beta_upload

```sh
[bundle exec] fastlane mac beta_upload
```

TestFlight에 업로드만 (flutter build macos 이미 실행한 경우)

### mac release

```sh
[bundle exec] fastlane mac release
```

App Store에 배포

### mac build

```sh
[bundle exec] fastlane mac build
```

로컬 빌드만 수행

### mac beta_quick

```sh
[bundle exec] fastlane mac beta_quick
```

빠른 TestFlight 배포 - 빌드 번호 수동 지정

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
