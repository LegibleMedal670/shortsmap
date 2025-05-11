import UIKit
import Flutter
import GoogleMaps
import FBSDKCoreKit   // ← Facebook SDK import

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // 1. Facebook SDK 초기화
    ApplicationDelegate.shared.application(
      application,
      didFinishLaunchingWithOptions: launchOptions
    )

    GMSServices.provideAPIKey("AIzaSyC0fC5Xjg33ZeaBChPXIK-ijjblzI4SnB4")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}