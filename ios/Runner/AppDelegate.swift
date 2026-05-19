import Flutter
import UIKit
import VisionKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {

  private var scannerHandler: DocumentScannerHandler?
  private var imagePickerHandler: ImagePickerHandler?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "RunnerAppDelegate") {
      setupChannels(messenger: registrar.messenger())
    }
  }

  private func setupChannels(messenger: FlutterBinaryMessenger) {
    let cameraChannel = FlutterMethodChannel(
      name: "com.docflow.docflow_immigrati/camera_capture",
      binaryMessenger: messenger
    )
    cameraChannel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { return }
      switch call.method {
      case "scanDocument":
        self.scanDocument(result: result)
      case "captureImage":
        self.captureImage(result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    let shareChannel = FlutterMethodChannel(
      name: "com.docflow.docflow_immigrati/share",
      binaryMessenger: messenger
    )
    shareChannel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { return }
      switch call.method {
      case "shareToWhatsApp", "shareToEmail":
        self.shareFile(call: call, result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  // Scene-safe top view controller lookup (replaces deprecated keyWindow path).
  private func topViewController() -> UIViewController? {
    let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    let scene = scenes.first(where: { $0.activationState == .foregroundActive }) ?? scenes.first
    let window = scene?.windows.first(where: { $0.isKeyWindow }) ?? scene?.windows.first
    var top = window?.rootViewController
    while let presented = top?.presentedViewController { top = presented }
    return top
  }

  private func scanDocument(result: @escaping FlutterResult) {
    guard VNDocumentCameraViewController.isSupported else {
      result(FlutterError(code: "UNAVAILABLE", message: "Scanner non supportato su questo dispositivo", details: nil))
      return
    }
    guard let presenter = topViewController() else {
      result(FlutterError(code: "NO_PRESENTER", message: "Nessuna finestra disponibile", details: nil))
      return
    }
    let scanner = VNDocumentCameraViewController()
    let handler = DocumentScannerHandler { [weak self] paths, error in
      self?.scannerHandler = nil
      if let error = error {
        result(FlutterError(code: "SCAN_ERROR", message: error.localizedDescription, details: nil))
      } else {
        result(paths ?? [])
      }
    }
    self.scannerHandler = handler
    scanner.delegate = handler
    scanner.modalPresentationStyle = .fullScreen
    presenter.present(scanner, animated: true)
  }

  private func captureImage(result: @escaping FlutterResult) {
    guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
      result(FlutterError(code: "NO_CAMERA", message: "Fotocamera non disponibile", details: nil))
      return
    }
    guard let presenter = topViewController() else {
      result(FlutterError(code: "NO_PRESENTER", message: "Nessuna finestra disponibile", details: nil))
      return
    }
    let picker = UIImagePickerController()
    picker.sourceType = .camera
    picker.cameraCaptureMode = .photo
    let handler = ImagePickerHandler { [weak self] path in
      self?.imagePickerHandler = nil
      result(path)
    }
    self.imagePickerHandler = handler
    picker.delegate = handler
    picker.modalPresentationStyle = .fullScreen
    presenter.present(picker, animated: true)
  }

  private func shareFile(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let filePath = args["filePath"] as? String,
          !filePath.isEmpty else {
      result(FlutterError(code: "MISSING_ARG", message: "filePath required", details: nil))
      return
    }
    guard FileManager.default.fileExists(atPath: filePath) else {
      result(FlutterError(code: "FILE_NOT_FOUND", message: "File non trovato", details: nil))
      return
    }
    let url = URL(fileURLWithPath: filePath)
    let text = (args["text"] as? String) ?? (args["body"] as? String) ?? ""
    var items: [Any] = [url]
    if !text.isEmpty { items.append(text) }

    guard let presenter = topViewController() else {
      result(FlutterError(code: "NO_PRESENTER", message: "Nessuna finestra disponibile", details: nil))
      return
    }
    let activity = UIActivityViewController(activityItems: items, applicationActivities: nil)
    if let popover = activity.popoverPresentationController {
      popover.sourceView = presenter.view
      popover.sourceRect = CGRect(x: presenter.view.bounds.midX, y: presenter.view.bounds.midY, width: 0, height: 0)
      popover.permittedArrowDirections = []
    }
    activity.completionWithItemsHandler = { _, _, _, _ in
      result(true)
    }
    presenter.present(activity, animated: true)
  }
}

private class DocumentScannerHandler: NSObject, VNDocumentCameraViewControllerDelegate {
  let completion: ([String]?, Error?) -> Void
  init(completion: @escaping ([String]?, Error?) -> Void) { self.completion = completion }

  func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
    let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
      .appendingPathComponent("scanner_pages", isDirectory: true)
    try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    let ts = Int(Date().timeIntervalSince1970 * 1000)
    var paths: [String] = []
    for i in 0..<scan.pageCount {
      let image = scan.imageOfPage(at: i)
      let url = dir.appendingPathComponent("scan_\(ts)_\(i).jpg")
      if let data = image.jpegData(compressionQuality: 0.92) {
        do {
          try data.write(to: url)
          paths.append(url.path)
        } catch {
          // skip page on write failure
        }
      }
    }
    controller.dismiss(animated: true) { [weak self] in
      self?.completion(paths, nil)
    }
  }

  func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
    controller.dismiss(animated: true) { [weak self] in
      self?.completion([], nil)
    }
  }

  func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
    controller.dismiss(animated: true) { [weak self] in
      self?.completion(nil, error)
    }
  }
}

private class ImagePickerHandler: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  let completion: (String?) -> Void
  init(completion: @escaping (String?) -> Void) { self.completion = completion }

  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
    let image = (info[.editedImage] as? UIImage) ?? (info[.originalImage] as? UIImage)
    picker.dismiss(animated: true) { [weak self] in
      guard let image = image, let data = image.jpegData(compressionQuality: 0.92) else {
        self?.completion(nil); return
      }
      let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("captures", isDirectory: true)
      try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
      let url = dir.appendingPathComponent("capture_\(Int(Date().timeIntervalSince1970 * 1000)).jpg")
      try? data.write(to: url)
      self?.completion(url.path)
    }
  }

  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    picker.dismiss(animated: true) { [weak self] in
      self?.completion(nil)
    }
  }
}
