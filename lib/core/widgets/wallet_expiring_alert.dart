import 'package:flutter/material.dart';
import '../../features/strumenti/documento_wallet_screen.dart';
import '../services/wallet_bridge.dart';

/// Home banner that surfaces the most urgent wallet document — but only
/// when there's actually something expiring within 60 days.
/// Renders nothing when the wallet is empty or all dates are far away,
/// so it never adds noise to a healthy home screen.
class WalletExpiringAlert extends StatefulWidget {
  const WalletExpiringAlert({super.key});

  @override
  State<WalletExpiringAlert> createState() => _WalletExpiringAlertState();
}

class _WalletExpiringAlertState extends State<WalletExpiringAlert>
    with WidgetsBindingObserver {
  Future<WalletSummary> _future = WalletBridge.getSummary();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() => _future = WalletBridge.getSummary());
    }
  }

  Future<void> _open() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DocumentoWalletScreen()),
    );
    if (mounted) setState(() => _future = WalletBridge.getSummary());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WalletSummary>(
      future: _future,
      builder: (_, snap) {
        final s = snap.data;
        if (s == null || !s.hasUrgent) return const SizedBox.shrink();
        final days = s.nextDays!;
        final label = s.nextLabel ?? 'Documento';
        final expired = days < 0;

        final bg = expired
            ? const [Color(0xFFB71C1C), Color(0xFFE53935)]
            : days <= 30
                ? const [Color(0xFFE65100), Color(0xFFFB8C00)]
                : const [Color(0xFFFF8F00), Color(0xFFFFA726)];

        final title = expired
            ? '$label SCADUTO'
            : days == 0
                ? '$label scade OGGI'
                : days == 1
                    ? '$label scade domani'
                    : '$label scade fra $days giorni';

        final subtitle = expired
            ? 'Tocca per aggiornare il documento nel Portafoglio'
            : 'Tocca per vedere il dettaglio nel Portafoglio';

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: InkWell(
            onTap: _open,
            borderRadius: BorderRadius.circular(14),
            child: Ink(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: bg,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: bg.first.withValues(alpha: 0.30),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.warning_amber_rounded,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            )),
                        const SizedBox(height: 2),
                        Text(subtitle,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            )),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.white, size: 22),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
