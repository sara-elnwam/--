import Flutter
import UIKit
import flutter_downloader // استيراد المكتبة للتعامل مع التحميلات

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // تسجيل إضافة flutter_downloader لتعمل في الخلفية على iOS
    FlutterDownloader.register(with: self)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}