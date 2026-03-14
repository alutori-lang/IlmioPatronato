import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/services/language_service.dart';
import 'features/home/home_screen.dart';
import 'features/guide/guide_list_screen.dart';
import 'features/agevolazioni/agevolazioni_screen.dart';
import 'features/strumenti/strumenti_tab_screen.dart';
import 'features/profilo/profilo_screen.dart';
import 'core/widgets/app_nav_bar.dart';
import 'config/constants.dart';

class MioPatronatoApp extends StatelessWidget {
  const MioPatronatoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LanguageService(),
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

  void _navigateTo(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeScreen(
            onNavigateToGuide: () => _navigateTo(1),
            onNavigateToAgevolazioni: () => _navigateTo(2),
            onNavigateToStrumenti: () => _navigateTo(3),
          ),
          const GuideListScreen(),
          const AgevolazioniScreen(),
          const StrumentiTabScreen(),
          const ProfiloScreen(),
        ],
      ),
      bottomNavigationBar: AppNavBar(
        currentIndex: _currentIndex,
        onTap: _navigateTo,
      ),
    );
  }
}
