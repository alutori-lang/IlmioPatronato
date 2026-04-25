import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/services/language_service.dart';
import 'core/services/profilo_utente_service.dart';
import 'core/services/scanner_service.dart';
import 'core/services/pratica_service.dart';
import 'core/services/notification_service.dart';
import 'core/localization/app_strings.dart';
import 'features/home/home_screen.dart';
import 'features/agevolazioni/agevolazioni_screen.dart';
import 'features/sbroglia/sbroglia_chat_screen.dart';
import 'features/profilo/profilo_screen.dart';
import 'features/onboarding/language_picker_screen.dart';
import 'core/widgets/app_nav_bar.dart';
import 'config/constants.dart';

class MioPatronatoApp extends StatelessWidget {
  const MioPatronatoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageService()),
        ChangeNotifierProvider(create: (_) => ProfiloUtenteService()..load()),
        ChangeNotifierProvider(create: (_) => ScannerService()..load()),
        ChangeNotifierProvider(create: (_) => PraticaService()..load()),
      ],
      child: Consumer<LanguageService>(
        builder: (context, lang, _) {
          final code = lang.currentCode;
          final isRtl = code == 'ar' || code == 'ur';
          return MaterialApp(
            title: 'Il Mio Patronato',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.theme,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('it', 'IT'),
              Locale('en', 'US'),
              Locale('ar'),
              Locale('ur'),
              Locale('hi'),
              Locale('ro'),
              Locale('fr'),
              Locale('es'),
              Locale('sq'),
              Locale('zh'),
              Locale('bn'),
              Locale('uk'),
              Locale('ru'),
              Locale('pa'),
            ],
            locale: Locale(code),
            builder: (context, child) {
              return Directionality(
                textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                child: child ?? const SizedBox.shrink(),
              );
            },
            home: const _LanguageGate(),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _LanguageGate — mostra LanguagePickerScreen al primo avvio, poi MainShell.
// ---------------------------------------------------------------------------
class _LanguageGate extends StatefulWidget {
  const _LanguageGate();

  @override
  State<_LanguageGate> createState() => _LanguageGateState();
}

class _LanguageGateState extends State<_LanguageGate> {
  bool? _languageChosen;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final done = await LanguagePickerScreen.alreadyChosen();
    if (!mounted) return;
    setState(() => _languageChosen = done);
  }

  @override
  Widget build(BuildContext context) {
    if (_languageChosen == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_languageChosen == false) {
      return LanguagePickerScreen(
        onComplete: () => setState(() => _languageChosen = true),
      );
    }
    return const MainShell();
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  DateTime? _lastBackPress;

  @override
  void initState() {
    super.initState();
    // Richiedi permesso notifiche dopo il primo frame (non bloccante).
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await NotificationService.instance.requestPermission();
    });
  }

  void _navigateTo(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final now = DateTime.now();
        if (_lastBackPress != null && now.difference(_lastBackPress!) < const Duration(seconds: 2)) {
          Navigator.of(context).pop();
        } else {
          _lastBackPress = now;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(s.pressBackAgain),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeScreen(
            onNavigateToGuide: () {},
            onNavigateToAgevolazioni: () => _navigateTo(1),
            onNavigateToStrumenti: () {},
            onNavigateToSbroglia: () => _navigateTo(2),
          ),
          const AgevolazioniScreen(),    // index 1 — Bonus
          const SbrogliaScreen(),        // index 2 — Sbroglia.AI
          const ProfiloScreen(),         // index 3 — Profilo
        ],
      ),
      bottomNavigationBar: AppNavBar(
        currentIndex: _currentIndex,
        onTap: _navigateTo,
      ),
    ),
    );
  }
}
