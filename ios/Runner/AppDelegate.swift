import Flutter
import UIKit
import FirebaseMessaging

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // 새 implicit-engine AppDelegate 패턴에서는 firebase_messaging의 자동 APNs 등록이
    // 트리거되지 않는다. 원격 알림 등록을 명시적으로 호출해야 APNs 토큰이 발급되고,
    // 이어서 FCM 토큰 발급/서버 등록이 가능해진다.
    application.registerForRemoteNotifications()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // APNs 디바이스 토큰 수신 시 Firebase Messaging에 직접 전달한다.
  // (implicit-engine 패턴에서는 Firebase의 메서드 스위즐링이 자동 전달하지 못함)
  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    Messaging.messaging().apnsToken = deviceToken
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
