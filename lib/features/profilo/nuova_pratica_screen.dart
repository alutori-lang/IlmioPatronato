import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../core/services/pratica_service.dart';
import '../../models/pratica.dart';
import '../agevolazioni/agevolazioni_data.dart' as ag;

class NuovaPraticaScreen extends StatefulWidget {
  /// Optional: pre-fill from a catalog bonus.
  final ag.Agevolazione? fromAgevolazione;
  const NuovaPraticaScreen({super.key, this.fromAgevolazione});

  @override
  State<NuovaPraticaScreen> createState() => _NuovaPraticaScreenState();
}

class _NuovaPraticaScreenState extends State<NuovaPraticaScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    if (widget.fromAgevolazione != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _create(widget.fromAgevolazione!);
      });
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final list = _query.isEmpty ? ag.allAgevolazioni : ag.cerca(_query);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          _buildSearch(),
          const SizedBox(height: 8),
          _buildCustomTile(),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(children: [
              Icon(Icons.auto_awesome, size: 14, color: AppColors.iconOrange),
              SizedBox(width: 6),
              Text('Dal catalogo — checklist automatica',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.iconOrange, letterSpacing: 0.3)),
            ]),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount: list.length,
              itemBuilder: (_, i) => _AgevolazioneTile(
                agevolazione: list[i],
                onTap: () => _create(list[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 8, right: 20, bottom: 14,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE65100), Color(0xFFFF8F00)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      child: Row(children: [
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        const Text('Nuova pratica',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
      ]),
    );
  }

  Widget _buildSearch() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: TextField(
        controller: _search,
        onChanged: (v) => setState(() => _query = v),
        decoration: InputDecoration(
          hintText: 'Cerca (es. NASpI, ISEE, Bonus Nuovi Nati)',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          prefixIcon: const Icon(Icons.search, color: AppColors.iconOrange),
          suffixIcon: _query.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    _search.clear();
                    setState(() => _query = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildCustomTile() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: _createCustom,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.iconOrange.withValues(alpha: 0.3), width: 1.5),
            ),
            child: Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: AppColors.iconOrange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.edit, color: AppColors.iconOrange, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pratica personalizzata',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                    SizedBox(height: 2),
                    Text('Titolo ed ente li scegli tu',
                        style: TextStyle(fontSize: 12, color: AppColors.textLight)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textLight),
            ]),
          ),
        ),
      ),
    );
  }

  Future<void> _create(ag.Agevolazione a) async {
    final checklist = <ChecklistItem>[
      ...a.documenti.map((d) => ChecklistItem(text: 'Documento: $d')),
      ...a.requisiti.map((r) => ChecklistItem(text: 'Verifica requisito: $r')),
      const ChecklistItem(text: 'Invia la domanda'),
      const ChecklistItem(text: 'Conserva la ricevuta'),
    ];

    final pratica = Pratica(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      titolo: a.titolo,
      ente: a.ente,
      agevolazioneId: a.id,
      stato: PraticaStato.daFare,
      dataCreazione: DateTime.now(),
      checklist: checklist,
      linkUfficiale: a.linkUfficiale,
    );

    final created = await context.read<PraticaService>().create(pratica);
    if (!mounted) return;
    Navigator.pop(context, created);
  }

  Future<void> _createCustom() async {
    final result = await showDialog<_CustomData>(
      context: context,
      builder: (ctx) => const _CustomPraticaDialog(),
    );
    if (result == null) return;

    final pratica = Pratica(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      titolo: result.titolo,
      ente: result.ente.isEmpty ? 'Altro' : result.ente,
      stato: PraticaStato.daFare,
      dataCreazione: DateTime.now(),
    );

    if (!mounted) return;
    final created = await context.read<PraticaService>().create(pratica);
    if (!mounted) return;
    Navigator.pop(context, created);
  }
}

class _AgevolazioneTile extends StatelessWidget {
  final ag.Agevolazione agevolazione;
  final VoidCallback onTap;
  const _AgevolazioneTile({required this.agevolazione, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(agevolazione.titolo,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Row(children: [
                      Text(agevolazione.ente,
                          style: const TextStyle(fontSize: 11, color: AppColors.iconOrange, fontWeight: FontWeight.w700)),
                      const SizedBox(width: 8),
                      Text('• ${agevolazione.categoria}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                    ]),
                  ],
                ),
              ),
              const Icon(Icons.add_circle, color: AppColors.iconOrange),
            ]),
          ),
        ),
      ),
    );
  }
}

class _CustomData {
  final String titolo;
  final String ente;
  _CustomData(this.titolo, this.ente);
}

class _CustomPraticaDialog extends StatefulWidget {
  const _CustomPraticaDialog();
  @override
  State<_CustomPraticaDialog> createState() => _CustomPraticaDialogState();
}

class _CustomPraticaDialogState extends State<_CustomPraticaDialog> {
  final _titolo = TextEditingController();
  final _ente = TextEditingController();

  @override
  void dispose() {
    _titolo.dispose();
    _ente.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pratica personalizzata'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titolo,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Titolo *',
              hintText: 'es. Permesso di soggiorno',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ente,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Ente',
              hintText: 'es. Questura, INPS, Comune',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla')),
        TextButton(
          onPressed: () {
            if (_titolo.text.trim().isEmpty) return;
            Navigator.pop(context, _CustomData(_titolo.text.trim(), _ente.text.trim()));
          },
          child: const Text('Crea'),
        ),
      ],
    );
  }
}
