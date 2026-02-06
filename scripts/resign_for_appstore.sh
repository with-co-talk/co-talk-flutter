#!/bin/bash
# macOS App Store 배포용 완전 재서명 스크립트

set -e

APP_PATH="$1"
ENTITLEMENTS="$2"
PROFILE_PATH="$3"
SIGN_IDENTITY="Apple Distribution: seunggu lee (QW7DJ7FBDT)"

if [ -z "$APP_PATH" ] || [ -z "$ENTITLEMENTS" ] || [ -z "$PROFILE_PATH" ]; then
    echo "Usage: $0 <app_path> <entitlements_path> <profile_path>"
    exit 1
fi

echo "=== macOS App Store 재서명 시작 ==="
echo "앱 경로: $APP_PATH"
echo "Entitlements: $ENTITLEMENTS"
echo "프로필: $PROFILE_PATH"
echo "서명 ID: $SIGN_IDENTITY"
echo ""

# 1. 프로비저닝 프로필 복사
echo ">>> 프로비저닝 프로필 복사..."
cp "$PROFILE_PATH" "$APP_PATH/Contents/embedded.provisionprofile"

# 2. 모든 프레임워크 내부 실행파일 서명 (가장 깊은 곳부터)
echo ">>> 프레임워크 내부 실행파일 서명..."
FRAMEWORKS_PATH="$APP_PATH/Contents/Frameworks"

for framework in "$FRAMEWORKS_PATH"/*.framework; do
    if [ -d "$framework" ]; then
        framework_name=$(basename "$framework" .framework)
        executable="$framework/Versions/A/$framework_name"

        if [ -f "$executable" ]; then
            echo "  서명: $framework_name"
            codesign --force --timestamp --options runtime \
                --sign "$SIGN_IDENTITY" \
                "$executable"
        fi
    fi
done

# 3. 프레임워크 번들 전체 서명
echo ">>> 프레임워크 번들 서명..."
for framework in "$FRAMEWORKS_PATH"/*.framework; do
    if [ -d "$framework" ]; then
        framework_name=$(basename "$framework" .framework)
        echo "  서명: $framework_name.framework"
        codesign --force --timestamp --options runtime \
            --sign "$SIGN_IDENTITY" \
            "$framework"
    fi
done

# 4. 메인 실행파일 서명 (entitlements 포함)
echo ">>> 메인 실행파일 서명..."
MAIN_EXECUTABLE="$APP_PATH/Contents/MacOS/Co Talk"
codesign --force --timestamp --options runtime \
    --entitlements "$ENTITLEMENTS" \
    --sign "$SIGN_IDENTITY" \
    "$MAIN_EXECUTABLE"

# 5. 앱 번들 전체 서명 (entitlements 포함)
echo ">>> 앱 번들 전체 서명..."
codesign --force --timestamp --options runtime \
    --entitlements "$ENTITLEMENTS" \
    --sign "$SIGN_IDENTITY" \
    "$APP_PATH"

# 6. 서명 검증
echo ""
echo "=== 서명 검증 ==="
echo ">>> codesign --verify..."
codesign --verify --deep --strict --verbose=2 "$APP_PATH"

echo ""
echo ">>> 메인 앱 서명 정보:"
codesign -dvv "$APP_PATH" 2>&1 | grep -E "Authority|TeamIdentifier|Signature"

echo ""
echo ">>> 프레임워크 서명 확인 (FlutterMacOS):"
codesign -dvv "$FRAMEWORKS_PATH/FlutterMacOS.framework" 2>&1 | grep -E "Authority|TeamIdentifier"

echo ""
echo "=== 재서명 완료 ==="
