import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Observe screen recording and screenshot events
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(screenCaptureChanged),
      name: UIScreen.capturedDidChangeNotification,
      object: nil
    )

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(userDidTakeScreenshot),
      name: UIApplication.userDidTakeScreenshotNotification,
      object: nil
    )

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  @objc func screenCaptureChanged() {
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      if UIScreen.main.isCaptured {
        // Hide sensitive content while screen recording is active
        self.window?.isHidden = true
      } else {
        self.window?.isHidden = false
      }
    }
  }

  @objc func userDidTakeScreenshot() {
    // Briefly hide content when a screenshot is taken
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      self.window?.isHidden = true
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
        self.window?.isHidden = false
      }
    }
  }
}
