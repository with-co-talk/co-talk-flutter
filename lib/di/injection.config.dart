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
import '../core/network/dio_client.dart' as _i393;
import '../core/network/websocket_service.dart' as _i682;
import '../core/router/app_router.dart' as _i877;
import '../core/services/desktop_notification_bridge.dart' as _i396;
import '../core/services/fcm_service.dart' as _i809;
import '../core/services/notification_service.dart' as _i570;
import '../core/window/window_focus_tracker.dart' as _i156;
import '../data/datasources/local/auth_local_datasource.dart' as _i860;
import '../data/datasources/local/chat_local_datasource.dart' as _i601;
import '../data/datasources/local/database/app_database.dart' as _i441;
import '../data/datasources/local/notification_local_datasource.dart' as _i64;
import '../data/datasources/remote/auth_remote_datasource.dart' as _i633;
import '../data/datasources/remote/chat_remote_datasource.dart' as _i397;
import '../data/datasources/remote/friend_remote_datasource.dart' as _i867;
import '../data/datasources/remote/notification_remote_datasource.dart'
    as _i708;
import '../data/datasources/remote/profile_remote_datasource.dart' as _i710;
import '../data/repositories/auth_repository_impl.dart' as _i74;
import '../data/repositories/chat_repository_impl.dart' as _i919;
import '../data/repositories/friend_repository_impl.dart' as _i364;
import '../data/repositories/notification_repository_impl.dart' as _i888;
import '../data/repositories/profile_repository_impl.dart' as _i953;
import '../domain/repositories/auth_repository.dart' as _i800;
import '../domain/repositories/chat_repository.dart' as _i792;
import '../domain/repositories/friend_repository.dart' as _i1069;
import '../domain/repositories/notification_repository.dart' as _i965;
import '../domain/repositories/profile_repository.dart' as _i217;
import '../presentation/blocs/auth/auth_bloc.dart' as _i525;
import '../presentation/blocs/chat/chat_list_bloc.dart' as _i995;
import '../presentation/blocs/chat/chat_room_bloc.dart' as _i995;
import '../presentation/blocs/chat/message_search/message_search_bloc.dart'
    as _i487;
import '../presentation/blocs/friend/friend_bloc.dart' as _i367;
import '../presentation/blocs/profile/profile_bloc.dart' as _i256;
import 'injection.dart' as _i464;

const String _mobile = 'mobile';
const String _desktop = 'desktop';

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final registerModule = _$RegisterModule();
    gh.singleton<_i682.WebSocketPayloadParser>(
      () => const _i682.WebSocketPayloadParser(),
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
    gh.lazySingleton<_i860.AuthLocalDataSource>(
      () => _i860.AuthLocalDataSourceImpl(gh<_i558.FlutterSecureStorage>()),
    );
    gh.lazySingleton<_i892.FirebaseMessaging>(
      () => registerModule.firebaseMessaging,
      registerFor: {_mobile},
    );
    gh.lazySingleton<_i809.FcmService>(
      () => _i809.NoOpFcmService(),
      registerFor: {_desktop},
    );
    gh.lazySingleton<_i64.NotificationLocalDataSource>(
      () => _i64.NotificationLocalDataSourceImpl(
        gh<_i558.FlutterSecureStorage>(),
      ),
    );
    gh.lazySingleton<_i552.AuthInterceptor>(
      () => _i552.AuthInterceptor(gh<_i860.AuthLocalDataSource>()),
    );
    gh.lazySingleton<_i601.ChatLocalDataSource>(
      () => _i601.ChatLocalDataSourceImpl(gh<_i441.AppDatabase>()),
    );
    gh.lazySingleton<_i682.WebSocketService>(
      () => _i682.WebSocketService(
        gh<_i860.AuthLocalDataSource>(),
        payloadParser: gh<_i682.WebSocketPayloadParser>(),
      ),
    );
    gh.lazySingleton<_i570.NotificationService>(
      () => _i570.NotificationService(
        plugin: gh<_i163.FlutterLocalNotificationsPlugin>(),
      ),
    );
    gh.lazySingleton<_i393.DioClient>(
      () => _i393.DioClient(gh<_i552.AuthInterceptor>()),
    );
    gh.lazySingleton<_i809.FcmService>(
      () => _i809.FcmServiceImpl(
        messaging: gh<_i892.FirebaseMessaging>(),
        notificationService: gh<_i570.NotificationService>(),
      ),
      registerFor: {_mobile},
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
    gh.lazySingleton<_i708.NotificationRemoteDataSource>(
      () => _i708.NotificationRemoteDataSourceImpl(gh<_i393.DioClient>()),
    );
    gh.lazySingleton<_i867.FriendRemoteDataSource>(
      () => _i867.FriendRemoteDataSourceImpl(gh<_i393.DioClient>()),
    );
    gh.lazySingleton<_i396.DesktopNotificationBridge>(
      () => _i396.DesktopNotificationBridge(
        notificationService: gh<_i570.NotificationService>(),
        webSocketService: gh<_i682.WebSocketService>(),
        windowFocusTracker: gh<_i156.WindowFocusTracker>(),
      ),
    );
    gh.lazySingleton<_i792.ChatRepository>(
      () => _i919.ChatRepositoryImpl(
        gh<_i397.ChatRemoteDataSource>(),
        gh<_i601.ChatLocalDataSource>(),
      ),
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
    gh.factory<_i995.ChatRoomBloc>(
      () => _i995.ChatRoomBloc(
        gh<_i792.ChatRepository>(),
        gh<_i682.WebSocketService>(),
        gh<_i860.AuthLocalDataSource>(),
        gh<_i396.DesktopNotificationBridge>(),
      ),
    );
    gh.lazySingleton<_i1069.FriendRepository>(
      () => _i364.FriendRepositoryImpl(gh<_i867.FriendRemoteDataSource>()),
    );
    gh.factory<_i487.MessageSearchBloc>(
      () => _i487.MessageSearchBloc(gh<_i792.ChatRepository>()),
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
    gh.factory<_i525.AuthBloc>(
      () => _i525.AuthBloc(
        gh<_i800.AuthRepository>(),
        gh<_i682.WebSocketService>(),
        gh<_i792.ChatRepository>(),
        gh<_i965.NotificationRepository>(),
        gh<_i396.DesktopNotificationBridge>(),
      ),
    );
    gh.factory<_i256.ProfileBloc>(
      () => _i256.ProfileBloc(
        gh<_i217.ProfileRepository>(),
        gh<_i800.AuthRepository>(),
      ),
    );
    gh.lazySingleton<_i877.AppRouter>(
      () => _i877.AppRouter(gh<_i525.AuthBloc>()),
    );
    return this;
  }
}

class _$RegisterModule extends _i464.RegisterModule {}
