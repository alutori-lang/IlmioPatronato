// Una-tantum: esporta la lista seed di Agevolazione in JSON per pubblicarla
// come fonte unica remota. Esegui con:
//   dart run tools/export_bonuses.dart
// Output: assets/bonuses_2026.json
import 'dart:convert';
import 'dart:io';

import '../lib/features/agevolazioni/agevolazioni_data.dart';

Future<void> main() async {
  final today = DateTime.now().toIso8601String().split('T').first;
  final payload = {
    'version': today,
    'lastUpdate': today,
    'description': 'IlmioPatronato — master list of 2026 Italian bonuses. '
        'Edit this file and push to GitHub to update all installed apps within 24h.',
    'bonuses': allAgevolazioni.map((a) => a.toJson()).toList(),
  };
  final encoder = const JsonEncoder.withIndent('  ');
  final out = encoder.convert(payload);
  final file = File('assets/bonuses_2026.json');
  await file.create(recursive: true);
  await file.writeAsString('$out\n');
  stdout.writeln('Wrote ${allAgevolazioni.length} bonuses → ${file.path}');
}
