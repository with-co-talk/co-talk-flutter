import 'package:flutter/foundation.dart';
import 'app_config.dart';

/// Security configuration for certificate pinning and other security features
class SecurityConfig {
  SecurityConfig._();

  /// Certificate pinning enabled flag
  /// Disabled in development for easier testing
  /// 
  /// ⚠️ PRODUCTION: Currently disabled until actual server certificate fingerprints are configured.
  /// To enable: Replace placeholder in pinnedCertificates with real SHA-256 fingerprints.
  static bool get certificatePinningEnabled {
    // Disable certificate pinning in development/debug mode
    if (AppConfig.isDevelopment || kDebugMode) {
      return false;
    }
    // Disabled in production until real certificates are configured
    // TODO: Enable after configuring actual server certificate fingerprints
    return false;
  }

  /// List of pinned certificate SHA-256 fingerprints
  ///
  /// ⚠️ PRODUCTION: Currently empty. Certificate pinning is disabled.
  /// 
  /// To enable certificate pinning:
  /// 1. Get your server certificate SHA-256 fingerprint:
  ///    ```bash
  ///    openssl s_client -connect your-server.com:443 -servername your-server.com \
  ///      | openssl x509 -pubkey -noout \
  ///      | openssl pkey -pubin -outform der \
  ///      | openssl dgst -sha256 -binary \
  ///      | openssl enc -base64
  ///    ```
  /// 2. Add the fingerprint to this list
  /// 3. Set certificatePinningEnabled to return true in production
  ///
  /// Store multiple certificates to support certificate rotation.
  static const List<String> pinnedCertificates = [
    // Add actual server certificate SHA-256 fingerprints here when ready
    // Example format: 'a1b2c3d4e5f6789012345678901234567890123456789012345678901234567890'
  ];

  /// Validates if the configuration is production-ready
  static bool get isProductionReady {
    if (!certificatePinningEnabled) {
      return true; // OK if disabled (certificate pinning is optional)
    }
    // If pinning is enabled, must have at least one certificate
    return pinnedCertificates.isNotEmpty;
  }

  /// Warning message for production deployment
  static String get productionWarning {
    if (isProductionReady) {
      return 'Security configuration is production-ready';
    }
    return 'WARNING: Certificate pinning is enabled but no certificates are configured. '
        'Either disable pinning or add actual server certificate fingerprints.';
  }
}
