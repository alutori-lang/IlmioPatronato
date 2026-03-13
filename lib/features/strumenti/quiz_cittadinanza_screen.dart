import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/constants.dart';

// ───────────────────── DATA MODEL ─────────────────────

class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String category;

  const QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.category,
  });
}

// ───────────────────── CATEGORY ENUM ─────────────────────

enum QuizCategory {
  linguaItaliana,
  culturaStoria,
  costituzione,
  vitaCivica,
  educazioneCivica,
}

extension QuizCategoryExt on QuizCategory {
  String get label {
    switch (this) {
      case QuizCategory.linguaItaliana:
        return 'Lingua Italiana';
      case QuizCategory.culturaStoria:
        return 'Cultura e Storia';
      case QuizCategory.costituzione:
        return 'Costituzione';
      case QuizCategory.vitaCivica:
        return 'Vita Civica';
      case QuizCategory.educazioneCivica:
        return 'Educazione Civica';
    }
  }

  String get subtitle {
    switch (this) {
      case QuizCategory.linguaItaliana:
        return 'Grammatica, vocabolario, espressioni';
      case QuizCategory.culturaStoria:
        return 'Storia, geografia, tradizioni';
      case QuizCategory.costituzione:
        return 'Articoli e principi fondamentali';
      case QuizCategory.vitaCivica:
        return 'Diritti, doveri, servizi pubblici';
      case QuizCategory.educazioneCivica:
        return 'Leggi, governo, istituzioni';
    }
  }

  IconData get icon {
    switch (this) {
      case QuizCategory.linguaItaliana:
        return Icons.menu_book_rounded;
      case QuizCategory.culturaStoria:
        return Icons.account_balance_rounded;
      case QuizCategory.costituzione:
        return Icons.gavel_rounded;
      case QuizCategory.vitaCivica:
        return Icons.people_rounded;
      case QuizCategory.educazioneCivica:
        return Icons.school_rounded;
    }
  }

  Color get color {
    switch (this) {
      case QuizCategory.linguaItaliana:
        return const Color(0xFF1565C0);
      case QuizCategory.culturaStoria:
        return const Color(0xFFE65100);
      case QuizCategory.costituzione:
        return const Color(0xFF6A1B9A);
      case QuizCategory.vitaCivica:
        return const Color(0xFF2E7D32);
      case QuizCategory.educazioneCivica:
        return const Color(0xFFC62828);
    }
  }

  Color get lightColor {
    switch (this) {
      case QuizCategory.linguaItaliana:
        return const Color(0xFFE3F2FD);
      case QuizCategory.culturaStoria:
        return const Color(0xFFFFF3E0);
      case QuizCategory.costituzione:
        return const Color(0xFFF3E5F5);
      case QuizCategory.vitaCivica:
        return const Color(0xFFE8F5E9);
      case QuizCategory.educazioneCivica:
        return const Color(0xFFFFEBEE);
    }
  }

  String get prefKey => 'quiz_${name}_correct';
  String get highScoreKey => 'quiz_${name}_highscore';
  String get totalKey => 'quiz_${name}_total';
}

// ───────────────────── 200+ QUESTIONS ─────────────────────

const List<QuizQuestion> _allQuestions = [
  // ═══════════════════════════════════════════════════════
  // LINGUA ITALIANA (50 questions)
  // ═══════════════════════════════════════════════════════
  QuizQuestion(
    category: 'linguaItaliana',
    question: "Qual e' il plurale di 'problema'?",
    options: ['probleme', 'problemi', 'problemie', 'problemmi'],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'linguaItaliana',
    question: "Quale articolo va con 'zucchero'?",
    options: ['il', 'lo', 'la', 'un'],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'linguaItaliana',
    question: "Il passato prossimo di 'andare' (io) e':",
    options: ['ho andato', 'sono andato', 'avevo andato', 'andai'],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'linguaItaliana',
    question: "Qual e' il contrario di 'alto'?",
    options: ['grande', 'lungo', 'basso', 'corto'],
    correctIndex: 2,
  ),
  QuizQuestion(
    category: 'linguaItaliana',
    question: "Quale di queste frasi e' corretta?",
    options: [
      'Io mangio una mela',
      'Io mangia una mela',
      'Io mangiano una mela',
      'Io mangiate una mela',
    ],
    correctIndex: 0,
  ),
  QuizQuestion(
    category: 'linguaItaliana',
    question: "Il plurale di 'uomo' e':",
    options: ['uomi', 'uomini', 'uomoni', 'uomes'],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'linguaItaliana',
    question: "Quale preposizione si usa con 'vado ... scuola'?",
    options: ['in', 'a', 'di', 'da'],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'linguaItaliana',
    question: "Il femminile di 'attore' e':",
    options: ['attora', 'attrice', 'attressa', 'attoressa'],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'linguaItaliana',
    question: "'Buonasera' si usa a partire da che ora?",
    options: ['dalle 12', 'dalle 14', 'dalle 17', 'dalle 20'],
    correctIndex: 2,
  ),
  QuizQuestion(
    category: 'linguaItaliana',
    question: "Qual e' il participio passato di 'scrivere'?",
    options: ['scrivuto', 'scritto', 'scrivito', 'scrissuto'],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'linguaItaliana',
    question: "Il plurale di 'citta' e':",
    options: ['cittae', 'cittes', 'citta', 'cittai'],
    correctIndex: 2,
  ),
  QuizQuestion(
    category: 'linguaItaliana',
    question: "Quale articolo si usa con 'amica'?",
    options: ['la', 'il', "l'", 'le'],
    correctIndex: 2,
  ),
  QuizQuestion(
    category: 'linguaItaliana',
    question: "'Vorrei un caffe'' e' una forma di:",
    options: ['imperativo', 'condizionale', 'congiuntivo', 'indicativo'],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'linguaItaliana',
    question: "Qual e' il plurale di 'braccio' (parte del corpo)?",
    options: ['bracci', 'braccia', 'braccii', 'braccie'],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'linguaItaliana',
    question: "Quale verbo ausiliare si usa con 'partire'?",
    options: ['avere', 'essere', 'stare', 'venire'],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'linguaItaliana',
    question: "Il superlativo assoluto di 'bello' e':",
    options: ['bellissimo', 'il piu bello', 'molto bello', 'bello forte'],
    correctIndex: 0,
  ),
  QuizQuestion(
    category: 'linguaItaliana',
    question: "'Mi piace la pizza' - 'pizza' e':",
    options: ['soggetto', 'complemento oggetto', 'verbo', 'avverbio'],
    correctIndex: 0,
  ),
  QuizQuestion(
    category: 'linguaItaliana',
    question: "Quale forma e' corretta?",
    options: [
      'Se avrei tempo, verrei',
      'Se avessi tempo, verrei',
      'Se avevo tempo, venivo',
      'Se ho tempo, verrei',
    ],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'linguaItaliana',
    question: "Il plurale di 'uovo' e':",
    options: ['uovi', 'uova', 'uovoi', 'uove'],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'linguaItaliana',
    question: "'Andarsene' significa:",
    options: ['arrivare', 'restare', 'andare via', 'tornare'],
    correctIndex: 2,
  ),
  QuizQuestion(
    category: 'linguaItaliana',
    question: "Quale di queste e' una congiunzione?",
    options: ['velocemente', 'perche', 'bello', 'sotto'],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'linguaItaliana',
    question: "Il gerundio di 'fare' e':",
    options: ['facendo', 'fando', 'farendo', 'faccendo'],
    correctIndex: 0,
  ),
  QuizQuestion(
    category: 'linguaItaliana',
    question: "'Ce l'ho fatta' significa:",
    options: [
      'Ho fallito',
      'Sono riuscito',
      'Sono stanco',
      'Ho dimenticato',
    ],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'linguaItaliana',
    question: "Quale articolo si usa con 'studente'?",
    options: ['il', 'lo', 'la', 'un'],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'linguaItaliana',
    question: "Il passato remoto di 'essere' (io) e':",
    options: ['ero', 'fui', 'sono stato', 'stetti'],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'linguaItaliana',
    question: "Il plurale di 'medico' e':",
    options: ['medichi', 'medici', 'medicii', 'medicos'],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'linguaItaliana',
    question: "'Magari!' esprime:",
    options: ['rabbia', 'desiderio/speranza', 'tristezza', 'noia'],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'linguaItaliana',
    question: "Quale preposizione: 'Vengo ... Francia'?",
    options: ['di', 'da', 'dalla', 'in'],
    correctIndex: 2,
  ),
  QuizQuestion(
    category: 'linguaItaliana',
    question: "'Fare le ore piccole' significa:",
    options: [
      'svegliarsi presto',
      'andare a dormire tardi',
      'lavorare poco',
      'essere puntuali',
    ],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'linguaItaliana',
    question: "Il condizionale di 'potere' (io) e':",
    options: ['posso', 'potrei', 'potevo', 'potessi'],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'linguaItaliana',
    question: "'Ci vediamo domani' - 'ci' e':",
    options: [
      'avverbio di luogo',
      'pronome riflessivo reciproco',
      'congiunzione',
      'preposizione',
    ],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'linguaItaliana',
    question: "Il plurale di 'amico' e':",
    options: ['amichi', 'amici', 'amicii', 'amicos'],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'linguaItaliana',
    question: "Qual e' il sinonimo di 'veloce'?",
    options: ['lento', 'rapido', 'pesante', 'leggero'],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'linguaItaliana',
    question: "'Non ne posso piu' significa:",
    options: [
      'Non sono capace',
      'Sono esausto/stufo',
      'Non ho soldi',
      'Non capisco',
    ],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'linguaItaliana',
    question: "Il plurale di 'moglie' e':",
    options: ['moglie', 'mogli', 'moglie', 'moglii'],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'linguaItaliana',
    question: "'Stare per' indica un'azione:",
    options: ['passata', 'imminente', 'impossibile', 'ripetuta'],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'linguaItaliana',
    question: "Quale e' la forma corretta?",
    options: [
      'A me mi piace',
      'Mi piace',
      'Io piaccio',
      'A me piaccio',
    ],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'linguaItaliana',
    question: "Il participio passato di 'aprire' e':",
    options: ['aprito', 'aperto', 'apruto', 'apriso'],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'linguaItaliana',
    question: "'In bocca al lupo' si risponde con:",
    options: ['Grazie', 'Crepi!', 'Anche a te', 'Prego'],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'linguaItaliana',
    question: "Il futuro di 'venire' (io) e':",
    options: ['veniro', 'verro', 'veniro', 'venero'],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'linguaItaliana',
    question: "'Acqua in bocca!' significa:",
    options: ['Ho sete', 'Mantieni il segreto', 'Stai zitto', 'Bevi acqua'],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'linguaItaliana',
    question: "Quale forma e' corretta?",
    options: [
      'Ho mangiato tre pizza',
      'Ho mangiato tre pizze',
      'Ho mangiato tre pizzi',
      'Ho mangiato tre pizzas',
    ],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'linguaItaliana',
    question: "Il contrario di 'ricco' e':",
    options: ['brutto', 'povero', 'piccolo', 'vecchio'],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'linguaItaliana',
    question: "'Dare del Lei' significa:",
    options: [
      'Dare qualcosa a lei',
      'Usare la forma formale',
      'Parlare a voce alta',
      'Dire bugie',
    ],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'linguaItaliana',
    question: "L'imperfetto di 'avere' (noi) e':",
    options: ['abbiamo', 'avevamo', 'avremmo', 'avremo'],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'linguaItaliana',
    question: "Il plurale di 'ginocchio' e':",
    options: ['ginocchi', 'ginocchia', 'ginocchii', 'ginocchie'],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'linguaItaliana',
    question: "'Prendere in giro' significa:",
    options: ['accompagnare', 'deridere', 'aiutare', 'aspettare'],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'linguaItaliana',
    question: "Quale preposizione: 'Vado ... medico'?",
    options: ['a', 'al', 'dal', 'nel'],
    correctIndex: 2,
  ),
  QuizQuestion(
    category: 'linguaItaliana',
    question: "Il participio passato di 'leggere' e':",
    options: ['leggito', 'letto', 'legguto', 'leggiuto'],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'linguaItaliana',
    question: "'Che ore sono?' - 'Sono le tre e ...'  (3:30):",
    options: ['trenta', 'mezza', 'meta', 'mezzo'],
    correctIndex: 1,
  ),

  // ═══════════════════════════════════════════════════════
  // CULTURA E STORIA (42 questions)
  // ═══════════════════════════════════════════════════════
  QuizQuestion(
    category: 'culturaStoria',
    question: "Qual e' la capitale d'Italia?",
    options: ['Milano', 'Roma', 'Napoli', 'Firenze'],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'culturaStoria',
    question: "In che anno e' stata fondata la Repubblica Italiana?",
    options: ['1945', '1946', '1948', '1950'],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'culturaStoria',
    question: "Chi ha scritto la Divina Commedia?",
    options: ['Petrarca', 'Boccaccio', 'Dante Alighieri', 'Manzoni'],
    correctIndex: 2,
  ),
  QuizQuestion(
    category: 'culturaStoria',
    question: "Quante regioni ha l'Italia?",
    options: ['15', '18', '20', '25'],
    correctIndex: 2,
  ),
  QuizQuestion(
    category: 'culturaStoria',
    question: "Qual e' il fiume piu' lungo d'Italia?",
    options: ['Tevere', 'Adige', 'Po', 'Arno'],
    correctIndex: 2,
  ),
  QuizQuestion(
    category: 'culturaStoria',
    question: "Il 25 aprile si celebra:",
    options: [
      'La Festa della Repubblica',
      'La Liberazione',
      "La Festa dell'Unita'",
      'Il Natale',
    ],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'culturaStoria',
    question: "Il 2 giugno e' la festa della:",
    options: ['Liberazione', 'Repubblica', 'Costituzione', 'Unificazione'],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'culturaStoria',
    question: "Chi ha dipinto la Cappella Sistina?",
    options: ['Leonardo', 'Raffaello', 'Michelangelo', 'Caravaggio'],
    correctIndex: 2,
  ),
  QuizQuestion(
    category: 'culturaStoria',
    question: "L'Italia e' bagnata da quanti mari?",
    options: ['2', '3', '4', '5'],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'culturaStoria',
    question: "Chi era Giuseppe Garibaldi?",
    options: [
      'Un pittore',
      "Un eroe del Risorgimento",
      'Un musicista',
      'Un papa',
    ],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'culturaStoria',
    question: "L'Unita' d'Italia e' avvenuta nel:",
    options: ['1848', '1861', '1870', '1900'],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'culturaStoria',
    question: "La Torre di Pisa si trova in:",
    options: ['Lombardia', 'Lazio', 'Toscana', 'Campania'],
    correctIndex: 2,
  ),
  QuizQuestion(
    category: 'culturaStoria',
    question: "Quale citta' e' famosa per il Colosseo?",
    options: ['Firenze', 'Roma', 'Napoli', 'Venezia'],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'culturaStoria',
    question: "Il tricolore italiano e' composto da:",
    options: [
      'Rosso, bianco, nero',
      'Verde, bianco, rosso',
      'Blu, bianco, rosso',
      'Verde, giallo, rosso',
    ],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'culturaStoria',
    question: "Chi ha scritto 'I Promessi Sposi'?",
    options: ['Verga', 'Manzoni', 'Pirandello', 'Leopardi'],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'culturaStoria',
    question: "Il vulcano Vesuvio si trova vicino a:",
    options: ['Roma', 'Palermo', 'Napoli', 'Catania'],
    correctIndex: 2,
  ),
  QuizQuestion(
    category: 'culturaStoria',
    question: "Leonardo da Vinci ha dipinto:",
    options: [
      'La nascita di Venere',
      'La Gioconda',
      'La Primavera',
      'Il Giudizio Universale',
    ],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'culturaStoria',
    question: "Il Rinascimento e' nato in:",
    options: ['Roma', 'Venezia', 'Firenze', 'Milano'],
    correctIndex: 2,
  ),
  QuizQuestion(
    category: 'culturaStoria',
    question: "Quale isola e' la piu' grande del Mediterraneo?",
    options: ['Sardegna', 'Corsica', 'Sicilia', 'Creta'],
    correctIndex: 2,
  ),
  QuizQuestion(
    category: 'culturaStoria',
    question: "L'inno nazionale italiano si chiama:",
    options: [
      "L'Inno di Mameli",
      "L'Inno di Garibaldi",
      "L'Inno della Patria",
      "L'Inno del Popolo",
    ],
    correctIndex: 0,
  ),
  QuizQuestion(
    category: 'culturaStoria',
    question: "Roma e' stata fondata secondo la leggenda nel:",
    options: ['553 a.C.', '753 a.C.', '453 a.C.', '953 a.C.'],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'culturaStoria',
    question: "Chi ha inventato la radio?",
    options: ['Edison', 'Tesla', 'Marconi', 'Volta'],
    correctIndex: 2,
  ),
  QuizQuestion(
    category: 'culturaStoria',
    question: "Il Colosseo poteva contenere circa:",
    options: ['20.000 persone', '50.000 persone', '100.000 persone', '10.000 persone'],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'culturaStoria',
    question: "Quale citta' e' famosa per i canali?",
    options: ['Genova', 'Trieste', 'Venezia', 'Bari'],
    correctIndex: 2,
  ),
  QuizQuestion(
    category: 'culturaStoria',
    question: "La moneta usata in Italia e':",
    options: ['Lira', 'Euro', 'Dollaro', 'Sterlina'],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'culturaStoria',
    question: "In che anno l'Italia ha adottato l'Euro?",
    options: ['1999', '2000', '2002', '2004'],
    correctIndex: 2,
  ),
  QuizQuestion(
    category: 'culturaStoria',
    question: "Chi e' il compositore de 'La Traviata'?",
    options: ['Puccini', 'Rossini', 'Verdi', 'Donizetti'],
    correctIndex: 2,
  ),
  QuizQuestion(
    category: 'culturaStoria',
    question: "Il lago piu' grande d'Italia e':",
    options: ['Lago Maggiore', 'Lago di Como', 'Lago di Garda', 'Lago Trasimeno'],
    correctIndex: 2,
  ),
  QuizQuestion(
    category: 'culturaStoria',
    question: "La Sardegna e':",
    options: ['Una regione del nord', "Un'isola", 'Una citta', 'Una provincia'],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'culturaStoria',
    question: "Il Vaticano si trova a:",
    options: ['Milano', 'Firenze', 'Roma', 'Torino'],
    correctIndex: 2,
  ),
  QuizQuestion(
    category: 'culturaStoria',
    question: "Il Monte Bianco si trova al confine tra Italia e:",
    options: ['Svizzera', 'Austria', 'Francia', 'Slovenia'],
    correctIndex: 2,
  ),
  QuizQuestion(
    category: 'culturaStoria',
    question: "La pizza margherita e' nata a:",
    options: ['Roma', 'Milano', 'Napoli', 'Palermo'],
    correctIndex: 2,
  ),
  QuizQuestion(
    category: 'culturaStoria',
    question: "Chi era Cristoforo Colombo?",
    options: [
      'Un pittore',
      'Un navigatore/esploratore',
      'Un musicista',
      'Un poeta',
    ],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'culturaStoria',
    question: "La regione con capoluogo Torino e':",
    options: ['Lombardia', 'Piemonte', 'Liguria', 'Emilia-Romagna'],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'culturaStoria',
    question: "Il Palio si corre a:",
    options: ['Firenze', 'Siena', 'Perugia', 'Arezzo'],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'culturaStoria',
    question: "Alessandro Volta ha inventato:",
    options: ['Il telefono', 'La pila elettrica', 'La radio', 'Il motore'],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'culturaStoria',
    question: "Il Capodanno in Italia si festeggia il:",
    options: ['31 dicembre', '1 gennaio', '6 gennaio', '25 dicembre'],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'culturaStoria',
    question: "Galileo Galilei e' considerato il padre della:",
    options: ['Filosofia', 'Scienza moderna', 'Medicina', 'Letteratura'],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'culturaStoria',
    question: "La catena montuosa che attraversa l'Italia e':",
    options: ['Le Alpi', 'Gli Appennini', 'Le Dolomiti', 'I Pirenei'],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'culturaStoria',
    question: "L'Italia confina a nord con:",
    options: [
      'Francia, Svizzera, Austria, Slovenia',
      'Francia, Germania, Austria',
      'Spagna, Francia, Svizzera',
      'Svizzera, Austria, Ungheria',
    ],
    correctIndex: 0,
  ),
  QuizQuestion(
    category: 'culturaStoria',
    question: "La Festa di Ferragosto cade il:",
    options: ['1 agosto', '10 agosto', '15 agosto', '20 agosto'],
    correctIndex: 2,
  ),
  QuizQuestion(
    category: 'culturaStoria',
    question: "Qual e' il capoluogo della Lombardia?",
    options: ['Torino', 'Milano', 'Genova', 'Brescia'],
    correctIndex: 1,
  ),

  // ═══════════════════════════════════════════════════════
  // COSTITUZIONE (42 questions)
  // ═══════════════════════════════════════════════════════
  QuizQuestion(
    category: 'costituzione',
    question: "Quanti articoli ha la Costituzione italiana?",
    options: ['100', '120', '139', '150'],
    correctIndex: 2,
  ),
  QuizQuestion(
    category: 'costituzione',
    question: "L'articolo 1 dice che l'Italia e':",
    options: [
      'Una monarchia costituzionale',
      'Una Repubblica democratica fondata sul lavoro',
      'Una Repubblica federale',
      'Una Repubblica presidenziale',
    ],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'costituzione',
    question: "La Costituzione italiana e' entrata in vigore il:",
    options: [
      '2 giugno 1946',
      '25 aprile 1945',
      '1 gennaio 1948',
      '1 gennaio 1950',
    ],
    correctIndex: 2,
  ),
  QuizQuestion(
    category: 'costituzione',
    question: "L'articolo 3 parla di:",
    options: [
      'Diritto al lavoro',
      'Uguaglianza dei cittadini',
      'Liberta di religione',
      'Diritto alla salute',
    ],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'costituzione',
    question: "L'articolo 4 riguarda:",
    options: [
      'Il diritto alla salute',
      'Il diritto al lavoro',
      'La liberta di pensiero',
      'Il diritto allo studio',
    ],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'costituzione',
    question: "L'articolo 7 regola i rapporti tra Stato e:",
    options: [
      'Regioni',
      'Chiesa Cattolica',
      'Unione Europea',
      'Partiti politici',
    ],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'costituzione',
    question: "I principi fondamentali della Costituzione sono negli articoli:",
    options: ['1-5', '1-12', '1-20', '1-50'],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'costituzione',
    question: "L'articolo 11 dice che l'Italia:",
    options: [
      'E una monarchia',
      'Ripudia la guerra',
      'Non ha esercito',
      'Non fa alleanze',
    ],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'costituzione',
    question: "L'articolo 13 garantisce:",
    options: [
      'La liberta personale',
      'La liberta di stampa',
      'Il diritto al lavoro',
      'Il diritto di voto',
    ],
    correctIndex: 0,
  ),
  QuizQuestion(
    category: 'costituzione',
    question: "L'articolo 21 tutela:",
    options: [
      'Il diritto alla salute',
      'La liberta di pensiero e parola',
      'Il diritto alla casa',
      'La liberta di religione',
    ],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'costituzione',
    question: "L'articolo 32 riguarda:",
    options: [
      'Il diritto alla salute',
      'Il diritto allo studio',
      'Il diritto al lavoro',
      'La liberta di culto',
    ],
    correctIndex: 0,
  ),
  QuizQuestion(
    category: 'costituzione',
    question: "L'articolo 34 dice che la scuola e':",
    options: [
      'Facoltativa',
      'Aperta a tutti',
      'Solo per cittadini italiani',
      'Privata',
    ],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'costituzione',
    question: "Secondo l'articolo 48, chi ha diritto di voto?",
    options: [
      'Tutti i residenti',
      'Tutti i cittadini maggiorenni',
      'Solo gli uomini',
      'Solo chi lavora',
    ],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'costituzione',
    question: "L'articolo 2 riconosce i diritti:",
    options: [
      'Solo dei cittadini',
      "Inviolabili dell'uomo",
      'Solo dei lavoratori',
      'Solo delle donne',
    ],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'costituzione',
    question: "La bandiera italiana e' descritta nell'articolo:",
    options: ['Art. 10', 'Art. 12', 'Art. 15', 'Art. 1'],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'costituzione',
    question: "L'articolo 8 garantisce:",
    options: [
      'La liberta di culto',
      'La liberta di stampa',
      'Il diritto di voto',
      'Il diritto alla casa',
    ],
    correctIndex: 0,
  ),
  QuizQuestion(
    category: 'costituzione',
    question: "L'articolo 9 promuove:",
    options: [
      'Lo sport',
      'La cultura e la ricerca scientifica',
      'Il turismo',
      'Il commercio',
    ],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'costituzione',
    question: "L'articolo 10 riguarda:",
    options: [
      'Il diritto internazionale e gli stranieri',
      'Il diritto alla salute',
      'La liberta di stampa',
      'Il lavoro',
    ],
    correctIndex: 0,
  ),
  QuizQuestion(
    category: 'costituzione',
    question: "La sovranita' appartiene a (Art. 1):",
    options: ['Il Presidente', 'Il Parlamento', 'Il popolo', 'Il Governo'],
    correctIndex: 2,
  ),
  QuizQuestion(
    category: 'costituzione',
    question: "L'articolo 37 tutela i diritti:",
    options: [
      'Dei bambini',
      'Delle donne lavoratrici e dei minori',
      'Degli anziani',
      'Degli stranieri',
    ],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'costituzione',
    question: "L'articolo 29 riguarda:",
    options: ['Lo sport', 'La famiglia', 'Il lavoro', 'La religione'],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'costituzione',
    question: "L'articolo 53 stabilisce che tutti devono:",
    options: [
      'Lavorare',
      'Pagare le tasse in base alla capacita contributiva',
      'Votare',
      'Fare il servizio militare',
    ],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'costituzione',
    question: "L'articolo 27 dice che la pena di morte:",
    options: [
      'E ammessa in casi gravi',
      'Non e ammessa',
      'E facoltativa',
      'Dipende dal reato',
    ],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'costituzione',
    question: "L'articolo 36 stabilisce che il lavoratore ha diritto a:",
    options: [
      'Lavorare sempre',
      'Una retribuzione equa e sufficiente',
      'Non pagare tasse',
      'Scegliere le ore',
    ],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'costituzione',
    question: "L'articolo 19 garantisce la liberta di:",
    options: [
      'Stampa',
      'Professare la propria fede religiosa',
      'Movimento',
      'Commercio',
    ],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'costituzione',
    question: "L'articolo 16 garantisce la liberta di:",
    options: [
      'Parola',
      'Circolazione nel territorio',
      'Religione',
      'Stampa',
    ],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'costituzione',
    question: "L'articolo 38 riguarda:",
    options: [
      "L'assistenza sociale e la previdenza",
      'Il commercio',
      "L'istruzione",
      'La difesa',
    ],
    correctIndex: 0,
  ),
  QuizQuestion(
    category: 'costituzione',
    question: "L'articolo 5 dice che la Repubblica e':",
    options: [
      'Federale',
      'Una e indivisibile',
      'Divisa in stati',
      'Monarchica',
    ],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'costituzione',
    question: "La Costituzione e' stata approvata dall':",
    options: [
      'Assemblea Costituente',
      'Parlamento',
      'Re',
      'Presidente della Repubblica',
    ],
    correctIndex: 0,
  ),
  QuizQuestion(
    category: 'costituzione',
    question: "L'articolo 6 tutela:",
    options: [
      'Le minoranze linguistiche',
      'I partiti politici',
      'La proprieta privata',
      'Il lavoro femminile',
    ],
    correctIndex: 0,
  ),
  QuizQuestion(
    category: 'costituzione',
    question: "L'articolo 40 riconosce il diritto di:",
    options: ['Voto', 'Sciopero', 'Proprieta', 'Salute'],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'costituzione',
    question: "L'articolo 33 stabilisce che l'arte e la scienza sono:",
    options: ['Regolate dallo Stato', 'Libere', 'Vietate', 'Controllate'],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'costituzione',
    question: "Il referendum abrogativo e' previsto dall'articolo:",
    options: ['Art. 70', 'Art. 75', 'Art. 80', 'Art. 90'],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'costituzione',
    question: "L'articolo 52 riguarda:",
    options: [
      'Il commercio',
      'La difesa della Patria',
      'La famiglia',
      'Lo sport',
    ],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'costituzione',
    question: "L'articolo 54 stabilisce il dovere di:",
    options: [
      'Lavorare',
      'Fedelta alla Repubblica e alla Costituzione',
      'Votare',
      'Pagare le tasse',
    ],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'costituzione',
    question: "La prima parte della Costituzione tratta di:",
    options: [
      'Ordinamento della Repubblica',
      'Diritti e doveri dei cittadini',
      'Disposizioni transitorie',
      'Organizzazione militare',
    ],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'costituzione',
    question: "L'articolo 18 riconosce il diritto di:",
    options: [
      'Associarsi liberamente',
      'Sciopero',
      'Voto',
      'Religione',
    ],
    correctIndex: 0,
  ),
  QuizQuestion(
    category: 'costituzione',
    question: "L'articolo 15 tutela la liberta e la segretezza:",
    options: [
      'Del voto',
      'Della corrispondenza',
      'Della religione',
      'Del domicilio',
    ],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'costituzione',
    question: "L'articolo 14 dichiara inviolabile:",
    options: ['La persona', 'Il domicilio', 'La corrispondenza', 'Il lavoro'],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'costituzione',
    question: "L'articolo 30 stabilisce il dovere dei genitori di:",
    options: [
      'Lavorare',
      'Mantenere, istruire, educare i figli',
      'Pagare le tasse',
      'Votare',
    ],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'costituzione',
    question: "L'articolo 17 riconosce il diritto di:",
    options: [
      'Riunirsi pacificamente',
      'Scioperare',
      'Emigrare',
      'Possedere armi',
    ],
    correctIndex: 0,
  ),
  QuizQuestion(
    category: 'costituzione',
    question: "L'articolo 22 vieta la privazione per motivi politici:",
    options: [
      'Del lavoro',
      'Della cittadinanza e del nome',
      'Della casa',
      'Del voto',
    ],
    correctIndex: 1,
  ),

  // ═══════════════════════════════════════════════════════
  // VITA CIVICA (42 questions)
  // ═══════════════════════════════════════════════════════
  QuizQuestion(
    category: 'vitaCivica',
    question: "Cosa significa SPID?",
    options: [
      "Sistema Pubblico di Identita' Digitale",
      "Servizio Pubblico di Identita' Digitale",
      'Sistema Privato di Identita Digitale',
      'Servizio Privato di Identita Digitale',
    ],
    correctIndex: 0,
  ),
  QuizQuestion(
    category: 'vitaCivica',
    question: "Qual e' il numero di emergenza in Italia (e in Europa)?",
    options: ['911', '118', '112', '113'],
    correctIndex: 2,
  ),
  QuizQuestion(
    category: 'vitaCivica',
    question: "Per il permesso di soggiorno ci si rivolge a:",
    options: ['Comune', 'Questura', 'Prefettura', 'Tribunale'],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'vitaCivica',
    question: "La tessera sanitaria da' diritto a:",
    options: [
      'Votare',
      "Assistenza sanitaria gratuita nell'SSN",
      'Guidare',
      'Lavorare',
    ],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'vitaCivica',
    question: "L'INPS si occupa di:",
    options: ['Sanita', 'Previdenza e assistenza sociale', 'Istruzione', 'Difesa'],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'vitaCivica',
    question: "Il medico di base e' chiamato anche:",
    options: [
      'Medico di famiglia',
      'Medico ospedaliero',
      'Medico sportivo',
      'Medico scolastico',
    ],
    correctIndex: 0,
  ),
  QuizQuestion(
    category: 'vitaCivica',
    question: "Per registrare una nascita si va al:",
    options: ['Ospedale', 'Comune (Ufficio di Stato Civile)', 'Questura', 'Tribunale'],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'vitaCivica',
    question: "Il codice fiscale e' rilasciato da:",
    options: ['Il Comune', "L'Agenzia delle Entrate", "L'INPS", 'La Questura'],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'vitaCivica',
    question: "La carta d'identita' e' rilasciata dal:",
    options: ['Comune', 'Questura', 'Prefettura', 'Tribunale'],
    correctIndex: 0,
  ),
  QuizQuestion(
    category: 'vitaCivica',
    question: "Per sposarsi civilmente ci si rivolge al:",
    options: ['Parroco', 'Comune', 'Tribunale', 'Questura'],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'vitaCivica',
    question: "L'obbligo scolastico in Italia va dai:",
    options: ['5 ai 14 anni', '6 ai 16 anni', '6 ai 18 anni', '7 ai 15 anni'],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'vitaCivica',
    question: "Il 118 e' il numero per:",
    options: [
      'I Carabinieri',
      "L'emergenza sanitaria",
      'I Vigili del Fuoco',
      'La Polizia',
    ],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'vitaCivica',
    question: "L'ISEE serve per:",
    options: [
      'Pagare le tasse',
      'Misurare la situazione economica del nucleo familiare',
      "Ottenere la cittadinanza",
      "Richiedere il passaporto",
    ],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'vitaCivica',
    question: "Il CAF e':",
    options: [
      'Un centro sportivo',
      'Un Centro di Assistenza Fiscale',
      'Un centro medico',
      'Un centro culturale',
    ],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'vitaCivica',
    question: "Il Patronato aiuta i cittadini per:",
    options: [
      'Questioni sportive',
      'Pratiche previdenziali e assistenziali',
      'Questioni religiose',
      'Questioni scolastiche',
    ],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'vitaCivica',
    question: "La residenza si dichiara al:",
    options: ['Questura', 'Comune', 'Prefettura', 'Tribunale'],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'vitaCivica',
    question: "Per guidare in Italia serve:",
    options: [
      "Solo il documento d'identita",
      'La patente di guida',
      'Solo il passaporto',
      'Il codice fiscale',
    ],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'vitaCivica',
    question: "Il SSN e':",
    options: [
      'Un sindacato',
      'Il Servizio Sanitario Nazionale',
      'Un servizio postale',
      'Un ente scolastico',
    ],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'vitaCivica',
    question: "Per denunciare un furto si va da:",
    options: ['Il medico', 'Carabinieri o Polizia', 'Il Comune', 'Il notaio'],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'vitaCivica',
    question: "Il CIE e':",
    options: [
      'Carta Italiana Europea',
      "Carta d'Identita' Elettronica",
      'Certificato di Identita Economica',
      'Centro Informazioni Europeo',
    ],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'vitaCivica',
    question: "Il 115 e' il numero dei:",
    options: [
      'Carabinieri',
      'Vigili del Fuoco',
      'Polizia',
      'Guardia di Finanza',
    ],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'vitaCivica',
    question: "Per iscrivere un figlio a scuola bisogna:",
    options: [
      'Andare al Comune',
      'Fare iscrizione online o alla segreteria scolastica',
      'Andare in Questura',
      'Chiedere al medico',
    ],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'vitaCivica',
    question: "Il contratto di lavoro in Italia deve essere:",
    options: ['Solo orale', 'Scritto', 'Facoltativo', 'Solo in inglese'],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'vitaCivica',
    question: "L'assicurazione auto in Italia e':",
    options: ['Facoltativa', 'Obbligatoria', 'Solo per auto nuove', 'Gratuita'],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'vitaCivica',
    question: "Il PEC e':",
    options: [
      'Posta Elettronica Comune',
      'Posta Elettronica Certificata',
      'Permesso Europeo Certificato',
      'Protocollo Europeo Comune',
    ],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'vitaCivica',
    question: "Per ottenere la cittadinanza italiana per residenza servono:",
    options: ['5 anni', '8 anni', '10 anni', '15 anni'],
    correctIndex: 2,
  ),
  QuizQuestion(
    category: 'vitaCivica',
    question: "Il permesso di soggiorno UE di lungo periodo richiede:",
    options: [
      '3 anni di residenza',
      '5 anni di residenza legale',
      '10 anni di residenza',
      '1 anno di residenza',
    ],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'vitaCivica',
    question: "La dichiarazione dei redditi si presenta con il modello:",
    options: ['740 o 730', 'ISEE', 'F24', 'CUD'],
    correctIndex: 0,
  ),
  QuizQuestion(
    category: 'vitaCivica',
    question: "L'anagrafe si trova presso:",
    options: ['La Questura', 'Il Comune', 'La Prefettura', "L'INPS"],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'vitaCivica',
    question: "Il TFR e':",
    options: [
      'Tassa sulla casa',
      'Trattamento di Fine Rapporto (liquidazione)',
      'Tassa sui rifiuti',
      'Tassa sul reddito',
    ],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'vitaCivica',
    question: "Per cambiare il medico di base ci si rivolge alla:",
    options: ['Farmacia', 'ASL', 'Questura', 'Regione'],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'vitaCivica',
    question: "La raccolta differenziata e':",
    options: [
      'Facoltativa',
      'Obbligatoria per legge',
      'Solo per le aziende',
      'Vietata',
    ],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'vitaCivica',
    question: "Il Pronto Soccorso usa codici colore. Il rosso indica:",
    options: [
      'Non urgente',
      'Urgente',
      'Emergenza gravissima',
      'Problema lieve',
    ],
    correctIndex: 2,
  ),
  QuizQuestion(
    category: 'vitaCivica',
    question: "L'IMU e':",
    options: [
      "Un'imposta sugli immobili",
      "Un'imposta sul reddito",
      "Un'assicurazione sanitaria",
      'Un contributo INPS',
    ],
    correctIndex: 0,
  ),
  QuizQuestion(
    category: 'vitaCivica',
    question: "Il passaporto italiano e' rilasciato dalla:",
    options: ['Comune', 'Questura', 'Prefettura', 'Ambasciata'],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'vitaCivica',
    question: "L'eta' minima per lavorare in Italia e':",
    options: ['14 anni', '16 anni', '18 anni', '15 anni'],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'vitaCivica',
    question: "Il numero 113 e' quello della:",
    options: [
      'Polizia di Stato',
      'Carabinieri',
      'Vigili del Fuoco',
      'Ambulanza',
    ],
    correctIndex: 0,
  ),
  QuizQuestion(
    category: 'vitaCivica',
    question: "Per aprire un conto in banca serve:",
    options: [
      'Solo il passaporto',
      'Documento di identita e codice fiscale',
      'Solo il codice fiscale',
      'La tessera sanitaria',
    ],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'vitaCivica',
    question: "La scuola pubblica in Italia e':",
    options: ['A pagamento', 'Gratuita', 'Solo per italiani', 'Facoltativa'],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'vitaCivica',
    question: "L'ACI si occupa di:",
    options: [
      'Assistenza sanitaria',
      'Assistenza automobilisti',
      'Assistenza fiscale',
      'Assistenza legale',
    ],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'vitaCivica',
    question: "La TARI e':",
    options: [
      "Un'imposta sulla casa",
      'La tassa sui rifiuti',
      "Un'imposta sul reddito",
      'Una tassa scolastica',
    ],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'vitaCivica',
    question: "Per votare alle elezioni comunali, gli stranieri UE:",
    options: [
      'Non possono votare',
      'Possono votare se residenti',
      'Devono essere cittadini',
      'Votano solo al Senato',
    ],
    correctIndex: 1,
  ),

  // ═══════════════════════════════════════════════════════
  // EDUCAZIONE CIVICA (42 questions)
  // ═══════════════════════════════════════════════════════
  QuizQuestion(
    category: 'educazioneCivica',
    question: "Chi e' il capo dello Stato in Italia?",
    options: [
      'Il Presidente del Consiglio',
      'Il Presidente della Repubblica',
      'Il Presidente del Senato',
      'Il Papa',
    ],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'educazioneCivica',
    question: "Ogni quanti anni si elegge il Parlamento?",
    options: ['3 anni', '4 anni', '5 anni', '7 anni'],
    correctIndex: 2,
  ),
  QuizQuestion(
    category: 'educazioneCivica',
    question: "Il Parlamento italiano e' composto da:",
    options: [
      'Solo la Camera dei Deputati',
      'Camera dei Deputati e Senato',
      'Solo il Senato',
      'Camera, Senato e Governo',
    ],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'educazioneCivica',
    question: "Il Presidente della Repubblica dura in carica:",
    options: ['4 anni', '5 anni', '7 anni', '10 anni'],
    correctIndex: 2,
  ),
  QuizQuestion(
    category: 'educazioneCivica',
    question: "Chi nomina il Presidente del Consiglio?",
    options: [
      'Il popolo',
      'Il Presidente della Repubblica',
      'Il Parlamento',
      'La Corte Costituzionale',
    ],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'educazioneCivica',
    question: "La Corte Costituzionale giudica:",
    options: [
      'I reati penali',
      'La conformita delle leggi alla Costituzione',
      'Le cause civili',
      'I reati fiscali',
    ],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'educazioneCivica',
    question: "Il potere legislativo appartiene a:",
    options: ['Il Governo', 'Il Parlamento', 'La Magistratura', 'Il Presidente'],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'educazioneCivica',
    question: "Il potere esecutivo appartiene a:",
    options: ['Il Parlamento', 'Il Governo', 'La Magistratura', 'Il popolo'],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'educazioneCivica',
    question: "Il potere giudiziario appartiene a:",
    options: ['Il Governo', 'Il Parlamento', 'La Magistratura', 'Il Presidente'],
    correctIndex: 2,
  ),
  QuizQuestion(
    category: 'educazioneCivica',
    question: "Quanti deputati ha la Camera dopo la riforma del 2020?",
    options: ['630', '400', '500', '315'],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'educazioneCivica',
    question: "Quanti senatori ha il Senato dopo la riforma del 2020?",
    options: ['315', '200', '400', '100'],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'educazioneCivica',
    question: "Per votare alla Camera bisogna avere almeno:",
    options: ['16 anni', '18 anni', '21 anni', '25 anni'],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'educazioneCivica',
    question: "Per votare al Senato bisogna avere almeno:",
    options: ['18 anni', '21 anni', '25 anni', '30 anni'],
    correctIndex: 0,
  ),
  QuizQuestion(
    category: 'educazioneCivica',
    question: "Il Sindaco e' il capo del:",
    options: ['Regione', 'Provincia', 'Comune', 'Stato'],
    correctIndex: 2,
  ),
  QuizQuestion(
    category: 'educazioneCivica',
    question: "Il Prefetto rappresenta:",
    options: [
      'Il Comune',
      'Il Governo nella provincia',
      'La Regione',
      'Il Parlamento',
    ],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'educazioneCivica',
    question: "L'Unione Europea ha attualmente (2024) quanti stati membri?",
    options: ['25', '27', '28', '30'],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'educazioneCivica',
    question: "L'Italia e' membro fondatore dell'UE?",
    options: [
      'Si, dal 1957',
      'No, ha aderito nel 1973',
      'Si, dal 1945',
      'No, ha aderito nel 1986',
    ],
    correctIndex: 0,
  ),
  QuizQuestion(
    category: 'educazioneCivica',
    question: "Chi puo' sciogliere il Parlamento?",
    options: [
      'Il Presidente del Consiglio',
      'Il Presidente della Repubblica',
      'La Corte Costituzionale',
      'Il popolo',
    ],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'educazioneCivica',
    question: "Il CSM (Consiglio Superiore della Magistratura) e' presieduto da:",
    options: [
      'Il Ministro della Giustizia',
      'Il Presidente della Repubblica',
      'Il Presidente del Senato',
      'Il Procuratore Generale',
    ],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'educazioneCivica',
    question: "Le regioni a statuto speciale sono:",
    options: ['3', '5', '7', '10'],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'educazioneCivica',
    question: "Quale di queste e' una regione a statuto speciale?",
    options: ['Lombardia', 'Toscana', 'Sicilia', 'Lazio'],
    correctIndex: 2,
  ),
  QuizQuestion(
    category: 'educazioneCivica',
    question: "Il Governo e' composto da:",
    options: [
      'Solo il Presidente del Consiglio',
      'Presidente del Consiglio e Ministri',
      'Solo i Ministri',
      'Presidente della Repubblica e Ministri',
    ],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'educazioneCivica',
    question: "L'ONU e' stata fondata nel:",
    options: ['1940', '1945', '1950', '1955'],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'educazioneCivica',
    question: "L'Italia e' membro della NATO?",
    options: [
      'Si, dal 1949',
      'No',
      'Si, dal 1955',
      'Si, dal 2000',
    ],
    correctIndex: 0,
  ),
  QuizQuestion(
    category: 'educazioneCivica',
    question: "Il referendum e':",
    options: [
      "Un'elezione del Presidente",
      'Una consultazione popolare su una legge',
      'Una seduta del Parlamento',
      'Una riunione del Governo',
    ],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'educazioneCivica',
    question: "Il Presidente della Repubblica puo' essere rieletto?",
    options: [
      'No, mai',
      'Si, senza limiti',
      'Solo una volta',
      'Solo due volte',
    ],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'educazioneCivica',
    question: "Per essere eletto Presidente della Repubblica bisogna avere almeno:",
    options: ['40 anni', '50 anni', '60 anni', '35 anni'],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'educazioneCivica',
    question: "Chi elegge il Presidente della Repubblica?",
    options: [
      'Il popolo direttamente',
      'Il Parlamento in seduta comune + delegati regionali',
      'Solo il Senato',
      'Solo la Camera',
    ],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'educazioneCivica',
    question: "La Gazzetta Ufficiale pubblica:",
    options: [
      'Le notizie di cronaca',
      'Le leggi e i decreti dello Stato',
      'Le sentenze dei tribunali',
      'I risultati elettorali',
    ],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'educazioneCivica',
    question: "Il voto in Italia e':",
    options: [
      'Obbligatorio',
      'Un diritto e un dovere civico',
      'Solo un diritto',
      'Facoltativo per gli stranieri',
    ],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'educazioneCivica',
    question: "Quante sono le regioni italiane a statuto ordinario?",
    options: ['10', '15', '12', '20'],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'educazioneCivica',
    question: "Il Consiglio dei Ministri e' presieduto da:",
    options: [
      'Il Presidente della Repubblica',
      'Il Presidente del Consiglio',
      'Il Presidente del Senato',
      'Il Ministro degli Interni',
    ],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'educazioneCivica',
    question: "La Corte dei Conti controlla:",
    options: [
      'La giustizia penale',
      'La gestione finanziaria dello Stato',
      'Le elezioni',
      'I matrimoni',
    ],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'educazioneCivica',
    question: "Il Trattato di Roma del 1957 ha istituito:",
    options: [
      "L'ONU",
      'La CEE (Comunita Economica Europea)',
      'La NATO',
      "L'OCSE",
    ],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'educazioneCivica',
    question: "L'Accordo di Schengen permette:",
    options: [
      'Il libero scambio commerciale',
      'La libera circolazione delle persone',
      'Il voto europeo',
      'La moneta unica',
    ],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'educazioneCivica',
    question: "Il Consiglio Regionale ha funzione:",
    options: [
      'Esecutiva',
      'Legislativa regionale',
      'Giudiziaria',
      'Militare',
    ],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'educazioneCivica',
    question: "Un decreto legge deve essere convertito in legge entro:",
    options: ['30 giorni', '60 giorni', '90 giorni', '120 giorni'],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'educazioneCivica',
    question: "La fiducia al Governo e' votata da:",
    options: [
      'Il popolo',
      'Entrambe le Camere del Parlamento',
      'Solo la Camera dei Deputati',
      'Il Presidente della Repubblica',
    ],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'educazioneCivica',
    question: "Il Presidente del Senato sostituisce il Presidente della Repubblica quando:",
    options: [
      'E in vacanza',
      "E' impedito o all'estero",
      'Non e mai possibile',
      'Solo durante le elezioni',
    ],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'educazioneCivica',
    question: "Le Province sono state:",
    options: [
      'Abolite completamente',
      'Riformate (enti di area vasta)',
      'Sostituite dalle Regioni',
      'Mai esistite',
    ],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'educazioneCivica',
    question: "L'AIRE e' il registro degli:",
    options: [
      'Automobilisti italiani',
      "Italiani residenti all'estero",
      'Imprenditori italiani',
      'Anziani in Italia',
    ],
    correctIndex: 1,
  ),
  QuizQuestion(
    category: 'educazioneCivica',
    question: "Il Difensore Civico tutela:",
    options: [
      'I diritti dei militari',
      'I diritti dei cittadini nei confronti della pubblica amministrazione',
      'I diritti degli animali',
      'I diritti dei detenuti',
    ],
    correctIndex: 1,
  ),
];

// ───────────────────── HELPER: get questions by category ─────────────────────

List<QuizQuestion> _getQuestionsByCategory(QuizCategory cat) {
  return _allQuestions.where((q) => q.category == cat.name).toList();
}

// ═══════════════════════════════════════════════════════════════════
// MAIN SCREEN  (category menu)
// ═══════════════════════════════════════════════════════════════════

class QuizCittadinanzaScreen extends StatefulWidget {
  const QuizCittadinanzaScreen({super.key});

  @override
  State<QuizCittadinanzaScreen> createState() => _QuizCittadinanzaScreenState();
}

class _QuizCittadinanzaScreenState extends State<QuizCittadinanzaScreen> {
  Map<String, int> _correctCounts = {};
  Map<String, int> _totalCounts = {};
  Map<String, int> _highScores = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    final correct = <String, int>{};
    final total = <String, int>{};
    final high = <String, int>{};
    for (final cat in QuizCategory.values) {
      correct[cat.name] = prefs.getInt(cat.prefKey) ?? 0;
      total[cat.name] = prefs.getInt(cat.totalKey) ?? 0;
      high[cat.name] = prefs.getInt(cat.highScoreKey) ?? 0;
    }
    if (mounted) {
      setState(() {
        _correctCounts = correct;
        _totalCounts = total;
        _highScores = high;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalQuestions = _allQuestions.length;
    final totalCorrect =
        _correctCounts.values.fold<int>(0, (a, b) => a + b);
    final totalAnswered =
        _totalCounts.values.fold<int>(0, (a, b) => a + b);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(context)),
          SliverToBoxAdapter(
            child: _buildOverallProgress(totalCorrect, totalAnswered, totalQuestions),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                QuizCategory.values.map((cat) {
                  final questions = _getQuestionsByCategory(cat);
                  final correct = _correctCounts[cat.name] ?? 0;
                  final total = _totalCounts[cat.name] ?? 0;
                  final highScore = _highScores[cat.name] ?? 0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _CategoryCard(
                      category: cat,
                      questionCount: questions.length,
                      correctCount: correct,
                      totalAnswered: total,
                      highScore: highScore,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                _QuizSessionScreen(category: cat),
                          ),
                        );
                        _loadStats();
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          // "All categories" button
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              child: GestureDetector(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const _QuizSessionScreen(category: null),
                    ),
                  );
                  _loadStats();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: AppColors.buttonGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shuffle_rounded, color: Colors.white, size: 22),
                      SizedBox(width: 10),
                      Text(
                        'Quiz Misto - Tutte le Categorie',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 20,
        right: 20,
        bottom: 14,
      ),
      decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF43A047), Color(0xFF66BB6A)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF43A047).withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.quiz_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quiz Cittadinanza',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 1),
                Text(
                  'Preparati al test B1 + cultura civica',
                  style: TextStyle(
                    color: AppColors.textSubtitle,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallProgress(int correct, int answered, int total) {
    final pct = total > 0 ? (correct / total * 100).round() : 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bar_chart_rounded,
                    color: AppColors.primary, size: 22),
                const SizedBox(width: 8),
                const Text(
                  'Progresso Totale',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$total domande totali',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _StatChip(
                    label: 'Risposte',
                    value: '$answered',
                    color: AppColors.primary),
                const SizedBox(width: 12),
                _StatChip(
                    label: 'Corrette',
                    value: '$correct',
                    color: const Color(0xFF43A047)),
                const SizedBox(width: 12),
                _StatChip(
                    label: 'Precisione',
                    value: '$pct%',
                    color: const Color(0xFFE65100)),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: total > 0 ? correct / total : 0,
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Color(0xFF43A047)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────── stat chip ─────────────

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────── category card ─────────────

class _CategoryCard extends StatelessWidget {
  final QuizCategory category;
  final int questionCount;
  final int correctCount;
  final int totalAnswered;
  final int highScore;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.questionCount,
    required this.correctCount,
    required this.totalAnswered,
    required this.highScore,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.black.withValues(alpha: 0.03)),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: category.lightColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(category.icon, color: category.color, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    category.subtitle,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textMedium),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _MiniTag(
                        text: '$questionCount domande',
                        color: category.color,
                      ),
                      const SizedBox(width: 6),
                      if (highScore > 0)
                        _MiniTag(
                          text: 'Best: $highScore/10',
                          color: const Color(0xFF43A047),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.play_circle_filled_rounded,
              color: category.color.withValues(alpha: 0.7),
              size: 32,
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  final String text;
  final Color color;
  const _MiniTag({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// QUIZ SESSION SCREEN (10 questions, timer, scoring)
// ═══════════════════════════════════════════════════════════════════

class _QuizSessionScreen extends StatefulWidget {
  final QuizCategory? category; // null = mixed
  const _QuizSessionScreen({required this.category});

  @override
  State<_QuizSessionScreen> createState() => _QuizSessionScreenState();
}

class _QuizSessionScreenState extends State<_QuizSessionScreen>
    with TickerProviderStateMixin {
  late List<QuizQuestion> _questions;
  int _currentIndex = 0;
  int _correctCount = 0;
  int _wrongCount = 0;
  int _skippedCount = 0;
  int? _selectedOption;
  bool _answered = false;
  bool _quizFinished = false;

  // Timer
  late AnimationController _timerController;
  Timer? _autoAdvanceTimer;

  // Answer flash
  late AnimationController _flashController;
  Color _flashColor = Colors.transparent;

  // Track wrong answers for review
  final List<_WrongAnswer> _wrongAnswers = [];

  @override
  void initState() {
    super.initState();
    _prepareQuestions();

    _timerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && !_answered) {
          _handleTimeout();
        }
      });

    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _startTimer();
  }

  void _prepareQuestions() {
    List<QuizQuestion> pool;
    if (widget.category != null) {
      pool = _getQuestionsByCategory(widget.category!);
    } else {
      pool = List.of(_allQuestions);
    }
    pool.shuffle(Random());
    _questions = pool.take(10).toList();
  }

  void _startTimer() {
    _timerController.forward(from: 0);
  }

  void _handleTimeout() {
    if (_answered) return;
    setState(() {
      _answered = true;
      _skippedCount++;
      _flashColor = Colors.orange;
      _wrongAnswers.add(_WrongAnswer(
        question: _questions[_currentIndex],
        userAnswer: 'Tempo scaduto',
      ));
    });
    _flashController.forward(from: 0);
    _autoAdvanceTimer = Timer(const Duration(seconds: 2), _nextQuestion);
  }

  void _selectAnswer(int index) {
    if (_answered) return;
    _timerController.stop();
    final question = _questions[_currentIndex];
    final isCorrect = index == question.correctIndex;

    setState(() {
      _selectedOption = index;
      _answered = true;
      if (isCorrect) {
        _correctCount++;
        _flashColor = const Color(0xFF43A047);
      } else {
        _wrongCount++;
        _flashColor = const Color(0xFFE53935);
        _wrongAnswers.add(_WrongAnswer(
          question: question,
          userAnswer: question.options[index],
        ));
      }
    });
    _flashController.forward(from: 0);
    _autoAdvanceTimer = Timer(const Duration(seconds: 2), _nextQuestion);
  }

  void _nextQuestion() {
    _autoAdvanceTimer?.cancel();
    if (_currentIndex >= _questions.length - 1) {
      _finishQuiz();
      return;
    }
    setState(() {
      _currentIndex++;
      _selectedOption = null;
      _answered = false;
      _flashColor = Colors.transparent;
    });
    _startTimer();
  }

  Future<void> _finishQuiz() async {
    _timerController.stop();
    setState(() => _quizFinished = true);

    // Save stats
    final prefs = await SharedPreferences.getInstance();

    if (widget.category != null) {
      final cat = widget.category!;
      final prevCorrect = prefs.getInt(cat.prefKey) ?? 0;
      final prevTotal = prefs.getInt(cat.totalKey) ?? 0;
      final prevHigh = prefs.getInt(cat.highScoreKey) ?? 0;

      await prefs.setInt(cat.prefKey, prevCorrect + _correctCount);
      await prefs.setInt(cat.totalKey, prevTotal + _questions.length);
      if (_correctCount > prevHigh) {
        await prefs.setInt(cat.highScoreKey, _correctCount);
      }
    } else {
      // Mixed quiz: distribute stats across categories
      for (final q in _questions) {
        final catName = q.category;
        final cat = QuizCategory.values.firstWhere((c) => c.name == catName);
        final prevTotal = prefs.getInt(cat.totalKey) ?? 0;
        await prefs.setInt(cat.totalKey, prevTotal + 1);
      }
      // Count correct per category
      final correctPerCat = <String, int>{};
      for (int i = 0; i < _questions.length; i++) {
        final q = _questions[i];
        final isWrong =
            _wrongAnswers.any((w) => w.question == q);
        if (!isWrong) {
          correctPerCat[q.category] = (correctPerCat[q.category] ?? 0) + 1;
        }
      }
      for (final entry in correctPerCat.entries) {
        final cat =
            QuizCategory.values.firstWhere((c) => c.name == entry.key);
        final prev = prefs.getInt(cat.prefKey) ?? 0;
        await prefs.setInt(cat.prefKey, prev + entry.value);
      }
    }
  }

  @override
  void dispose() {
    _timerController.dispose();
    _flashController.dispose();
    _autoAdvanceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_quizFinished) {
      return _buildResultScreen();
    }
    return _buildQuizScreen();
  }

  // ─────────── QUIZ SCREEN ───────────

  Widget _buildQuizScreen() {
    final question = _questions[_currentIndex];
    final catEnum =
        QuizCategory.values.firstWhere((c) => c.name == question.category);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnimatedBuilder(
        animation: _flashController,
        builder: (context, child) {
          final flashOpacity =
              (1.0 - _flashController.value).clamp(0.0, 0.3);
          return Container(
            color: _flashColor.withValues(alpha: flashOpacity),
            child: child,
          );
        },
        child: SafeArea(
          child: Column(
            children: [
              // top bar
              _buildQuizTopBar(catEnum),
              const SizedBox(height: 8),
              // timer + progress
              _buildTimerRow(),
              const SizedBox(height: 16),
              // question
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _buildQuestionCard(question),
                      const SizedBox(height: 20),
                      ...List.generate(question.options.length, (i) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildOptionButton(question, i),
                        );
                      }),
                      const SizedBox(height: 20),
                      if (_answered)
                        _buildNextButton(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuizTopBar(QuizCategory cat) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _showQuitDialog(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.close_rounded,
                  color: AppColors.textDark, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: cat.lightColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              cat.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: cat.color,
              ),
            ),
          ),
          const Spacer(),
          Text(
            '${_currentIndex + 1}/${_questions.length}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Animated countdown circle
          SizedBox(
            width: 44,
            height: 44,
            child: AnimatedBuilder(
              animation: _timerController,
              builder: (context, child) {
                final remaining =
                    (30 * (1 - _timerController.value)).ceil();
                final progress = 1 - _timerController.value;
                Color timerColor;
                if (progress > 0.5) {
                  timerColor = const Color(0xFF43A047);
                } else if (progress > 0.2) {
                  timerColor = const Color(0xFFFFA000);
                } else {
                  timerColor = const Color(0xFFE53935);
                }
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 4,
                        backgroundColor: Colors.grey.shade200,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(timerColor),
                      ),
                    ),
                    Text(
                      '$remaining',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: timerColor,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(width: 14),
          // Progress bar
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _ScoreIcon(
                        icon: Icons.check_circle,
                        color: const Color(0xFF43A047),
                        count: _correctCount),
                    const SizedBox(width: 12),
                    _ScoreIcon(
                        icon: Icons.cancel,
                        color: const Color(0xFFE53935),
                        count: _wrongCount),
                    const SizedBox(width: 12),
                    _ScoreIcon(
                        icon: Icons.remove_circle,
                        color: Colors.orange,
                        count: _skippedCount),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (_currentIndex + 1) / _questions.length,
                    minHeight: 6,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(QuizQuestion question) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.help_outline_rounded,
                color: AppColors.primary, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            question.question,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionButton(QuizQuestion question, int index) {
    final isSelected = _selectedOption == index;
    final isCorrect = index == question.correctIndex;

    Color bgColor = Colors.white;
    Color borderColor = Colors.black.withValues(alpha: 0.06);
    Color textColor = AppColors.textDark;
    IconData? trailingIcon;

    if (_answered) {
      if (isCorrect) {
        bgColor = const Color(0xFFE8F5E9);
        borderColor = const Color(0xFF43A047);
        textColor = const Color(0xFF2E7D32);
        trailingIcon = Icons.check_circle_rounded;
      } else if (isSelected && !isCorrect) {
        bgColor = const Color(0xFFFFEBEE);
        borderColor = const Color(0xFFE53935);
        textColor = const Color(0xFFC62828);
        trailingIcon = Icons.cancel_rounded;
      }
    } else if (isSelected) {
      bgColor = AppColors.primary.withValues(alpha: 0.08);
      borderColor = AppColors.primary;
    }

    final letters = ['A', 'B', 'C', 'D'];

    return GestureDetector(
      onTap: () => _selectAnswer(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _answered && isCorrect
                    ? const Color(0xFF43A047)
                    : _answered && isSelected && !isCorrect
                        ? const Color(0xFFE53935)
                        : AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  letters[index],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _answered && (isCorrect || (isSelected && !isCorrect))
                        ? Colors.white
                        : AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                question.options[index],
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
            if (trailingIcon != null)
              Icon(
                trailingIcon,
                color: isCorrect
                    ? const Color(0xFF43A047)
                    : const Color(0xFFE53935),
                size: 22,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextButton() {
    final isLast = _currentIndex >= _questions.length - 1;
    return GestureDetector(
      onTap: _nextQuestion,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
        decoration: BoxDecoration(
          gradient: AppColors.buttonGradient,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isLast ? 'Vedi Risultati' : 'Prossima Domanda',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isLast ? Icons.emoji_events_rounded : Icons.arrow_forward_rounded,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showQuitDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Abbandonare il quiz?'),
        content: const Text(
            'Il progresso di questa sessione non verra salvato.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Continua'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Esci', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ─────────── RESULT SCREEN ───────────

  Widget _buildResultScreen() {
    final total = _questions.length;
    final percentage = ((_correctCount / total) * 100).round();
    final passed = _correctCount >= 6;

    String emoji;
    String message;
    Color resultColor;

    if (percentage >= 90) {
      emoji = '\u{1F3C6}'; // trophy
      message = 'Eccellente! Sei prontissimo!';
      resultColor = const Color(0xFFFFD600);
    } else if (percentage >= 70) {
      emoji = '\u{1F44D}'; // thumbs up
      message = 'Bravo! Buon risultato!';
      resultColor = const Color(0xFF43A047);
    } else if (passed) {
      emoji = '\u{2705}'; // check
      message = 'Sufficiente, ma puoi migliorare!';
      resultColor = const Color(0xFFFFA000);
    } else {
      emoji = '\u{1F4DA}'; // books
      message = 'Non sufficiente. Continua a studiare!';
      resultColor = const Color(0xFFE53935);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Result card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      emoji,
                      style: const TextStyle(fontSize: 60),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      passed ? 'SUPERATO!' : 'NON SUPERATO',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: resultColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textMedium,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Score circle
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: resultColor, width: 6),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$_correctCount/$total',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: resultColor,
                              ),
                            ),
                            Text(
                              '$percentage%',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: resultColor.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Breakdown
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _ResultStat(
                            label: 'Corrette',
                            value: '$_correctCount',
                            color: const Color(0xFF43A047)),
                        _ResultStat(
                            label: 'Sbagliate',
                            value: '$_wrongCount',
                            color: const Color(0xFFE53935)),
                        _ResultStat(
                            label: 'Saltate',
                            value: '$_skippedCount',
                            color: Colors.orange),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Wrong answers review
              if (_wrongAnswers.isNotEmpty) ...[
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Risposte da rivedere',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ..._wrongAnswers.map((wa) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _WrongAnswerCard(wrongAnswer: wa),
                    )),
                const SizedBox(height: 12),
              ],

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.primary),
                        ),
                        child: const Center(
                          child: Text(
                            'Torna al Menu',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _currentIndex = 0;
                          _correctCount = 0;
                          _wrongCount = 0;
                          _skippedCount = 0;
                          _selectedOption = null;
                          _answered = false;
                          _quizFinished = false;
                          _wrongAnswers.clear();
                          _prepareQuestions();
                        });
                        _startTimer();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: AppColors.buttonGradient,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Center(
                          child: Text(
                            'Riprova',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────── score icon in quiz bar ─────────────

class _ScoreIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final int count;
  const _ScoreIcon({
    required this.icon,
    required this.color,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 3),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ───────────── result stat ─────────────

class _ResultStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _ResultStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textMedium,
          ),
        ),
      ],
    );
  }
}

// ───────────── wrong answer model + card ─────────────

class _WrongAnswer {
  final QuizQuestion question;
  final String userAnswer;
  const _WrongAnswer({required this.question, required this.userAnswer});
}

class _WrongAnswerCard extends StatelessWidget {
  final _WrongAnswer wrongAnswer;
  const _WrongAnswerCard({required this.wrongAnswer});

  @override
  Widget build(BuildContext context) {
    final q = wrongAnswer.question;
    final correctAnswer = q.options[q.correctIndex];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE53935).withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            q.question,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.cancel_rounded,
                  color: Color(0xFFE53935), size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Tua risposta: ${wrongAnswer.userAnswer}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFE53935),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Color(0xFF43A047), size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Risposta corretta: $correctAnswer',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF43A047),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ───────────── AnimatedBuilder alias (cleaner than AnimatedBuilder) ─────────

// AnimatedBuilder is already available in Flutter as AnimatedBuilder.
// We use it directly above.
