import Flutter
import UIKit
import GoogleMaps  // <-- Add this import

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // Provide your real Google Maps API key here
    GMSServices.provideAPIKey("AIzaSyBsvPbA-EkeH3YM16tPb23XfDlf3rKrRrk")

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
