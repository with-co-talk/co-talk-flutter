import 'package:flutter/material.dart';
import '../../core/network/websocket/websocket_events.dart';
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

  @override
  Widget build(BuildContext context) {
    // Banner background colour. Only consumed inside the `_isVisible`
    // Material branch below, so it can always be computed non-null.
    final backgroundColor = connectionState == WebSocketConnectionState.failed
        ? Colors.red.shade700
        : Colors.orange.shade700;

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
                  color: backgroundColor,
                  elevation: 4,
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            connectionState == WebSocketConnectionState.failed
                                ? Icons.error_outline
                                : Icons.wifi_off,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              connectionState == WebSocketConnectionState.failed
                                  ? AppLocalizations.of(context)!
                                      .widgetConnectionFailed
                                  : AppLocalizations.of(context)!
                                      .widgetConnectionLost,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: onReconnect,
                            icon: const Icon(
                              Icons.refresh,
                              color: Colors.white,
                              size: 18,
                            ),
                            label: Text(
                              AppLocalizations.of(context)!.widgetReconnect,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
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
