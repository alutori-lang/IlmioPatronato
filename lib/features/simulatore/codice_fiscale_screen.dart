import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/constants.dart';

// ═══════════════════════════════════════════════════════════════════
// CODICE FISCALE GENERATOR  –  Algoritmo ufficiale italiano
// ═══════════════════════════════════════════════════════════════════

class CodiceFiscaleScreen extends StatefulWidget {
  const CodiceFiscaleScreen({super.key});

  @override
  State<CodiceFiscaleScreen> createState() => _CodiceFiscaleScreenState();
}

class _CodiceFiscaleScreenState extends State<CodiceFiscaleScreen>
    with SingleTickerProviderStateMixin {
  // ── Form controllers ──
  final _cognomeController = TextEditingController();
  final _nomeController = TextEditingController();
  DateTime? _dataNascita;
  String _sesso = 'M';
  _ComuneEntry? _selectedComune;
  final _comuneSearchController = TextEditingController();

  // ── Result ──
  bool _showResult = false;
  String _codiceFiscale = '';
  String _parteCognome = '';
  String _parteNome = '';
  String _parteAnno = '';
  String _parteMese = '';
  String _parteGiorno = '';
  String _parteCodice = '';
  String _parteCheck = '';

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  // ── Filtered comuni list ──
  List<_ComuneEntry> _filteredComuni = [];
  bool _showComuneDropdown = false;
  final FocusNode _comuneFocusNode = FocusNode();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _filteredComuni = _allComuni;

    _comuneSearchController.addListener(_filterComuni);
    _comuneFocusNode.addListener(() {
      if (_comuneFocusNode.hasFocus) {
        _showOverlay();
      } else {
        _removeOverlay();
      }
    });
  }

  @override
  void dispose() {
    _cognomeController.dispose();
    _nomeController.dispose();
    _comuneSearchController.dispose();
    _comuneFocusNode.dispose();
    _animController.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _filterComuni() {
    final query = _comuneSearchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredComuni = _allComuni;
      } else {
        _filteredComuni = _allComuni
            .where((c) => c.nome.toLowerCase().contains(query))
            .toList();
      }
    });
    _removeOverlay();
    if (_comuneFocusNode.hasFocus) {
      _showOverlay();
    }
  }

  void _showOverlay() {
    _removeOverlay();
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              _comuneFocusNode.unfocus();
            },
            child: const SizedBox.expand(),
          ),
        );
      },
    );
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _showComuneDropdown = true);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (_showComuneDropdown) {
      setState(() => _showComuneDropdown = false);
    }
  }

  // ─────────────────────────────────────────────────────
  // CODICE FISCALE ALGORITHM
  // ─────────────────────────────────────────────────────

  static const _vowels = 'AEIOU';
  static const _monthCodes = [
    'A', 'B', 'C', 'D', 'E', 'H', 'L', 'M', 'P', 'R', 'S', 'T'
  ];

  // Odd-position values (0-indexed positions 0,2,4,... which are positions 1,3,5,... in 1-indexed)
  static const Map<String, int> _oddValues = {
    '0': 1, '1': 0, '2': 5, '3': 7, '4': 9, '5': 13, '6': 15, '7': 17,
    '8': 19, '9': 21,
    'A': 1, 'B': 0, 'C': 5, 'D': 7, 'E': 9, 'F': 13, 'G': 15, 'H': 17,
    'I': 19, 'J': 21, 'K': 2, 'L': 4, 'M': 18, 'N': 20, 'O': 11, 'P': 3,
    'Q': 6, 'R': 8, 'S': 12, 'T': 14, 'U': 16, 'V': 10, 'W': 22, 'X': 25,
    'Y': 24, 'Z': 23,
  };

  // Even-position values
  static const Map<String, int> _evenValues = {
    '0': 0, '1': 1, '2': 2, '3': 3, '4': 4, '5': 5, '6': 6, '7': 7,
    '8': 8, '9': 9,
    'A': 0, 'B': 1, 'C': 2, 'D': 3, 'E': 4, 'F': 5, 'G': 6, 'H': 7,
    'I': 8, 'J': 9, 'K': 10, 'L': 11, 'M': 12, 'N': 13, 'O': 14, 'P': 15,
    'Q': 16, 'R': 17, 'S': 18, 'T': 19, 'U': 20, 'V': 21, 'W': 22, 'X': 23,
    'Y': 24, 'Z': 25,
  };

  static const _checkLetters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

  bool _isVowel(String c) => _vowels.contains(c);

  /// Extract 3 chars from COGNOME: consonants first, then vowels, pad with X
  String _encodeCognome(String cognome) {
    final upper =
        cognome.toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '');
    final consonants =
        upper.split('').where((c) => !_isVowel(c)).toList();
    final vowels =
        upper.split('').where((c) => _isVowel(c)).toList();

    final chars = <String>[];
    chars.addAll(consonants);
    chars.addAll(vowels);
    while (chars.length < 3) {
      chars.add('X');
    }
    return chars.sublist(0, 3).join();
  }

  /// Extract 3 chars from NOME: if >3 consonants take 1st,3rd,4th; else consonants+vowels+X
  String _encodeNome(String nome) {
    final upper =
        nome.toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '');
    final consonants =
        upper.split('').where((c) => !_isVowel(c)).toList();
    final vowels =
        upper.split('').where((c) => _isVowel(c)).toList();

    if (consonants.length > 3) {
      // Take 1st, 3rd, 4th consonant
      return '${consonants[0]}${consonants[2]}${consonants[3]}';
    }

    final chars = <String>[];
    chars.addAll(consonants);
    chars.addAll(vowels);
    while (chars.length < 3) {
      chars.add('X');
    }
    return chars.sublist(0, 3).join();
  }

  /// Calculate the check character (16th character)
  String _calcCheckChar(String first15) {
    final upper = first15.toUpperCase();
    int sum = 0;
    for (int i = 0; i < 15; i++) {
      final c = upper[i];
      if (i % 2 == 0) {
        // Odd position (1-indexed: 1, 3, 5, ...)
        sum += _oddValues[c] ?? 0;
      } else {
        // Even position (1-indexed: 2, 4, 6, ...)
        sum += _evenValues[c] ?? 0;
      }
    }
    return _checkLetters[sum % 26];
  }

  void _genera() {
    final cognome = _cognomeController.text.trim();
    final nome = _nomeController.text.trim();

    if (cognome.isEmpty || nome.isEmpty) {
      _showError('Inserisci cognome e nome');
      return;
    }
    if (_dataNascita == null) {
      _showError('Seleziona la data di nascita');
      return;
    }
    if (_selectedComune == null) {
      _showError('Seleziona il comune o stato di nascita');
      return;
    }

    // 1. COGNOME (3 chars)
    _parteCognome = _encodeCognome(cognome);

    // 2. NOME (3 chars)
    _parteNome = _encodeNome(nome);

    // 3. ANNO (2 digits)
    final year = _dataNascita!.year;
    _parteAnno = (year % 100).toString().padLeft(2, '0');

    // 4. MESE (1 letter)
    _parteMese = _monthCodes[_dataNascita!.month - 1];

    // 5. GIORNO (2 digits; +40 for female)
    final day = _dataNascita!.day;
    final dayCode = _sesso == 'F' ? day + 40 : day;
    _parteGiorno = dayCode.toString().padLeft(2, '0');

    // 6. CODICE CATASTALE (4 chars)
    _parteCodice = _selectedComune!.codice;

    // 7. CHECK CHARACTER
    final first15 =
        '$_parteCognome$_parteNome$_parteAnno$_parteMese$_parteGiorno$_parteCodice';
    _parteCheck = _calcCheckChar(first15);

    _codiceFiscale = '$first15$_parteCheck';

    setState(() => _showResult = true);
    _animController.forward(from: 0);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFF44336),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _codiceFiscale));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Codice Fiscale copiato!'),
          ],
        ),
        backgroundColor: const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dataNascita ?? DateTime(1990, 1, 1),
      firstDate: DateTime(1900),
      lastDate: now,
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
      setState(() => _dataNascita = picked);
    }
  }

  // ─────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context)),
            SliverToBoxAdapter(child: _buildInfoBanner()),
            SliverToBoxAdapter(child: _sectionTitle('Dati Anagrafici')),
            SliverToBoxAdapter(child: _buildAnagraficaSection()),
            SliverToBoxAdapter(child: _sectionTitle('Data di Nascita e Sesso')),
            SliverToBoxAdapter(child: _buildDataSessoSection()),
            SliverToBoxAdapter(
                child: _sectionTitle('Comune / Stato di Nascita')),
            SliverToBoxAdapter(child: _buildComuneSection()),
            SliverToBoxAdapter(child: _buildGeneraButton()),
            if (_showResult)
              SliverToBoxAdapter(child: _buildResultCard()),
            if (_showResult)
              SliverToBoxAdapter(child: _buildBreakdownCard()),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  // ── Header ──
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
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back,
                  color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF1976D2), Color(0xFF42A5F5)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                const Icon(Icons.badge, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CODICE FISCALE',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5)),
                SizedBox(height: 1),
                Text('Generatore con algoritmo ufficiale',
                    style: TextStyle(
                        color: AppColors.textSubtitle, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Info banner ──
  Widget _buildInfoBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: const Color(0xFF1565C0).withValues(alpha: 0.2)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Color(0xFF1565C0), size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Calcola il codice fiscale utilizzando l\'algoritmo ufficiale italiano. '
              'Inserisci tutti i dati richiesti per generare il CF corretto.',
              style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF0D47A1),
                  height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Text(title,
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark)),
    );
  }

  // ── Anagrafica (Cognome + Nome) ──
  Widget _buildAnagraficaSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _buildTextField(
            controller: _cognomeController,
            label: 'Cognome',
            icon: Icons.person_outline,
            hint: 'Es: Rossi',
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _nomeController,
            label: 'Nome',
            icon: Icons.person,
            hint: 'Es: Mario',
          ),
        ],
      ),
    );
  }

  // ── Data di nascita + Sesso ──
  Widget _buildDataSessoSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          // Date picker
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today,
                      size: 20, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _dataNascita != null
                          ? '${_dataNascita!.day.toString().padLeft(2, '0')}/${_dataNascita!.month.toString().padLeft(2, '0')}/${_dataNascita!.year}'
                          : 'Seleziona data di nascita',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: _dataNascita != null
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: _dataNascita != null
                            ? AppColors.textDark
                            : AppColors.textLight,
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_drop_down,
                      color: AppColors.textMedium),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Gender selector
          Row(
            children: [
              const Text('Sesso:',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark)),
              const SizedBox(width: 20),
              Expanded(
                child: Row(
                  children: [
                    _buildGenderOption('M', 'Maschio', Icons.male),
                    const SizedBox(width: 12),
                    _buildGenderOption('F', 'Femmina', Icons.female),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGenderOption(String value, String label, IconData icon) {
    final selected = _sesso == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _sesso = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.1)
                : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.primary : Colors.grey.shade200,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 20,
                  color: selected
                      ? AppColors.primary
                      : AppColors.textMedium),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? AppColors.primary
                      : AppColors.textMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Comune / Stato di nascita ──
  Widget _buildComuneSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cerca il comune italiano o lo stato estero di nascita',
            style: TextStyle(
                fontSize: 12,
                color: AppColors.textMedium,
                height: 1.3),
          ),
          const SizedBox(height: 12),
          // Search field
          TextField(
            controller: _comuneSearchController,
            focusNode: _comuneFocusNode,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.textDark),
            decoration: InputDecoration(
              labelText: 'Comune o Stato di nascita',
              labelStyle: const TextStyle(
                  fontSize: 13, color: AppColors.textMedium),
              hintText: 'Es: Roma, Milano, Albania...',
              hintStyle: TextStyle(
                  fontSize: 13, color: Colors.grey.shade400),
              prefixIcon: const Icon(Icons.search,
                  color: AppColors.primary, size: 20),
              suffixIcon: _comuneSearchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _comuneSearchController.clear();
                        setState(() => _selectedComune = null);
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: AppColors.primary, width: 2)),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
            ),
          ),
          // Selected comune chip
          if (_selectedComune != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    _selectedComune!.isEstero
                        ? Icons.public
                        : Icons.location_city,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_selectedComune!.nome}  (${_selectedComune!.codice})',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedComune = null;
                        _comuneSearchController.clear();
                      });
                    },
                    child: const Icon(Icons.close,
                        size: 16, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ],
          // Dropdown list
          if (_showComuneDropdown && _selectedComune == null)
            Container(
              margin: const EdgeInsets.only(top: 6),
              constraints: const BoxConstraints(maxHeight: 220),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _filteredComuni.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Nessun risultato trovato',
                          style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textLight)),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      shrinkWrap: true,
                      itemCount: _filteredComuni.length > 50
                          ? 50
                          : _filteredComuni.length,
                      separatorBuilder: (_, _) => Divider(
                          height: 1,
                          color: Colors.grey.shade100),
                      itemBuilder: (context, index) {
                        final comune = _filteredComuni[index];
                        return ListTile(
                          dense: true,
                          visualDensity: const VisualDensity(
                              vertical: -2),
                          leading: Icon(
                            comune.isEstero
                                ? Icons.public
                                : Icons.location_city,
                            size: 18,
                            color: comune.isEstero
                                ? const Color(0xFFE65100)
                                : AppColors.primary,
                          ),
                          title: Text(
                            comune.nome,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark),
                          ),
                          trailing: Text(
                            comune.codice,
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textLight,
                                fontFamily: 'monospace'),
                          ),
                          onTap: () {
                            setState(() {
                              _selectedComune = comune;
                              _comuneSearchController.text =
                                  comune.nome;
                            });
                            _comuneFocusNode.unfocus();
                          },
                        );
                      },
                    ),
            ),
        ],
      ),
    );
  }

  // ── Genera button ──
  Widget _buildGeneraButton() {
    return GestureDetector(
      onTap: _genera,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 24, 16, 0),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: AppColors.buttonGradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.badge, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text('GENERA CODICE FISCALE',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8)),
          ],
        ),
      ),
    );
  }

  // ── Result card ──
  Widget _buildResultCard() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Text('IL TUO CODICE FISCALE',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1)),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    vertical: 14, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _codiceFiscale,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: _copyToClipboard,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color:
                            Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.copy,
                          color: Colors.white, size: 16),
                      SizedBox(width: 8),
                      Text('COPIA NEGLI APPUNTI',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Breakdown card ──
  Widget _buildBreakdownCard() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Composizione del Codice',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark)),
            const SizedBox(height: 6),
            const Text(
                'Ogni parte del codice fiscale deriva dai tuoi dati anagrafici',
                style: TextStyle(
                    fontSize: 11, color: AppColors.textLight)),
            const SizedBox(height: 16),
            // Visual breakdown
            _buildColoredBreakdown(),
            const SizedBox(height: 18),
            // Detail rows
            _breakdownRow(
                'Cognome', _parteCognome, _cognomeController.text,
                color: const Color(0xFF1565C0)),
            _breakdownRow(
                'Nome', _parteNome, _nomeController.text,
                color: const Color(0xFF2E7D32)),
            _breakdownRow('Anno di nascita', _parteAnno,
                _dataNascita!.year.toString(),
                color: const Color(0xFFE65100)),
            _breakdownRow('Mese di nascita', _parteMese,
                _meseNome(_dataNascita!.month),
                color: const Color(0xFF6A1B9A)),
            _breakdownRow(
                'Giorno + sesso',
                _parteGiorno,
                '${_dataNascita!.day} (${_sesso == 'M' ? 'Maschio' : 'Femmina'})',
                color: const Color(0xFFC62828)),
            _breakdownRow('Codice catastale', _parteCodice,
                _selectedComune!.nome,
                color: const Color(0xFF00695C)),
            _breakdownRow(
                'Carattere di controllo', _parteCheck, 'Calcolato',
                color: const Color(0xFF37474F)),
          ],
        ),
      ),
    );
  }

  Widget _buildColoredBreakdown() {
    final parts = <_CFPart>[
      _CFPart(_parteCognome, 'CGN', const Color(0xFF1565C0)),
      _CFPart(_parteNome, 'NME', const Color(0xFF2E7D32)),
      _CFPart(_parteAnno, 'AN', const Color(0xFFE65100)),
      _CFPart(_parteMese, 'MS', const Color(0xFF6A1B9A)),
      _CFPart(_parteGiorno, 'GG', const Color(0xFFC62828)),
      _CFPart(_parteCodice, 'COD', const Color(0xFF00695C)),
      _CFPart(_parteCheck, 'CK', const Color(0xFF37474F)),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // CF characters with colors
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final part in parts)
                for (int i = 0; i < part.value.length; i++)
                  Container(
                    width: 20,
                    height: 28,
                    margin: const EdgeInsets.symmetric(horizontal: 0.5),
                    decoration: BoxDecoration(
                      color: part.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      part.value[i],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: part.color,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
            ],
          ),
          const SizedBox(height: 8),
          // Labels row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final part in parts)
                Container(
                  width: (21.0 * part.value.length),
                  alignment: Alignment.center,
                  child: Text(
                    part.label,
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: part.color,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _breakdownRow(String label, String code, String detail,
      {required Color color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 44,
            padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Text(
              code,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: color,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark)),
                Text(detail,
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textLight)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _meseNome(int month) {
    const nomi = [
      'Gennaio', 'Febbraio', 'Marzo', 'Aprile', 'Maggio', 'Giugno',
      'Luglio', 'Agosto', 'Settembre', 'Ottobre', 'Novembre', 'Dicembre'
    ];
    return nomi[month - 1];
  }

  // ─────────────────────────────────────────────────────
  // REUSABLE WIDGETS
  // ─────────────────────────────────────────────────────
  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 3)),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return TextField(
      controller: controller,
      textCapitalization: TextCapitalization.characters,
      style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            const TextStyle(fontSize: 13, color: AppColors.textMedium),
        hintText: hint,
        hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppColors.primary, width: 2)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// CF PART – for visual breakdown
// ─────────────────────────────────────────────────────
class _CFPart {
  final String value;
  final String label;
  final Color color;
  const _CFPart(this.value, this.label, this.color);
}

// ─────────────────────────────────────────────────────
// COMUNE / STATO ENTRY
// ─────────────────────────────────────────────────────
class _ComuneEntry {
  final String nome;
  final String codice;
  final bool isEstero;
  const _ComuneEntry(this.nome, this.codice, {this.isEstero = false});
}

// ═══════════════════════════════════════════════════════════════════
// DATABASE COMUNI + STATI ESTERI
// Codici catastali ufficiali
// ═══════════════════════════════════════════════════════════════════
const List<_ComuneEntry> _allComuni = [
  // ── CAPOLUOGHI DI REGIONE ──
  _ComuneEntry('Roma', 'H501'),
  _ComuneEntry('Milano', 'F205'),
  _ComuneEntry('Napoli', 'F839'),
  _ComuneEntry('Torino', 'L219'),
  _ComuneEntry('Palermo', 'G273'),
  _ComuneEntry('Genova', 'D969'),
  _ComuneEntry('Bologna', 'A944'),
  _ComuneEntry('Firenze', 'D612'),
  _ComuneEntry('Bari', 'A662'),
  _ComuneEntry('Catania', 'C351'),
  _ComuneEntry('Venezia', 'L736'),
  _ComuneEntry('Verona', 'L781'),
  _ComuneEntry('Messina', 'F158'),
  _ComuneEntry('Padova', 'G224'),
  _ComuneEntry('Trieste', 'L424'),
  _ComuneEntry('Brescia', 'B157'),
  _ComuneEntry('Taranto', 'L049'),
  _ComuneEntry('Prato', 'G999'),
  _ComuneEntry('Reggio Calabria', 'H224'),
  _ComuneEntry('Modena', 'F257'),
  _ComuneEntry('Reggio Emilia', 'H223'),
  _ComuneEntry('Perugia', 'G478'),
  _ComuneEntry('Livorno', 'E625'),
  _ComuneEntry('Ravenna', 'H199'),
  _ComuneEntry('Cagliari', 'B354'),
  _ComuneEntry('Foggia', 'D643'),
  _ComuneEntry('Rimini', 'H294'),
  _ComuneEntry('Salerno', 'H703'),
  _ComuneEntry('Ferrara', 'D548'),
  _ComuneEntry('Sassari', 'I452'),
  _ComuneEntry('Latina', 'E472'),
  _ComuneEntry('Monza', 'F704'),
  _ComuneEntry('Siracusa', 'I754'),
  _ComuneEntry('Bergamo', 'A794'),
  _ComuneEntry('Pescara', 'G482'),
  _ComuneEntry('Trento', 'L378'),
  _ComuneEntry('Forlì', 'D704'),
  _ComuneEntry('Vicenza', 'L840'),
  _ComuneEntry('Terni', 'L117'),
  _ComuneEntry('Bolzano', 'A952'),
  _ComuneEntry('Novara', 'F952'),
  _ComuneEntry('Piacenza', 'G535'),
  _ComuneEntry('Ancona', 'A271'),
  _ComuneEntry('Andria', 'A285'),
  _ComuneEntry('Arezzo', 'A390'),
  _ComuneEntry('Udine', 'L483'),
  _ComuneEntry('Cesena', 'C573'),
  _ComuneEntry('Lecce', 'E506'),
  _ComuneEntry('Pesaro', 'G479'),
  _ComuneEntry('Alessandria', 'A182'),
  _ComuneEntry('Catanzaro', 'C352'),
  _ComuneEntry('Potenza', 'G942'),
  _ComuneEntry('L\'Aquila', 'A345'),
  _ComuneEntry('Campobasso', 'B519'),

  // ── ALTRE CITTA\' IMPORTANTI ──
  _ComuneEntry('Parma', 'G337'),
  _ComuneEntry('Pisa', 'G702'),
  _ComuneEntry('Como', 'C933'),
  _ComuneEntry('Lucca', 'E715'),
  _ComuneEntry('Treviso', 'L407'),
  _ComuneEntry('Varese', 'L682'),
  _ComuneEntry('La Spezia', 'E463'),
  _ComuneEntry('Siena', 'I726'),
  _ComuneEntry('Ragusa', 'H163'),
  _ComuneEntry('Trapani', 'L331'),
  _ComuneEntry('Cosenza', 'D086'),
  _ComuneEntry('Agrigento', 'A089'),
  _ComuneEntry('Crotone', 'D122'),
  _ComuneEntry('Vibo Valentia', 'F537'),
  _ComuneEntry('Avellino', 'A509'),
  _ComuneEntry('Benevento', 'A783'),
  _ComuneEntry('Caserta', 'B963'),
  _ComuneEntry('Enna', 'C342'),
  _ComuneEntry('Matera', 'F052'),
  _ComuneEntry('Nuoro', 'F979'),
  _ComuneEntry('Oristano', 'G113'),
  _ComuneEntry('Isernia', 'E335'),
  _ComuneEntry('Aosta', 'A326'),
  _ComuneEntry('Mantova', 'E897'),
  _ComuneEntry('Cremona', 'D150'),
  _ComuneEntry('Lodi', 'E648'),
  _ComuneEntry('Lecco', 'E507'),
  _ComuneEntry('Sondrio', 'I829'),
  _ComuneEntry('Pavia', 'G388'),
  _ComuneEntry('Imperia', 'E290'),
  _ComuneEntry('Savona', 'I480'),
  _ComuneEntry('Asti', 'A479'),
  _ComuneEntry('Cuneo', 'D205'),
  _ComuneEntry('Biella', 'A859'),
  _ComuneEntry('Verbania', 'L746'),
  _ComuneEntry('Vercelli', 'L750'),
  _ComuneEntry('Belluno', 'A757'),
  _ComuneEntry('Rovigo', 'H620'),
  _ComuneEntry('Pordenone', 'G888'),
  _ComuneEntry('Gorizia', 'E098'),
  _ComuneEntry('Grosseto', 'E202'),
  _ComuneEntry('Massa', 'F023'),
  _ComuneEntry('Pistoia', 'G713'),
  _ComuneEntry('Ascoli Piceno', 'A462'),
  _ComuneEntry('Fermo', 'D542'),
  _ComuneEntry('Macerata', 'E783'),
  _ComuneEntry('Rieti', 'H282'),
  _ComuneEntry('Viterbo', 'M082'),
  _ComuneEntry('Frosinone', 'D810'),
  _ComuneEntry('Chieti', 'C632'),
  _ComuneEntry('Teramo', 'L103'),
  _ComuneEntry('Brindisi', 'B180'),
  _ComuneEntry('Caltanissetta', 'B429'),
  _ComuneEntry('Carbonia', 'B745'),
  _ComuneEntry('Iglesias', 'E281'),
  _ComuneEntry('Olbia', 'D938'),
  _ComuneEntry('Tempio Pausania', 'L093'),
  _ComuneEntry('Lanusei', 'E441'),
  _ComuneEntry('Tortolì', 'A355'),
  _ComuneEntry('Sanluri', 'H974'),
  _ComuneEntry('Villacidro', 'L924'),
  _ComuneEntry('Giugliano in Campania', 'E054'),
  _ComuneEntry('Torre del Greco', 'L259'),
  _ComuneEntry('Pozzuoli', 'G964'),
  _ComuneEntry('Castellammare di Stabia', 'C129'),
  _ComuneEntry('Guidonia Montecelio', 'E263'),
  _ComuneEntry('Fiumicino', 'M297'),
  _ComuneEntry('Cinisello Balsamo', 'C707'),
  _ComuneEntry('Sesto San Giovanni', 'I690'),
  _ComuneEntry('Busto Arsizio', 'B300'),
  _ComuneEntry('Gallarate', 'D869'),
  _ComuneEntry('Legnano', 'E514'),
  _ComuneEntry('Rho', 'H264'),
  _ComuneEntry('Cologno Monzese', 'C895'),
  _ComuneEntry('Mestre (Venezia)', 'L736'), // Same code as Venezia
  _ComuneEntry('Moncalieri', 'F335'),
  _ComuneEntry('Rivoli', 'H355'),
  _ComuneEntry('Collegno', 'C860'),
  _ComuneEntry('Settimo Torinese', 'I703'),

  // ── STATI ESTERI ── (codici catastali Z + 3 cifre)
  // EUROPA
  _ComuneEntry('Albania', 'Z100', isEstero: true),
  _ComuneEntry('Andorra', 'Z101', isEstero: true),
  _ComuneEntry('Austria', 'Z102', isEstero: true),
  _ComuneEntry('Belgio', 'Z103', isEstero: true),
  _ComuneEntry('Bulgaria', 'Z104', isEstero: true),
  _ComuneEntry('Cipro', 'Z211', isEstero: true),
  _ComuneEntry('Croazia', 'Z149', isEstero: true),
  _ComuneEntry('Danimarca', 'Z107', isEstero: true),
  _ComuneEntry('Estonia', 'Z144', isEstero: true),
  _ComuneEntry('Finlandia', 'Z109', isEstero: true),
  _ComuneEntry('Francia', 'Z110', isEstero: true),
  _ComuneEntry('Germania', 'Z112', isEstero: true),
  _ComuneEntry('Grecia', 'Z115', isEstero: true),
  _ComuneEntry('Irlanda', 'Z116', isEstero: true),
  _ComuneEntry('Islanda', 'Z117', isEstero: true),
  _ComuneEntry('Kosovo', 'Z160', isEstero: true),
  _ComuneEntry('Lettonia', 'Z145', isEstero: true),
  _ComuneEntry('Liechtenstein', 'Z119', isEstero: true),
  _ComuneEntry('Lituania', 'Z146', isEstero: true),
  _ComuneEntry('Lussemburgo', 'Z120', isEstero: true),
  _ComuneEntry('Macedonia del Nord', 'Z148', isEstero: true),
  _ComuneEntry('Malta', 'Z121', isEstero: true),
  _ComuneEntry('Moldavia', 'Z140', isEstero: true),
  _ComuneEntry('Monaco', 'Z123', isEstero: true),
  _ComuneEntry('Montenegro', 'Z159', isEstero: true),
  _ComuneEntry('Norvegia', 'Z124', isEstero: true),
  _ComuneEntry('Paesi Bassi (Olanda)', 'Z126', isEstero: true),
  _ComuneEntry('Polonia', 'Z127', isEstero: true),
  _ComuneEntry('Portogallo', 'Z128', isEstero: true),
  _ComuneEntry('Regno Unito', 'Z114', isEstero: true),
  _ComuneEntry('Repubblica Ceca', 'Z156', isEstero: true),
  _ComuneEntry('Romania', 'Z129', isEstero: true),
  _ComuneEntry('Russia', 'Z154', isEstero: true),
  _ComuneEntry('San Marino', 'Z130', isEstero: true),
  _ComuneEntry('Serbia', 'Z158', isEstero: true),
  _ComuneEntry('Slovacchia', 'Z155', isEstero: true),
  _ComuneEntry('Slovenia', 'Z150', isEstero: true),
  _ComuneEntry('Spagna', 'Z131', isEstero: true),
  _ComuneEntry('Svezia', 'Z132', isEstero: true),
  _ComuneEntry('Svizzera', 'Z133', isEstero: true),
  _ComuneEntry('Turchia', 'Z243', isEstero: true),
  _ComuneEntry('Ucraina', 'Z138', isEstero: true),
  _ComuneEntry('Ungheria', 'Z134', isEstero: true),
  _ComuneEntry('Bielorussia', 'Z139', isEstero: true),
  _ComuneEntry('Bosnia-Erzegovina', 'Z153', isEstero: true),
  _ComuneEntry('Città del Vaticano', 'Z106', isEstero: true),

  // AFRICA
  _ComuneEntry('Algeria', 'Z301', isEstero: true),
  _ComuneEntry('Angola', 'Z302', isEstero: true),
  _ComuneEntry('Benin', 'Z314', isEstero: true),
  _ComuneEntry('Botswana', 'Z358', isEstero: true),
  _ComuneEntry('Burkina Faso', 'Z354', isEstero: true),
  _ComuneEntry('Burundi', 'Z305', isEstero: true),
  _ComuneEntry('Camerun', 'Z306', isEstero: true),
  _ComuneEntry('Capo Verde', 'Z307', isEstero: true),
  _ComuneEntry('Ciad', 'Z309', isEstero: true),
  _ComuneEntry('Comore', 'Z310', isEstero: true),
  _ComuneEntry('Congo', 'Z311', isEstero: true),
  _ComuneEntry('Congo (Rep. Dem.)', 'Z312', isEstero: true),
  _ComuneEntry('Costa d\'Avorio', 'Z313', isEstero: true),
  _ComuneEntry('Egitto', 'Z336', isEstero: true),
  _ComuneEntry('Eritrea', 'Z368', isEstero: true),
  _ComuneEntry('Eswatini (Swaziland)', 'Z349', isEstero: true),
  _ComuneEntry('Etiopia', 'Z315', isEstero: true),
  _ComuneEntry('Gabon', 'Z316', isEstero: true),
  _ComuneEntry('Gambia', 'Z317', isEstero: true),
  _ComuneEntry('Ghana', 'Z318', isEstero: true),
  _ComuneEntry('Gibuti', 'Z361', isEstero: true),
  _ComuneEntry('Guinea', 'Z319', isEstero: true),
  _ComuneEntry('Guinea Bissau', 'Z320', isEstero: true),
  _ComuneEntry('Guinea Equatoriale', 'Z321', isEstero: true),
  _ComuneEntry('Kenya', 'Z322', isEstero: true),
  _ComuneEntry('Lesotho', 'Z359', isEstero: true),
  _ComuneEntry('Liberia', 'Z325', isEstero: true),
  _ComuneEntry('Libia', 'Z326', isEstero: true),
  _ComuneEntry('Madagascar', 'Z327', isEstero: true),
  _ComuneEntry('Malawi', 'Z328', isEstero: true),
  _ComuneEntry('Mali', 'Z329', isEstero: true),
  _ComuneEntry('Marocco', 'Z330', isEstero: true),
  _ComuneEntry('Mauritania', 'Z331', isEstero: true),
  _ComuneEntry('Mauritius', 'Z332', isEstero: true),
  _ComuneEntry('Mozambico', 'Z333', isEstero: true),
  _ComuneEntry('Namibia', 'Z300', isEstero: true),
  _ComuneEntry('Niger', 'Z334', isEstero: true),
  _ComuneEntry('Nigeria', 'Z335', isEstero: true),
  _ComuneEntry('Rep. Centrafricana', 'Z308', isEstero: true),
  _ComuneEntry('Ruanda', 'Z338', isEstero: true),
  _ComuneEntry('Senegal', 'Z343', isEstero: true),
  _ComuneEntry('Seychelles', 'Z342', isEstero: true),
  _ComuneEntry('Sierra Leone', 'Z344', isEstero: true),
  _ComuneEntry('Somalia', 'Z345', isEstero: true),
  _ComuneEntry('Sudafrica', 'Z347', isEstero: true),
  _ComuneEntry('Sudan', 'Z348', isEstero: true),
  _ComuneEntry('Sud Sudan', 'Z907', isEstero: true),
  _ComuneEntry('Tanzania', 'Z357', isEstero: true),
  _ComuneEntry('Togo', 'Z351', isEstero: true),
  _ComuneEntry('Tunisia', 'Z352', isEstero: true),
  _ComuneEntry('Uganda', 'Z353', isEstero: true),
  _ComuneEntry('Zambia', 'Z355', isEstero: true),
  _ComuneEntry('Zimbabwe', 'Z337', isEstero: true),

  // ASIA
  _ComuneEntry('Afghanistan', 'Z200', isEstero: true),
  _ComuneEntry('Arabia Saudita', 'Z203', isEstero: true),
  _ComuneEntry('Armenia', 'Z252', isEstero: true),
  _ComuneEntry('Azerbaigian', 'Z253', isEstero: true),
  _ComuneEntry('Bahrein', 'Z204', isEstero: true),
  _ComuneEntry('Bangladesh', 'Z249', isEstero: true),
  _ComuneEntry('Bhutan', 'Z205', isEstero: true),
  _ComuneEntry('Birmania (Myanmar)', 'Z206', isEstero: true),
  _ComuneEntry('Brunei', 'Z207', isEstero: true),
  _ComuneEntry('Cambogia', 'Z208', isEstero: true),
  _ComuneEntry('Cina', 'Z210', isEstero: true),
  _ComuneEntry('Corea del Nord', 'Z214', isEstero: true),
  _ComuneEntry('Corea del Sud', 'Z213', isEstero: true),
  _ComuneEntry('Emirati Arabi Uniti', 'Z215', isEstero: true),
  _ComuneEntry('Filippine', 'Z216', isEstero: true),
  _ComuneEntry('Georgia', 'Z254', isEstero: true),
  _ComuneEntry('Giappone', 'Z219', isEstero: true),
  _ComuneEntry('Giordania', 'Z220', isEstero: true),
  _ComuneEntry('India', 'Z222', isEstero: true),
  _ComuneEntry('Indonesia', 'Z223', isEstero: true),
  _ComuneEntry('Iran', 'Z224', isEstero: true),
  _ComuneEntry('Iraq', 'Z225', isEstero: true),
  _ComuneEntry('Israele', 'Z226', isEstero: true),
  _ComuneEntry('Kazakistan', 'Z255', isEstero: true),
  _ComuneEntry('Kirghizistan', 'Z256', isEstero: true),
  _ComuneEntry('Kuwait', 'Z227', isEstero: true),
  _ComuneEntry('Laos', 'Z228', isEstero: true),
  _ComuneEntry('Libano', 'Z229', isEstero: true),
  _ComuneEntry('Malaysia', 'Z247', isEstero: true),
  _ComuneEntry('Maldive', 'Z232', isEstero: true),
  _ComuneEntry('Mongolia', 'Z233', isEstero: true),
  _ComuneEntry('Nepal', 'Z234', isEstero: true),
  _ComuneEntry('Oman', 'Z235', isEstero: true),
  _ComuneEntry('Pakistan', 'Z236', isEstero: true),
  _ComuneEntry('Palestina', 'Z161', isEstero: true),
  _ComuneEntry('Qatar', 'Z237', isEstero: true),
  _ComuneEntry('Singapore', 'Z248', isEstero: true),
  _ComuneEntry('Siria', 'Z240', isEstero: true),
  _ComuneEntry('Sri Lanka', 'Z209', isEstero: true),
  _ComuneEntry('Tagikistan', 'Z257', isEstero: true),
  _ComuneEntry('Taiwan', 'Z217', isEstero: true),
  _ComuneEntry('Thailandia', 'Z241', isEstero: true),
  _ComuneEntry('Timor Est', 'Z242', isEstero: true),
  _ComuneEntry('Turkmenistan', 'Z258', isEstero: true),
  _ComuneEntry('Uzbekistan', 'Z259', isEstero: true),
  _ComuneEntry('Vietnam', 'Z251', isEstero: true),
  _ComuneEntry('Yemen', 'Z246', isEstero: true),

  // AMERICHE
  _ComuneEntry('Argentina', 'Z600', isEstero: true),
  _ComuneEntry('Bahamas', 'Z502', isEstero: true),
  _ComuneEntry('Barbados', 'Z522', isEstero: true),
  _ComuneEntry('Belize', 'Z512', isEstero: true),
  _ComuneEntry('Bolivia', 'Z601', isEstero: true),
  _ComuneEntry('Brasile', 'Z602', isEstero: true),
  _ComuneEntry('Canada', 'Z401', isEstero: true),
  _ComuneEntry('Cile', 'Z603', isEstero: true),
  _ComuneEntry('Colombia', 'Z604', isEstero: true),
  _ComuneEntry('Costa Rica', 'Z503', isEstero: true),
  _ComuneEntry('Cuba', 'Z504', isEstero: true),
  _ComuneEntry('Dominica', 'Z526', isEstero: true),
  _ComuneEntry('Ecuador', 'Z605', isEstero: true),
  _ComuneEntry('El Salvador', 'Z506', isEstero: true),
  _ComuneEntry('Giamaica', 'Z507', isEstero: true),
  _ComuneEntry('Guatemala', 'Z509', isEstero: true),
  _ComuneEntry('Guyana', 'Z606', isEstero: true),
  _ComuneEntry('Haiti', 'Z510', isEstero: true),
  _ComuneEntry('Honduras', 'Z511', isEstero: true),
  _ComuneEntry('Messico', 'Z514', isEstero: true),
  _ComuneEntry('Nicaragua', 'Z515', isEstero: true),
  _ComuneEntry('Panama', 'Z516', isEstero: true),
  _ComuneEntry('Paraguay', 'Z610', isEstero: true),
  _ComuneEntry('Perù', 'Z611', isEstero: true),
  _ComuneEntry('Rep. Dominicana', 'Z505', isEstero: true),
  _ComuneEntry('Stati Uniti d\'America', 'Z404', isEstero: true),
  _ComuneEntry('Suriname', 'Z608', isEstero: true),
  _ComuneEntry('Trinidad e Tobago', 'Z612', isEstero: true),
  _ComuneEntry('Uruguay', 'Z613', isEstero: true),
  _ComuneEntry('Venezuela', 'Z614', isEstero: true),

  // OCEANIA
  _ComuneEntry('Australia', 'Z700', isEstero: true),
  _ComuneEntry('Fiji', 'Z704', isEstero: true),
  _ComuneEntry('Kiribati', 'Z731', isEstero: true),
  _ComuneEntry('Isole Marshall', 'Z711', isEstero: true),
  _ComuneEntry('Micronesia', 'Z735', isEstero: true),
  _ComuneEntry('Nauru', 'Z713', isEstero: true),
  _ComuneEntry('Nuova Zelanda', 'Z719', isEstero: true),
  _ComuneEntry('Palau', 'Z734', isEstero: true),
  _ComuneEntry('Papua Nuova Guinea', 'Z730', isEstero: true),
  _ComuneEntry('Samoa', 'Z726', isEstero: true),
  _ComuneEntry('Isole Salomone', 'Z724', isEstero: true),
  _ComuneEntry('Tonga', 'Z728', isEstero: true),
  _ComuneEntry('Tuvalu', 'Z732', isEstero: true),
  _ComuneEntry('Vanuatu', 'Z733', isEstero: true),
];
