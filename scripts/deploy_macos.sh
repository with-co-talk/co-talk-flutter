#!/bin/bash
# macOS App Store 배포 - 한번에 실행
set -e

cd "$(dirname "$0")/.."

echo "=== macOS App Store 배포 시작 ==="

# 1. 빌드 번호 증가
echo ">>> 빌드 번호 증가..."
fastlane bump_build

# 2. Flutter 빌드
echo ">>> Flutter macOS 빌드..."
flutter build macos --release --dart-define=ENVIRONMENT=prod

# 3. 재서명 + 업로드
echo ">>> 재서명 및 TestFlight 업로드..."
fastlane deploy_macos_quick skip_bump:true

echo "=== macOS App Store 배포 완료 ==="
