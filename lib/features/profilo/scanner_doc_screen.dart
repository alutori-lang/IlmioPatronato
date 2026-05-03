import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../config/constants.dart';
import '../../core/localization/app_strings.dart';
import '../../core/services/scanner_service.dart';
import '../../models/scanned_document.dart';
import 'scanner_preview_screen.dart';

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
    final s = AppStrings.of(context);
    final svc = context.watch<ScannerService>();
    final docs = svc.documents;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(context, s, docs.length),
          Expanded(
            child: docs.isEmpty ? _buildEmpty(s) : _buildList(docs),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _startScan(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.document_scanner_rounded),
        label: Text(s.scanLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppStrings s, int count) {
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
        Text(s.scannerTitle,
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
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

  Widget _buildEmpty(AppStrings s) {
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
            Text(s.noDocs,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark)),
            const SizedBox(height: 8),
            Text(
              s.noDocsHint,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.textLight, height: 1.4),
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
              label: Text(s.scanFirstDoc,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
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
        onWhatsApp: () => _shareWhatsApp(docs[i]),
        onEmail: () => _shareEmail(docs[i]),
        onDelete: () => _confirmDelete(docs[i]),
      ),
    );
  }

  Future<void> _startScan(BuildContext context) async {
    final svc = context.read<ScannerService>();
    final messenger = ScaffoldMessenger.of(context);
    final s = AppStrings.read(context);

    List<String> pages;
    try {
      pages = await svc.scanPages();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('${s.scanError}: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 6),
        ),
      );
      return;
    }
    if (pages.isEmpty) return;
    if (!context.mounted) return;

    final result = await Navigator.push<ScannedDocument?>(
      context,
      MaterialPageRoute(
        builder: (_) => ScannerPreviewScreen(pagePaths: pages),
      ),
    );
    if (result != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('"${result.name}" salvato (${result.pageCount} pagin${result.pageCount == 1 ? 'a' : 'e'})'),
          backgroundColor: AppColors.iconGreen,
        ),
      );
    }
  }

  Future<void> _openDoc(ScannedDocument doc) async {
    await OpenFilex.open(doc.pdfPath);
  }

  Future<void> _shareDoc(ScannedDocument doc) async {
    await Share.shareXFiles([XFile(doc.pdfPath)], subject: doc.name);
  }

  Future<void> _shareWhatsApp(ScannedDocument doc) async {
    final svc = context.read<ScannerService>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      await svc.shareToWhatsApp(filePath: doc.pdfPath, text: doc.name);
    } on PlatformException catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text(e.code == 'NOT_INSTALLED'
            ? 'WhatsApp non è installato su questo dispositivo'
            : 'Errore condivisione WhatsApp: ${e.message ?? e.code}'),
        backgroundColor: Colors.red,
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Errore: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _shareEmail(ScannedDocument doc) async {
    final svc = context.read<ScannerService>();
    final messenger = ScaffoldMessenger.of(context);
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
            : 'Errore email: ${e.message ?? e.code}'),
        backgroundColor: Colors.red,
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Errore: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _promptRename(ScannedDocument doc) async {
    final s = AppStrings.read(context);
    final controller = TextEditingController(text: doc.name);
    final svc = context.read<ScannerService>();
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.rename),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(hintText: s.docName),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(s.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(s.save),
          ),
        ],
      ),
    );
    if (newName != null && newName.isNotEmpty) {
      await svc.rename(doc.id, newName);
    }
  }

  Future<void> _confirmDelete(ScannedDocument doc) async {
    final s = AppStrings.read(context);
    final svc = context.read<ScannerService>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.deleteDoc),
        content: Text('"${doc.name}" ${s.willBeRemoved}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.deleteBtn, style: const TextStyle(color: Colors.red)),
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
  final VoidCallback onWhatsApp;
  final VoidCallback onEmail;
  final VoidCallback onDelete;

  const _DocCard({
    required this.doc,
    required this.onOpen,
    required this.onRename,
    required this.onShare,
    required this.onWhatsApp,
    required this.onEmail,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
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
                      case 'whatsapp':
                        onWhatsApp();
                        break;
                      case 'email':
                        onEmail();
                        break;
                      case 'share':
                        onShare();
                        break;
                      case 'delete':
                        onDelete();
                        break;
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'open', child: Row(children: [const Icon(Icons.visibility, size: 18), const SizedBox(width: 10), Text(s.open)])),
                    PopupMenuItem(value: 'rename', child: Row(children: [const Icon(Icons.edit, size: 18), const SizedBox(width: 10), Text(s.rename)])),
                    const PopupMenuItem(value: 'whatsapp', child: Row(children: [Icon(Icons.chat_bubble, size: 18, color: Color(0xFF25D366)), SizedBox(width: 10), Text('Invia su WhatsApp')])),
                    const PopupMenuItem(value: 'email', child: Row(children: [Icon(Icons.email_outlined, size: 18, color: Color(0xFF1976D2)), SizedBox(width: 10), Text('Invia via Email')])),
                    PopupMenuItem(value: 'share', child: Row(children: [const Icon(Icons.share, size: 18), const SizedBox(width: 10), Text(s.share)])),
                    PopupMenuItem(value: 'delete', child: Row(children: [const Icon(Icons.delete, size: 18, color: Colors.red), const SizedBox(width: 10), Text(s.deleteBtn, style: const TextStyle(color: Colors.red))])),
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
