import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';
import 'core/services/ad_service.dart';
import 'core/services/bonus_repository.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('it_IT', null);
  // Inizializza notifiche locali + timezone (non chiede permesso: lo fa dopo l'onboarding)
  await NotificationService.instance.initialize();
  // Carica bonus da remoto/cache/asset PRIMA di runApp (fallback: lista hardcodata).
  // Include rilevamento nuovi bonus + notifica locale.
  await BonusRepository.instance.load();
  // Schedula la notifica giornaliera "bonus del giorno" alle 12:20 per i
  // prossimi 30 giorni con rotazione random dei titoli.
  await NotificationService.instance.scheduleDailyBonusNotifications(
    BonusRepository.instance.all,
  );
  // TEMP_SCREENSHOTS: AdService initialization disabled to prevent ATT dialog
  // and Google Mobile Ads banners from appearing in App Store screenshots.
  // Restore before submitting to App Store.
  // if (!kIsWeb) {
  //   await AdService().initialize();
  // }
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const MioPatronatoApp());
}
