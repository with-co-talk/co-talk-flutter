import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';

/// 로컬 알림 서비스
///
/// 모든 플랫폼(Android/iOS/macOS/Windows/Linux)에서 로컬 알림을 표시합니다.
/// 데스크톱에서는 WebSocket 메시지 수신 시 로컬 알림으로 표시하고,
/// 모바일에서는 FCM 포그라운드 메시지를 로컬 알림으로 표시합니다.
@lazySingleton
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin;

  /// 알림 클릭 시 콜백
  final StreamController<String?> _notificationClickController =
      StreamController<String?>.broadcast();

  /// 알림 클릭 이벤트 스트림
  Stream<String?> get onNotificationClick => _notificationClickController.stream;

  // 알림 ID 카운터
  int _notificationIdCounter = 0;

  // Android 알림 채널 설정
  static const String _channelId = 'chat_messages';
  static const String _channelName = 'Chat Messages';
  static const String _channelDescription = 'Notifications for new chat messages';

  NotificationService({required FlutterLocalNotificationsPlugin plugin})
      : _plugin = plugin;

  /// 알림 서비스 초기화
  ///
  /// 플랫폼별 초기화 설정을 수행합니다:
  /// - Android: 알림 채널 생성, 알림 아이콘 @mipmap/ic_launcher 사용
  /// - iOS/macOS: 알림 권한 요청 (알림 아이콘은 앱 번들 아이콘 사용, 별도 지정 불가)
  /// - Windows/Linux: 기본 설정
  ///
  /// iOS/macOS/Windows에서 알림에 앱 아이콘이 보이려면, 앱 아이콘이 Co-Talk 아이콘으로
  /// 설정되어 있어야 합니다. `assets/icons/app_icon.png`를 Co-Talk 아이콘으로 둔 뒤
  /// `dart run flutter_launcher_icons`를 실행해 모든 플랫폼 아이콘을 재생성하세요.
  Future<void> initialize() async {
    // Android: 알림 아이콘으로 앱 런처 아이콘 사용 (flutter_launcher_icons로 생성된 ic_launcher)
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS/macOS: 알림은 앱 번들 아이콘을 사용. 앱 아이콘을 바꾸려면 flutter_launcher_icons 실행
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Linux 설정
    const linuxSettings = LinuxInitializationSettings(
      defaultActionName: 'Open notification',
    );

    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
      linux: linuxSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    // Android 알림 채널 생성
    if (!kIsWeb && Platform.isAndroid) {
      await _createAndroidNotificationChannel();
    }

    // iOS/macOS 권한 요청
    if (!kIsWeb && (Platform.isIOS || Platform.isMacOS)) {
      await _requestIOSPermissions();
    }
  }

  /// Android 알림 채널 생성
  Future<void> _createAndroidNotificationChannel() async {
    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      const channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );

      await androidPlugin.createNotificationChannel(channel);
    }
  }

  /// iOS/macOS 알림 권한 요청
  Future<void> _requestIOSPermissions() async {
    if (Platform.isIOS) {
      final iosPlugin =
          _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();

      await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    } else if (Platform.isMacOS) {
      final macOSPlugin =
          _plugin.resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>();

      await macOSPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  /// 알림 응답 핸들러
  void _onNotificationResponse(NotificationResponse response) {
    _notificationClickController.add(response.payload);
  }

  /// 알림 표시
  ///
  /// [title] 알림 제목
  /// [body] 알림 내용
  /// [payload] 알림 클릭 시 전달할 데이터
  /// [soundEnabled] 알림 소리 (설정에서 토글한 값 즉시 반영)
  /// [vibrationEnabled] 알림 진동 (설정에서 토글한 값 즉시 반영)
  /// [avatarUrl] 발신자 프로필 이미지 URL (없으면 null, 다운로드 실패 시 기본 알림)
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
    bool soundEnabled = true,
    bool vibrationEnabled = true,
    String? avatarUrl,
  }) async {
    final notificationId = _generateNotificationId();

    // 아바타 이미지 다운로드 (3초 타임아웃, 실패 시 null)
    Uint8List? avatarBytes;
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      avatarBytes = await _downloadImage(avatarUrl);
    }

    // Android: largeIcon으로 아바타 표시
    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      icon: '@mipmap/ic_launcher',
      largeIcon: avatarBytes != null ? ByteArrayAndroidBitmap(avatarBytes) : null,
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      autoCancel: true,
      playSound: soundEnabled,
      enableVibration: vibrationEnabled,
    );

    // iOS: attachment로 아바타 표시
    List<DarwinNotificationAttachment>? iosAttachments;
    if (!kIsWeb && (Platform.isIOS || Platform.isMacOS) && avatarBytes != null) {
      final filePath = await _saveToTempFile(avatarBytes, 'avatar_$notificationId.jpg');
      if (filePath != null) {
        iosAttachments = [DarwinNotificationAttachment(filePath)];
      }
    }

    final darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: soundEnabled,
      attachments: iosAttachments,
    );

    const linuxDetails = LinuxNotificationDetails();

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
      linux: linuxDetails,
    );

    await _plugin.show(
      notificationId,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// URL에서 이미지를 다운로드한다 (3초 타임아웃).
  ///
  /// 다운로드 실패 시 null을 반환하여 graceful degradation을 보장한다.
  Future<Uint8List?> _downloadImage(String url) async {
    try {
      final dio = Dio();
      final response = await dio.get<List<int>>(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(seconds: 3),
          sendTimeout: const Duration(seconds: 3),
        ),
      );
      if (response.statusCode == 200 && response.data != null) {
        return Uint8List.fromList(response.data!);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[NotificationService] Failed to download avatar: $e');
      }
    }
    return null;
  }

  /// 바이트 데이터를 임시 파일로 저장한다 (iOS attachment용).
  Future<String?> _saveToTempFile(Uint8List bytes, String fileName) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(bytes);
      return file.path;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[NotificationService] Failed to save temp file: $e');
      }
      return null;
    }
  }

  /// 특정 알림 취소
  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
  }

  /// 모든 알림 취소
  Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
  }

  /// 고유한 알림 ID 생성
  int _generateNotificationId() {
    return _notificationIdCounter++;
  }

  /// 리소스 해제
  void dispose() {
    _notificationClickController.close();
  }
}
