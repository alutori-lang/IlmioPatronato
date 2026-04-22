import 'dart:io';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/scanned_document.dart';

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

  /// Launches the native Google ML Kit scanner. Returns null if cancelled.
  Future<ScannedDocument?> scanAndSave({required String name}) async {
    final pages = await CunningDocumentScanner.getPictures(
      noOfPages: 100,
      isGalleryImportAllowed: true,
    );
    if (pages == null || pages.isEmpty) return null;

    final dir = await _docsDir();
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    final thumbFile = File('${dir.path}/${id}_thumb.jpg');
    await File(pages.first).copy(thumbFile.path);

    final pdfFile = File('${dir.path}/$id.pdf');
    final pdfDoc = pw.Document(compress: true);
    for (final p in pages) {
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
      pageCount: pages.length,
      createdAt: DateTime.now(),
    );

    _documents.add(doc);
    await _persist();
    notifyListeners();
    return doc;
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
