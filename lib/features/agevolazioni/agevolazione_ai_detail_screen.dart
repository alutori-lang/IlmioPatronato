import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/constants.dart';
import '../../core/services/agevolazioni_service.dart';
import '../../core/services/gemini_service.dart';

// ─────────────────────────────────────────────
// Dettaglio Agevolazione AI (generate on-demand da Groq)
// ─────────────────────────────────────────────

class AgevolazioneAiDetailScreen extends StatefulWidget {
  final Agevolazione agevolazione;

  const AgevolazioneAiDetailScreen({super.key, required this.agevolazione});

  @override
  State<AgevolazioneAiDetailScreen> createState() => _AgevolazioneAiDetailScreenState();
}

class _AgevolazioneAiDetailScreenState extends State<AgevolazioneAiDetailScreen> {
  bool _loading = true;

  // Dati generati da AI
  String _descrizioneCompleta = '';
  List<String> _requisiti = [];
  List<String> _documenti = [];
  String _comeRichiederlo = '';
  String _ente = '';
  String _scadenza = '';
  String _linkUfficiale = '';

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    setState(() { _loading = true; });

    final a = widget.agevolazione;

    // Prompt breve per risposta rapida
    final prompt = 'Agevolazione italiana: "${a.titolo}". '
        'Rispondi SOLO JSON (no markdown):\n'
        '{"descrizioneCompleta":"2-3 frasi su cos\'è e a chi serve",'
        '"ente":"ente erogatore",'
        '"scadenza":"scadenza o Aperto",'
        '"requisiti":["req1","req2","req3"],'
        '"documenti":["doc1","doc2","doc3"],'
        '"comeRichiederlo":"1. passo uno 2. passo due 3. passo tre",'
        '"linkUfficiale":"https://url sito ufficiale dove presentare domanda"}';

    final res = await GeminiService().chat(
      messages: [{'role': 'user', 'content': prompt}],
      systemPrompt: 'Sei esperto agevolazioni italiane. Rispondi SOLO con JSON valido, senza testo aggiuntivo.',
    );

    if (!mounted) return;

    Map<String, dynamic>? json;

    // ignore: avoid_print
    print('GROQ isSuccess=${res.isSuccess} error=${res.errorMessage} textLen=${res.text.length}');
    // ignore: avoid_print
    if (res.text.isNotEmpty) print('GROQ text=${res.text.substring(0, res.text.length.clamp(0, 300))}');

    if (res.isSuccess && res.text.isNotEmpty) {
      try {
        String text = res.text.trim();
        // Rimuovi qualsiasi markdown code block
        text = text.replaceAll(RegExp(r'```json', caseSensitive: false), '');
        text = text.replaceAll('```', '');
        text = text.trim();
        // Estrai da { fino a }
        final start = text.indexOf('{');
        final end = text.lastIndexOf('}');
        if (start != -1 && end > start) {
          json = jsonDecode(text.substring(start, end + 1)) as Map<String, dynamic>;
        }
      } catch (_) {
        // JSON malformato — proviamo a usare il testo come descrizione
      }
    }

    if (json != null) {
      setState(() {
        _descrizioneCompleta = _parseString(json!['descrizioneCompleta']) ?? a.descrizione;
        _ente = _parseString(json['ente']) ?? a.fonte;
        _scadenza = _parseString(json['scadenza']) ?? a.data;
        _requisiti = _parseStringList(json['requisiti']);
        _documenti = _parseStringList(json['documenti']);
        _comeRichiederlo = _parseString(json['comeRichiederlo']) ?? '';
        _linkUfficiale = _parseString(json['linkUfficiale']) ?? '';
        _loading = false;
      });
    } else if (res.isSuccess && res.text.isNotEmpty) {
      // AI ha risposto ma non in JSON: usa il testo come descrizione
      setState(() {
        _descrizioneCompleta = res.text.trim().length > 20
            ? res.text.trim()
            : a.descrizione;
        _ente = a.fonte;
        _scadenza = a.data;
        _loading = false;
      });
    } else {
      // Errore API: mostra dati base senza messaggio di errore visibile
      setState(() {
        _descrizioneCompleta = a.descrizione;
        _ente = a.fonte;
        _scadenza = a.data;
        _loading = false;
      });
    }
  }

  String? _parseString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is List) return value.join(', ');
    return value.toString();
  }

  List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => e.toString()).toList();
    if (value is String) {
      // Se è una stringa con newline, splittala
      return value.split('\n').where((s) => s.trim().isNotEmpty).toList();
    }
    return [];
  }

  Color get _color {
    switch (widget.agevolazione.categoria.toLowerCase()) {
      case 'famiglia': return const Color(0xFFC62828);
      case 'lavoro':   return const Color(0xFF1565C0);
      case 'disabilità': return const Color(0xFF283593);
      case 'giovani':  return const Color(0xFFFF6F00);
      case 'casa':     return const Color(0xFFE65100);
      case 'fiscale':  return const Color(0xFF4E342E);
      case 'immigrazione': return const Color(0xFF00838F);
      case 'salute':   return const Color(0xFF2E7D32);
      default:         return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(child: _buildHeader(context, color)),

          // Hero card
          SliverToBoxAdapter(child: _buildHeroCard(color)),

          // Info importo/scadenza
          SliverToBoxAdapter(child: _buildInfoRow(color)),

          if (_loading)
            SliverToBoxAdapter(child: _buildLoading(color))
          else ...[
            // Descrizione
            if (_descrizioneCompleta.isNotEmpty)
              SliverToBoxAdapter(child: _buildSection('Descrizione Completa', Icons.info_outline, _descrizioneCompleta, color)),

            // Requisiti
            if (_requisiti.isNotEmpty)
              SliverToBoxAdapter(child: _buildChecklist('Requisiti per Accedere', Icons.checklist, _requisiti, color)),

            // Documenti
            if (_documenti.isNotEmpty)
              SliverToBoxAdapter(child: _buildChecklist('Documenti Necessari', Icons.folder_open, _documenti, color)),

            // Come richiederlo
            if (_comeRichiederlo.isNotEmpty)
              SliverToBoxAdapter(child: _buildSection('Come Fare Domanda', Icons.route, _comeRichiederlo, color)),

            // Ente
            if (_ente.isNotEmpty)
              SliverToBoxAdapter(child: _buildEnteCard(color)),

            // Link ufficiale
            if (_linkUfficiale.isNotEmpty)
              SliverToBoxAdapter(child: _buildLinkButton(context, color)),

          ],

          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color color) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 20, right: 20, bottom: 14,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.9), color],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('DETTAGLIO AGEVOLAZIONE', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                const SizedBox(height: 2),
                Text(widget.agevolazione.titolo,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.amber.shade600, borderRadius: BorderRadius.circular(8)),
            child: const Text('NUOVO', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(Color color) {
    final a = widget.agevolazione;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 24, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(child: Text(a.categoriaIcon, style: const TextStyle(fontSize: 30))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.titolo, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                const SizedBox(height: 4),
                Text(a.descrizione, style: const TextStyle(fontSize: 12, color: AppColors.textMedium), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                  child: Text(a.categoria, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(Color color) {
    final a = widget.agevolazione;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Expanded(child: _InfoBox(icon: Icons.euro, label: 'IMPORTO', value: a.importo.isNotEmpty ? a.importo : 'Variabile', color: Colors.green.shade700)),
          const SizedBox(width: 12),
          Expanded(child: _InfoBox(icon: Icons.calendar_today, label: 'AGGIUNTO', value: a.data, color: Colors.orange.shade700)),
        ],
      ),
    );
  }

  Widget _buildLoading(Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          SizedBox(width: 36, height: 36, child: CircularProgressIndicator(strokeWidth: 3, color: color)),
          const SizedBox(height: 14),
          const Text('Sto raccogliendo i dettagli completi...', style: TextStyle(fontSize: 13, color: AppColors.textMedium)),
          const SizedBox(height: 4),
          const Text('Requisiti, documenti e procedura', style: TextStyle(fontSize: 11, color: AppColors.textLight)),
        ],
      ),
    );
  }

  Widget _buildSection(String title, IconData titleIcon, String content, Color color) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(titleIcon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
          ]),
          const SizedBox(height: 12),
          Text(content, style: const TextStyle(fontSize: 13, color: AppColors.textMedium, height: 1.6)),
        ],
      ),
    );
  }

  Widget _buildChecklist(String title, IconData titleIcon, List<String> items, Color color) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(titleIcon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
          ]),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  width: 20, height: 20,
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                  child: Icon(Icons.check, size: 13, color: color),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(item, style: const TextStyle(fontSize: 13, color: AppColors.textMedium, height: 1.4))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildLinkButton(BuildContext context, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: GestureDetector(
        onTap: () async {
          final url = Uri.parse(_linkUfficiale);
          try {
            await launchUrl(url, mode: LaunchMode.externalApplication);
          } catch (_) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Impossibile aprire il link')),
              );
            }
          }
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.8)]),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.open_in_new, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('VAI AL SITO UFFICIALE', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnteCard(Color color) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.account_balance, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ente Erogatore', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textLight, letterSpacing: 0.5)),
                const SizedBox(height: 2),
                Text(_ente, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _InfoBox({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.5)),
          ]),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark), maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
