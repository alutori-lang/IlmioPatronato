import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'moduli_data.dart';

// ---------------------------------------------------------------------------
// Generatore PDF per i moduli compilati
// ---------------------------------------------------------------------------
class PdfGenerator {
  PdfGenerator._();

  /// Genera e condivide il PDF del modulo compilato.
  static Future<void> genera(
    BuildContext context,
    Modulo modulo,
    Map<String, String> dati,
  ) async {
    final pdf = pw.Document();
    final dataOggi = DateFormat('dd/MM/yyyy').format(DateTime.now());

    // Colori
    const bluScuro = PdfColor.fromInt(0xFF0D2D5E);
    const bluPrimario = PdfColor.fromInt(0xFF1565C0);
    const grigio = PdfColor.fromInt(0xFF666666);
    const grigioChiaro = PdfColor.fromInt(0xFFEEEEEE);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader(modulo, dataOggi, bluScuro, bluPrimario),
        footer: (context) => _buildFooter(modulo, context, grigio),
        build: (context) => _buildContent(modulo, dati, bluPrimario, grigio, grigioChiaro),
      ),
    );

    final bytes = await pdf.save();

    if (!context.mounted) return;

    await Printing.sharePdf(
      bytes: bytes,
      filename: '${modulo.id}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  // -------------------------------------------------------------------------
  // Header del PDF
  // -------------------------------------------------------------------------
  static pw.Widget _buildHeader(
    Modulo modulo,
    String dataOggi,
    PdfColor bluScuro,
    PdfColor bluPrimario,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'IL MIO PATRONATO',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: bluScuro,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Il Patronato in Tasca',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: bluPrimario,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'Data: $dataOggi',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 14),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromInt(0xFFE3F2FD),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                modulo.nomeUfficiale,
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: bluScuro,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                modulo.titolo,
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 14),
        pw.Divider(color: PdfColors.grey300, thickness: 0.5),
        pw.SizedBox(height: 6),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Contenuto principale: sezioni per ogni step
  // -------------------------------------------------------------------------
  static List<pw.Widget> _buildContent(
    Modulo modulo,
    Map<String, String> dati,
    PdfColor bluPrimario,
    PdfColor grigio,
    PdfColor grigioChiaro,
  ) {
    final widgets = <pw.Widget>[];

    for (final step in modulo.steps) {
      // Titolo della sezione
      widgets.add(
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 10),
          margin: const pw.EdgeInsets.only(bottom: 8),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromInt(0xFFF5F5F5),
            borderRadius: pw.BorderRadius.circular(3),
            border: pw.Border(
              left: pw.BorderSide(color: bluPrimario, width: 3),
            ),
          ),
          child: pw.Text(
            step.titolo,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: bluPrimario,
            ),
          ),
        ),
      );

      // Campi compilati (tabella 2 colonne)
      final rows = <pw.TableRow>[];
      for (final campo in step.campi) {
        final valore = dati[campo.id]?.trim() ?? '';
        if (valore.isEmpty) continue;

        rows.add(
          pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                child: pw.Text(
                  campo.etichetta,
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: grigio,
                  ),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                child: pw.Text(
                  valore,
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
            ],
          ),
        );
      }

      if (rows.isNotEmpty) {
        widgets.add(
          pw.Table(
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(3),
            },
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            children: rows,
          ),
        );
      }

      widgets.add(pw.SizedBox(height: 14));
    }

    return widgets;
  }

  // -------------------------------------------------------------------------
  // Footer del PDF con note
  // -------------------------------------------------------------------------
  static pw.Widget _buildFooter(
    Modulo modulo,
    pw.Context context,
    PdfColor grigio,
  ) {
    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey300, thickness: 0.5),
        pw.SizedBox(height: 4),
        if (modulo.note.isNotEmpty)
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFFFF8E1),
              borderRadius: pw.BorderRadius.circular(3),
              border: pw.Border.all(color: PdfColor.fromInt(0xFFFFCC80), width: 0.5),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'NOTA: ',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromInt(0xFFE65100),
                  ),
                ),
                pw.Expanded(
                  child: pw.Text(
                    modulo.note,
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800),
                  ),
                ),
              ],
            ),
          ),
        pw.SizedBox(height: 6),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Generato da Il Mio Patronato',
              style: pw.TextStyle(
                fontSize: 7,
                color: grigio,
                fontStyle: pw.FontStyle.italic,
              ),
            ),
            pw.Text(
              'Pagina ${context.pageNumber} di ${context.pagesCount}',
              style: pw.TextStyle(fontSize: 7, color: grigio),
            ),
          ],
        ),
      ],
    );
  }
}
