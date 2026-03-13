import 'package:flutter/material.dart';

class GuidaStep {
  final String title;
  final String description;
  final String? link;
  bool isCompleted;

  GuidaStep({
    required this.title,
    required this.description,
    this.link,
    this.isCompleted = false,
  });
}

class GuidaDocument {
  final String name;
  bool isChecked;

  GuidaDocument({required this.name, this.isChecked = false});
}

class Guida {
  final int id;
  final String title;
  final String shortDescription;
  final IconData icon;
  final Color color;
  final String category;
  final String tempiStimati;
  final String costoStimato;
  final List<GuidaDocument> documenti;
  final List<GuidaStep> steps;
  final List<String> linkUtili;

  Guida({
    required this.id,
    required this.title,
    required this.shortDescription,
    required this.icon,
    required this.color,
    required this.category,
    required this.tempiStimati,
    required this.costoStimato,
    required this.documenti,
    required this.steps,
    this.linkUtili = const [],
  });
}
