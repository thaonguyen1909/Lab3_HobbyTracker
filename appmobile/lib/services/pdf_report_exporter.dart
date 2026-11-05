import '../l10n/app_strings.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/hobby_data.dart';
import 'device_services.dart';

class PdfReportExporter implements ReportExporter {
  PdfReportExporter({this.languageCode = 'en'});
  final String languageCode;
  String t(String value) => AppStrings(languageCode).text(value);
  @override
  Future<Uint8List> export(
    List<Hobby> hobbies,
    List<PracticeRecord> history,
  ) async {
    final font = pw.Font.ttf(
      await rootBundle.load('assets/fonts/DejaVuSans.ttf'),
    );
    final doc = pw.Document();
    final total = history.fold<int>(0, (sum, r) => sum + r.elapsedMs);
    doc.addPage(
      pw.MultiPage(
        maxPages: 1000,
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: font, bold: font),
        build: (_) => [
          pw.Header(
            level: 0,
            child: pw.Text(t('Hobby Tracker — Báo cáo hoạt động')),
          ),
          pw.Text(t('Tạo lúc: ${DateTime.now().toLocal().toIso8601String()}')),
          pw.Text(
            t(
              '${hobbies.length} sở thích • ${history.length} phiên • ${(total / 60000).toStringAsFixed(1)} phút luyện tập',
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Text(t('Sở thích hiện tại')),
          if (hobbies.isEmpty) pw.Text(t('Chưa có sở thích.')),
          for (final h in hobbies)
            pw.Text(
              '${h.name} — ${t(h.priority == 'active' ? 'Active' : 'Interested')}',
            ),
          pw.SizedBox(height: 16),
          pw.Text(t('Lịch sử luyện tập')),
          if (history.isEmpty) pw.Text(t('Chưa có phiên luyện tập.')),
          for (final r in history)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 12),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    t(
                      '${r.name} — ${(r.elapsedMs / 60000).toStringAsFixed(1)} phút — ${r.finishedAt.toLocal().toIso8601String().substring(0, 16)}',
                    ),
                  ),
                  if (r.notes.isNotEmpty) pw.Text(r.notes),
                ],
              ),
            ),
        ],
      ),
    );
    return doc.save();
  }
}
