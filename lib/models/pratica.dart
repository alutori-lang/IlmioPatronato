import 'dart:convert';

enum PraticaStato { daFare, inCorso, inAttesa, completata, rifiutata }

extension PraticaStatoExt on PraticaStato {
  String get label {
    switch (this) {
      case PraticaStato.daFare:     return 'Da fare';
      case PraticaStato.inCorso:    return 'In corso';
      case PraticaStato.inAttesa:   return 'In attesa';
      case PraticaStato.completata: return 'Completata';
      case PraticaStato.rifiutata:  return 'Rifiutata';
    }
  }

  String get emoji {
    switch (this) {
      case PraticaStato.daFare:     return '🟡';
      case PraticaStato.inCorso:    return '🟠';
      case PraticaStato.inAttesa:   return '⏳';
      case PraticaStato.completata: return '🟢';
      case PraticaStato.rifiutata:  return '🔴';
    }
  }

  int get sortOrder {
    switch (this) {
      case PraticaStato.inCorso:    return 0;
      case PraticaStato.inAttesa:   return 1;
      case PraticaStato.daFare:     return 2;
      case PraticaStato.completata: return 3;
      case PraticaStato.rifiutata:  return 4;
    }
  }
}

class ChecklistItem {
  final String text;
  final bool done;

  const ChecklistItem({required this.text, this.done = false});

  ChecklistItem toggle() => ChecklistItem(text: text, done: !done);

  Map<String, dynamic> toJson() => {'text': text, 'done': done};

  factory ChecklistItem.fromJson(Map<String, dynamic> j) => ChecklistItem(
        text: j['text'] as String,
        done: j['done'] as bool? ?? false,
      );
}

class Pratica {
  final String id;
  final String titolo;
  final String ente;
  final String? agevolazioneId;
  final PraticaStato stato;
  final DateTime dataCreazione;
  final DateTime? dataInvio;
  final DateTime? scadenza;
  final List<ChecklistItem> checklist;
  final String note;
  final String? importo;
  final String? linkUfficiale;

  const Pratica({
    required this.id,
    required this.titolo,
    required this.ente,
    this.agevolazioneId,
    required this.stato,
    required this.dataCreazione,
    this.dataInvio,
    this.scadenza,
    this.checklist = const [],
    this.note = '',
    this.importo,
    this.linkUfficiale,
  });

  Pratica copyWith({
    String? titolo,
    String? ente,
    PraticaStato? stato,
    DateTime? dataInvio,
    bool clearDataInvio = false,
    DateTime? scadenza,
    bool clearScadenza = false,
    List<ChecklistItem>? checklist,
    String? note,
    String? importo,
    bool clearImporto = false,
    String? linkUfficiale,
  }) =>
      Pratica(
        id: id,
        titolo: titolo ?? this.titolo,
        ente: ente ?? this.ente,
        agevolazioneId: agevolazioneId,
        stato: stato ?? this.stato,
        dataCreazione: dataCreazione,
        dataInvio: clearDataInvio ? null : (dataInvio ?? this.dataInvio),
        scadenza: clearScadenza ? null : (scadenza ?? this.scadenza),
        checklist: checklist ?? this.checklist,
        note: note ?? this.note,
        importo: clearImporto ? null : (importo ?? this.importo),
        linkUfficiale: linkUfficiale ?? this.linkUfficiale,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'titolo': titolo,
        'ente': ente,
        'agevolazioneId': agevolazioneId,
        'stato': stato.name,
        'dataCreazione': dataCreazione.toIso8601String(),
        'dataInvio': dataInvio?.toIso8601String(),
        'scadenza': scadenza?.toIso8601String(),
        'checklist': checklist.map((c) => c.toJson()).toList(),
        'note': note,
        'importo': importo,
        'linkUfficiale': linkUfficiale,
      };

  factory Pratica.fromJson(Map<String, dynamic> j) => Pratica(
        id: j['id'] as String,
        titolo: j['titolo'] as String,
        ente: j['ente'] as String,
        agevolazioneId: j['agevolazioneId'] as String?,
        stato: PraticaStato.values.firstWhere(
          (s) => s.name == j['stato'],
          orElse: () => PraticaStato.daFare,
        ),
        dataCreazione: DateTime.parse(j['dataCreazione'] as String),
        dataInvio: j['dataInvio'] == null ? null : DateTime.parse(j['dataInvio'] as String),
        scadenza: j['scadenza'] == null ? null : DateTime.parse(j['scadenza'] as String),
        checklist: ((j['checklist'] as List?) ?? [])
            .map((e) => ChecklistItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        note: j['note'] as String? ?? '',
        importo: j['importo'] as String?,
        linkUfficiale: j['linkUfficiale'] as String?,
      );

  static String encodeList(List<Pratica> list) =>
      jsonEncode(list.map((p) => p.toJson()).toList());

  static List<Pratica> decodeList(String s) => (jsonDecode(s) as List)
      .map((e) => Pratica.fromJson(e as Map<String, dynamic>))
      .toList();
}
