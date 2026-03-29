import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/constants.dart';

/// Widget che renderizza i messaggi AI in modo bello e moderno.
/// Pulisce TUTTI gli asterischi, rende i link cliccabili,
/// mostra liste con card colorate, header con gradiente.
class RichMessageWidget extends StatelessWidget {
  final String text;
  const RichMessageWidget({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final blocks = _parseBlocks(text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: blocks,
    );
  }

  List<Widget> _parseBlocks(String raw) {
    final widgets = <Widget>[];
    final lines = raw.split('\n');
    final buffer = <String>[];
    // Raccoglie bullet consecutivi per metterli in una card unica
    final bulletBuffer = <String>[];
    int bulletStartType = 0; // 0=none, 1=dash/bullet, 2=numbered

    void flushText() {
      if (buffer.isNotEmpty) {
        final joined = buffer.join('\n').trim();
        if (joined.isNotEmpty) {
          widgets.add(_buildTextBlock(joined));
        }
        buffer.clear();
      }
    }

    void flushBullets() {
      if (bulletBuffer.isNotEmpty) {
        if (bulletStartType == 2) {
          widgets.add(_buildNumberedListCard(List.from(bulletBuffer)));
        } else {
          widgets.add(_buildBulletListCard(List.from(bulletBuffer)));
        }
        bulletBuffer.clear();
        bulletStartType = 0;
      }
    }

    for (final line in lines) {
      final trimmed = line.trim();

      // Riga vuota
      if (trimmed.isEmpty) {
        flushText();
        flushBullets();
        continue;
      }

      // Link standalone
      final link = _extractStandaloneLink(trimmed);
      if (link != null) {
        flushText();
        flushBullets();
        widgets.add(_buildLinkCard(link['label']!, link['url']!));
        continue;
      }

      // Header di sezione
      final header = _extractSectionHeader(trimmed);
      if (header != null) {
        flushText();
        flushBullets();
        widgets.add(_buildSectionHeader(header));
        continue;
      }

      // Lista numerata (1. qualcosa)
      final numbered = RegExp(r'^(\d+)[.)]\s+(.+)$').firstMatch(trimmed);
      if (numbered != null) {
        flushText();
        if (bulletStartType != 2 && bulletBuffer.isNotEmpty) flushBullets();
        bulletStartType = 2;
        bulletBuffer.add(numbered.group(2)!);
        continue;
      }

      // Bullet point (- qualcosa, • qualcosa, + qualcosa) → trattati come lista numerata
      if (trimmed.startsWith('- ') || trimmed.startsWith('• ') || trimmed.startsWith('+ ')) {
        flushText();
        if (bulletStartType != 2 && bulletBuffer.isNotEmpty) flushBullets();
        bulletStartType = 2;
        bulletBuffer.add(trimmed.substring(2));
        continue;
      }

      // Testo normale
      flushBullets();
      buffer.add(line);
    }

    flushText();
    flushBullets();
    return widgets;
  }

  // ── Link detection ──

  Map<String, String>? _extractStandaloneLink(String line) {
    // [testo](url)
    final mdLink = RegExp(r'^\[([^\]]+)\]\((https?://[^\)]+)\)$');
    final m = mdLink.firstMatch(line);
    if (m != null) return {'label': _cleanText(m.group(1)!), 'url': m.group(2)!};

    // URL nudo (anche con testo prima tipo "Sito: https://...")
    final urlInLine = RegExp(r'(https?://\S+)');
    final u = urlInLine.firstMatch(line);
    if (u != null) {
      final url = u.group(1)!;
      // Se la riga è SOLO il URL
      if (line.trim() == url) {
        return {'label': _prettyDomain(url), 'url': url};
      }
      // Se c'è testo + URL nella stessa riga
      final label = line.replaceAll(url, '').replaceAll(RegExp(r'[:\-–—]\s*$'), '').trim();
      if (label.isNotEmpty) {
        return {'label': _cleanText(label), 'url': url};
      }
      return {'label': _prettyDomain(url), 'url': url};
    }

    return null;
  }

  String? _extractSectionHeader(String line) {
    if (line.startsWith('### ')) return _cleanText(line.substring(4));
    if (line.startsWith('## ')) return _cleanText(line.substring(3));

    // **Header:** oppure **Header**
    final boldHeader = RegExp(r'^\*\*([^*]+)\*\*:?\s*$');
    final m = boldHeader.firstMatch(line);
    if (m != null) return _cleanText(m.group(1)!);

    return null;
  }

  // ── Builders ──

  /// Card per link cliccabile — bella con gradiente
  Widget _buildLinkCard(String label, String url) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openUrl(url),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.open_in_new_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _prettyDomain(url),
                    style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.7)),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                ]),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.white.withValues(alpha: 0.7)),
            ]),
          ),
        ),
      ),
    );
  }

  /// Header di sezione con gradiente e icona
  Widget _buildSectionHeader(String title) {
    final icon = _getIconForTitle(title);
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.1),
              AppColors.primary.withValues(alpha: 0.03),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(color: AppColors.primary, width: 3.5),
          ),
        ),
        child: Row(children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _cleanText(title),
              style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w800,
                color: AppColors.textDark, letterSpacing: -0.2,
              ),
            ),
          ),
        ]),
      ),
    );
  }

  /// Card con lista numerata — passi con badge colorati
  Widget _buildNumberedListCard(List<String> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE8EEF5), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: List.generate(items.length, (i) {
            final isLast = i == items.length - 1;
            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getStepColor(i),
                        _getStepColor(i).withValues(alpha: 0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: [
                      BoxShadow(
                        color: _getStepColor(i).withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: RichText(text: _buildRichSpan(_cleanText(items[i]))),
                  ),
                ),
              ]),
            );
          }),
        ),
      ),
    );
  }

  /// Card con bullet list — pallini colorati
  Widget _buildBulletListCard(List<String> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE8EEF5), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: List.generate(items.length, (i) {
            final isLast = i == items.length - 1;
            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 8, height: 8,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: BoxDecoration(
                    color: _getStepColor(i),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: RichText(text: _buildRichSpan(_cleanText(items[i]))),
                ),
              ]),
            );
          }),
        ),
      ),
    );
  }

  /// Blocco di testo con rich formatting
  Widget _buildTextBlock(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(text: _buildRichSpan(_cleanText(text))),
    );
  }

  /// Costruisce un TextSpan ricco — grassetto e link inline
  TextSpan _buildRichSpan(String text) {
    final spans = <InlineSpan>[];
    // Regex: **bold**, [label](url), URL nudo
    final regex = RegExp(
      r'\*\*([^*]+)\*\*'
      r'|\[([^\]]+)\]\((https?://[^\)]+)\)'
      r'|(https?://\S+)'
    );

    int lastEnd = 0;
    for (final match in regex.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: _normalStyle,
        ));
      }

      if (match.group(1) != null) {
        spans.add(TextSpan(
          text: match.group(1),
          style: _boldStyle,
        ));
      } else if (match.group(2) != null && match.group(3) != null) {
        final url = match.group(3)!;
        spans.add(TextSpan(
          text: match.group(2),
          style: _linkStyle,
          recognizer: TapGestureRecognizer()..onTap = () => _openUrl(url),
        ));
      } else if (match.group(4) != null) {
        final url = match.group(4)!;
        spans.add(TextSpan(
          text: _prettyDomain(url),
          style: _linkStyle,
          recognizer: TapGestureRecognizer()..onTap = () => _openUrl(url),
        ));
      }
      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd), style: _normalStyle));
    }

    if (spans.isEmpty) {
      return TextSpan(text: text, style: _normalStyle);
    }
    return TextSpan(children: spans);
  }

  // ── Styles ──

  static const _normalStyle = TextStyle(
    fontSize: 14, color: AppColors.textDark, height: 1.55,
    fontWeight: FontWeight.w400,
  );

  static const _boldStyle = TextStyle(
    fontSize: 14, color: AppColors.textDark, height: 1.55,
    fontWeight: FontWeight.w700,
  );

  static const _linkStyle = TextStyle(
    fontSize: 14, color: AppColors.primary, height: 1.55,
    fontWeight: FontWeight.w600,
    decoration: TextDecoration.underline,
    decorationColor: AppColors.primary,
  );

  // ── Helpers ──

  /// Pulisce il testo da asterischi residui e artefatti markdown
  static String _cleanText(String text) {
    return text
        // Rimuovi asterischi singoli residui (non coppie)
        .replaceAll(RegExp(r'(?<!\*)\*(?!\*)'), '')
        // Rimuovi triple+ asterischi
        .replaceAll(RegExp(r'\*{3,}'), '')
        // Pulisci spazi multipli
        .replaceAll(RegExp(r'  +'), ' ')
        .trim();
  }

  /// Colori diversi per ogni step — progressione visiva
  static Color _getStepColor(int index) {
    const colors = [
      Color(0xFF1565C0), // blu
      Color(0xFF2E7D32), // verde
      Color(0xFFE65100), // arancione
      Color(0xFF6A1B9A), // viola
      Color(0xFF00838F), // teal
      Color(0xFFC62828), // rosso
      Color(0xFF4527A0), // indaco
      Color(0xFF2E7D32), // verde scuro
    ];
    return colors[index % colors.length];
  }

  /// Icona automatica basata sul titolo della sezione
  static IconData _getIconForTitle(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('requisit')) return Icons.checklist_rounded;
    if (lower.contains('come') || lower.contains('procedur') || lower.contains('fare')) return Icons.route_rounded;
    if (lower.contains('document')) return Icons.description_rounded;
    if (lower.contains('link') || lower.contains('sito') || lower.contains('dove')) return Icons.link_rounded;
    if (lower.contains('import') || lower.contains('cifr') || lower.contains('€')) return Icons.euro_rounded;
    if (lower.contains('scaden') || lower.contains('quando') || lower.contains('temp')) return Icons.schedule_rounded;
    if (lower.contains('attenz') || lower.contains('nota') || lower.contains('avvis')) return Icons.warning_amber_rounded;
    if (lower.contains('consig') || lower.contains('suggerim')) return Icons.lightbulb_outline_rounded;
    if (lower.contains('bonus') || lower.contains('agevolaz')) return Icons.card_giftcard_rounded;
    if (lower.contains('contatt') || lower.contains('telefon')) return Icons.phone_rounded;
    return Icons.bookmark_rounded;
  }

  /// Dominio leggibile da URL
  static String _prettyDomain(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host.replaceFirst(RegExp(r'^www\.'), '');
    } catch (_) {
      return url.replaceFirst(RegExp(r'^https?://'), '').replaceFirst(RegExp(r'^www\.'), '');
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
