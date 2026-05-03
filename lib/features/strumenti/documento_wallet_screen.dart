import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/constants.dart';
import '../../core/services/scanner_service.dart';

// ---------------------------------------------------------------------------
// Data model — wallet documents are now photo-first.
// nome (required) + dataScadenza (optional) + imagePath.
// Legacy fields (tipoKey/numero/dataRilascio/note) are kept in JSON so old
// entries created before this rewrite still load.
// ---------------------------------------------------------------------------
class _Documento {
  final String id;
  final String nome;
  final String imagePath; // empty for legacy entries without a photo
  final DateTime? dataScadenza;
  // Legacy / pass-through:
  final String tipoKey;
  final String numero;
  final DateTime? dataRilascio;
  final String note;

  _Documento({
    required this.id,
    required this.nome,
    this.imagePath = '',
    this.dataScadenza,
    this.tipoKey = '',
    this.numero = '',
    this.dataRilascio,
    this.note = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'imagePath': imagePath,
        'dataScadenza': dataScadenza?.toIso8601String(),
        'tipoKey': tipoKey,
        'numero': numero,
        'dataRilascio': dataRilascio?.toIso8601String(),
        'note': note,
      };

  factory _Documento.fromJson(Map<String, dynamic> j) => _Documento(
        id: j['id'] as String,
        nome: (j['nome'] as String?) ?? '',
        imagePath: (j['imagePath'] as String?) ?? '',
        dataScadenza: j['dataScadenza'] != null
            ? DateTime.tryParse(j['dataScadenza'] as String)
            : null,
        tipoKey: (j['tipoKey'] as String?) ?? '',
        numero: (j['numero'] as String?) ?? '',
        dataRilascio: j['dataRilascio'] != null
            ? DateTime.tryParse(j['dataRilascio'] as String)
            : null,
        note: (j['note'] as String?) ?? '',
      );

  int? get giorniRimanenti {
    if (dataScadenza == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final scad = DateTime(dataScadenza!.year, dataScadenza!.month, dataScadenza!.day);
    return scad.difference(today).inDays;
  }

  Color get coloreScadenza {
    final g = giorniRimanenti;
    if (g == null) return AppColors.textMedium;
    if (g < 0) return const Color(0xFF212121);
    if (g < 30) return const Color(0xFFC62828);
    if (g < 90) return const Color(0xFFE65100);
    return const Color(0xFF2E7D32);
  }

  _Documento copyWith({
    String? nome,
    String? imagePath,
    DateTime? dataScadenza,
    bool clearScadenza = false,
  }) {
    return _Documento(
      id: id,
      nome: nome ?? this.nome,
      imagePath: imagePath ?? this.imagePath,
      dataScadenza: clearScadenza ? null : (dataScadenza ?? this.dataScadenza),
      tipoKey: tipoKey,
      numero: numero,
      dataRilascio: dataRilascio,
      note: note,
    );
  }
}

const _kStorageKey = 'documento_wallet_items';
const _kImagesSubdir = 'wallet_documents';

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------
class DocumentoWalletScreen extends StatefulWidget {
  const DocumentoWalletScreen({super.key});

  @override
  State<DocumentoWalletScreen> createState() => _DocumentoWalletScreenState();
}

class _DocumentoWalletScreenState extends State<DocumentoWalletScreen> {
  List<_Documento> _documenti = [];
  bool _loading = true;
  bool _gridView = true; // default = preview grid
  String _query = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── persistence ──────────────────────────────────────────────────────────
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kStorageKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw) as List;
        _documenti = list
            .map((e) => _Documento.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        _documenti = [];
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kStorageKey,
      jsonEncode(_documenti.map((d) => d.toJson()).toList()),
    );
  }

  void _upsert(_Documento d) {
    setState(() {
      final i = _documenti.indexWhere((x) => x.id == d.id);
      if (i >= 0) {
        _documenti[i] = d;
      } else {
        _documenti.add(d);
      }
    });
    _save();
  }

  Future<void> _delete(_Documento d) async {
    setState(() => _documenti.removeWhere((x) => x.id == d.id));
    await _save();
    if (d.imagePath.isNotEmpty) {
      final f = File(d.imagePath);
      if (f.existsSync()) {
        try {
          f.deleteSync();
        } catch (_) {}
      }
    }
  }

  // ── filtering ────────────────────────────────────────────────────────────
  List<_Documento> get _filtered {
    if (_query.isEmpty) return _documenti;
    final q = _query.toLowerCase();
    return _documenti.where((d) => d.nome.toLowerCase().contains(q)).toList();
  }

  List<_Documento> get _alertDocumenti {
    return _documenti.where((d) {
      final g = d.giorniRimanenti;
      return g != null && g >= 0 && g <= 60;
    }).toList()
      ..sort((a, b) => a.giorniRimanenti!.compareTo(b.giorniRimanenti!));
  }

  // ── add / edit flow ──────────────────────────────────────────────────────
  Future<String?> _captureImage(_AddSource source) async {
    final svc = context.read<ScannerService>();
    if (source == _AddSource.camera) {
      final pages = await svc.scanPages(maxPages: 1);
      if (pages.isEmpty) return null;
      return pages.first;
    } else {
      final picker = ImagePicker();
      final shot = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 92,
      );
      return shot?.path;
    }
  }

  Future<String> _persistImage(String sourcePath, String id) async {
    final root = await getApplicationDocumentsDirectory();
    final dir = Directory('${root.path}/$_kImagesSubdir');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    final ext = sourcePath.toLowerCase().endsWith('.png') ? 'png' : 'jpg';
    final dest = File('${dir.path}/$id.$ext');
    await File(sourcePath).copy(dest.path);
    return dest.path;
  }

  Future<void> _onAddPressed() async {
    final source = await _pickSource();
    if (source == null || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    String? imgPath;
    try {
      imgPath = await _captureImage(source);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Errore acquisizione: $e'), backgroundColor: Colors.red));
      return;
    }
    if (imgPath == null || !mounted) return;

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final stored = await _persistImage(imgPath, id);
    if (!mounted) return;

    final draft = _Documento(id: id, nome: '', imagePath: stored);
    final saved = await _showFormSheet(draft, isNew: true);
    if (saved == null) {
      // user cancelled — clean up the image
      final f = File(stored);
      if (f.existsSync()) {
        try {
          f.deleteSync();
        } catch (_) {}
      }
      return;
    }
    _upsert(saved);
  }

  Future<_AddSource?> _pickSource() async {
    return showModalBottomSheet<_AddSource>(
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
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const Text('Aggiungi documento',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textDark)),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: _sourceTile(
                    icon: Icons.photo_camera_rounded,
                    label: 'Scatta foto',
                    color: const Color(0xFF1976D2),
                    onTap: () => Navigator.pop(ctx, _AddSource.camera),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _sourceTile(
                    icon: Icons.photo_library_rounded,
                    label: 'Da galleria',
                    color: const Color(0xFF2E7D32),
                    onTap: () => Navigator.pop(ctx, _AddSource.gallery),
                  ),
                ),
              ]),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sourceTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }

  Future<_Documento?> _showFormSheet(_Documento draft, {required bool isNew}) {
    return showModalBottomSheet<_Documento>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DocumentoFormSheet(initial: draft, isNew: isNew),
    );
  }

  Future<void> _editDocumento(_Documento d) async {
    final saved = await _showFormSheet(d, isNew: false);
    if (saved != null) _upsert(saved);
  }

  Future<void> _confirmDelete(_Documento d) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Elimina documento'),
        content: Text('Vuoi eliminare "${d.nome}" dal tuo wallet?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annulla')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Elimina', style: TextStyle(color: Color(0xFFC62828))),
          ),
        ],
      ),
    );
    if (ok == true) await _delete(d);
  }

  // ── build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: _buildFab(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildHeader(),
                if (_alertDocumenti.isNotEmpty) _buildAlertBanner(),
                _buildToolbar(),
                Expanded(
                  child: _documenti.isEmpty
                      ? _buildEmptyState()
                      : _filtered.isEmpty
                          ? _buildNoResults()
                          : _gridView
                              ? _buildGrid()
                              : _buildList(),
                ),
              ],
            ),
    );
  }

  // header
  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 20, right: 20, bottom: 14,
      ),
      decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF1976D2), Color(0xFF42A5F5)]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PORTAFOGLIO',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              SizedBox(height: 1),
              Text('Foto dei tuoi documenti',
                  style: TextStyle(color: AppColors.textSubtitle, fontSize: 11)),
            ],
          ),
        ),
      ]),
    );
  }

  // alert banner (urgent expirations)
  Widget _buildAlertBanner() {
    final first = _alertDocumenti.first;
    final g = first.giorniRimanenti!;
    final msg = g == 0
        ? 'ATTENZIONE! "${first.nome}" scade oggi!'
        : 'ATTENZIONE! "${first.nome}" scade tra $g giorn${g == 1 ? 'o' : 'i'}!';
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFB74D)),
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFE65100).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFE65100), size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(msg,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFE65100))),
        ),
      ]),
    );
  }

  // toolbar (search + view toggle + count)
  Widget _buildToolbar() {
    if (_documenti.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Cerca documento...',
                  hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 14),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textLight, size: 22),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMedium),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _query = '');
                          },
                        ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _viewBtn(Icons.grid_view_rounded, true),
                _viewBtn(Icons.view_list_rounded, false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _viewBtn(IconData icon, bool grid) {
    final selected = _gridView == grid;
    return InkWell(
      onTap: () => setState(() => _gridView = grid),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 20,
            color: selected ? AppColors.primary : AppColors.textMedium),
      ),
    );
  }

  // grid view (default — preview-first)
  Widget _buildGrid() {
    final docs = _filtered;
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.78,
      ),
      itemCount: docs.length,
      itemBuilder: (_, i) => _DocCardGrid(
        documento: docs[i],
        onTap: () => _editDocumento(docs[i]),
        onDelete: () => _confirmDelete(docs[i]),
      ),
    );
  }

  // list view
  Widget _buildList() {
    final docs = _filtered;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
      itemCount: docs.length,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _DocCardList(
          documento: docs[i],
          onTap: () => _editDocumento(docs[i]),
          onDelete: () => _confirmDelete(docs[i]),
        ),
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 60, color: AppColors.textLight.withValues(alpha: 0.6)),
            const SizedBox(height: 14),
            Text('Nessun documento trovato per "$_query"',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: AppColors.textMedium, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.folder_open_rounded, size: 48, color: AppColors.primary.withValues(alpha: 0.4)),
            ),
            const SizedBox(height: 24),
            const Text('Il tuo wallet è vuoto',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark)),
            const SizedBox(height: 10),
            const Text(
              'Scatta una foto al tuo documento o\ncaricalo dalla galleria.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textMedium, height: 1.5),
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: _onAddPressed,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  gradient: AppColors.buttonGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text('Aggiungi documento',
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFab() {
    if (_documenti.isEmpty) return const SizedBox.shrink();
    return GestureDetector(
      onTap: _onAddPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: AppColors.buttonGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6)),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('AGGIUNGI',
                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }
}

enum _AddSource { camera, gallery }

// ===========================================================================
// Grid card — preview-first
// ===========================================================================
class _DocCardGrid extends StatelessWidget {
  final _Documento documento;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _DocCardGrid({
    required this.documento,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final g = documento.giorniRimanenti;
    return GestureDetector(
      onTap: onTap,
      onLongPress: onDelete,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildPreview(),
                    if (g != null)
                      Positioned(
                        top: 8, right: 8,
                        child: _CountdownBadge(days: g, color: documento.coloreScadenza),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Text(
                documento.nome.isEmpty ? 'Senza nome' : documento.nome,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    if (documento.imagePath.isEmpty || !File(documento.imagePath).existsSync()) {
      return Container(
        color: AppColors.background,
        child: const Center(
          child: Icon(Icons.image_not_supported_rounded, color: AppColors.textLight, size: 42),
        ),
      );
    }
    return Image.file(
      File(documento.imagePath),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: AppColors.background,
        child: const Center(
          child: Icon(Icons.broken_image_rounded, color: AppColors.textLight, size: 42),
        ),
      ),
    );
  }
}

// ===========================================================================
// List card
// ===========================================================================
class _DocCardList extends StatelessWidget {
  final _Documento documento;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _DocCardList({
    required this.documento,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final g = documento.giorniRimanenti;
    final df = DateFormat('dd/MM/yyyy');
    return Dismissible(
      key: ValueKey(documento.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: const Color(0xFFC62828),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 26),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onDelete,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 56, height: 70,
                  child: documento.imagePath.isNotEmpty &&
                          File(documento.imagePath).existsSync()
                      ? Image.file(File(documento.imagePath), fit: BoxFit.cover)
                      : Container(
                          color: AppColors.background,
                          child: const Icon(Icons.image_not_supported_rounded,
                              color: AppColors.textLight, size: 22),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(documento.nome.isEmpty ? 'Senza nome' : documento.nome,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        )),
                    if (documento.dataScadenza != null) ...[
                      const SizedBox(height: 4),
                      Text('Scade: ${df.format(documento.dataScadenza!)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: documento.coloreScadenza,
                            fontWeight: FontWeight.w600,
                          )),
                    ],
                  ],
                ),
              ),
              if (g != null) _CountdownBadge(days: g, color: documento.coloreScadenza),
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// Countdown badge
// ===========================================================================
class _CountdownBadge extends StatelessWidget {
  final int days;
  final Color color;
  const _CountdownBadge({required this.days, required this.color});

  @override
  Widget build(BuildContext context) {
    final label = days < 0
        ? 'SCADUTO'
        : days == 0
            ? 'OGGI'
            : '$days gg';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
    );
  }
}

// ===========================================================================
// Form bottom sheet — minimal: name (required) + expiry (optional) + photo
// ===========================================================================
class _DocumentoFormSheet extends StatefulWidget {
  final _Documento initial;
  final bool isNew;
  const _DocumentoFormSheet({required this.initial, required this.isNew});

  @override
  State<_DocumentoFormSheet> createState() => _DocumentoFormSheetState();
}

class _DocumentoFormSheetState extends State<_DocumentoFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomeCtrl;
  DateTime? _dataScadenza;
  late String _imagePath;

  @override
  void initState() {
    super.initState();
    _nomeCtrl = TextEditingController(text: widget.initial.nome);
    _dataScadenza = widget.initial.dataScadenza;
    _imagePath = widget.initial.imagePath;
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final initial = _dataScadenza ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('it', 'IT'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _dataScadenza = picked);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final saved = widget.initial.copyWith(
      nome: _nomeCtrl.text.trim(),
      imagePath: _imagePath,
      dataScadenza: _dataScadenza,
      clearScadenza: _dataScadenza == null,
    );
    Navigator.of(context).pop(saved);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;
    final df = DateFormat('dd/MM/yyyy');

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPad),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Text(
                    widget.isNew ? 'Nuovo documento' : 'Modifica documento',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark),
                  ),
                  const Spacer(),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Photo preview
                      if (_imagePath.isNotEmpty && File(_imagePath).existsSync())
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(_imagePath),
                            height: 180,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 180,
                              color: AppColors.background,
                              child: const Center(child: Icon(Icons.broken_image_rounded, size: 48, color: AppColors.textLight)),
                            ),
                          ),
                        )
                      else
                        Container(
                          height: 180,
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Icon(Icons.image_outlined, size: 48, color: AppColors.textLight),
                          ),
                        ),
                      const SizedBox(height: 18),

                      // Nome (REQUIRED)
                      const Text('Nome documento',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _nomeCtrl,
                        autofocus: widget.isNew,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: _inputDecoration("es. Passaporto Adnan"),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Inserisci un nome' : null,
                      ),
                      const SizedBox(height: 16),

                      // Scadenza (OPTIONAL)
                      Row(
                        children: const [
                          Text('Scadenza',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                          SizedBox(width: 6),
                          Text('(opzionale)',
                              style: TextStyle(fontSize: 11, color: AppColors.textLight, fontWeight: FontWeight.w500)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: _pickDate,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _dataScadenza != null
                                            ? df.format(_dataScadenza!)
                                            : 'Tocca per scegliere',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: _dataScadenza != null ? AppColors.textDark : AppColors.textLight,
                                        ),
                                      ),
                                    ),
                                    Icon(Icons.calendar_today_rounded,
                                        size: 16,
                                        color: _dataScadenza != null ? AppColors.primary : AppColors.textLight),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (_dataScadenza != null) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.clear_rounded, color: AppColors.textMedium),
                              onPressed: () => setState(() => _dataScadenza = null),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Save button
                      GestureDetector(
                        onTap: _save,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: AppColors.buttonGradient,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              widget.isNew ? 'SALVA DOCUMENTO' : 'SALVA MODIFICHE',
                              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 14),
      filled: true,
      fillColor: AppColors.background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFC62828)),
      ),
    );
  }
}
