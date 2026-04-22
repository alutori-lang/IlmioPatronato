import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../config/constants.dart';
import '../../core/services/scanner_service.dart';
import '../../models/scanned_document.dart';

class ScannerDocScreen extends StatefulWidget {
  const ScannerDocScreen({super.key});

  @override
  State<ScannerDocScreen> createState() => _ScannerDocScreenState();
}

class _ScannerDocScreenState extends State<ScannerDocScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final svc = context.read<ScannerService>();
      if (!svc.isLoaded) svc.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<ScannerService>();
    final docs = svc.documents;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(context, docs.length),
          Expanded(
            child: docs.isEmpty ? _buildEmpty() : _buildList(docs),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _startScan(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.document_scanner_rounded),
        label: const Text('Scansiona', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int count) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 8,
        right: 20,
        bottom: 14,
      ),
      decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      child: Row(children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        const Icon(Icons.document_scanner_rounded, color: Colors.white, size: 22),
        const SizedBox(width: 10),
        const Text('Scanner DOC',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
        const Spacer(),
        if (count > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('$count',
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
          ),
      ]),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.document_scanner_rounded,
                  color: AppColors.primary, size: 56),
            ),
            const SizedBox(height: 22),
            const Text('Nessun documento',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark)),
            const SizedBox(height: 8),
            const Text(
              'Scansiona documenti d\'identità, ricevute, moduli — li trovi tutti qui, sempre con te.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textLight, height: 1.4),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _startScan(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.add_a_photo_rounded),
              label: const Text('Scansiona il primo documento',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<ScannedDocument> docs) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemCount: docs.length,
      itemBuilder: (_, i) => _DocCard(
        doc: docs[i],
        onOpen: () => _openDoc(docs[i]),
        onRename: () => _promptRename(docs[i]),
        onShare: () => _shareDoc(docs[i]),
        onDelete: () => _confirmDelete(docs[i]),
      ),
    );
  }

  Future<void> _startScan(BuildContext context) async {
    final name = await _promptName(context);
    if (name == null) return;
    if (!context.mounted) return;

    final svc = context.read<ScannerService>();
    final messenger = ScaffoldMessenger.of(context);

    try {
      final doc = await svc.scanAndSave(name: name);
      if (doc == null) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('"${doc.name}" salvato (${doc.pageCount} pagin${doc.pageCount == 1 ? 'a' : 'e'})'),
          backgroundColor: AppColors.iconGreen,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Errore durante la scansione: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String?> _promptName(BuildContext context) async {
    final controller = TextEditingController();
    const suggestions = [
      'Carta Identità',
      'Passaporto',
      'Permesso Soggiorno',
      'Codice Fiscale',
      'ISEE',
      'Busta Paga',
      '730',
      'Contratto',
    ];

    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        String selected = '';
        return StatefulBuilder(builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Nome documento',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'es. Carta Identità',
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (v) => setSheetState(() => selected = v),
                  ),
                  const SizedBox(height: 14),
                  const Text('Suggerimenti',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textLight)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: suggestions.map((s) {
                      return GestureDetector(
                        onTap: () {
                          controller.text = s;
                          setSheetState(() => selected = s);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(s,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(ctx, controller.text.trim().isEmpty ? 'Documento' : controller.text.trim()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.document_scanner_rounded),
                      label: const Text('Avvia scansione',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  Future<void> _openDoc(ScannedDocument doc) async {
    await OpenFilex.open(doc.pdfPath);
  }

  Future<void> _shareDoc(ScannedDocument doc) async {
    await Share.shareXFiles([XFile(doc.pdfPath)], subject: doc.name);
  }

  Future<void> _promptRename(ScannedDocument doc) async {
    final controller = TextEditingController(text: doc.name);
    final svc = context.read<ScannerService>();
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rinomina'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'Nome documento'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annulla')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Salva'),
          ),
        ],
      ),
    );
    if (newName != null && newName.isNotEmpty) {
      await svc.rename(doc.id, newName);
    }
  }

  Future<void> _confirmDelete(ScannedDocument doc) async {
    final svc = context.read<ScannerService>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Elimina documento?'),
        content: Text('"${doc.name}" sarà rimosso definitivamente.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annulla')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Elimina', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) await svc.delete(doc.id);
  }
}

class _DocCard extends StatelessWidget {
  final ScannedDocument doc;
  final VoidCallback onOpen;
  final VoidCallback onRename;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  const _DocCard({
    required this.doc,
    required this.onOpen,
    required this.onRename,
    required this.onShare,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('d MMM yyyy • HH:mm', 'it_IT');
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onOpen,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(
                    File(doc.thumbPath),
                    width: 64,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 64,
                      height: 80,
                      color: AppColors.primary.withValues(alpha: 0.08),
                      child: const Icon(Icons.picture_as_pdf, color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(doc.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.picture_as_pdf, size: 13, color: AppColors.textLight),
                          const SizedBox(width: 4),
                          Text('${doc.pageCount} pagin${doc.pageCount == 1 ? 'a' : 'e'}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(df.format(doc.createdAt),
                          style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: AppColors.textMedium),
                  onSelected: (v) {
                    switch (v) {
                      case 'open':
                        onOpen();
                        break;
                      case 'rename':
                        onRename();
                        break;
                      case 'share':
                        onShare();
                        break;
                      case 'delete':
                        onDelete();
                        break;
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'open', child: Row(children: [Icon(Icons.visibility, size: 18), SizedBox(width: 10), Text('Apri')])),
                    PopupMenuItem(value: 'rename', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 10), Text('Rinomina')])),
                    PopupMenuItem(value: 'share', child: Row(children: [Icon(Icons.share, size: 18), SizedBox(width: 10), Text('Condividi')])),
                    PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 10), Text('Elimina', style: TextStyle(color: Colors.red))])),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
