import 'package:flutter/material.dart';
import '../../core/network/websocket/websocket_events.dart';

/// Banner widget that displays WebSocket connection status and provides reconnect functionality.
///
/// Shows a warning banner when connection is disconnected or failed, with a retry button.
class ConnectionStatusBanner extends StatelessWidget {
  final WebSocketConnectionState connectionState;
  final VoidCallback onReconnect;

  const ConnectionStatusBanner({
    super.key,
    required this.connectionState,
    required this.onReconnect,
  });

  @override
  Widget build(BuildContext context) {
    // Only show banner when disconnected or failed
    if (connectionState != WebSocketConnectionState.disconnected &&
        connectionState != WebSocketConnectionState.failed) {
      return const SizedBox.shrink();
    }

    final backgroundColor = connectionState == WebSocketConnectionState.failed
        ? Colors.red.shade700
        : Colors.orange.shade700;

    return Material(
      color: backgroundColor,
      elevation: 4,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      ? '연결 실패 - 재시도가 중단되었습니다'
                      : '연결이 끊어졌습니다',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onReconnect,
                icon: const Icon(Icons.refresh, color: Colors.white, size: 18),
                label: const Text(
                  '재연결',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
