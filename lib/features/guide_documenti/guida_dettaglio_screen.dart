import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/constants.dart';
import '../../core/services/guide_ai_service.dart';
import '../../core/services/language_service.dart';
import '../sbroglia/sbroglia_chat_screen.dart';
import 'guide_documenti_data.dart';

class GuidaDettaglioScreen extends StatefulWidget {
  final String schedaId;
  const GuidaDettaglioScreen({super.key, required this.schedaId});

  @override
  State<GuidaDettaglioScreen> createState() => _GuidaDettaglioScreenState();
}

class _GuidaDettaglioScreenState extends State<GuidaDettaglioScreen> {
  late String _lang;
  GuidaContenuto? _contenuto;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _lang = context.read<LanguageService>().currentCode;
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  GuidaScheda get _scheda => schedaById(widget.schedaId)!;
  GuidaCategoria get _categoria => categoriaById(_scheda.categoriaId)!;
  Color get _color => Color(_categoria.color);

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final svc = GuideAiService();
      final cached = await svc.cached(_scheda.id, _lang);
      if (cached != null) {
        if (!mounted) return;
        setState(() {
          _contenuto = cached;
          _loading = false;
        });
        return;
      }
      final generated = await svc.generate(_scheda, _lang);
      if (!mounted) return;
      setState(() {
        _contenuto = generated;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _changeLang() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 14),
            const Text('Scegli lingua',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textDark)),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: supportedLanguages.length,
                itemBuilder: (_, i) {
                  final lang = supportedLanguages[i];
                  final selected = lang.code == _lang;
                  return ListTile(
                    leading: Text(lang.flag, style: const TextStyle(fontSize: 24)),
                    title: Text(lang.name,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                            color: selected ? _color : AppColors.textDark)),
                    subtitle: Text(lang.nameEn,
                        style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
                    trailing: selected ? Icon(Icons.check_circle, color: _color) : null,
                    onTap: () => Navigator.pop(ctx, lang.code),
                  );
                },
              ),
            ),
            SizedBox(height: MediaQuery.of(ctx).padding.bottom + 8),
          ],
        ),
      ),
    );
    if (picked != null && picked != _lang) {
      setState(() => _lang = picked);
      _load();
    }
  }

  AppLanguage get _currentLang =>
      supportedLanguages.firstWhere((l) => l.code == _lang, orElse: () => supportedLanguages.first);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverToBoxAdapter(child: _buildLangBar()),
          if (_loading)
            SliverToBoxAdapter(child: _buildLoading())
          else if (_error != null)
            SliverToBoxAdapter(child: _buildError())
          else if (_contenuto != null)
            ..._buildContent(_contenuto!),
          SliverToBoxAdapter(child: _buildActions()),
          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 8, right: 20, bottom: 20,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_color.withValues(alpha: 0.95), _color],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            const Spacer(),
          ]),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_scheda.emoji, style: const TextStyle(fontSize: 40)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_categoria.titolo.toUpperCase(),
                          style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                      const SizedBox(height: 4),
                      Text(_scheda.titolo,
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, height: 1.2)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(_scheda.ente,
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLangBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: GestureDetector(
        onTap: _changeLang,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
          ),
          child: Row(children: [
            const Icon(Icons.language, size: 18, color: AppColors.primary),
            const SizedBox(width: 10),
            const Text('Lingua:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textMedium)),
            const SizedBox(width: 6),
            Text(_currentLang.flag, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 6),
            Text(_currentLang.name,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
            const Spacer(),
            const Icon(Icons.expand_more, size: 20, color: AppColors.textLight),
          ]),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 16),
      child: Column(
        children: [
          CircularProgressIndicator(color: _color),
          const SizedBox(height: 14),
          Text('Carico la scheda in ${_currentLang.name}…',
              style: const TextStyle(fontSize: 14, color: AppColors.textMedium, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          const Text('Prima volta: qualche secondo. Dopo è immediato.',
              style: TextStyle(fontSize: 12, color: AppColors.textLight)),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.textLight),
        const SizedBox(height: 12),
        const Text('Non riesco a caricare la scheda',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textDark)),
        const SizedBox(height: 6),
        Text(_error ?? '',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _load,
          style: ElevatedButton.styleFrom(backgroundColor: _color, foregroundColor: Colors.white),
          icon: const Icon(Icons.refresh),
          label: const Text('Riprova'),
        ),
      ]),
    );
  }

  List<Widget> _buildContent(GuidaContenuto c) {
    return [
      if (c.cosEce.isNotEmpty) SliverToBoxAdapter(child: _section(Icons.info_outline, 'Cos\'è', c.cosEce)),
      if (c.requisiti.isNotEmpty) SliverToBoxAdapter(child: _checklistSection(Icons.checklist, 'Requisiti', c.requisiti)),
      if (c.documenti.isNotEmpty) SliverToBoxAdapter(child: _checklistSection(Icons.folder_open, 'Documenti necessari', c.documenti)),
      if (c.dove.isNotEmpty) SliverToBoxAdapter(child: _section(Icons.location_on, 'Dove fare la domanda', c.dove)),
      if (c.procedura.isNotEmpty) SliverToBoxAdapter(child: _numberedSection(Icons.route, 'Procedura passo-passo', c.procedura)),
      if (c.costi.isNotEmpty) SliverToBoxAdapter(child: _section(Icons.euro, 'Costi', c.costi)),
      if (c.tempi.isNotEmpty) SliverToBoxAdapter(child: _section(Icons.schedule, 'Tempi', c.tempi)),
      if (c.avvertenze.isNotEmpty) SliverToBoxAdapter(child: _warnSection('Attenzione', c.avvertenze)),
      if (c.faq.isNotEmpty) SliverToBoxAdapter(child: _faqSection(c.faq)),
    ];
  }

  Widget _section(IconData icon, String title, String body) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 18, color: _color),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textDark)),
        ]),
        const SizedBox(height: 10),
        SelectableText(body, style: const TextStyle(fontSize: 14, color: AppColors.textMedium, height: 1.55)),
      ]),
    );
  }

  Widget _checklistSection(IconData icon, String title, List<String> items) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 18, color: _color),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textDark)),
        ]),
        const SizedBox(height: 10),
        ...items.map((it) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  width: 18, height: 18,
                  decoration: BoxDecoration(
                    color: _color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Icon(Icons.check, size: 12, color: _color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(it, style: const TextStyle(fontSize: 13, color: AppColors.textMedium, height: 1.4)),
                ),
              ]),
            )),
      ]),
    );
  }

  Widget _numberedSection(IconData icon, String title, List<String> items) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 18, color: _color),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textDark)),
        ]),
        const SizedBox(height: 10),
        ...List.generate(items.length, (i) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 24, height: 24,
                  decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
                  child: Center(
                    child: Text('${i + 1}',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(items[i],
                      style: const TextStyle(fontSize: 13, color: AppColors.textDark, height: 1.45)),
                ),
              ]),
            )),
      ]),
    );
  }

  Widget _warnSection(String title, List<String> items) {
    const warnColor = Color(0xFFE65100);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: warnColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: warnColor.withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.warning_amber_rounded, size: 20, color: warnColor),
          SizedBox(width: 8),
          Text('Attenzione',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: warnColor)),
        ]),
        const SizedBox(height: 10),
        ...items.map((it) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('• ', style: TextStyle(color: warnColor, fontWeight: FontWeight.w800, fontSize: 14)),
                Expanded(
                  child: Text(it, style: const TextStyle(fontSize: 13, color: AppColors.textDark, height: 1.45)),
                ),
              ]),
            )),
      ]),
    );
  }

  Widget _faqSection(List<GuidaFaq> faq) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.help_outline, size: 18, color: _color),
          const SizedBox(width: 8),
          const Text('Domande frequenti',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textDark)),
        ]),
        const SizedBox(height: 4),
        ...faq.map((f) => Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(f.domanda,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                childrenPadding: const EdgeInsets.only(bottom: 8, right: 10),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(f.risposta,
                        style: const TextStyle(fontSize: 13, color: AppColors.textMedium, height: 1.5)),
                  ),
                ],
              ),
            )),
      ]),
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: Column(children: [
        _bigButton(
          icon: Icons.launch_rounded,
          label: 'Sito ufficiale ${_scheda.ente}',
          color: _color,
          onTap: () async {
            try {
              await launchUrl(Uri.parse(_scheda.linkUfficiale), mode: LaunchMode.externalApplication);
            } catch (_) {}
          },
        ),
        const SizedBox(height: 10),
        _bigButton(
          icon: Icons.auto_awesome,
          label: 'Chiedi al Patronato AI',
          color: const Color(0xFF9C27B0),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SbrogliaScreen(
                  initialCategory: UserCategory.neogenitore,
                  initialQuestion:
                      'Spiegami in dettaglio la procedura per "${_scheda.titolo}" (${_scheda.ente}). '
                      'Il mio caso è: [descrivilo tu]. Cosa mi conviene fare nel mio caso specifico?',
                ),
              ),
            );
          },
        ),
      ]),
    );
  }

  Widget _bigButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.8)]),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Flexible(
              child: Text(label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.4)),
            ),
          ],
        ),
      ),
    );
  }
}
