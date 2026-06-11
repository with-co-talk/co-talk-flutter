import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../domain/entities/chat_settings.dart';
import '../../../domain/repositories/settings_repository.dart';
import 'chat_settings_state.dart';

/// 채팅 설정 Cubit
///
/// 채팅 설정을 관리하고 SharedPreferences에 저장합니다.
@lazySingleton
class ChatSettingsCubit extends Cubit<ChatSettingsState> {
  final SettingsRepository _repository;

  ChatSettingsCubit(this._repository) : super(const ChatSettingsState.initial());

  /// 채팅 설정 로드
  Future<void> loadSettings() async {
    emit(const ChatSettingsState.loading());
    try {
      final settings = await _repository.getChatSettings();
      emit(ChatSettingsState.loaded(settings));
    } catch (e) {
      // 로컬 설정 로드 실패 시 기본값 사용
      emit(ChatSettingsState.loaded(const ChatSettings()));
    }
  }

  /// 글꼴 크기 변경 (0.8 ~ 1.4)
  Future<void> setFontSize(double size) async {
    // 부동소수점 정밀도 문제 방지: 소수점 1자리로 반올림
    final rounded = (size * 10).roundToDouble() / 10;
    final clampedSize = rounded.clamp(0.8, 1.4);
    await _updateSetting(state.settings.copyWith(fontSize: clampedSize));
  }

  /// 이미지 자동 다운로드 설정 (WiFi)
  Future<void> setAutoDownloadImagesOnWifi(bool value) async {
    await _updateSetting(state.settings.copyWith(autoDownloadImagesOnWifi: value));
  }

  /// 이미지 자동 다운로드 설정 (모바일)
  Future<void> setAutoDownloadImagesOnMobile(bool value) async {
    await _updateSetting(state.settings.copyWith(autoDownloadImagesOnMobile: value));
  }

  /// 동영상 자동 다운로드 설정 (WiFi)
  Future<void> setAutoDownloadVideosOnWifi(bool value) async {
    await _updateSetting(state.settings.copyWith(autoDownloadVideosOnWifi: value));
  }

  /// 동영상 자동 다운로드 설정 (모바일)
  Future<void> setAutoDownloadVideosOnMobile(bool value) async {
    await _updateSetting(state.settings.copyWith(autoDownloadVideosOnMobile: value));
  }

  /// 입력중 표시 설정
  Future<void> setShowTypingIndicator(bool value) async {
    await _updateSetting(state.settings.copyWith(showTypingIndicator: value));
  }

  /// 캐시 삭제
  Future<void> clearCache() async {
    emit(const ChatSettingsState.clearing());
    try {
      await _repository.clearCache();
      emit(state.copyWith(status: ChatSettingsStatus.loaded));
    } catch (e) {
      emit(ChatSettingsState.error('캐시 삭제에 실패했습니다'));
      emit(state.copyWith(status: ChatSettingsStatus.loaded));
    }
  }

  /// 설정 업데이트 공통 메서드
  Future<void> _updateSetting(ChatSettings newSettings) async {
    emit(state.copyWith(settings: newSettings));
    try {
      await _repository.saveChatSettings(newSettings);
    } catch (e) {
      // 로컬 저장 실패는 무시 (다음 앱 시작 시 다시 시도)
    }
  }
}
