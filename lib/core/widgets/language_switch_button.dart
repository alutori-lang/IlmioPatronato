import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/language_service.dart';
import '../localization/app_strings.dart';

/// Pulsante 🌐 mostrato in alto nelle schermate principali.
/// Apre un bottom sheet con la lista delle lingue supportate.
class LanguageSwitchButton extends StatelessWidget {
  final Color? iconColor;
  final double iconSize;
  const LanguageSwitchButton({super.key, this.iconColor, this.iconSize = 20});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageService>();
    return GestureDetector(
      onTap: () => _openSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(lang.current.flag, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              lang.currentCode.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: iconColor ?? Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openSheet(BuildContext context) {
    final s = AppStrings.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _LanguageSheet(title: s.chooseLanguage),
    );
  }
}

class _LanguageSheet extends StatelessWidget {
  final String title;
  const _LanguageSheet({required this.title});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageService>();
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(16, 10, 16, MediaQuery.of(context).padding.bottom + 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 14),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: supportedLanguages.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (_, i) {
                final l = supportedLanguages[i];
                final selected = l.code == lang.currentCode;
                return InkWell(
                  onTap: () async {
                    await lang.setLanguage(l.code);
                    if (context.mounted) Navigator.pop(context);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: selected ? Colors.grey.shade100 : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? Colors.grey.shade400 : Colors.grey.shade200,
                      ),
                    ),
                    child: Row(children: [
                      Text(l.flag, style: const TextStyle(fontSize: 26)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                            Text(l.nameEn, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                          ],
                        ),
                      ),
                      if (selected) const Icon(Icons.check_circle, color: Color(0xFF1B5E20)),
                    ]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
