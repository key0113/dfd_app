import UIKit
import Flutter
import AppTrackingTransparency

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
    
    override func applicationDidBecomeActive(_ application: UIApplication) {
        super.applicationDidBecomeActive(application)
        if #available(iOS 14, *) {
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                ATTrackingManager.requestTrackingAuthorization { status in
                    print("requestTrackingAuthorization - \(status)")
                }
            }
        }
    }

}

