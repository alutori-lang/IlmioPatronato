import 'dart:io';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/scanned_document.dart';
import 'wallet_bridge.dart';

class ScannerService extends ChangeNotifier {
  static const _prefsKey = 'scanned_documents_v1';
  static const _docsSubdir = 'scanned_documents';

  List<ScannedDocument> _documents = [];
  bool _loaded = false;

  List<ScannedDocument> get documents =>
      List.unmodifiable(_documents.reversed);
  bool get isLoaded => _loaded;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        _documents = ScannedDocument.decodeList(raw);
        _documents.removeWhere((d) => !File(d.pdfPath).existsSync());
      } catch (_) {
        _documents = [];
      }
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, ScannedDocument.encodeList(_documents));
  }

  Future<Directory> _docsDir() async {
    final root = await getApplicationDocumentsDirectory();
    final dir = Directory('${root.path}/$_docsSubdir');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  static const _cameraChannel =
      MethodChannel('com.docflow.docflow_immigrati/camera_capture');
  static const _shareChannel =
      MethodChannel('com.docflow.docflow_immigrati/share');

  /// Sends a PDF directly to WhatsApp. Throws PlatformException
  /// with code "NOT_INSTALLED" if WhatsApp isn't on the device.
  Future<void> shareToWhatsApp({required String filePath, String text = ''}) {
    return _shareChannel.invokeMethod<void>('shareToWhatsApp', {
      'filePath': filePath,
      'text': text,
    });
  }

  /// Opens an email composer with the PDF attached. Throws PlatformException
  /// with code "NO_EMAIL_APP" if no email app is installed.
  Future<void> shareToEmail({
    required String filePath,
    String subject = '',
    String body = '',
  }) {
    return _shareChannel.invokeMethod<void>('shareToEmail', {
      'filePath': filePath,
      'subject': subject,
      'body': body,
    });
  }

  /// Ensures the camera permission is granted before opening the camera.
  Future<bool> _ensureCameraPermission() async {
    final status = await Permission.camera.status;
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) return false;
    final result = await Permission.camera.request();
    return result.isGranted;
  }

  /// Captures a single photo via the platform-native camera handler.
  /// Android: system camera intent. iOS: UIImagePickerController (.camera).
  Future<String?> _nativeCapture() async {
    try {
      final path = await _cameraChannel.invokeMethod<String>('captureImage');
      debugPrint('[Scanner] native capture path: $path');
      return path;
    } on PlatformException catch (e) {
      debugPrint('[Scanner] native capture PlatformException: ${e.code} ${e.message}');
      return null;
    } on MissingPluginException catch (e) {
      debugPrint('[Scanner] native capture MissingPluginException: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('[Scanner] native capture error: $e');
      return null;
    }
  }

  /// iOS-safe fallback: opens the standard system camera through image_picker.
  /// The Android-only [_nativeCapture] method channel does not exist on iOS,
  /// so VisionKit failures must fall through here instead.
  Future<String?> _imagePickerCapture() async {
    try {
      final picker = ImagePicker();
      final shot = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 92,
      );
      return shot?.path;
    } catch (e) {
      debugPrint('[Scanner] image_picker camera capture failed: $e');
      return null;
    }
  }

  /// Opens the document scanner.
  /// - iOS: native VisionKit (VNDocumentCameraViewController) via method channel.
  /// - Android: CunningDocumentScanner (ML Kit) with native camera intent fallback.
  Future<List<String>> scanPages({int maxPages = 100}) async {
    debugPrint('[Scanner] scanPages() called');
    final granted = await _ensureCameraPermission();
    if (!granted) {
      throw Exception(
        'Permesso fotocamera negato. Vai in Impostazioni > Bonus Italia e attiva Fotocamera.',
      );
    }

    if (Platform.isIOS) {
      try {
        final paths =
            await _cameraChannel.invokeListMethod<String>('scanDocument');
        debugPrint('[Scanner] iOS VisionKit returned ${paths?.length ?? 0} page(s)');
        return paths ?? [];
      } on PlatformException catch (e) {
        debugPrint('[Scanner] iOS scanner PlatformException: ${e.code} ${e.message}');
        if (e.code == 'UNAVAILABLE') {
          final path = await _imagePickerCapture();
          return path == null ? [] : [path];
        }
        throw Exception(e.message ?? 'Errore scanner (${e.code})');
      } on MissingPluginException {
        final path = await _imagePickerCapture();
        return path == null ? [] : [path];
      }
    }

    try {
      final mlKitPages = await CunningDocumentScanner.getPictures(
        noOfPages: maxPages,
        isGalleryImportAllowed: false,
      );
      if (mlKitPages != null && mlKitPages.isNotEmpty) {
        debugPrint('[Scanner] ML Kit returned ${mlKitPages.length} page(s)');
        return mlKitPages;
      }
      debugPrint('[Scanner] ML Kit returned no pages — user cancelled or empty');
      return [];
    } catch (e) {
      debugPrint('[Scanner] ML Kit failed: $e — falling back');
    }

    final path = Platform.isIOS
        ? await _imagePickerCapture()
        : await _nativeCapture();
    if (path == null) return [];
    return [path];
  }

  /// Single shot via camera, used by the "Aggiungi pagina" button.
  Future<List<String>> capturePage() async {
    final granted = await _ensureCameraPermission();
    if (!granted) {
      throw Exception('Permesso fotocamera negato');
    }
    final path = Platform.isIOS
        ? await _imagePickerCapture()
        : await _nativeCapture();
    if (path == null) return [];
    return [path];
  }

  /// Pick image(s) from gallery as scan pages.
  Future<List<String>> pickFromGallery({int max = 10}) async {
    final picker = ImagePicker();
    final shots = await picker.pickMultiImage(imageQuality: 92);
    if (shots.isEmpty) return [];
    return shots.take(max).map((x) => x.path).toList();
  }

  /// Builds a PDF from the given page paths and persists the document.
  Future<ScannedDocument> savePages({
    required String name,
    required List<String> pagePaths,
  }) async {
    if (pagePaths.isEmpty) {
      throw StateError('No pages to save');
    }

    final dir = await _docsDir();
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    final thumbFile = File('${dir.path}/${id}_thumb.jpg');
    await File(pagePaths.first).copy(thumbFile.path);

    final pdfFile = File('${dir.path}/$id.pdf');
    final pdfDoc = pw.Document(compress: true);
    for (final p in pagePaths) {
      final bytes = await File(p).readAsBytes();
      final image = pw.MemoryImage(bytes);
      pdfDoc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
          build: (ctx) => pw.Center(
            child: pw.Image(image, fit: pw.BoxFit.contain),
          ),
        ),
      );
    }
    await pdfFile.writeAsBytes(await pdfDoc.save());

    final doc = ScannedDocument(
      id: id,
      name: name.trim().isEmpty ? 'Documento' : name.trim(),
      pdfPath: pdfFile.path,
      thumbPath: thumbFile.path,
      pageCount: pagePaths.length,
      createdAt: DateTime.now(),
    );

    _documents.add(doc);
    await _persist();
    notifyListeners();

    try {
      await WalletBridge.autoSaveIfImportant(name: doc.name);
    } catch (_) {}

    return doc;
  }

  /// Legacy single-call helper kept for backwards compatibility.
  /// Opens the native scanner and saves the result with the given name.
  Future<ScannedDocument?> scanAndSave({required String name}) async {
    final pages = await scanPages();
    if (pages.isEmpty) return null;
    return savePages(name: name, pagePaths: pages);
  }

  Future<void> rename(String id, String newName) async {
    final idx = _documents.indexWhere((d) => d.id == id);
    if (idx < 0) return;
    _documents[idx] = _documents[idx].copyWith(name: newName.trim());
    await _persist();
    notifyListeners();
  }

  Future<void> delete(String id) async {
    final idx = _documents.indexWhere((d) => d.id == id);
    if (idx < 0) return;
    final doc = _documents[idx];
    for (final path in [doc.pdfPath, doc.thumbPath]) {
      final f = File(path);
      if (f.existsSync()) {
        try {
          f.deleteSync();
        } catch (_) {}
      }
    }
    _documents.removeAt(idx);
    await _persist();
    notifyListeners();
  }
}
