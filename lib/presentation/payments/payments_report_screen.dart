import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
// ignore: depend_on_referenced_packages
import 'package:printing/pdf_google_fonts.dart';
import '../../data/repositories/payment_repository.dart';
import '../../data/repositories/student_repository.dart';
import '../../data/models/models.dart';
import '../../core/di/service_locator.dart';

class PaymentsReportScreen extends StatefulWidget {
  const PaymentsReportScreen({super.key});

  @override
  State<PaymentsReportScreen> createState() => _PaymentsReportScreenState();
}

class _PaymentsReportScreenState extends State<PaymentsReportScreen> {
  final _payRepo = Locator.instance.paymentRepository;
  final _stuRepo = Locator.instance.studentRepository;

  double _today = 0, _week = 0, _month = 0, _year = 0;
  List<Student> _lateStudents = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final now = DateTime.now();
    final todayStr = now.toIso8601String().substring(0, 10);
    final weekStart = now.subtract(Duration(days: now.weekday - 1)).toIso8601String().substring(0, 10);
    final monthStart = '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
    final yearStart = '${now.year}-01-01';

    final allStudents = await _stuRepo.getAll();
    final allPayments = await _payRepo.getAll();

    double sumToday = 0, sumWeek = 0, sumMonth = 0, sumYear = 0;
    for (final p in allPayments) {
      final d = p.paidAt.toIso8601String().substring(0, 10);
      if (d == todayStr) sumToday += p.amount;
      if (d >= weekStart) sumWeek += p.amount;
      if (d >= monthStart) sumMonth += p.amount;
      if (d >= yearStart) sumYear += p.amount;
    }

    // الطلاب المتأخرون: مش دفعوا هذا الشهر
    final paidThisMonth = allPayments
        .where((p) => p.paidAt.toIso8601String().substring(0, 10) >= monthStart)
        .map((p) => p.studentId)
        .toSet();
    final late = allStudents.where((s) => s.isActive && !paidThisMonth.contains(s.id)).toList();

    if (mounted) {
      setState(() {
        _today = sumToday;
        _week = sumWeek;
        _month = sumMonth;
        _year = sumYear;
        _lateStudents = late;
        _loading = false;
      });
    }
  }

  Future<void> _exportPdf() async {
    final font = await PdfGoogleFonts.cairoRegular();
    final fontBold = await PdfGoogleFonts.cairoBold();

    final doc = pw.Document();
    final baseStyle = pw.TextStyle(font: font, fontSize: 11);
    final boldStyle = pw.TextStyle(font: fontBold, fontSize: 13, fontWeight: pw.FontWeight.bold);
    final titleStyle = pw.TextStyle(font: fontBold, fontSize: 18, fontWeight: pw.FontWeight.bold);

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        build: (ctx) => pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Padding(
            padding: const pw.EdgeInsets.all(28),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('تقرير المدفوعات', style: titleStyle),
                pw.SizedBox(height: 8),
                pw.Text(
                  'تاريخ التقرير: ${DateTime.now().toIso8601String().substring(0, 10)}',
                  style: baseStyle,
                ),
                pw.Divider(height: 24),
                // ملخص
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    _pdfStatCard(font, fontBold, 'اليوم', '${_today.toStringAsFixed(0)} ج.م'),
                    _pdfStatCard(font, fontBold, 'الأسبوع', '${_week.toStringAsFixed(0)} ج.م'),
                    _pdfStatCard(font, fontBold, 'الشهر', '${_month.toStringAsFixed(0)} ج.م'),
                    _pdfStatCard(font, fontBold, 'العام', '${_year.toStringAsFixed(0)} ج.م'),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'الطلاب المتأخرون في الدفع هذا الشهر (${_lateStudents.length})',
                  style: boldStyle,
                ),
                pw.SizedBox(height: 8),
                if (_lateStudents.isEmpty)
                  pw.Text('لا يوجد طلاب متأخرون', style: baseStyle)
                else
                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey400),
                    children: [
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(color: PdfColors.indigo100),
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text('الكود', style: boldStyle.copyWith(fontSize: 11)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text('الاسم', style: boldStyle.copyWith(fontSize: 11)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text('الهاتف', style: boldStyle.copyWith(fontSize: 11)),
                          ),
                        ],
                      ),
                      ..._lateStudents.map((s) => pw.TableRow(
                        children: [
                          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(s.code, style: baseStyle)),
                          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(s.name, style: baseStyle)),
                          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(s.phone ?? '', style: baseStyle)),
                        ],
                      )),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => doc.save());
  }

  pw.Widget _pdfStatCard(pw.Font font, pw.Font bold, String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.indigo200),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        children: [
          pw.Text(value, style: pw.TextStyle(font: bold, fontSize: 14)),
          pw.SizedBox(height: 4),
          pw.Text(label, style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey600)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('المدفوعات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            tooltip: 'تصدير PDF',
            onPressed: _loading ? null : _exportPdf,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Summary cards
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [
                      _statCard(context, 'مبيعات اليوم', '${_today.toStringAsFixed(0)} ج.م', Icons.today_rounded, Colors.blue),
                      _statCard(context, 'مبيعات الأسبوع', '${_week.toStringAsFixed(0)} ج.م', Icons.date_range_rounded, Colors.green),
                      _statCard(context, 'مبيعات الشهر', '${_month.toStringAsFixed(0)} ج.م', Icons.calendar_month_rounded, Colors.orange),
                      _statCard(context, 'مبيعات العام', '${_year.toStringAsFixed(0)} ج.م', Icons.calendar_today_rounded, Colors.purple),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Text(
                        'متأخرون في الدفع (${_lateStudents.length})',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: _exportPdf,
                        icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                        label: const Text('تصدير PDF'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_lateStudents.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('لا يوجد طلاب متأخرون', style: TextStyle(color: Colors.grey)),
                      ),
                    )
                  else
                    ..._lateStudents.map((s) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.red.withOpacity(0.1),
                          child: Text(s.code, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.red)),
                        ),
                        title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(s.phone ?? ''),
                        trailing: const Icon(Icons.warning_rounded, color: Colors.red, size: 18),
                      ),
                    )),
                ],
              ),
            ),
    );
  }

  Widget _statCard(BuildContext context, String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
