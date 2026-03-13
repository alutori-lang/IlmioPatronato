import 'package:flutter/material.dart';
import '../../config/constants.dart';

class CreaDomandaScreen extends StatefulWidget {
  const CreaDomandaScreen({super.key});

  @override
  State<CreaDomandaScreen> createState() => _CreaDomandaScreenState();
}

class _CreaDomandaScreenState extends State<CreaDomandaScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = 'Permesso';

  final List<String> _categories = ['Permesso', 'Cittadinanza', 'Lavoro', 'SPID', 'Sanità', 'ISEE', 'Altro'];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        Container(
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10, left: 16, right: 20, bottom: 14),
          decoration: const BoxDecoration(gradient: AppColors.headerGradient),
          child: Row(children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(width: 38, height: 38, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 20)),
            ),
            const SizedBox(width: 12),
            const Text('Nuova Domanda', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
          ]),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Categoria', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: _categories.map((cat) {
                final sel = cat == _selectedCategory;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: sel ? AppColors.primary : const Color(0xFFE0E0E0)),
                    ),
                    child: Text(cat, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: sel ? Colors.white : AppColors.textMedium)),
                  ),
                );
              }).toList()),
              const SizedBox(height: 20),
              const Text('Titolo', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15)]),
                child: TextField(controller: _titleController, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  decoration: const InputDecoration(hintText: 'Scrivi la tua domanda...', hintStyle: TextStyle(color: AppColors.textLight),
                    border: InputBorder.none, contentPadding: EdgeInsets.all(14)), maxLines: 2),
              ),
              const SizedBox(height: 20),
              const Text('Dettagli', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15)]),
                child: TextField(controller: _descriptionController, style: const TextStyle(fontSize: 14),
                  decoration: const InputDecoration(hintText: 'Aggiungi dettagli sulla tua situazione...', hintStyle: TextStyle(color: AppColors.textLight),
                    border: InputBorder.none, contentPadding: EdgeInsets.all(14)), maxLines: 6),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Funzione disponibile con Firebase!'), backgroundColor: AppColors.primary),
                  );
                },
                child: Container(
                  width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(gradient: AppColors.buttonGradient, borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))]),
                  child: const Center(child: Text('Pubblica Domanda', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700))),
                ),
              ),
              const SizedBox(height: 40),
            ]),
          ),
        ),
      ]),
    );
  }
}
