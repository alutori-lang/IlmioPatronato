import 'package:flutter/material.dart';
import '../../config/constants.dart';

class CittadinanzaScreen extends StatefulWidget {
  const CittadinanzaScreen({super.key});

  @override
  State<CittadinanzaScreen> createState() => _CittadinanzaScreenState();
}

class _CittadinanzaScreenState extends State<CittadinanzaScreen>
    with SingleTickerProviderStateMixin {
  // Step 1: tipo domanda
  String _tipoDomanda = 'residenza'; // 'residenza' | 'matrimonio'

  // Step 2 residenza
  String _nazionalita = 'extracomunitario'; // 'extracomunitario' | 'ue'

  // Step 2 matrimonio
  bool _haFigli = false;
  bool _risiedeInItalia = true;

  // Step 3
  DateTime? _dataChiave;

  // Result
  bool _showResult = false;
  bool _isEligible = false;
  DateTime? _dataIdonea;
  int _anniMancanti = 0;
  int _mesiMancanti = 0;
  int _giorniMancanti = 0;
  double _progressPercent = 0.0;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  /// Returns the number of years required based on Italian citizenship law.
  int _anniRichiesti() {
    if (_tipoDomanda == 'residenza') {
      return _nazionalita == 'ue' ? 4 : 10;
    }
    // Matrimonio
    if (_risiedeInItalia) {
      return _haFigli ? 1 : 2;
    }
    // Residente all'estero - in mesi we handle separately
    return _haFigli ? 0 : 3; // 0 signals "18 mesi" handled in _calcolaMesi
  }

  int _mesiRichiesti() {
    if (_tipoDomanda == 'matrimonio' && !_risiedeInItalia && _haFigli) {
      return 18;
    }
    return _anniRichiesti() * 12;
  }

  void _calcola() {
    if (_dataChiave == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seleziona la data prima di calcolare'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final now = DateTime.now();
    final mesiTotali = _mesiRichiesti();
    final dataIdonea = DateTime(
      _dataChiave!.year + (mesiTotali ~/ 12),
      _dataChiave!.month + (mesiTotali % 12),
      _dataChiave!.day,
    );

    final eligible = now.isAfter(dataIdonea) || now.isAtSameMomentAs(dataIdonea);

    // Calculate remaining time
    int anniM = 0;
    int mesiM = 0;
    int giorniM = 0;
    double progress = 1.0;

    if (!eligible) {
      final totalDiff = dataIdonea.difference(_dataChiave!);
      final elapsed = now.difference(_dataChiave!);
      progress = totalDiff.inDays > 0
          ? (elapsed.inDays / totalDiff.inDays).clamp(0.0, 1.0)
          : 0.0;

      // Calculate anni, mesi, giorni mancanti
      DateTime temp = now;
      while (DateTime(temp.year + 1, temp.month, temp.day)
          .isBefore(dataIdonea)) {
        anniM++;
        temp = DateTime(temp.year + 1, temp.month, temp.day);
      }
      while (DateTime(temp.year, temp.month + 1, temp.day)
          .isBefore(dataIdonea)) {
        mesiM++;
        temp = DateTime(temp.year, temp.month + 1, temp.day);
      }
      giorniM = dataIdonea.difference(temp).inDays;
    }

    setState(() {
      _showResult = true;
      _isEligible = eligible;
      _dataIdonea = dataIdonea;
      _anniMancanti = anniM;
      _mesiMancanti = mesiM;
      _giorniMancanti = giorniM;
      _progressPercent = progress;
    });

    _animController.reset();
    _animController.forward();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dataChiave ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      locale: const Locale('it', 'IT'),
      helpText: _tipoDomanda == 'residenza'
          ? 'Data prima iscrizione anagrafe'
          : 'Data del matrimonio',
    );
    if (picked != null) {
      setState(() {
        _dataChiave = picked;
        _showResult = false;
      });
    }
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(context)),
          SliverToBoxAdapter(child: _buildStep1()),
          SliverToBoxAdapter(child: _buildStep2()),
          SliverToBoxAdapter(child: _buildStep3()),
          SliverToBoxAdapter(child: _buildCalcolaButton()),
          if (_showResult) ...[
            SliverToBoxAdapter(child: _buildResultCard()),
            SliverToBoxAdapter(child: _buildInfoCard()),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 6,
        right: 20,
        bottom: 14,
      ),
      decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white, size: 18),
          ),
          const Icon(Icons.flag, color: Colors.white, size: 22),
          const SizedBox(width: 10),
          const Text(
            'Countdown Cittadinanza',
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String number, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: AppColors.buttonGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('1', 'Tipo domanda'),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 15,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              RadioListTile<String>(
                title: const Text('Per Residenza',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: const Text('Anni di residenza continuativa',
                    style: TextStyle(fontSize: 11, color: AppColors.textLight)),
                value: 'residenza',
                groupValue: _tipoDomanda,
                activeColor: AppColors.primary,
                onChanged: (v) => setState(() {
                  _tipoDomanda = v!;
                  _showResult = false;
                }),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              RadioListTile<String>(
                title: const Text('Per Matrimonio',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: const Text('Matrimonio con cittadino/a italiano/a',
                    style: TextStyle(fontSize: 11, color: AppColors.textLight)),
                value: 'matrimonio',
                groupValue: _tipoDomanda,
                activeColor: AppColors.primary,
                onChanged: (v) => setState(() {
                  _tipoDomanda = v!;
                  _showResult = false;
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    if (_tipoDomanda == 'residenza') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('2', 'Nazionalita'),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                RadioListTile<String>(
                  title: const Text('Extracomunitario',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: const Text('10 anni di residenza richiesti',
                      style:
                          TextStyle(fontSize: 11, color: AppColors.textLight)),
                  value: 'extracomunitario',
                  groupValue: _nazionalita,
                  activeColor: AppColors.primary,
                  onChanged: (v) => setState(() {
                    _nazionalita = v!;
                    _showResult = false;
                  }),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                RadioListTile<String>(
                  title: const Text('Cittadino UE',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: const Text('4 anni di residenza richiesti',
                      style:
                          TextStyle(fontSize: 11, color: AppColors.textLight)),
                  value: 'ue',
                  groupValue: _nazionalita,
                  activeColor: AppColors.primary,
                  onChanged: (v) => setState(() {
                    _nazionalita = v!;
                    _showResult = false;
                  }),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Matrimonio
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('2', 'Dettagli matrimonio'),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 15,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Text(
                  'Hai figli nati/adottati?',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text('Si',
                          style: TextStyle(fontSize: 13)),
                      value: true,
                      groupValue: _haFigli,
                      activeColor: AppColors.primary,
                      dense: true,
                      onChanged: (v) => setState(() {
                        _haFigli = v!;
                        _showResult = false;
                      }),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text('No',
                          style: TextStyle(fontSize: 13)),
                      value: false,
                      groupValue: _haFigli,
                      activeColor: AppColors.primary,
                      dense: true,
                      onChanged: (v) => setState(() {
                        _haFigli = v!;
                        _showResult = false;
                      }),
                    ),
                  ),
                ],
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Text(
                  'Risiedi in Italia?',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text('Si',
                          style: TextStyle(fontSize: 13)),
                      value: true,
                      groupValue: _risiedeInItalia,
                      activeColor: AppColors.primary,
                      dense: true,
                      onChanged: (v) => setState(() {
                        _risiedeInItalia = v!;
                        _showResult = false;
                      }),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text('No',
                          style: TextStyle(fontSize: 13)),
                      value: false,
                      groupValue: _risiedeInItalia,
                      activeColor: AppColors.primary,
                      dense: true,
                      onChanged: (v) => setState(() {
                        _risiedeInItalia = v!;
                        _showResult = false;
                      }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep3() {
    final label = _tipoDomanda == 'residenza'
        ? 'Data prima iscrizione anagrafe in Italia'
        : 'Data del matrimonio';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('3', 'Data chiave'),
        GestureDetector(
          onTap: _pickDate,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 2),
                ),
              ],
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
                  child: const Icon(Icons.calendar_month,
                      color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _dataChiave != null
                            ? _formatDate(_dataChiave!)
                            : 'Tocca per selezionare',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _dataChiave != null
                              ? AppColors.textDark
                              : AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.edit_calendar,
                    color: AppColors.primary, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCalcolaButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: GestureDetector(
        onTap: _calcola,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: AppColors.buttonGradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calculate, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'CALCOLA',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 24, 16, 0),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _isEligible
                ? Colors.green.shade50
                : const Color(0xFFE3F2FD),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isEligible
                  ? Colors.green.shade200
                  : AppColors.primary.withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: (_isEligible
                        ? Colors.green
                        : AppColors.primary)
                    .withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: _isEligible ? _buildEligibleContent() : _buildNotEligibleContent(),
        ),
      ),
    );
  }

  Widget _buildEligibleContent() {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.check_circle,
              color: Colors.green.shade700, size: 36),
        ),
        const SizedBox(height: 14),
        Text(
          'PUOI FARE DOMANDA!',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.green.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Sei idoneo dal ${_formatDate(_dataIdonea!)}',
          style: TextStyle(
            fontSize: 14,
            color: Colors.green.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: () {
            // Could navigate to compilatore
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Funzione in arrivo: Compila Domanda'),
                backgroundColor: AppColors.primary,
              ),
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: Colors.green.shade700,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.edit_document, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text(
                  'Compila Domanda',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotEligibleContent() {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: const BoxDecoration(
            color: Color(0xFFBBDEFB),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.hourglass_top,
              color: AppColors.primary, size: 32),
        ),
        const SizedBox(height: 14),
        const Text(
          'Ancora un po\' di pazienza...',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryDark,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Data idonea: ${_formatDate(_dataIdonea!)}',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: const TextStyle(
                fontSize: 14, color: AppColors.textDark, height: 1.5),
            children: [
              const TextSpan(text: 'Mancano: '),
              TextSpan(
                text: '$_anniMancanti anni',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const TextSpan(text: ', '),
              TextSpan(
                text: '$_mesiMancanti mesi',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const TextSpan(text: ', '),
              TextSpan(
                text: '$_giorniMancanti giorni',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Progress bar
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Progresso',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMedium)),
                Text(
                  '${(_progressPercent * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: _progressPercent),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: value,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: AppColors.buttonGradient,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 15,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.info_outline,
                      color: AppColors.primary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Informazioni utili',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildInfoRow(
                Icons.euro,
                'Costo domanda',
                '\u20AC250 (contributo)',
              ),
              const SizedBox(height: 12),
              const Text(
                'Documenti necessari:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 6),
              _buildBullet('Certificato di nascita tradotto e legalizzato'),
              _buildBullet('Certificato penale del Paese di origine'),
              _buildBullet('Certificato di residenza storico'),
              _buildBullet('Dichiarazione dei redditi (ultime 3 annualita)'),
              if (_tipoDomanda == 'matrimonio') ...[
                _buildBullet('Certificato di matrimonio'),
                _buildBullet('Stato di famiglia'),
              ],
              _buildBullet('Marca da bollo \u20AC16,00'),
              _buildBullet('Ricevuta pagamento contributo \u20AC250'),
              const SizedBox(height: 12),
              _buildInfoRow(
                Icons.schedule,
                'Tempo medio risposta',
                '2-4 anni',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 16),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textMedium,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 5,
            height: 5,
            margin: const EdgeInsets.only(top: 6, right: 8),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textMedium,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
