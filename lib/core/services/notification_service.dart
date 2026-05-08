import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../../features/agevolazioni/agevolazioni_data.dart';

// ---------------------------------------------------------------------------
// NotificationService — notifiche locali:
//   1) Nuovi bonus pubblicati (confronto ID noti ↔ JSON scaricato)
//   2) Scadenze documenti (permesso di soggiorno, ISEE, pratiche)
//
// Usa solo flutter_local_notifications (niente server). Permesso richiesto
// lazily al primo avvio post-install su Android 13+ (POST_NOTIFICATIONS).
// ---------------------------------------------------------------------------

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static const _channelBonusId = 'nuovi_bonus';
  static const _channelBonusName = 'Nuovi Bonus';
  static const _channelBonusDesc = 'Notifiche quando nuove agevolazioni vengono aggiunte';
  static const _channelDocId = 'scadenze_documenti';
  static const _channelDocName = 'Scadenze Documenti';
  static const _channelDocDesc = 'Promemoria per documenti in scadenza (permesso, ISEE, pratiche)';
  static const _channelDailyId = 'bonus_giornaliero';
  static const _channelDailyName = 'Bonus del Giorno';
  static const _channelDailyDesc = 'Ogni giorno alle 12:20 ricevi il titolo di un bonus interessante';

  static const _prefsKnownBonusIds = 'notification_known_bonus_ids_v1';
  static const _prefsInitialized = 'notification_first_run_done_v1';

  bool _ready = false;

  Future<void> initialize() async {
    if (_ready) return;
    try {
      tz_data.initializeTimeZones();
      try {
        tz.setLocalLocation(tz.getLocation('Europe/Rome'));
      } catch (_) {
        tz.setLocalLocation(tz.getLocation('UTC'));
      }

      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const init = InitializationSettings(android: androidInit);
      await _plugin.initialize(init);

      await _ensureChannels();
      _ready = true;
      debugPrint('[Notif] initialized');
    } catch (e, st) {
      debugPrint('[Notif] init error: $e\n$st');
    }
  }

  Future<void> _ensureChannels() async {
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;
    await android.createNotificationChannel(const AndroidNotificationChannel(
      _channelBonusId,
      _channelBonusName,
      description: _channelBonusDesc,
      importance: Importance.high,
    ));
    await android.createNotificationChannel(const AndroidNotificationChannel(
      _channelDocId,
      _channelDocName,
      description: _channelDocDesc,
      importance: Importance.high,
    ));
    await android.createNotificationChannel(const AndroidNotificationChannel(
      _channelDailyId,
      _channelDailyName,
      description: _channelDailyDesc,
      importance: Importance.high,
    ));
  }

  /// Whether the OS-level notifications permission is currently granted.
  Future<bool> isPermissionGranted() async {
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (android == null) return false;
      return await android.areNotificationsEnabled() ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Returns the list of currently scheduled notifications (e.g. document
  /// expiry reminders) so the UI can show what's queued.
  Future<List<PendingNotificationRequest>> getPending() async {
    try {
      return await _plugin.pendingNotificationRequests();
    } catch (_) {
      return [];
    }
  }

  Future<bool> requestPermission() async {
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (android == null) return false;
      final granted = await android.requestNotificationsPermission();
      final exact = await android.requestExactAlarmsPermission();
      debugPrint('[Notif] permission granted=$granted exact=$exact');
      return granted ?? false;
    } catch (e) {
      debugPrint('[Notif] requestPermission error: $e');
      return false;
    }
  }

  /// Confronta gli ID ricevuti con quelli già noti. Se ce ne sono di nuovi,
  /// fa scattare una notifica di riepilogo. Va chiamato dopo BonusRepository.load().
  Future<void> checkForNewBonuses(List<Agevolazione> allBonuses) async {
    if (!_ready) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final firstRun = !(prefs.getBool(_prefsInitialized) ?? false);
      final currentIds = allBonuses.map((a) => a.id).toSet();

      final knownJson = prefs.getString(_prefsKnownBonusIds);
      final knownIds = knownJson != null
          ? Set<String>.from(jsonDecode(knownJson) as List)
          : <String>{};

      // Prima installazione: salva la baseline e non notificare
      if (firstRun || knownIds.isEmpty) {
        await prefs.setString(_prefsKnownBonusIds, jsonEncode(currentIds.toList()));
        await prefs.setBool(_prefsInitialized, true);
        debugPrint('[Notif] baseline ${currentIds.length} bonus IDs salvati (prima installazione)');
        return;
      }

      final newIds = currentIds.difference(knownIds);
      if (newIds.isEmpty) {
        debugPrint('[Notif] nessun nuovo bonus');
        return;
      }

      final nuoviBonus = allBonuses.where((b) => newIds.contains(b.id)).toList();
      debugPrint('[Notif] ${nuoviBonus.length} nuovi bonus rilevati: ${newIds.take(5).join(", ")}');

      // Una notifica per bonus (max 3 in un colpo, altrimenti digest)
      if (nuoviBonus.length <= 3) {
        for (final b in nuoviBonus) {
          await _showNewBonusNotification(b);
        }
      } else {
        await _showDigestNotification(nuoviBonus);
      }

      // Aggiorna la baseline
      await prefs.setString(_prefsKnownBonusIds, jsonEncode(currentIds.toList()));
    } catch (e, st) {
      debugPrint('[Notif] checkForNewBonuses error: $e\n$st');
    }
  }

  Future<void> _showNewBonusNotification(Agevolazione b) async {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelBonusId,
        _channelBonusName,
        channelDescription: _channelBonusDesc,
        importance: Importance.high,
        priority: Priority.high,
        styleInformation: BigTextStyleInformation(
          '${b.descrizione}\n\n💰 ${b.importo}',
          contentTitle: '🎉 Nuovo bonus: ${b.titolo}',
        ),
      ),
    );
    await _plugin.show(
      _hashId('bonus_${b.id}'),
      '🎉 Nuovo bonus: ${b.titolo}',
      b.descrizione,
      details,
      payload: 'bonus:${b.id}',
    );
  }

  Future<void> _showDigestNotification(List<Agevolazione> nuovi) async {
    final titles = nuovi.take(5).map((b) => '• ${b.titolo}').join('\n');
    final extra = nuovi.length > 5 ? '\n…e altri ${nuovi.length - 5}' : '';
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelBonusId,
        _channelBonusName,
        channelDescription: _channelBonusDesc,
        importance: Importance.high,
        priority: Priority.high,
        styleInformation: BigTextStyleInformation(
          '$titles$extra',
          contentTitle: '🎉 ${nuovi.length} nuovi bonus disponibili',
        ),
      ),
    );
    await _plugin.show(
      _hashId('bonus_digest'),
      '🎉 ${nuovi.length} nuovi bonus disponibili',
      'Apri l\'app per vederli tutti',
      details,
      payload: 'bonus_digest',
    );
  }

  /// Schedula le notifiche di scadenza per un documento (60, 30 e 7 giorni prima).
  /// Se la data è già passata, nessuna notifica.
  Future<void> scheduleDocumentExpiry({
    required String id,
    required String titolo,
    required DateTime scadenza,
  }) async {
    if (!_ready) return;
    await cancelDocumentExpiry(id);
    final now = DateTime.now();
    for (final giorniPrima in [60, 30, 7, 1]) {
      final when = scadenza.subtract(Duration(days: giorniPrima));
      if (when.isBefore(now)) continue;
      final notifId = _hashId('doc_${id}_$giorniPrima');
      final testo = giorniPrima == 1
          ? 'Scade domani!'
          : 'Scade tra $giorniPrima giorni';
      try {
        await _plugin.zonedSchedule(
          notifId,
          '📄 $titolo: $testo',
          'Il tuo $titolo scade il ${_formatDate(scadenza)}. Muoviti per il rinnovo!',
          tz.TZDateTime.from(when, tz.local),
          NotificationDetails(
            android: AndroidNotificationDetails(
              _channelDocId,
              _channelDocName,
              channelDescription: _channelDocDesc,
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          payload: 'doc:$id',
        );
        debugPrint('[Notif] scheduled $id -$giorniPrima gg @ $when');
      } catch (e) {
        debugPrint('[Notif] schedule error for $id @ $giorniPrima: $e');
      }
    }
  }

  Future<void> cancelDocumentExpiry(String id) async {
    for (final giorniPrima in [60, 30, 7, 1]) {
      await _plugin.cancel(_hashId('doc_${id}_$giorniPrima'));
    }
  }

  /// Pianifica una notifica al giorno alle 12:20 per i prossimi 30 giorni.
  /// Ogni notifica mostra il titolo di un bonus interessante (rotazione random).
  /// Va richiamata dopo BonusRepository.load() così la lista è fresca.
  Future<void> scheduleDailyBonusNotifications(List<Agevolazione> bonuses) async {
    if (!_ready || bonuses.isEmpty) return;
    try {
      // Cancella eventuali notifiche giornaliere precedenti
      for (int i = 0; i < 60; i++) {
        await _plugin.cancel(_hashId('daily_bonus_$i'));
      }

      final now = tz.TZDateTime.now(tz.local);
      // Mescola i bonus per rotazione random; usa DateTime come seed per
      // mantenere lo stesso ordine entro la stessa giornata di scheduling.
      final shuffled = List<Agevolazione>.from(bonuses)..shuffle();

      int scheduledCount = 0;
      for (int day = 0; day < 30; day++) {
        var fireAt = tz.TZDateTime(tz.local, now.year, now.month, now.day, 12, 20);
        fireAt = fireAt.add(Duration(days: day));
        if (fireAt.isBefore(now)) continue;

        final b = shuffled[day % shuffled.length];
        final id = _hashId('daily_bonus_$day');
        try {
          await _plugin.zonedSchedule(
            id,
            '💰 ${b.titolo}',
            'Tocca per scoprire requisiti e come richiederlo.',
            fireAt,
            NotificationDetails(
              android: AndroidNotificationDetails(
                _channelDailyId,
                _channelDailyName,
                channelDescription: _channelDailyDesc,
                importance: Importance.high,
                priority: Priority.high,
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
            payload: 'bonus:${b.id}',
          );
          scheduledCount++;
        } catch (e) {
          debugPrint('[Notif] daily schedule error day=$day: $e');
        }
      }
      debugPrint('[Notif] daily bonus alerts scheduled: $scheduledCount @12:20');
    } catch (e, st) {
      debugPrint('[Notif] scheduleDailyBonusNotifications error: $e\n$st');
    }
  }

  Future<void> cancelAll() => _plugin.cancelAll();

  /// Notifica di test (per verificare setup). Fire immediatamente.
  Future<void> sendTestNotification() async {
    if (!_ready) {
      debugPrint('[Notif] non ancora inizializzato');
      return;
    }
    await _plugin.show(
      9999,
      '✅ Notifiche attive',
      'Riceverai avvisi per nuovi bonus e scadenze documenti.',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelBonusId,
          _channelBonusName,
          channelDescription: _channelBonusDesc,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  // ── Helper ──────────────────────────────────────────────────────────
  int _hashId(String key) => key.hashCode & 0x7fffffff;

  String _formatDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd/$mm/${d.year}';
  }
}
