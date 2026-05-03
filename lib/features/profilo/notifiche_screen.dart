import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../config/constants.dart';
import '../../core/services/notification_service.dart';

class NotificheScreen extends StatefulWidget {
  const NotificheScreen({super.key});

  @override
  State<NotificheScreen> createState() => _NotificheScreenState();
}

class _NotificheScreenState extends State<NotificheScreen>
    with WidgetsBindingObserver {
  bool _granted = false;
  bool _loading = true;
  List<PendingNotificationRequest> _pending = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final granted = await NotificationService.instance.isPermissionGranted();
    final pending = await NotificationService.instance.getPending();
    if (!mounted) return;
    setState(() {
      _granted = granted;
      _pending = pending;
      _loading = false;
    });
  }

  Future<void> _onActivate() async {
    final ok = await NotificationService.instance.requestPermission();
    if (!mounted) return;
    if (!ok) {
      // OS likely blocked the prompt → guide user to settings
      final go = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Permesso negato'),
          content: const Text(
            'Le notifiche sono disattivate da Android. Apri le impostazioni di sistema per attivarle.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annulla')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Apri impostazioni'),
            ),
          ],
        ),
      );
      if (go == true) await openAppSettings();
    }
    _refresh();
  }

  Future<void> _onTest() async {
    if (!_granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attiva prima le notifiche')),
      );
      return;
    }
    await NotificationService.instance.sendTestNotification();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('📬 Notifica di prova inviata')),
    );
  }

  Future<void> _cancelAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancella tutte'),
        content: const Text('Vuoi annullare tutte le notifiche programmate?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annulla')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancella', style: TextStyle(color: Color(0xFFC62828))),
          ),
        ],
      ),
    );
    if (ok == true) {
      await NotificationService.instance.cancelAll();
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    children: [
                      _buildPermissionCard(),
                      const SizedBox(height: 14),
                      _buildChannelsCard(),
                      const SizedBox(height: 14),
                      _buildTestCard(),
                      const SizedBox(height: 14),
                      _buildPendingSection(),
                    ],
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
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 22),
        const SizedBox(width: 10),
        const Text('Notifiche',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
      ]),
    );
  }

  Widget _buildPermissionCard() {
    final color = _granted ? const Color(0xFF2E7D32) : const Color(0xFFC62828);
    final icon = _granted ? Icons.check_circle_rounded : Icons.cancel_rounded;
    final title = _granted ? 'Notifiche attive' : 'Notifiche disattivate';
    final subtitle = _granted
        ? 'Riceverai avvisi per nuovi bonus e scadenze documenti.'
        : 'Attiva le notifiche per ricevere avvisi su nuovi bonus e scadenze.';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w800, color: color)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textMedium, height: 1.3)),
                ],
              ),
            ),
          ]),
          if (!_granted) ...[
            const SizedBox(height: 14),
            GestureDetector(
              onTap: _onActivate,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: AppColors.buttonGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('ATTIVA NOTIFICHE',
                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChannelsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Cosa ti notifichiamo',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textDark)),
          const SizedBox(height: 12),
          _channelRow(
            icon: Icons.celebration_rounded,
            color: const Color(0xFF1976D2),
            title: 'Nuovi bonus disponibili',
            subtitle: 'Quando viene pubblicata una nuova agevolazione (NASpI, ISEE, contributi…)',
          ),
          const SizedBox(height: 10),
          _channelRow(
            icon: Icons.event_available_rounded,
            color: const Color(0xFFE65100),
            title: 'Scadenze documenti',
            subtitle: 'Promemoria 60, 30, 7 e 1 giorno prima della scadenza',
          ),
        ],
      ),
    );
  }

  Widget _channelRow({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textLight, height: 1.35)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTestCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF5E35B1).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.send_rounded, color: Color(0xFF5E35B1), size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Notifica di prova',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                SizedBox(height: 2),
                Text('Verifica che le notifiche funzionino',
                    style: TextStyle(fontSize: 11, color: AppColors.textLight)),
              ],
            ),
          ),
          GestureDetector(
            onTap: _onTest,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF5E35B1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('INVIA',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingSection() {
    if (_pending.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10),
          ],
        ),
        child: Column(
          children: [
            Icon(Icons.notifications_off_rounded,
                color: AppColors.textLight.withValues(alpha: 0.5), size: 36),
            const SizedBox(height: 8),
            const Text('Nessuna notifica programmata',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textMedium)),
            const SizedBox(height: 4),
            const Text(
              'I promemoria di scadenza appariranno qui.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: AppColors.textLight),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('Promemoria programmati',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textDark)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('${_pending.length}',
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primary)),
            ),
          ]),
          const SizedBox(height: 10),
          ..._pending.take(20).map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.schedule_rounded,
                        size: 16, color: AppColors.textMedium),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.title ?? 'Promemoria',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                          if (p.body != null && p.body!.isNotEmpty)
                            Text(p.body!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 11, color: AppColors.textLight, height: 1.3)),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
          if (_pending.length > 20)
            Text('e altri ${_pending.length - 20}…',
                style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _cancelAll,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFC62828).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text('CANCELLA TUTTI',
                    style: TextStyle(color: Color(0xFFC62828), fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
