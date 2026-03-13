import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/constants.dart';

// ---------------------------------------------------------------------------
// Data model
// ---------------------------------------------------------------------------
class _DocumentoInfo {
  static const List<_DocumentoTipo> tipi = [
    _DocumentoTipo(
      key: 'passaporto',
      label: 'Passaporto',
      icon: Icons.menu_book_rounded,
      color: Color(0xFF1565C0),
    ),
    _DocumentoTipo(
      key: 'permesso_soggiorno',
      label: 'Permesso di Soggiorno',
      icon: Icons.card_membership_rounded,
      color: Color(0xFF2E7D32),
    ),
    _DocumentoTipo(
      key: 'cie',
      label: "Carta d'Identita (CIE)",
      icon: Icons.badge_rounded,
      color: Color(0xFF6A1B9A),
    ),
    _DocumentoTipo(
      key: 'codice_fiscale',
      label: 'Codice Fiscale',
      icon: Icons.pin_rounded,
      color: Color(0xFFE65100),
    ),
    _DocumentoTipo(
      key: 'tessera_sanitaria',
      label: 'Tessera Sanitaria',
      icon: Icons.local_hospital_rounded,
      color: Color(0xFFC62828),
    ),
    _DocumentoTipo(
      key: 'patente',
      label: 'Patente di Guida',
      icon: Icons.directions_car_rounded,
      color: Color(0xFF00838F),
    ),
  ];

  static _DocumentoTipo tipoByKey(String key) {
    return tipi.firstWhere(
      (t) => t.key == key,
      orElse: () => tipi.first,
    );
  }
}

class _DocumentoTipo {
  final String key;
  final String label;
  final IconData icon;
  final Color color;

  const _DocumentoTipo({
    required this.key,
    required this.label,
    required this.icon,
    required this.color,
  });
}

class _Documento {
  final String id;
  final String tipoKey;
  final String nome;
  final String numero;
  final DateTime? dataRilascio;
  final DateTime? dataScadenza;
  final String note;

  _Documento({
    required this.id,
    required this.tipoKey,
    required this.nome,
    required this.numero,
    this.dataRilascio,
    this.dataScadenza,
    this.note = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'tipoKey': tipoKey,
        'nome': nome,
        'numero': numero,
        'dataRilascio': dataRilascio?.toIso8601String(),
        'dataScadenza': dataScadenza?.toIso8601String(),
        'note': note,
      };

  factory _Documento.fromJson(Map<String, dynamic> json) => _Documento(
        id: json['id'] as String,
        tipoKey: json['tipoKey'] as String,
        nome: json['nome'] as String? ?? '',
        numero: json['numero'] as String? ?? '',
        dataRilascio: json['dataRilascio'] != null
            ? DateTime.tryParse(json['dataRilascio'] as String)
            : null,
        dataScadenza: json['dataScadenza'] != null
            ? DateTime.tryParse(json['dataScadenza'] as String)
            : null,
        note: json['note'] as String? ?? '',
      );

  int? get giorniRimanenti {
    if (dataScadenza == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final scad = DateTime(
        dataScadenza!.year, dataScadenza!.month, dataScadenza!.day);
    return scad.difference(today).inDays;
  }

  Color get coloreScadenza {
    final giorni = giorniRimanenti;
    if (giorni == null) return AppColors.textMedium;
    if (giorni < 0) return const Color(0xFF212121); // expired - black
    if (giorni < 30) return const Color(0xFFC62828); // red
    if (giorni < 90) return const Color(0xFFE65100); // orange
    return const Color(0xFF2E7D32); // green
  }

  String get numeroMascherato {
    if (numero.isEmpty) return '---';
    if (numero.length <= 4) return numero;
    final visible = numero.substring(numero.length - 4);
    final masked = '*' * (numero.length - 4);
    return '$masked$visible';
  }
}

// ---------------------------------------------------------------------------
// Persistence key
// ---------------------------------------------------------------------------
const _kStorageKey = 'documento_wallet_items';

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------
class DocumentoWalletScreen extends StatefulWidget {
  const DocumentoWalletScreen({super.key});

  @override
  State<DocumentoWalletScreen> createState() => _DocumentoWalletScreenState();
}

class _DocumentoWalletScreenState extends State<DocumentoWalletScreen>
    with TickerProviderStateMixin {
  List<_Documento> _documenti = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDocumenti();
  }

  // -------------------------------------------------------------------------
  // Persistence
  // -------------------------------------------------------------------------
  Future<void> _loadDocumenti() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kStorageKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw) as List;
        _documenti =
            list.map((e) => _Documento.fromJson(e as Map<String, dynamic>)).toList();
      } catch (_) {
        _documenti = [];
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _saveDocumenti() async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(_documenti.map((d) => d.toJson()).toList());
    await prefs.setString(_kStorageKey, json);
  }

  void _addOrUpdateDocumento(_Documento doc) {
    setState(() {
      final idx = _documenti.indexWhere((d) => d.id == doc.id);
      if (idx >= 0) {
        _documenti[idx] = doc;
      } else {
        _documenti.add(doc);
      }
    });
    _saveDocumenti();
  }

  void _deleteDocumento(String id) {
    setState(() => _documenti.removeWhere((d) => d.id == id));
    _saveDocumenti();
  }

  // -------------------------------------------------------------------------
  // Alert documents (expiring within 60 days)
  // -------------------------------------------------------------------------
  List<_Documento> get _alertDocumenti {
    return _documenti.where((d) {
      final g = d.giorniRimanenti;
      return g != null && g >= 0 && g <= 60;
    }).toList()
      ..sort((a, b) => a.giorniRimanenti!.compareTo(b.giorniRimanenti!));
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: _buildFab(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(context)),
                if (_alertDocumenti.isNotEmpty)
                  SliverToBoxAdapter(child: _buildAlertBanner()),
                if (_documenti.isEmpty)
                  SliverFillRemaining(child: _buildEmptyState())
                else ...[
                  SliverToBoxAdapter(child: _buildSectionTitle()),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final doc = _documenti[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _DocumentoCard(
                              documento: doc,
                              onTap: () => _showDocumentoSheet(
                                  context, existingDoc: doc),
                              onDelete: () => _confirmDelete(context, doc),
                            ),
                          );
                        },
                        childCount: _documenti.length,
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  // -------------------------------------------------------------------------
  // Header
  // -------------------------------------------------------------------------
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 20,
        right: 20,
        bottom: 14,
      ),
      decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1976D2).withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.account_balance_wallet_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DOCUMENTO WALLET',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 1),
                Text(
                  'I tuoi documenti sempre a portata di mano',
                  style: TextStyle(
                    color: AppColors.textSubtitle,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Alert banner
  // -------------------------------------------------------------------------
  Widget _buildAlertBanner() {
    final alerts = _alertDocumenti;
    final first = alerts.first;
    final tipo = _DocumentoInfo.tipoByKey(first.tipoKey);
    final giorni = first.giorniRimanenti!;

    String message;
    if (giorni == 0) {
      message = 'ATTENZIONE! Il tuo ${tipo.label} scade oggi!';
    } else {
      message =
          'ATTENZIONE! Il tuo ${tipo.label} scade tra $giorni giorn${giorni == 1 ? 'o' : 'i'}!';
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFB74D), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF9800).withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFE65100).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.warning_amber_rounded,
                color: Color(0xFFE65100), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFE65100),
                  ),
                ),
                if (alerts.length > 1) ...[
                  const SizedBox(height: 2),
                  Text(
                    'e ${alerts.length - 1} altr${alerts.length - 1 == 1 ? 'o documento' : 'i documenti'} in scadenza',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFFBF360C),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Section title
  // -------------------------------------------------------------------------
  Widget _buildSectionTitle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        children: [
          const Text(
            'I tuoi documenti',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_documenti.length}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Empty state
  // -------------------------------------------------------------------------
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.folder_open_rounded,
                size: 48,
                color: AppColors.primary.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Il tuo wallet e vuoto',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Aggiungi il tuo primo documento per\naverlo sempre a portata di mano e\nricevere avvisi prima della scadenza.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textMedium,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: () => _showDocumentoSheet(context),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  gradient: AppColors.buttonGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Aggiungi documento',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // FAB
  // -------------------------------------------------------------------------
  Widget _buildFab() {
    if (_documenti.isEmpty) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () => _showDocumentoSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: AppColors.buttonGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              'AGGIUNGI DOCUMENTO',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Delete confirmation
  // -------------------------------------------------------------------------
  void _confirmDelete(BuildContext context, _Documento doc) {
    final tipo = _DocumentoInfo.tipoByKey(doc.tipoKey);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Elimina documento'),
        content: Text('Vuoi eliminare "${tipo.label}" dal tuo wallet?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _deleteDocumento(doc.id);
            },
            child: const Text(
              'Elimina',
              style: TextStyle(color: Color(0xFFC62828)),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Bottom sheet - Add / Edit
  // -------------------------------------------------------------------------
  void _showDocumentoSheet(BuildContext context, {_Documento? existingDoc}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _DocumentoFormSheet(
        existingDoc: existingDoc,
        onSave: _addOrUpdateDocumento,
        onDelete: existingDoc != null
            ? () {
                Navigator.of(ctx).pop();
                _confirmDelete(context, existingDoc);
              }
            : null,
      ),
    );
  }
}

// ===========================================================================
// Document card widget
// ===========================================================================
class _DocumentoCard extends StatefulWidget {
  final _Documento documento;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _DocumentoCard({
    required this.documento,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<_DocumentoCard> createState() => _DocumentoCardState();
}

class _DocumentoCardState extends State<_DocumentoCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    final giorni = widget.documento.giorniRimanenti;
    final shouldPulse = giorni != null && giorni >= 0 && giorni <= 30;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (shouldPulse) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final doc = widget.documento;
    final tipo = _DocumentoInfo.tipoByKey(doc.tipoKey);
    final giorni = doc.giorniRimanenti;
    final dateFormatter = DateFormat('dd/MM/yyyy');

    return Dismissible(
      key: ValueKey(doc.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: const Color(0xFFC62828),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: Colors.white, size: 28),
      ),
      confirmDismiss: (_) async {
        widget.onDelete();
        return false;
      },
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onDelete,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: giorni != null && giorni <= 30
                  ? doc.coloreScadenza.withValues(alpha: 0.25)
                  : Colors.black.withValues(alpha: 0.03),
            ),
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: tipo.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(tipo.icon, color: tipo.color, size: 26),
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tipo.label,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'N. ${doc.numeroMascherato}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMedium,
                        fontFamily: 'monospace',
                      ),
                    ),
                    if (doc.dataScadenza != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        'Scade: ${dateFormatter.format(doc.dataScadenza!)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: doc.coloreScadenza,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Countdown badge
              if (giorni != null) _buildCountdownBadge(giorni, doc.coloreScadenza),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountdownBadge(int giorni, Color color) {
    final String label;
    if (giorni < 0) {
      label = 'SCADUTO';
    } else if (giorni == 0) {
      label = 'OGGI';
    } else {
      label = '$giorni gg';
    }

    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );

    // Animate only if urgent
    if (giorni >= 0 && giorni <= 30) {
      return AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: child,
          );
        },
        child: badge,
      );
    }

    return badge;
  }
}

// ===========================================================================
// Bottom sheet form
// ===========================================================================
class _DocumentoFormSheet extends StatefulWidget {
  final _Documento? existingDoc;
  final void Function(_Documento doc) onSave;
  final VoidCallback? onDelete;

  const _DocumentoFormSheet({
    this.existingDoc,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<_DocumentoFormSheet> createState() => _DocumentoFormSheetState();
}

class _DocumentoFormSheetState extends State<_DocumentoFormSheet> {
  final _formKey = GlobalKey<FormState>();

  late String _selectedTipoKey;
  late TextEditingController _nomeCtrl;
  late TextEditingController _numeroCtrl;
  late TextEditingController _noteCtrl;
  DateTime? _dataRilascio;
  DateTime? _dataScadenza;

  bool get _isEditing => widget.existingDoc != null;

  @override
  void initState() {
    super.initState();
    final doc = widget.existingDoc;
    _selectedTipoKey = doc?.tipoKey ?? _DocumentoInfo.tipi.first.key;
    _nomeCtrl = TextEditingController(text: doc?.nome ?? '');
    _numeroCtrl = TextEditingController(text: doc?.numero ?? '');
    _noteCtrl = TextEditingController(text: doc?.note ?? '');
    _dataRilascio = doc?.dataRilascio;
    _dataScadenza = doc?.dataScadenza;
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _numeroCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isRilascio) async {
    final initial =
        (isRilascio ? _dataRilascio : _dataScadenza) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
      locale: const Locale('it', 'IT'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isRilascio) {
          _dataRilascio = picked;
        } else {
          _dataScadenza = picked;
        }
      });
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final doc = _Documento(
      id: widget.existingDoc?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      tipoKey: _selectedTipoKey,
      nome: _nomeCtrl.text.trim(),
      numero: _numeroCtrl.text.trim(),
      dataRilascio: _dataRilascio,
      dataScadenza: _dataScadenza,
      note: _noteCtrl.text.trim(),
    );

    widget.onSave(doc);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;
    final dateFormatter = DateFormat('dd/MM/yyyy');

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPad),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title row
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Text(
                    _isEditing ? 'Modifica documento' : 'Nuovo documento',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                  const Spacer(),
                  if (widget.onDelete != null)
                    GestureDetector(
                      onTap: widget.onDelete,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC62828).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.delete_outline_rounded,
                            color: Color(0xFFC62828), size: 20),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Form
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Tipo documento
                      _buildLabel('Tipo di documento'),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedTipoKey,
                        decoration: _inputDecoration('Seleziona tipo'),
                        items: _DocumentoInfo.tipi.map((t) {
                          return DropdownMenuItem<String>(
                            value: t.key,
                            child: Row(
                              children: [
                                Icon(t.icon, size: 18, color: t.color),
                                const SizedBox(width: 10),
                                Text(t.label),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedTipoKey = val);
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Nome documento
                      _buildLabel('Nome / Descrizione'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _nomeCtrl,
                        decoration: _inputDecoration('es. Passaporto italiano'),
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 16),

                      // Numero
                      _buildLabel('Numero documento'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _numeroCtrl,
                        decoration: _inputDecoration('es. YA1234567'),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Inserisci il numero del documento';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Date row
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Data rilascio'),
                                const SizedBox(height: 6),
                                _buildDateField(
                                  value: _dataRilascio,
                                  hint: 'GG/MM/AAAA',
                                  formatter: dateFormatter,
                                  onTap: () => _pickDate(true),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Data scadenza'),
                                const SizedBox(height: 6),
                                _buildDateField(
                                  value: _dataScadenza,
                                  hint: 'GG/MM/AAAA',
                                  formatter: dateFormatter,
                                  onTap: () => _pickDate(false),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Note
                      _buildLabel('Note (opzionale)'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _noteCtrl,
                        decoration: _inputDecoration('Aggiungi note...'),
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      const SizedBox(height: 24),

                      // Save button
                      GestureDetector(
                        onTap: _save,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: AppColors.buttonGradient,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              _isEditing ? 'SALVA MODIFICHE' : 'SALVA DOCUMENTO',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 14),
      filled: true,
      fillColor: AppColors.background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFC62828), width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFC62828), width: 1.5),
      ),
    );
  }

  Widget _buildDateField({
    required DateTime? value,
    required String hint,
    required DateFormat formatter,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value != null ? formatter.format(value) : hint,
                style: TextStyle(
                  fontSize: 14,
                  color: value != null ? AppColors.textDark : AppColors.textLight,
                ),
              ),
            ),
            Icon(
              Icons.calendar_today_rounded,
              size: 16,
              color: value != null
                  ? AppColors.primary
                  : AppColors.textLight,
            ),
          ],
        ),
      ),
    );
  }
}
