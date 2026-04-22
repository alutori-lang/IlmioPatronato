import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/services/language_service.dart';
import 'core/services/profilo_utente_service.dart';
import 'core/services/scanner_service.dart';
import 'features/home/home_screen.dart';
import 'features/agevolazioni/agevolazioni_screen.dart';
import 'features/sbroglia/sbroglia_chat_screen.dart';
import 'features/profilo/profilo_screen.dart';
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
      ],
      child: MaterialApp(
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
        ],
        locale: const Locale('it', 'IT'),
        home: const MainShell(),
      ),
    );
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

  void _navigateTo(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
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
            const SnackBar(
              content: Text('Premi di nuovo per uscire'),
              duration: Duration(seconds: 2),
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
