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
    // Guard: only configure when GoogleService-Info.plist is present in the
    // bundle so the app doesn't crash on simulators / CI where the plist has
    // not been added to the Xcode target yet.
    if FirebaseApp.app() == nil,
       Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil {
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
