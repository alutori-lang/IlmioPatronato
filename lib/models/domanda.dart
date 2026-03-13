class Domanda {
  final String id;
  final String titolo;
  final String descrizione;
  final String autore;
  final String categoria;
  final DateTime dataCreazione;
  final int voti;
  final int risposteCount;
  final bool isNew;
  final List<Risposta> risposte;

  Domanda({
    required this.id,
    required this.titolo,
    required this.descrizione,
    required this.autore,
    required this.categoria,
    required this.dataCreazione,
    this.voti = 0,
    this.risposteCount = 0,
    this.isNew = false,
    this.risposte = const [],
  });
}

class Risposta {
  final String id;
  final String testo;
  final String autore;
  final bool isEsperto;
  final DateTime data;
  final int voti;

  Risposta({
    required this.id,
    required this.testo,
    required this.autore,
    this.isEsperto = false,
    required this.data,
    this.voti = 0,
  });
}
