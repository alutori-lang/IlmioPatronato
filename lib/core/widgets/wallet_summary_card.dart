import 'package:flutter/material.dart';
import '../../config/constants.dart';
import '../../features/strumenti/documento_wallet_screen.dart';
import '../services/wallet_bridge.dart';

/// Prominent Wallet card shown in the Profilo screen above the tools grid.
/// Replaces the old small "Wallet" tile and surfaces the next expiring
/// document so the user sees urgency at a glance.
class WalletSummaryCard extends StatefulWidget {
  const WalletSummaryCard({super.key});

  @override
  State<WalletSummaryCard> createState() => _WalletSummaryCardState();
}

class _WalletSummaryCardState extends State<WalletSummaryCard>
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
    if (state == AppLifecycleState.resumed) _refresh();
  }

  void _refresh() {
    setState(() => _future = WalletBridge.getSummary());
  }

  Future<void> _open() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DocumentoWalletScreen()),
    );
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WalletSummary>(
      future: _future,
      builder: (_, snap) {
        final summary = snap.data ?? const WalletSummary.empty();
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: InkWell(
            onTap: _open,
            borderRadius: BorderRadius.circular(16),
            child: Ink(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1976D2).withValues(alpha: 0.3),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(Icons.account_balance_wallet_rounded,
                        color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Portafoglio Documenti',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _buildSubtitle(summary),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildBadge(summary),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubtitle(WalletSummary s) {
    if (s.isEmpty) {
      return const Text(
        'Aggiungi il tuo primo documento',
        style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
      );
    }
    final docsLine =
        '${s.count} document${s.count == 1 ? 'o' : 'i'} salvat${s.count == 1 ? 'o' : 'i'}';
    if (s.nextDays == null || s.nextLabel == null) {
      return Text(
        docsLine,
        style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
      );
    }
    final scadLine = _expiryText(s.nextLabel!, s.nextDays!);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(docsLine,
            style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(
          scadLine,
          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  String _expiryText(String label, int days) {
    if (days < 0) return '$label SCADUTO da ${-days} giorn${-days == 1 ? 'o' : 'i'}';
    if (days == 0) return '$label scade OGGI';
    if (days == 1) return '$label scade domani';
    return '$label scade fra $days giorni';
  }

  Widget _buildBadge(WalletSummary s) {
    if (s.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text(
          'AGGIUNGI',
          style: TextStyle(color: Color(0xFF0D47A1), fontSize: 11, fontWeight: FontWeight.w800),
        ),
      );
    }
    final urgent = s.hasUrgent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: urgent ? const Color(0xFFFFAB00) : Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            urgent ? Icons.warning_amber_rounded : Icons.arrow_forward_rounded,
            color: urgent ? Colors.white : const Color(0xFF0D47A1),
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            urgent ? 'URGENTE' : 'APRI',
            style: TextStyle(
              color: urgent ? Colors.white : const Color(0xFF0D47A1),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
