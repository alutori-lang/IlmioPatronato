import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/constants.dart';

class AdiScreen extends StatefulWidget {
  const AdiScreen({super.key});

  @override
  State<AdiScreen> createState() => _AdiScreenState();
}

class _AdiScreenState extends State<AdiScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _iseeController = TextEditingController();
  final _immobiliareController = TextEditingController();
  final _mobiliareController = TextEditingController();
  final _componentiController = TextEditingController(text: '1');
  final _minoriController = TextEditingController(text: '0');
  final _disabiliController = TextEditingController(text: '0');
  final _over60Controller = TextEditingController(text: '0');
  final _anniResidenzaController = TextEditingController();

  String _tipoPermesso = 'lungo_soggiorno';

  // Result state
  bool _showResult = false;
  bool _isEligible = false;
  double _importoStimato = 0;
  List<_RequisitoResult> _requisiti = [];

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // Real ADI thresholds 2024-2026
  static const double _iseeMax = 9360.00;
  static const double _immobiliareMax = 30000.00;
  static const double _mobiliareBase = 6000.00;
  static const double _mobiliarePerComponente = 2000.00;
  static const double _mobiliareMax = 10000.00;
  static const double _mobiliarePerMinoreExtra = 1000.00;
  static const int _anniResidenzaMin = 5;
  static const double _importoBase = 500.00;

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
    _iseeController.dispose();
    _immobiliareController.dispose();
    _mobiliareController.dispose();
    _componentiController.dispose();
    _minoriController.dispose();
    _disabiliController.dispose();
    _over60Controller.dispose();
    _anniResidenzaController.dispose();
    _animController.dispose();
    super.dispose();
  }

  double _parseDouble(String s) {
    return double.tryParse(s.replaceAll(',', '.')) ?? 0;
  }

  int _parseInt(String s) {
    return int.tryParse(s) ?? 0;
  }

  double _calcolaSogliaMobiliare(int componenti, int minori) {
    // Base: 6000 + 2000 per ogni componente dopo il primo (max 10000)
    double soglia = _mobiliareBase;
    if (componenti > 1) {
      soglia += (componenti - 1) * _mobiliarePerComponente;
    }
    if (soglia > _mobiliareMax) {
      soglia = _mobiliareMax;
    }
    // +1000 per ogni minore dopo il secondo
    if (minori > 2) {
      soglia += (minori - 2) * _mobiliarePerMinoreExtra;
    }
    return soglia;
  }

  double _calcolaImporto(int minori, int disabili, int over60, int componenti) {
    // Scala di equivalenza
    double scala = 1.0; // Richiedente

    // Maggiorenni con disabilita
    scala += disabili * 0.50;

    // Over 60
    scala += over60 * 0.40;

    // Maggiorenni con carichi di cura (approximated: componenti - 1 - disabili - over60 - minori)
    final altriMaggiorenni = (componenti - 1 - disabili - over60 - minori)
        .clamp(0, componenti);
    // Assume maggiorenni con carichi di cura if they have minori
    if (minori > 0 && altriMaggiorenni > 0) {
      scala += altriMaggiorenni * 0.40;
    }

    // Minori
    scala += minori * 0.15;

    return _importoBase * scala;
  }

  void _verifica() {
    if (!_formKey.currentState!.validate()) return;

    final isee = _parseDouble(_iseeController.text);
    final immobiliare = _parseDouble(_immobiliareController.text);
    final mobiliare = _parseDouble(_mobiliareController.text);
    final componenti = _parseInt(_componentiController.text);
    final minori = _parseInt(_minoriController.text);
    final disabili = _parseInt(_disabiliController.text);
    final over60 = _parseInt(_over60Controller.text);
    final anniResidenza = _parseInt(_anniResidenzaController.text);

    final sogliaMobiliare = _calcolaSogliaMobiliare(componenti, minori);

    // Check each requirement
    final reqIsee = isee <= _iseeMax;
    final reqImmobiliare = immobiliare <= _immobiliareMax;
    final reqMobiliare = mobiliare <= sogliaMobiliare;
    final reqNucleo = minori > 0 || disabili > 0 || over60 > 0;
    final reqResidenza = anniResidenza >= _anniResidenzaMin;
    final reqPermesso = _tipoPermesso == 'lungo_soggiorno' ||
        _tipoPermesso == 'protezione_internazionale';

    final requisiti = <_RequisitoResult>[
      _RequisitoResult(
        label: 'ISEE \u2264 \u20AC${_iseeMax.toStringAsFixed(0)}',
        met: reqIsee,
        detail: reqIsee
            ? 'Il tuo ISEE (\u20AC${isee.toStringAsFixed(0)}) rientra nel limite'
            : 'Il tuo ISEE (\u20AC${isee.toStringAsFixed(0)}) supera il limite',
      ),
      _RequisitoResult(
        label:
            'Patrimonio immobiliare \u2264 \u20AC${_immobiliareMax.toStringAsFixed(0)}',
        met: reqImmobiliare,
        detail: reqImmobiliare
            ? 'Patrimonio (\u20AC${immobiliare.toStringAsFixed(0)}) entro il limite'
            : 'Patrimonio (\u20AC${immobiliare.toStringAsFixed(0)}) supera il limite',
      ),
      _RequisitoResult(
        label:
            'Patrimonio mobiliare \u2264 \u20AC${sogliaMobiliare.toStringAsFixed(0)}',
        met: reqMobiliare,
        detail: reqMobiliare
            ? 'Patrimonio (\u20AC${mobiliare.toStringAsFixed(0)}) entro il limite'
            : 'Patrimonio (\u20AC${mobiliare.toStringAsFixed(0)}) supera la soglia calcolata',
      ),
      _RequisitoResult(
        label: 'Nucleo con minore, disabile o over 60',
        met: reqNucleo,
        detail: reqNucleo
            ? 'Requisito nucleo soddisfatto'
            : 'Nessun minore, disabile o over 60 nel nucleo',
      ),
      _RequisitoResult(
        label: 'Residenza in Italia \u2265 5 anni',
        met: reqResidenza,
        detail: reqResidenza
            ? '$anniResidenza anni di residenza'
            : 'Solo $anniResidenza anni di residenza (minimo 5)',
      ),
      _RequisitoResult(
        label: 'Permesso lungo soggiorno o protezione internazionale',
        met: reqPermesso,
        detail: reqPermesso
            ? 'Tipo permesso idoneo'
            : 'Il tipo di permesso non da diritto all\'ADI',
      ),
    ];

    final eligible = requisiti.every((r) => r.met);
    final importo =
        eligible ? _calcolaImporto(minori, disabili, over60, componenti) : 0.0;

    setState(() {
      _showResult = true;
      _isEligible = eligible;
      _importoStimato = importo;
      _requisiti = requisiti;
    });

    _animController.reset();
    _animController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(context)),
          SliverToBoxAdapter(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNumberField(
                    'ISEE corrente (\u20AC)',
                    _iseeController,
                    'Inserisci il valore ISEE',
                    Icons.description,
                  ),
                  _buildNumberField(
                    'Patrimonio immobiliare (\u20AC)',
                    _immobiliareController,
                    'Esclusa prima casa fino a \u20AC150.000',
                    Icons.home,
                  ),
                  _buildNumberField(
                    'Patrimonio mobiliare (\u20AC)',
                    _mobiliareController,
                    'Conti correnti, depositi, ecc.',
                    Icons.account_balance,
                  ),
                  _buildNumberField(
                    'Numero componenti nucleo',
                    _componentiController,
                    'Totale persone nel nucleo familiare',
                    Icons.people,
                    isInteger: true,
                  ),
                  _buildNumberField(
                    'Minori nel nucleo',
                    _minoriController,
                    'Figli minorenni',
                    Icons.child_care,
                    isInteger: true,
                  ),
                  _buildNumberField(
                    'Disabili nel nucleo',
                    _disabiliController,
                    'Componenti con disabilita certificata',
                    Icons.accessible,
                    isInteger: true,
                  ),
                  _buildNumberField(
                    'Over 60 nel nucleo',
                    _over60Controller,
                    'Componenti con 60+ anni',
                    Icons.elderly,
                    isInteger: true,
                  ),
                  _buildNumberField(
                    'Anni di residenza in Italia',
                    _anniResidenzaController,
                    'Anni totali (ultimi 2 continuativi)',
                    Icons.location_city,
                    isInteger: true,
                  ),
                  _buildTipoPermesso(),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(child: _buildVerificaButton()),
          if (_showResult) ...[
            SliverToBoxAdapter(child: _buildResultCard()),
            SliverToBoxAdapter(child: _buildRequisitiDetail()),
            SliverToBoxAdapter(child: _buildComeFareDomanda()),
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
          const Icon(Icons.account_balance_wallet,
              color: Colors.white, size: 22),
          const SizedBox(width: 10),
          const Text(
            'Verifica ADI',
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

  Widget _buildNumberField(
    String label,
    TextEditingController controller,
    String hint,
    IconData icon, {
    bool isInteger = false,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
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
        child: TextFormField(
          controller: controller,
          keyboardType: isInteger
              ? TextInputType.number
              : const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: isInteger
              ? [FilteringTextInputFormatter.digitsOnly]
              : [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(
              fontSize: 13,
              color: AppColors.textMedium,
              fontWeight: FontWeight.w500,
            ),
            hintText: hint,
            hintStyle: const TextStyle(
              fontSize: 12,
              color: AppColors.textLight,
            ),
            prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) {
              return 'Campo obbligatorio';
            }
            return null;
          },
        ),
      ),
    );
  }

  Widget _buildTipoPermesso() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Text(
            'Tipo permesso di soggiorno',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
          child: DropdownButtonFormField<String>(
            value: _tipoPermesso,
            decoration: const InputDecoration(
              border: InputBorder.none,
              prefixIcon:
                  Icon(Icons.badge, color: AppColors.primary, size: 20),
            ),
            isExpanded: true,
            icon:
                const Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textDark,
              fontWeight: FontWeight.w500,
            ),
            items: const [
              DropdownMenuItem(
                value: 'lungo_soggiorno',
                child: Text('Lungo soggiorno'),
              ),
              DropdownMenuItem(
                value: 'protezione_internazionale',
                child: Text('Protezione internazionale'),
              ),
              DropdownMenuItem(
                value: 'altro',
                child: Text('Altro'),
              ),
            ],
            onChanged: (v) => setState(() {
              _tipoPermesso = v!;
              _showResult = false;
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildVerificaButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: GestureDetector(
        onTap: _verifica,
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
              Icon(Icons.verified_user, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'VERIFICA REQUISITI',
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
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _isEligible ? Colors.green.shade50 : Colors.red.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isEligible
                  ? Colors.green.shade200
                  : Colors.red.shade200,
            ),
            boxShadow: [
              BoxShadow(
                color: (_isEligible ? Colors.green : Colors.red)
                    .withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: _isEligible
                      ? Colors.green.shade100
                      : Colors.red.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isEligible ? Icons.check_circle : Icons.cancel,
                  color: _isEligible
                      ? Colors.green.shade700
                      : Colors.red.shade700,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _isEligible ? 'HAI DIRITTO ALL\'ADI!' : 'NON HAI I REQUISITI',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _isEligible
                      ? Colors.green.shade700
                      : Colors.red.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              if (_isEligible) ...[
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Importo stimato',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textMedium,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: _importoStimato),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) {
                          return Text(
                            '\u20AC${value.toStringAsFixed(0)}/mese',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Colors.green.shade700,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Calcolato con scala di equivalenza',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.green.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequisitiDetail() {
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
                  Icon(Icons.checklist, color: AppColors.primary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Dettaglio requisiti',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ..._requisiti.map((r) => _buildRequisitoRow(r)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequisitoRow(_RequisitoResult req) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: req.met
                  ? Colors.green.shade50
                  : Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              req.met ? Icons.check : Icons.close,
              color: req.met
                  ? Colors.green.shade700
                  : Colors.red.shade700,
              size: 15,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  req.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: req.met
                        ? AppColors.textDark
                        : Colors.red.shade700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  req.detail,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComeFareDomanda() {
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
                  Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Come fare domanda',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildStep(
                '1',
                'Vai su myINPS.it o al CAF',
                'Accedi con SPID o CIE al portale INPS',
              ),
              _buildStep(
                '2',
                'Presenta domanda con ISEE valido',
                'L\'ISEE deve essere in corso di validita',
              ),
              _buildStep(
                '3',
                'Sottoscrivi il PAD',
                'Patto di Attivazione Digitale su SIISL',
              ),
              _buildStep(
                '4',
                'Iscriviti al SIISL',
                'Sistema Informativo per l\'Inclusione Sociale e Lavorativa',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(String number, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMedium,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RequisitoResult {
  final String label;
  final bool met;
  final String detail;

  const _RequisitoResult({
    required this.label,
    required this.met,
    required this.detail,
  });
}
