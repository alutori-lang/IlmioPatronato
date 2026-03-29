import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/constants.dart';

// ---------------------------------------------------------------------------
// Widget riutilizzabile per caricare e mostrare un documento (foto/galleria)
// ---------------------------------------------------------------------------
class DocumentUploadWidget extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final File? selectedFile;
  final bool isLoading;
  final VoidCallback onPickCamera;
  final VoidCallback onPickGallery;
  final VoidCallback? onRemove;

  const DocumentUploadWidget({
    super.key,
    required this.label,
    this.subtitle = 'Scatta una foto o scegli dalla galleria',
    this.icon = Icons.document_scanner_rounded,
    this.selectedFile,
    this.isLoading = false,
    required this.onPickCamera,
    required this.onPickGallery,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) return _buildLoading();
    if (selectedFile != null) return _buildPreview();
    return _buildUploadArea(context);
  }

  Widget _buildUploadArea(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 2),
        borderRadius: BorderRadius.circular(16),
        color: AppColors.primary.withValues(alpha: 0.04),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showPickerSheet(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: AppColors.buttonGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                const SizedBox(height: 14),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _actionChip(Icons.camera_alt_rounded, 'Fotocamera', onPickCamera),
                    const SizedBox(width: 12),
                    _actionChip(Icons.photo_library_rounded, 'Galleria', onPickGallery),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionChip(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.3), width: 2),
        color: const Color(0xFF4CAF50).withValues(alpha: 0.04),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: Image.file(
              selectedFile!,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Documento caricato',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                ),
                if (onRemove != null)
                  GestureDetector(
                    onTap: onRemove,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF44336).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Rimuovi',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFF44336),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        color: AppColors.primary.withValues(alpha: 0.04),
      ),
      child: const Column(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.primary),
          ),
          SizedBox(height: 16),
          Text(
            'Analisi AI in corso...',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Claude sta leggendo il documento',
            style: TextStyle(fontSize: 12, color: AppColors.textLight),
          ),
        ],
      ),
    );
  }

  void _showPickerSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                label,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 20),
              _sheetOption(
                Icons.camera_alt_rounded,
                'Scatta foto',
                'Usa la fotocamera per fotografare il documento',
                () {
                  Navigator.pop(context);
                  onPickCamera();
                },
              ),
              const SizedBox(height: 10),
              _sheetOption(
                Icons.photo_library_rounded,
                'Scegli dalla galleria',
                'Seleziona una foto già presente sul telefono',
                () {
                  Navigator.pop(context);
                  onPickGallery();
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetOption(IconData icon, String title, String desc, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    Text(desc, style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textLight),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helper per pick immagine (usato da tutti gli screen)
// ---------------------------------------------------------------------------
Future<File?> pickImage(ImageSource source) async {
  final picker = ImagePicker();
  final picked = await picker.pickImage(
    source: source,
    maxWidth: 2048,
    maxHeight: 2048,
    imageQuality: 85,
  );
  if (picked == null) return null;
  return File(picked.path);
}
