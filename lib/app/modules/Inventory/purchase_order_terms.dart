import 'package:billkaro/config/config.dart';
import 'package:pdf/widgets.dart' as pw;

final _lineNumberPrefix = RegExp(r'^\s*\d+[\.\)\:\-]\s*');
final _inlineClauseStart = RegExp(r'(?:^|\s)(\d{1,2})[\.\)]\s+');

/// Splits stored PO terms into numbered points.
/// Supports one point per line, or inline numbering like "1. ... 2. ..." in one block.
List<String> parsePoTermsLines(String raw) {
  final text = raw.trim();
  if (text.isEmpty) return [];

  final matches = _inlineClauseStart.allMatches(text).toList();
  if (matches.length >= 2) {
    return _splitByNumberedMatches(text, matches);
  }
  if (matches.length == 1 &&
      text.substring(0, matches.first.start).trim().isEmpty) {
    final body = text.substring(matches.first.end).trim();
    return body.isEmpty ? [] : [_normalizeClause(body)];
  }

  return text
      .split(RegExp(r'\r?\n'))
      .map((line) => line.trim().replaceFirst(_lineNumberPrefix, '').trim())
      .where((line) => line.isNotEmpty)
      .map(_normalizeClause)
      .toList();
}

List<String> _splitByNumberedMatches(String text, List<RegExpMatch> matches) {
  final result = <String>[];
  for (var i = 0; i < matches.length; i++) {
    final start = matches[i].end;
    final end = i + 1 < matches.length ? matches[i + 1].start : text.length;
    final clause = text.substring(start, end).trim();
    if (clause.isNotEmpty) result.add(_normalizeClause(clause));
  }
  return result;
}

String _normalizeClause(String value) =>
    value.replaceAll(RegExp(r'\s+'), ' ').trim();

Widget buildPoDocumentFooter(String registeredOffice) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 12),
      Text(
        'This is a system generated document. Does not require any signature.',
        style: TextStyle(
          fontSize: 10,
          fontStyle: FontStyle.italic,
          color: Colors.grey.shade600,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        'Registered Office Address: $registeredOffice',
        style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
      ),
    ],
  );
}

Widget buildPoDocumentPageBreak({required int pageNumber}) {
  return Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 4),
    child: Column(
      children: [
        Container(height: 1, color: Colors.grey.shade400),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            'Page $pageNumber',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          ),
        ),
        const SizedBox(height: 12),
      ],
    ),
  );
}

Widget buildPoTermsDocumentPage({
  required AppLocalizations loc,
  required String termsText,
  required String orderNumber,
  required Widget headerLogo,
  required String registeredOffice,
  int pageNumber = 2,
  double headingSize = 11,
  double bodySize = 10,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      buildPoDocumentPageBreak(pageNumber: pageNumber),
      Container(
        padding: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(width: 140, child: headerLogo),
            Expanded(
              child: Text(
                'Purchase Order : $orderNumber',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 140),
          ],
        ),
      ),
      const SizedBox(height: 14),
      buildPoTermsSection(
        loc: loc,
        termsText: termsText,
        headingSize: headingSize,
        bodySize: bodySize,
      ),
      buildPoDocumentFooter(registeredOffice),
    ],
  );
}

Widget buildPoTermsSection({
  required AppLocalizations loc,
  required String termsText,
  double headingSize = 11,
  double bodySize = 10,
  Color? bodyColor,
}) {
  final lines = parsePoTermsLines(termsText);
  if (lines.isEmpty) return const SizedBox.shrink();

  final textColor = bodyColor ?? Colors.grey.shade800;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: headingSize,
            color: textColor,
            height: 1.4,
          ),
          children: [
            TextSpan(
              text: loc.po_terms_heading,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: ' ${loc.po_terms_intro}'),
          ],
        ),
      ),
      const SizedBox(height: 8),
      ...lines.asMap().entries.map((entry) {
        final index = entry.key + 1;
        final line = entry.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 22,
                child: Text(
                  '$index.',
                  style: TextStyle(
                    fontSize: bodySize,
                    color: textColor,
                    height: 1.45,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  line,
                  style: TextStyle(
                    fontSize: bodySize,
                    color: textColor,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    ],
  );
}

List<pw.Widget> buildPoTermsPdfSection({
  required String heading,
  required String intro,
  required String termsText,
  required pw.TextStyle bodyStyle,
  required pw.TextStyle headingStyle,
  bool startOnNewPage = true,
}) {
  final lines = parsePoTermsLines(termsText);
  if (lines.isEmpty) return const [];

  return [
    if (startOnNewPage) pw.NewPage(),
    pw.RichText(
      text: pw.TextSpan(
        style: bodyStyle,
        children: [
          pw.TextSpan(text: heading, style: headingStyle),
          pw.TextSpan(text: ' $intro'),
        ],
      ),
    ),
    pw.SizedBox(height: 6),
    ...lines.asMap().entries.map((entry) {
      final index = entry.key + 1;
      final line = entry.value;
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 3),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(width: 16, child: pw.Text('$index.', style: bodyStyle)),
            pw.Expanded(child: pw.Text(line, style: bodyStyle)),
          ],
        ),
      );
    }),
  ];
}
