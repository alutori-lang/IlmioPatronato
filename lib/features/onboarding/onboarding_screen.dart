import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/constants.dart';
import '../../core/services/language_service.dart';
import 'onboarding_strings.dart';

const onboardingDoneKey = 'onboarding_done_v1';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onFinish;
  const OnboardingScreen({super.key, required this.onFinish});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _page = 0;
  String _langCode = 'it';

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _pickLang(String code) {
    setState(() => _langCode = code);
    context.read<LanguageService>().setLanguage(code);
    _pageCtrl.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(onboardingDoneKey, true);
    if (!mounted) return;
    widget.onFinish();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                onPageChanged: (i) => setState(() => _page = i),
                physics: _page == 0
                    ? const NeverScrollableScrollPhysics()
                    : const AlwaysScrollableScrollPhysics(),
                children: [
                  _buildLangPage(),
                  _buildWelcomePage(),
                  _buildFeaturesPage(),
                  _buildStartPage(),
                ],
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  // ─────────── Step 1: language picker ───────────
  Widget _buildLangPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 76, height: 76,
              decoration: BoxDecoration(
                gradient: AppColors.buttonGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
              ),
              child: const Center(child: Text('🇮🇹', style: TextStyle(fontSize: 40))),
            ),
          ),
          const SizedBox(height: 22),
          ...chooseLanguageLabels.take(4).map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  s,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
              )),
          const SizedBox(height: 8),
          ...chooseLanguageLabels.skip(4).map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  s,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )),
          const SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.7,
            ),
            itemCount: supportedLanguages.length,
            itemBuilder: (_, i) {
              final lang = supportedLanguages[i];
              return _LangTile(
                lang: lang,
                selected: lang.code == _langCode,
                onTap: () => _pickLang(lang.code),
              );
            },
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // ─────────── Step 2: welcome ───────────
  Widget _buildWelcomePage() {
    final s = onboardingFor(_langCode);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 110, height: 110,
            decoration: BoxDecoration(
              gradient: AppColors.buttonGradient,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 8))],
            ),
            child: const Center(child: Text('🇮🇹', style: TextStyle(fontSize: 62))),
          ),
          const SizedBox(height: 28),
          Text(
            s.welcome,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            s.subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textMedium,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────── Step 3: features ───────────
  Widget _buildFeaturesPage() {
    final s = onboardingFor(_langCode);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            s.whatYouFind,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 22),
          _featureRow('🇮🇹', const Color(0xFF00838F), s.feat1Title, s.feat1Desc),
          const SizedBox(height: 12),
          _featureRow('📄', const Color(0xFF1565C0), s.feat2Title, s.feat2Desc),
          const SizedBox(height: 12),
          _featureRow('🗣️', const Color(0xFF2E7D32), s.feat3Title, s.feat3Desc),
          const SizedBox(height: 12),
          _featureRow('✅', const Color(0xFFE65100), s.feat4Title, s.feat4Desc),
        ],
      ),
    );
  }

  Widget _featureRow(String emoji, Color color, String title, String desc) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(child: Text(emoji, style: const TextStyle(fontSize: 28))),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textDark)),
              const SizedBox(height: 3),
              Text(desc,
                  style: const TextStyle(fontSize: 12, color: AppColors.textMedium, height: 1.3)),
            ],
          ),
        ),
      ]),
    );
  }

  // ─────────── Step 4: start ───────────
  Widget _buildStartPage() {
    final s = onboardingFor(_langCode);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🎉', style: TextStyle(fontSize: 72)),
          const SizedBox(height: 24),
          Text(
            s.welcome,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            s.subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textMedium,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────── Footer (dots + buttons) ───────────
  Widget _buildFooter() {
    final s = onboardingFor(_langCode);
    final isLast = _page == 3;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) {
              final active = i == _page;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: active ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          const SizedBox(height: 18),
          if (_page == 0)
            Text(
              // Small hint, neutral. No button here — user must pick a flag.
              chooseLanguageLabels[1],
              style: const TextStyle(fontSize: 12, color: AppColors.textLight, fontWeight: FontWeight.w500),
            )
          else
            Row(children: [
              TextButton.icon(
                onPressed: () => _pageCtrl.previousPage(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOut,
                ),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: Text(s.back),
                style: TextButton.styleFrom(foregroundColor: AppColors.textMedium),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: isLast
                    ? _finish
                    : () => _pageCtrl.nextPage(
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeOut,
                        ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  isLast ? s.start : s.next,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ),
            ]),
        ],
      ),
    );
  }
}

class _LangTile extends StatelessWidget {
  final AppLanguage lang;
  final bool selected;
  final VoidCallback onTap;

  const _LangTile({required this.lang, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary.withValues(alpha: 0.1) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.primary : Colors.grey.shade200,
              width: selected ? 2 : 1,
            ),
            boxShadow: selected
                ? null
                : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
          ),
          child: Row(children: [
            Text(lang.flag, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(lang.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                        color: AppColors.textDark,
                      )),
                  Text(lang.nameEn,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10, color: AppColors.textLight, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
