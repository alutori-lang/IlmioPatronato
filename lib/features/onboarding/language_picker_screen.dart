import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/constants.dart';
import '../../core/services/language_service.dart';
import '../../core/localization/app_strings.dart';

// ---------------------------------------------------------------------------
// Language picker — mostrato al primo avvio dell'app.
// Salva `onboarding_language_chosen` in SharedPreferences per non mostrarlo
// più dalla seconda apertura.
// ---------------------------------------------------------------------------

class LanguagePickerScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const LanguagePickerScreen({super.key, required this.onComplete});

  static const prefsKey = 'onboarding_language_chosen_v1';

  static Future<bool> alreadyChosen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(prefsKey) ?? false;
  }

  static Future<void> markChosen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefsKey, true);
  }

  @override
  State<LanguagePickerScreen> createState() => _LanguagePickerScreenState();
}

class _LanguagePickerScreenState extends State<LanguagePickerScreen> {
  String _selected = 'it';

  @override
  void initState() {
    super.initState();
    final current = context.read<LanguageService>().currentCode;
    _selected = current;
  }

  Future<void> _confirm() async {
    await context.read<LanguageService>().setLanguage(_selected);
    await LanguagePickerScreen.markChosen();
    if (!mounted) return;
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.forCode(_selected);
    return Directionality(
      textDirection: s.isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 36, 20, 24),
                decoration: const BoxDecoration(gradient: AppColors.headerGradient),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text('🌍', style: TextStyle(fontSize: 60)),
                    const SizedBox(height: 14),
                    Text(
                      s.chooseLanguage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      s.chooseLanguageSubtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13, height: 1.4),
                    ),
                  ],
                ),
              ),
              // Grid of languages
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2.2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: supportedLanguages.length,
                  itemBuilder: (_, i) {
                    final lang = supportedLanguages[i];
                    final selected = _selected == lang.code;
                    return GestureDetector(
                      onTap: () => setState(() => _selected = lang.code),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.primary : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selected ? AppColors.primary : Colors.grey.shade300,
                            width: selected ? 2 : 1,
                          ),
                          boxShadow: selected
                              ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 3))]
                              : null,
                        ),
                        child: Row(
                          children: [
                            Text(lang.flag, style: const TextStyle(fontSize: 30)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    lang.name,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: selected ? Colors.white : AppColors.textDark,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    lang.nameEn,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: selected ? Colors.white70 : AppColors.textLight,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            if (selected)
                              const Icon(Icons.check_circle, color: Colors.white, size: 22),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Continue button
              Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(context).padding.bottom + 20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _confirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                    ),
                    child: Text(s.continueBtn),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
