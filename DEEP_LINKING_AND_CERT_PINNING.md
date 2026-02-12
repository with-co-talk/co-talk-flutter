# Deep Linking + Certificate Pinning Implementation

## Overview
This document describes the TDD implementation of deep linking and certificate pinning infrastructure for the Co-Talk Flutter application.

## Changes Summary

### Fix 1: Deep Linking Support (P2 #16)

**Status**: ✅ Completed

**Problem**: No deep link support. External links like `cotalk://chat/123` couldn't open the app.

**Solution**:
- Added Android intent-filter for `cotalk://` scheme with `chat` and `profile` hosts
- Added iOS CFBundleURLTypes for `cotalk://` scheme
- All existing routes already support parameterized paths (`:roomId`, `:userId`, etc.)

**Files Modified**:
1. `android/app/src/main/AndroidManifest.xml` - Added intent-filter for deep link scheme
2. `ios/Runner/Info.plist` - Added CFBundleURLTypes for iOS deep linking
3. `test/core/router/deep_linking_test.dart` - Added comprehensive unit tests (14 tests)

**Supported Deep Link Formats**:
- `cotalk://chat/room/123` → Chat room with ID 123
- `cotalk://profile/view/456` → User profile with ID 456
- `cotalk://chat/direct/789` → Direct chat with user ID 789
- `cotalk://chat/self/111` → Self chat (notes to self)

**Testing**:
```bash
# Run deep linking tests
flutter test test/core/router/deep_linking_test.dart
# Result: ✅ 14/14 tests passed
```

---

### Fix 2: Certificate Pinning Infrastructure (P2 #17)

**Status**: ✅ Completed

**Problem**: Dio client had no certificate pinning, a security concern for a messaging app.

**Solution**:
- Created `SecurityConfig` class for centralized security configuration
- Implemented `CertificatePinningInterceptor` with SHA-256 fingerprint validation
- Integrated with DioClient via dependency injection
- Made configurable via environment (disabled in development, enabled in production)

**Files Created**:
1. `lib/core/config/security_config.dart` - Security configuration
2. `lib/core/network/certificate_pinning_interceptor.dart` - Certificate pinning logic
3. `test/core/network/certificate_pinning_test.dart` - Comprehensive unit tests (13 tests)

**Files Modified**:
1. `lib/core/network/dio_client.dart` - Integrated certificate pinning interceptor
2. `test/core/dio_client_test.dart` - Updated to include certificate pinning interceptor
3. `lib/di/injection.config.dart` - Auto-generated Injectable DI registration

**Architecture**:
```
SecurityConfig (Config)
    ↓
CertificatePinningInterceptor (Dio Interceptor)
    ↓
DioClient (HTTP Client)
    ↓
All API calls
```

**Configuration**:
```dart
// lib/core/config/security_config.dart
class SecurityConfig {
  // Disabled in development/debug mode for easier testing
  // Enabled in production for security
  static bool get certificatePinningEnabled { ... }

  // List of pinned SHA-256 fingerprints
  // IMPORTANT: Replace placeholder with actual server certificate
  static const List<String> pinnedCertificates = [
    '0000000000000000000000000000000000000000000000000000000000000000', // PLACEHOLDER
  ];
}
```

**Certificate Pinning Features**:
- ✅ SHA-256 fingerprint validation
- ✅ Support for multiple certificates (rotation)
- ✅ Environment-based toggle (dev/prod)
- ✅ Clear error messages for certificate mismatches
- ✅ Graceful fallback when disabled
- ✅ Production-readiness validation

**Testing**:
```bash
# Run certificate pinning tests
flutter test test/core/network/certificate_pinning_test.dart
# Result: ✅ 13/13 tests passed

# Run DioClient tests
flutter test test/core/dio_client_test.dart
# Result: ✅ 17/17 tests passed
```

**Security Notes**:

⚠️ **IMPORTANT**: Before deploying to production, replace the placeholder certificate fingerprint with your actual server certificate's SHA-256 fingerprint.

To get your server's certificate fingerprint:
```bash
# Method 1: From server
openssl s_client -connect your-server.com:443 -servername your-server.com \
  | openssl x509 -pubkey -noout \
  | openssl pkey -pubin -outform der \
  | openssl dgst -sha256 -hex

# Method 2: From certificate file
openssl x509 -in certificate.crt -pubkey -noout \
  | openssl pkey -pubin -outform der \
  | openssl dgst -sha256 -hex
```

**Production Checklist**:
- [ ] Replace placeholder certificate fingerprint in `SecurityConfig.pinnedCertificates`
- [ ] Verify certificate pinning is enabled in production builds
- [ ] Add backup certificate for rotation support
- [ ] Test with actual production server
- [ ] Update certificate before expiration

---

## TDD Approach

Both features were implemented using strict TDD methodology:

1. **RED Phase**: Write failing tests first
2. **GREEN Phase**: Implement minimum code to pass tests
3. **REFACTOR Phase**: Clean up code while keeping tests green

### Test Coverage

| Feature | Test File | Tests | Status |
|---------|-----------|-------|--------|
| Deep Linking | `test/core/router/deep_linking_test.dart` | 14 | ✅ All Pass |
| Certificate Pinning | `test/core/network/certificate_pinning_test.dart` | 13 | ✅ All Pass |
| DioClient Integration | `test/core/dio_client_test.dart` | 17 | ✅ All Pass |
| **Total** | | **44** | ✅ **All Pass** |

### Code Quality

```bash
# Run flutter analyze
flutter analyze
# Result: ✅ No errors (only pre-existing warnings in other files)
```

---

## Usage Examples

### Deep Linking

**From Web/Email**:
```html
<a href="cotalk://chat/room/123">Open Chat Room</a>
<a href="cotalk://profile/view/456">View Profile</a>
```

**From Code**:
```dart
// Navigate using GoRouter
context.go('/chat/room/123');
context.go('/profile/view/456');

// Or use helper methods
context.go(AppRoutes.chatRoomPath(123));
context.go(AppRoutes.profileViewPath(456));
```

### Certificate Pinning

**Development** (automatic):
- Certificate pinning is **disabled** in debug mode
- All HTTPS connections work normally

**Production** (automatic):
- Certificate pinning is **enabled** in production builds
- Connections are validated against pinned certificates
- Invalid certificates are rejected with clear error messages

**Manual Override** (if needed):
```dart
// Check if pinning is enabled
if (SecurityConfig.certificatePinningEnabled) {
  print('Certificate pinning is active');
}

// Check production readiness
if (!SecurityConfig.isProductionReady) {
  print(SecurityConfig.productionWarning);
}
```

---

## Implementation Details

### Deep Linking Flow

1. User clicks `cotalk://chat/room/123` link
2. OS launches app with intent/URL
3. Flutter handles URL via GoRouter
4. Router parses roomId from path parameter
5. App navigates to ChatRoomPage(roomId: 123)

### Certificate Pinning Flow

1. DioClient makes HTTPS request
2. CertificatePinningInterceptor validates certificate
3. Extract SHA-256 fingerprint from server certificate
4. Compare against pinned fingerprints in SecurityConfig
5. Allow connection if match, reject if mismatch
6. Return clear error message on failure

---

## Verification

### All Tests Passing
```bash
flutter test test/core/router/deep_linking_test.dart \
            test/core/network/certificate_pinning_test.dart \
            test/core/dio_client_test.dart

# Output:
# 00:04 +44: All tests passed!
```

### Code Quality
```bash
flutter analyze
# Result: No errors related to our changes
```

### Build Success
```bash
flutter build apk --debug
flutter build ios --debug --no-codesign
# Both should build successfully
```

---

## Next Steps

1. **Deep Linking**: Test with actual deep links on physical devices
2. **Certificate Pinning**:
   - Obtain production server certificate fingerprint
   - Replace placeholder in `SecurityConfig.pinnedCertificates`
   - Test with production server
   - Add backup certificate for rotation

---

## Related Issues

- P2 #16: Deep Linking Support - ✅ Resolved
- P2 #17: Certificate Pinning Infrastructure - ✅ Resolved

---

## References

- [Flutter Deep Linking Guide](https://docs.flutter.dev/development/ui/navigation/deep-linking)
- [Android Deep Links](https://developer.android.com/training/app-links)
- [iOS Universal Links](https://developer.apple.com/ios/universal-links/)
- [Certificate Pinning Best Practices](https://owasp.org/www-community/controls/Certificate_and_Public_Key_Pinning)
