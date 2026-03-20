// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:firebase_messaging/firebase_messaging.dart' as _i892;
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as _i163;
import 'package:flutter_secure_storage/flutter_secure_storage.dart' as _i558;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

import '../core/network/auth_interceptor.dart' as _i552;
import '../core/network/certificate_pinning_interceptor.dart' as _i206;
import '../core/network/dio_client.dart' as _i393;
import '../core/network/websocket/websocket_event_parser.dart' as _i60;
import '../core/network/websocket_service.dart' as _i682;
import '../core/router/app_router.dart' as _i877;
import '../core/services/active_room_tracker.dart' as _i480;
import '../core/services/biometric_service.dart' as _i379;
import '../core/services/deep_link_service.dart' as _i1031;
import '../core/services/desktop_notification_bridge.dart' as _i396;
import '../core/services/fcm_service.dart' as _i809;
import '../core/services/image_editor_service.dart' as _i413;
import '../core/services/notification_click_handler.dart' as _i774;
import '../core/services/notification_service.dart' as _i570;
import '../core/window/window_focus_tracker.dart' as _i156;
import '../data/datasources/local/auth_local_datasource.dart' as _i860;
import '../data/datasources/local/chat_local_datasource.dart' as _i601;
import '../data/datasources/local/chat_settings_local_datasource.dart' as _i30;
import '../data/datasources/local/database/app_database.dart' as _i441;
import '../data/datasources/local/notification_local_datasource.dart' as _i64;
import '../data/datasources/local/security_settings_local_datasource.dart'
    as _i171;
import '../data/datasources/local/theme_local_datasource.dart' as _i632;
import '../data/datasources/remote/auth_remote_datasource.dart' as _i633;
import '../data/datasources/remote/chat_remote_datasource.dart' as _i397;
import '../data/datasources/remote/friend_remote_datasource.dart' as _i867;
import '../data/datasources/remote/link_preview_remote_datasource.dart'
    as _i577;
import '../data/datasources/remote/notification_remote_datasource.dart'
    as _i708;
import '../data/datasources/remote/profile_remote_datasource.dart' as _i710;
import '../data/datasources/remote/report_remote_datasource.dart' as _i738;
import '../data/datasources/remote/settings_remote_datasource.dart' as _i991;
import '../data/repositories/auth_repository_impl.dart' as _i74;
import '../data/repositories/chat_repository_impl.dart' as _i919;
import '../data/repositories/friend_repository_impl.dart' as _i364;
import '../data/repositories/link_preview_repository_impl.dart' as _i319;
import '../data/repositories/notification_repository_impl.dart' as _i888;
import '../data/repositories/profile_repository_impl.dart' as _i953;
import '../data/repositories/report_repository_impl.dart' as _i209;
import '../data/repositories/settings_repository_impl.dart' as _i453;
import '../domain/repositories/auth_repository.dart' as _i800;
import '../domain/repositories/chat_repository.dart' as _i792;
import '../domain/repositories/friend_repository.dart' as _i1069;
import '../domain/repositories/link_preview_repository.dart' as _i1014;
import '../domain/repositories/notification_repository.dart' as _i965;
import '../domain/repositories/profile_repository.dart' as _i217;
import '../domain/repositories/report_repository.dart' as _i426;
import '../domain/repositories/settings_repository.dart' as _i977;
import '../presentation/blocs/app/app_lock_cubit.dart' as _i232;
import '../presentation/blocs/auth/auth_bloc.dart' as _i525;
import '../presentation/blocs/auth/email_verification_bloc.dart' as _i389;
import '../presentation/blocs/chat/chat_list_bloc.dart' as _i995;
import '../presentation/blocs/chat/chat_room_bloc.dart' as _i995;
import '../presentation/blocs/chat/group_image_cubit.dart' as _i446;
import '../presentation/blocs/chat/media_gallery_bloc.dart' as _i580;
import '../presentation/blocs/chat/message_search/message_search_bloc.dart'
    as _i487;
import '../presentation/blocs/friend/friend_bloc.dart' as _i367;
import '../presentation/blocs/profile/profile_bloc.dart' as _i256;
import '../presentation/blocs/settings/account_deletion_bloc.dart' as _i3;
import '../presentation/blocs/settings/biometric_settings_cubit.dart' as _i884;
import '../presentation/blocs/settings/change_password_bloc.dart' as _i870;
import '../presentation/blocs/settings/chat_settings_cubit.dart' as _i110;
import '../presentation/blocs/settings/notification_settings_cubit.dart'
    as _i728;
import '../presentation/blocs/theme/theme_cubit.dart' as _i450;
import 'injection.dart' as _i464;

const String _desktop = 'desktop';
const String _mobile = 'mobile';

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final registerModule = _$RegisterModule();
    gh.singleton<_i60.WebSocketPayloadParser>(
      () => const _i60.WebSocketPayloadParser(),
    );
    gh.lazySingleton<_i558.FlutterSecureStorage>(
      () => registerModule.secureStorage,
    );
    gh.lazySingleton<_i441.AppDatabase>(() => registerModule.appDatabase);
    gh.lazySingleton<_i163.FlutterLocalNotificationsPlugin>(
      () => registerModule.localNotificationsPlugin,
    );
    gh.lazySingleton<_i156.WindowFocusTracker>(
      () => registerModule.windowFocusTracker,
    );
    gh.lazySingleton<_i206.CertificatePinningInterceptor>(
      () => _i206.CertificatePinningInterceptor(),
    );
    gh.lazySingleton<_i379.BiometricService>(() => _i379.BiometricService());
    gh.lazySingleton<_i480.ActiveRoomTracker>(() => _i480.ActiveRoomTracker());
    gh.lazySingleton<_i413.ImageEditorService>(
      () => _i413.ImageEditorService(),
    );
    gh.lazySingleton<_i632.ThemeLocalDataSource>(
      () => _i632.ThemeLocalDataSourceImpl(),
    );
    gh.lazySingleton<_i30.ChatSettingsLocalDataSource>(
      () => _i30.ChatSettingsLocalDataSourceImpl(),
    );
    gh.lazySingleton<_i860.AuthLocalDataSource>(
      () => _i860.AuthLocalDataSourceImpl(gh<_i558.FlutterSecureStorage>()),
    );
    gh.lazySingleton<_i809.FcmService>(
      () => _i809.NoOpFcmService(),
      registerFor: {_desktop},
    );
    gh.lazySingleton<_i171.SecuritySettingsLocalDataSource>(
      () => _i171.SecuritySettingsLocalDataSource(
        gh<_i558.FlutterSecureStorage>(),
      ),
    );
    gh.lazySingleton<_i64.NotificationLocalDataSource>(
      () => _i64.NotificationLocalDataSourceImpl(
        gh<_i558.FlutterSecureStorage>(),
      ),
    );
    gh.lazySingleton<_i552.AuthInterceptor>(
      () => _i552.AuthInterceptor(gh<_i860.AuthLocalDataSource>()),
    );
    gh.lazySingleton<_i232.AppLockCubit>(
      () => _i232.AppLockCubit(
        gh<_i379.BiometricService>(),
        gh<_i171.SecuritySettingsLocalDataSource>(),
      ),
    );
    gh.lazySingleton<_i682.WebSocketService>(
      () => _i682.WebSocketService(
        gh<_i860.AuthLocalDataSource>(),
        payloadParser: gh<_i682.WebSocketPayloadParser>(),
      ),
      dispose: (i) => i.dispose(),
    );
    gh.lazySingleton<_i601.ChatLocalDataSource>(
      () => _i601.ChatLocalDataSourceImpl(gh<_i441.AppDatabase>()),
    );
    gh.lazySingleton<_i393.DioClient>(
      () => _i393.DioClient(
        gh<_i552.AuthInterceptor>(),
        gh<_i206.CertificatePinningInterceptor>(),
      ),
    );
    gh.lazySingleton<_i570.NotificationService>(
      () => _i570.NotificationService(
        plugin: gh<_i163.FlutterLocalNotificationsPlugin>(),
      ),
    );
    gh.lazySingleton<_i450.ThemeCubit>(
      () => _i450.ThemeCubit(gh<_i632.ThemeLocalDataSource>()),
    );
    gh.lazySingleton<_i991.SettingsRemoteDataSource>(
      () => _i991.SettingsRemoteDataSourceImpl(gh<_i393.DioClient>()),
    );
    gh.lazySingleton<_i577.LinkPreviewRemoteDataSource>(
      () => _i577.LinkPreviewRemoteDataSourceImpl(gh<_i393.DioClient>()),
    );
    gh.lazySingleton<_i738.ReportRemoteDataSource>(
      () => _i738.ReportRemoteDataSourceImpl(gh<_i393.DioClient>()),
    );
    gh.lazySingleton<_i1014.LinkPreviewRepository>(
      () => _i319.LinkPreviewRepositoryImpl(
        gh<_i577.LinkPreviewRemoteDataSource>(),
      ),
    );
    gh.lazySingleton<_i633.AuthRemoteDataSource>(
      () => _i633.AuthRemoteDataSourceImpl(gh<_i393.DioClient>()),
    );
    gh.lazySingleton<_i710.ProfileRemoteDataSource>(
      () => _i710.ProfileRemoteDataSourceImpl(gh<_i393.DioClient>()),
    );
    gh.lazySingleton<_i397.ChatRemoteDataSource>(
      () => _i397.ChatRemoteDataSourceImpl(
        gh<_i393.DioClient>(),
        gh<_i860.AuthLocalDataSource>(),
      ),
    );
    gh.factory<_i884.BiometricSettingsCubit>(
      () => _i884.BiometricSettingsCubit(
        gh<_i379.BiometricService>(),
        gh<_i171.SecuritySettingsLocalDataSource>(),
        gh<_i232.AppLockCubit>(),
      ),
    );
    gh.lazySingleton<_i708.NotificationRemoteDataSource>(
      () => _i708.NotificationRemoteDataSourceImpl(gh<_i393.DioClient>()),
    );
    gh.lazySingleton<_i867.FriendRemoteDataSource>(
      () => _i867.FriendRemoteDataSourceImpl(gh<_i393.DioClient>()),
    );
    gh.lazySingleton<_i426.ReportRepository>(
      () => _i209.ReportRepositoryImpl(gh<_i738.ReportRemoteDataSource>()),
    );
    gh.lazySingleton<_i792.ChatRepository>(
      () => _i919.ChatRepositoryImpl(
        gh<_i397.ChatRemoteDataSource>(),
        gh<_i601.ChatLocalDataSource>(),
      ),
    );
    gh.factory<_i580.MediaGalleryBloc>(
      () => _i580.MediaGalleryBloc(gh<_i397.ChatRemoteDataSource>()),
    );
    gh.lazySingleton<_i800.AuthRepository>(
      () => _i74.AuthRepositoryImpl(
        gh<_i633.AuthRemoteDataSource>(),
        gh<_i860.AuthLocalDataSource>(),
      ),
    );
    gh.lazySingleton<_i965.NotificationRepository>(
      () => _i888.NotificationRepositoryImpl(
        gh<_i64.NotificationLocalDataSource>(),
        gh<_i708.NotificationRemoteDataSource>(),
        gh<_i809.FcmService>(),
      ),
    );
    gh.lazySingleton<_i977.SettingsRepository>(
      () => _i453.SettingsRepositoryImpl(
        gh<_i991.SettingsRemoteDataSource>(),
        gh<_i30.ChatSettingsLocalDataSource>(),
      ),
    );
    gh.factory<_i389.EmailVerificationBloc>(
      () => _i389.EmailVerificationBloc(gh<_i800.AuthRepository>()),
    );
    gh.lazySingleton<_i1069.FriendRepository>(
      () => _i364.FriendRepositoryImpl(gh<_i867.FriendRemoteDataSource>()),
    );
    gh.factory<_i487.MessageSearchBloc>(
      () => _i487.MessageSearchBloc(gh<_i792.ChatRepository>()),
    );
    gh.factory<_i446.GroupImageCubit>(
      () => _i446.GroupImageCubit(gh<_i792.ChatRepository>()),
    );
    gh.lazySingleton<_i110.ChatSettingsCubit>(
      () => _i110.ChatSettingsCubit(gh<_i977.SettingsRepository>()),
    );
    gh.lazySingleton<_i728.NotificationSettingsCubit>(
      () => _i728.NotificationSettingsCubit(gh<_i977.SettingsRepository>()),
    );
    gh.lazySingleton<_i217.ProfileRepository>(
      () => _i953.ProfileRepositoryImpl(gh<_i710.ProfileRemoteDataSource>()),
    );
    gh.lazySingleton<_i995.ChatListBloc>(
      () => _i995.ChatListBloc(
        gh<_i792.ChatRepository>(),
        gh<_i682.WebSocketService>(),
        gh<_i860.AuthLocalDataSource>(),
      ),
    );
    gh.factory<_i367.FriendBloc>(
      () => _i367.FriendBloc(
        gh<_i1069.FriendRepository>(),
        gh<_i682.WebSocketService>(),
      ),
    );
    gh.factory<_i870.ChangePasswordBloc>(
      () => _i870.ChangePasswordBloc(gh<_i977.SettingsRepository>()),
    );
    gh.factory<_i3.AccountDeletionBloc>(
      () => _i3.AccountDeletionBloc(
        gh<_i977.SettingsRepository>(),
        gh<_i800.AuthRepository>(),
      ),
    );
    gh.lazySingleton<_i809.FcmService>(
      () => _i809.FcmServiceImpl(
        messaging: gh<_i892.FirebaseMessaging>(),
        notificationService: gh<_i570.NotificationService>(),
        settingsRepository: gh<_i977.SettingsRepository>(),
        activeRoomTracker: gh<_i480.ActiveRoomTracker>(),
      ),
      registerFor: {_mobile},
    );
    gh.lazySingleton<_i396.DesktopNotificationBridge>(
      () => _i396.DesktopNotificationBridge(
        notificationService: gh<_i570.NotificationService>(),
        webSocketService: gh<_i682.WebSocketService>(),
        windowFocusTracker: gh<_i156.WindowFocusTracker>(),
        settingsRepository: gh<_i977.SettingsRepository>(),
      ),
    );
    gh.factory<_i256.ProfileBloc>(
      () => _i256.ProfileBloc(
        gh<_i217.ProfileRepository>(),
        gh<_i800.AuthRepository>(),
      ),
    );
    gh.factory<_i995.ChatRoomBloc>(
      () => _i995.ChatRoomBloc(
        gh<_i792.ChatRepository>(),
        gh<_i682.WebSocketService>(),
        gh<_i860.AuthLocalDataSource>(),
        gh<_i396.DesktopNotificationBridge>(),
        gh<_i480.ActiveRoomTracker>(),
        gh<_i1069.FriendRepository>(),
        gh<_i977.SettingsRepository>(),
      ),
    );
    gh.factory<_i525.AuthBloc>(
      () => _i525.AuthBloc(
        gh<_i800.AuthRepository>(),
        gh<_i682.WebSocketService>(),
        gh<_i792.ChatRepository>(),
        gh<_i965.NotificationRepository>(),
        gh<_i396.DesktopNotificationBridge>(),
      ),
    );
    gh.lazySingleton<_i877.AppRouter>(
      () => _i877.AppRouter(gh<_i525.AuthBloc>()),
    );
    gh.lazySingleton<_i774.NotificationClickHandler>(
      () => _i774.NotificationClickHandler(
        notificationService: gh<_i570.NotificationService>(),
        appRouter: gh<_i877.AppRouter>(),
        activeRoomTracker: gh<_i480.ActiveRoomTracker>(),
      ),
    );
    gh.lazySingleton<_i1031.DeepLinkService>(
      () => _i1031.DeepLinkService(gh<_i877.AppRouter>()),
    );
    return this;
  }
}

class _$RegisterModule extends _i464.RegisterModule {}
