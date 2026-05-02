import 'package:flutter/material.dart';
import 'disclaimer_widget.dart';

/// Striscia gialla compatta da mettere in cima alle schermate
/// che mostrano informazioni governative (bonus, calcolatori, guide).
/// Tappando si apre il dialog con tutte le fonti ufficiali.
class DisclaimerStrip extends StatelessWidget {
  const DisclaimerStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => DisclaimerBox.showSourcesDialog(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        color: Colors.amber.shade100,
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 16, color: Colors.amber.shade900),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'App informativa indipendente · Non è un servizio del Governo · Tocca per vedere le fonti',
                style: TextStyle(fontSize: 11, color: Colors.amber.shade900, fontWeight: FontWeight.w600),
              ),
            ),
            Icon(Icons.chevron_right, size: 16, color: Colors.amber.shade900),
          ],
        ),
      ),
    );
  }
}
