import 'package:flutter/material.dart';
import '../../core/network/websocket/websocket_events.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../l10n/app_localizations.dart';

/// Banner widget that displays WebSocket connection status and provides reconnect functionality.
///
/// Shows a warning banner when connection is disconnected or failed, with a retry button.
/// Animates in/out with a slide+fade so the banner doesn't pop in abruptly.
class ConnectionStatusBanner extends StatelessWidget {
  final WebSocketConnectionState connectionState;
  final VoidCallback onReconnect;

  const ConnectionStatusBanner({
    super.key,
    required this.connectionState,
    required this.onReconnect,
  });

  bool get _isVisible =>
      connectionState == WebSocketConnectionState.disconnected ||
      connectionState == WebSocketConnectionState.failed;

  bool get _isFailed => connectionState == WebSocketConnectionState.failed;

  @override
  Widget build(BuildContext context) {
    // Guard: only compute per-status values when banner is visible,
    // avoiding unnecessary branching when the banner is hidden.
    // 상태별 톤: 연결 실패 = error(레드), 끊김 = warning(앰버).
    final accentColor = _isVisible
        ? (_isFailed ? AppColors.error : AppColors.warning)
        : AppColors.warning;

    // AnimatedSize collapses height to 0 when not visible (slide effect).
    // AnimatedOpacity fades the content so there's no hard pop-in.
    // IgnorePointer prevents the collapsing/hidden banner from intercepting
    // pointer events on the UI below during the ~250 ms animation window.
    return AnimatedSize(
      duration: AppMotion.normal,
      curve: AppMotion.standard,
      child: IgnorePointer(
        ignoring: !_isVisible,
        child: AnimatedOpacity(
          opacity: _isVisible ? 1.0 : 0.0,
          duration: AppMotion.normal,
          curve: AppMotion.standard,
          child: _isVisible
              ? Material(
                  color: Colors.transparent,
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withValues(alpha: 0.30),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                _isFailed
                                    ? Icons.error_outline_rounded
                                    : Icons.wifi_off_rounded,
                                color: Colors.white,
                                size: 19,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _isFailed
                                    ? AppLocalizations.of(context)!
                                        .widgetConnectionFailed
                                    : AppLocalizations.of(context)!
                                        .widgetConnectionLost,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed: onReconnect,
                              icon: const Icon(
                                Icons.refresh_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                              label: Text(
                                AppLocalizations.of(context)!.widgetReconnect,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.22,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ),
    );
  }
}
