import Flutter
import UIKit
import FirebaseCore

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Initialise Firebase before the Flutter engine starts so
    // Firebase.initializeApp() on the Dart side picks up the default app.
    // Reads GoogleService-Info.plist from the Runner bundle.
    if FirebaseApp.app() == nil {
      FirebaseApp.configure()
    }

    // APNs registration is forwarded to FCM automatically because
    // FirebaseAppDelegateProxyEnabled = true in Info.plist (default).
    // The firebase_messaging Flutter plugin sets the UNUserNotificationCenter
    // delegate, so no manual delegate wiring is required here.

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
