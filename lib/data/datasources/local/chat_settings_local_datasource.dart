import 'dart:convert';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/chat_settings_model.dart';

/// 채팅 설정 로컬 데이터소스 인터페이스
abstract class ChatSettingsLocalDataSource {
  /// 저장된 채팅 설정 조회
  Future<ChatSettingsModel> getChatSettings();

  /// 채팅 설정 저장
  Future<void> saveChatSettings(ChatSettingsModel settings);

  /// 캐시 삭제
  Future<void> clearCache();
}

/// 채팅 설정 로컬 데이터소스 구현체
@LazySingleton(as: ChatSettingsLocalDataSource)
class ChatSettingsLocalDataSourceImpl implements ChatSettingsLocalDataSource {
  static const String _chatSettingsKey = 'chat_settings';

  @override
  Future<ChatSettingsModel> getChatSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_chatSettingsKey);

    if (jsonString == null) {
      return const ChatSettingsModel();
    }

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return ChatSettingsModel.fromJson(json);
    } catch (_) {
      return const ChatSettingsModel();
    }
  }

  @override
  Future<void> saveChatSettings(ChatSettingsModel settings) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(settings.toJson());
    await prefs.setString(_chatSettingsKey, jsonString);
  }

  @override
  Future<void> clearCache() async {
    try {
      // 앱 캐시 디렉토리 삭제
      final cacheDir = await getTemporaryDirectory();
      if (cacheDir.existsSync()) {
        await cacheDir.delete(recursive: true);
      }

      // 앱 캐시 디렉토리 재생성
      await cacheDir.create();
    } catch (_) {
      // 캐시 삭제 실패는 무시
    }
  }
}
