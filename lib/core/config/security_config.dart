import 'package:flutter/foundation.dart';
import 'app_config.dart';

/// Security configuration for certificate pinning and other security features
class SecurityConfig {
  SecurityConfig._();

  /// Certificate pinning enabled flag
  /// Disabled in development for easier testing
  /// Should be enabled in production
  static bool get certificatePinningEnabled {
    // Disable certificate pinning in development/debug mode
    if (AppConfig.isDevelopment || kDebugMode) {
      return false;
    }
    // Enable in production
    return AppConfig.isProduction;
  }

  /// List of pinned certificate SHA-256 fingerprints
  ///
  /// IMPORTANT: Replace these placeholder values with actual server certificate fingerprints
  /// before deploying to production.
  ///
  /// To get the SHA-256 fingerprint of your server certificate:
  /// ```bash
  /// openssl s_client -connect your-server.com:443 -servername your-server.com \
  ///   | openssl x509 -pubkey -noout \
  ///   | openssl pkey -pubin -outform der \
  ///   | openssl dgst -sha256 -binary \
  ///   | openssl enc -base64
  /// ```
  ///
  /// Or using the DER format:
  /// ```bash
  /// openssl x509 -in certificate.crt -pubkey -noout \
  ///   | openssl pkey -pubin -outform der \
  ///   | openssl dgst -sha256 -hex
  /// ```
  ///
  /// Store multiple certificates to support certificate rotation.
  static const List<String> pinnedCertificates = [
    // TODO: Replace with actual server certificate SHA-256 fingerprint
    // Example format: 'a1b2c3d4e5f6789012345678901234567890123456789012345678901234567890'
    '0000000000000000000000000000000000000000000000000000000000000000', // Placeholder
  ];

  /// Validates if the configuration is production-ready
  static bool get isProductionReady {
    if (!certificatePinningEnabled) {
      return true; // OK if disabled (development)
    }
    // Check if placeholder certificate is still in use
    return !pinnedCertificates.contains(
      '0000000000000000000000000000000000000000000000000000000000000000',
    );
  }

  /// Warning message for production deployment
  static String get productionWarning {
    if (isProductionReady) {
      return 'Security configuration is production-ready';
    }
    return 'WARNING: Certificate pinning is using placeholder certificates. '
        'Replace with actual server certificate fingerprints before production deployment.';
  }
}
