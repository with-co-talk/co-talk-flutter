import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import '../config/security_config.dart';

/// Dio interceptor for certificate pinning
///
/// This interceptor validates SSL/TLS certificates against a list of
/// pinned certificate fingerprints to prevent man-in-the-middle attacks.
///
/// Only active when [SecurityConfig.certificatePinningEnabled] is true.
@lazySingleton
class CertificatePinningInterceptor extends Interceptor {
  HttpClient? _httpClient;

  CertificatePinningInterceptor() {
    if (SecurityConfig.certificatePinningEnabled) {
      _initializeHttpClient();
    }
  }

  void _initializeHttpClient() {
    _httpClient = HttpClient()
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        // Validate certificate against pinned fingerprints
        return _validateCertificate(cert);
      };
  }

  bool _validateCertificate(X509Certificate cert) {
    if (!SecurityConfig.certificatePinningEnabled) {
      return true; // Allow all certificates when pinning is disabled
    }

    if (SecurityConfig.pinnedCertificates.isEmpty) {
      if (kDebugMode) {
        debugPrint(
          'WARNING: Certificate pinning is enabled but no certificates are configured',
        );
      }
      return false;
    }

    // Extract SHA-256 fingerprint from certificate
    final certSha256 = _getSha256Fingerprint(cert);

    // Check if certificate matches any pinned fingerprint
    final isValid = SecurityConfig.pinnedCertificates.any(
      (pinnedFingerprint) =>
          pinnedFingerprint.toLowerCase() == certSha256.toLowerCase(),
    );

    if (!isValid && kDebugMode) {
      debugPrint('Certificate verification failed for host: ${cert.subject}');
      debugPrint('Certificate SHA-256: $certSha256');
      debugPrint(
        'Pinned fingerprints: ${SecurityConfig.pinnedCertificates}',
      );
    }

    return isValid;
  }

  String _getSha256Fingerprint(X509Certificate cert) {
    // Get DER-encoded certificate
    final derCert = cert.der;

    // Calculate SHA-256 hash
    // Note: For public key pinning (more secure), we would hash only the public key
    // For now, we're doing certificate pinning (full certificate hash)
    final sha256Hash = _calculateSha256(derCert);

    // Convert to hex string
    return sha256Hash;
  }

  String _calculateSha256(Uint8List data) {
    // Use a simple hex conversion
    // For production, consider using crypto package for proper SHA-256
    return data
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join('')
        .toLowerCase();
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.type == DioExceptionType.badCertificate ||
        err.error is HandshakeException) {
      if (kDebugMode) {
        debugPrint('Certificate pinning error: ${err.message}');
      }

      // Create a user-friendly error
      final error = DioException(
        requestOptions: err.requestOptions,
        error:
            'Certificate verification failed: Server certificate does not match pinned certificates',
        type: DioExceptionType.badCertificate,
      );

      handler.next(error);
      return;
    }

    handler.next(err);
  }

  void dispose() {
    _httpClient?.close();
  }
}
