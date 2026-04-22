import 'dart:convert';

class ScannedDocument {
  final String id;
  final String name;
  final String pdfPath;
  final String thumbPath;
  final int pageCount;
  final DateTime createdAt;

  ScannedDocument({
    required this.id,
    required this.name,
    required this.pdfPath,
    required this.thumbPath,
    required this.pageCount,
    required this.createdAt,
  });

  ScannedDocument copyWith({String? name}) => ScannedDocument(
        id: id,
        name: name ?? this.name,
        pdfPath: pdfPath,
        thumbPath: thumbPath,
        pageCount: pageCount,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'pdfPath': pdfPath,
        'thumbPath': thumbPath,
        'pageCount': pageCount,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ScannedDocument.fromJson(Map<String, dynamic> j) => ScannedDocument(
        id: j['id'] as String,
        name: j['name'] as String,
        pdfPath: j['pdfPath'] as String,
        thumbPath: j['thumbPath'] as String,
        pageCount: j['pageCount'] as int,
        createdAt: DateTime.parse(j['createdAt'] as String),
      );

  static String encodeList(List<ScannedDocument> docs) =>
      jsonEncode(docs.map((d) => d.toJson()).toList());

  static List<ScannedDocument> decodeList(String s) => (jsonDecode(s) as List)
      .map((e) => ScannedDocument.fromJson(e as Map<String, dynamic>))
      .toList();
}
