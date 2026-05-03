import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../config/constants.dart';
import '../../core/localization/app_strings.dart';
import '../../core/services/scanner_service.dart';
import '../../models/scanned_document.dart';

/// Anteprima delle pagine scansionate stile CamScanner.
/// Permette swipe tra pagine, rotazione, eliminazione, aggiunta nuove pagine,
/// rinominare e salvare come PDF.
class ScannerPreviewScreen extends StatefulWidget {
  final List<String> pagePaths;
  final String? suggestedName;

  const ScannerPreviewScreen({
    super.key,
    required this.pagePaths,
    this.suggestedName,
  });

  @override
  State<ScannerPreviewScreen> createState() => _ScannerPreviewScreenState();
}

class _ScannerPreviewScreenState extends State<ScannerPreviewScreen> {
  late List<String> _pages;
  late PageController _controller;
  int _currentIndex = 0;
  bool _saving = false;
  late TextEditingController _nameCtrl;
  // Mappa pageIndex -> rotation in 0/1/2/3 (multipli di 90°)
  final Map<int, int> _rotations = {};

  @override
  void initState() {
    super.initState();
    _pages = List<String>.from(widget.pagePaths);
    _controller = PageController();
    _nameCtrl = TextEditingController(text: widget.suggestedName ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _addFromCamera() async {
    final svc = context.read<ScannerService>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      final newPages = await svc.capturePage();
      if (newPages.isEmpty) return;
      setState(() {
        _pages.addAll(newPages);
        _currentIndex = _pages.length - 1;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_controller.hasClients) {
          _controller.jumpToPage(_currentIndex);
        }
      });
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Errore scansione: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _addFromGallery() async {
    final svc = context.read<ScannerService>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      final newPages = await svc.pickFromGallery();
      if (newPages.isEmpty) return;
      setState(() {
        _pages.addAll(newPages);
        _currentIndex = _pages.length - 1;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_controller.hasClients) {
          _controller.jumpToPage(_currentIndex);
        }
      });
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Errore galleria: $e'), backgroundColor: Colors.red));
    }
  }

  void _rotate() {
    setState(() {
      final cur = _rotations[_currentIndex] ?? 0;
      _rotations[_currentIndex] = (cur + 1) % 4;
    });
  }

  Future<void> _deleteCurrent() async {
    if (_pages.length == 1) {
      final close = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Eliminare l\'unica pagina?'),
          content: const Text('Se elimini l\'ultima pagina, l\'anteprima si chiuderà senza salvare.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annulla')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Esci', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
      if (close == true && mounted) Navigator.of(context).pop();
      return;
    }
    setState(() {
      _pages.removeAt(_currentIndex);
      // riallinea le rotazioni
      final newRotations = <int, int>{};
      _rotations.forEach((k, v) {
        if (k < _currentIndex) {
          newRotations[k] = v;
        } else if (k > _currentIndex) {
          newRotations[k - 1] = v;
        }
      });
      _rotations
        ..clear()
        ..addAll(newRotations);
      if (_currentIndex >= _pages.length) {
        _currentIndex = _pages.length - 1;
      }
    });
    if (_controller.hasClients) {
      _controller.jumpToPage(_currentIndex);
    }
  }

  Future<void> _save() async {
    final s = AppStrings.read(context);
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inserisci un nome per il documento')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      // Applico le rotazioni alle immagini prima del salvataggio
      final processedPaths = await _applyRotations();
      if (!mounted) return;
      final svc = context.read<ScannerService>();
      final doc = await svc.savePages(name: name, pagePaths: processedPaths);
      if (!mounted) return;
      await _showShareSheet(doc);
      if (!mounted) return;
      Navigator.of(context).pop(doc);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${s.scanError}: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _showShareSheet(ScannedDocument doc) async {
    final svc = context.read<ScannerService>();
    final messenger = ScaffoldMessenger.of(context);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Row(children: [
                const Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 26),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Documento salvato',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textDark),
                  ),
                ),
              ]),
              const SizedBox(height: 4),
              Text(
                '"${doc.name}" — ${doc.pageCount} pagin${doc.pageCount == 1 ? 'a' : 'e'}',
                style: const TextStyle(fontSize: 13, color: AppColors.textLight),
              ),
              const SizedBox(height: 18),
              Row(children: [
                Expanded(
                  child: _shareTile(
                    icon: Icons.chat_bubble,
                    label: 'WhatsApp',
                    color: const Color(0xFF25D366),
                    onTap: () async {
                      Navigator.pop(ctx);
                      try {
                        await svc.shareToWhatsApp(filePath: doc.pdfPath, text: doc.name);
                      } on PlatformException catch (e) {
                        messenger.showSnackBar(SnackBar(
                          content: Text(e.code == 'NOT_INSTALLED'
                              ? 'WhatsApp non è installato'
                              : 'Errore: ${e.message ?? e.code}'),
                          backgroundColor: Colors.red,
                        ));
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _shareTile(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    color: const Color(0xFF1976D2),
                    onTap: () async {
                      Navigator.pop(ctx);
                      try {
                        await svc.shareToEmail(
                          filePath: doc.pdfPath,
                          subject: doc.name,
                          body: 'Documento allegato: ${doc.name}',
                        );
                      } on PlatformException catch (e) {
                        messenger.showSnackBar(SnackBar(
                          content: Text(e.code == 'NO_EMAIL_APP'
                              ? 'Nessuna app email installata'
                              : 'Errore: ${e.message ?? e.code}'),
                          backgroundColor: Colors.red,
                        ));
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _shareTile(
                    icon: Icons.share,
                    label: 'Altro',
                    color: const Color(0xFF64748B),
                    onTap: () async {
                      Navigator.pop(ctx);
                      await Share.shareXFiles([XFile(doc.pdfPath)], subject: doc.name);
                    },
                  ),
                ),
              ]),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Chiudi', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shareTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Future<List<String>> _applyRotations() async {
    if (_rotations.isEmpty || _rotations.values.every((v) => v == 0)) {
      return List<String>.from(_pages);
    }
    final out = <String>[];
    for (var i = 0; i < _pages.length; i++) {
      final rot = _rotations[i] ?? 0;
      if (rot == 0) {
        out.add(_pages[i]);
      } else {
        final original = await File(_pages[i]).readAsBytes();
        final decoded = img.decodeImage(original);
        if (decoded == null) {
          out.add(_pages[i]);
          continue;
        }
        img.Image rotated = decoded;
        for (var k = 0; k < rot; k++) {
          rotated = img.copyRotate(rotated, angle: 90);
        }
        final bytes = Uint8List.fromList(img.encodeJpg(rotated, quality: 92));
        final outPath = '${_pages[i]}.rot$rot.jpg';
        await File(outPath).writeAsBytes(bytes);
        out.add(outPath);
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1A1A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0D2D5E),
          foregroundColor: Colors.white,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _saving ? null : () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Anteprima documento',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
          ),
          actions: [
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  '${_currentIndex + 1} / ${_pages.length}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(child: _buildPager()),
            _buildToolbar(),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildPager() {
    return Container(
      color: const Color(0xFF1A1A1A),
      child: PageView.builder(
        controller: _controller,
        itemCount: _pages.length,
        onPageChanged: (i) => setState(() => _currentIndex = i),
        itemBuilder: (_, i) {
          final rot = _rotations[i] ?? 0;
          return InteractiveViewer(
            minScale: 0.8,
            maxScale: 4,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: RotatedBox(
                  quarterTurns: rot,
                  child: Image.file(
                    File(_pages[i]),
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Container(
                      width: 200, height: 280,
                      color: Colors.white12,
                      child: const Icon(Icons.broken_image, color: Colors.white54, size: 48),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      color: const Color(0xFF222222),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _toolBtn(Icons.rotate_right, 'Ruota', _saving ? null : _rotate),
          _toolBtn(Icons.add_a_photo_outlined, 'Foto', _saving ? null : _addFromCamera),
          _toolBtn(Icons.photo_library_outlined, 'Galleria', _saving ? null : _addFromGallery),
          _toolBtn(Icons.delete_outline, 'Elimina', _saving ? null : _deleteCurrent, color: Colors.redAccent),
        ],
      ),
    );
  }

  Widget _toolBtn(IconData icon, String label, VoidCallback? onTap, {Color? color}) {
    final c = color ?? Colors.white;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: onTap == null ? c.withValues(alpha: 0.4) : c, size: 26),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: onTap == null ? c.withValues(alpha: 0.4) : c,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      child: Column(
        children: [
          TextField(
            controller: _nameCtrl,
            enabled: !_saving,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'Nome del documento (es. Carta d\'identità)',
              prefixIcon: const Icon(Icons.label_outline),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              icon: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.save_alt_rounded),
              label: Text(
                _saving ? 'Salvataggio...' : 'Salva PDF',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Risultato della Preview: il [ScannedDocument] salvato, o null se annullato.
typedef ScannerPreviewResult = ScannedDocument?;
