import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
// ignore: depend_on_referenced_packages
import 'package:printing/pdf_google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/di/service_locator.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/models/models.dart';

class StudentCardScreen extends StatefulWidget {
  final int studentId;
  const StudentCardScreen({super.key, required this.studentId});

  @override
  State<StudentCardScreen> createState() => _StudentCardScreenState();
}

class _StudentCardScreenState extends State<StudentCardScreen> {
  final _studentRepo = Locator.instance.studentRepository;
  final _groupRepo = Locator.instance.groupRepository;
  final _gradeRepo = Locator.instance.gradeRepository;
  Student? _student;
  StudyGroup? _group;
  Grade? _grade;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await _studentRepo.getById(widget.studentId);
    if (s == null) return;
    final group = s.groupId != null ? await _groupRepo.getById(s.groupId!) : null;
    final grade = s.gradeId != null ? await _gradeRepo.getById(s.gradeId!) : null;
    setState(() {
      _student = s;
      _group = group;
      _grade = grade;
    });
  }

  String get _qrData => 'STUDENT:${_student?.code}|${_student?.name}|${_student?.phone ?? ''}';

  Future<Uint8List> _buildPdf() async {
    final s = _student!;
    final font = await PdfGoogleFonts.cairoRegular();
    final fontBold = await PdfGoogleFonts.cairoBold();
    final baseStyle = pw.TextStyle(font: font, fontSize: 11);
    final boldStyle = pw.TextStyle(font: fontBold, fontSize: 14, fontWeight: pw.FontWeight.bold);

    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(280, 170, marginAll: 12),
        textDirection: pw.TextDirection.rtl,
        build: (ctx) => pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Container(
            decoration: pw.BoxDecoration(border: pw.Border.all(width: 1.2), borderRadius: pw.BorderRadius.circular(10)),
            padding: const pw.EdgeInsets.all(14),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(
                  width: 80,
                  height: 80,
                  child: pw.BarcodeWidget(barcode: pw.Barcode.qrCode(), data: _qrData),
                ),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(s.name, style: boldStyle),
                      pw.SizedBox(height: 6),
                      pw.Text('كود الطالب: ${s.code}', style: baseStyle),
                      pw.Text('الصف: ${_grade?.name ?? ''}', style: baseStyle),
                      pw.Text('المجموعة: ${_group?.name ?? ''}', style: baseStyle),
                      pw.Text('الهاتف: ${s.phone ?? ''}', style: baseStyle),
                      pw.Text('ولي الأمر: ${s.parentPhone ?? ''}', style: baseStyle),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return doc.save();
  }

  @override
  Widget build(BuildContext context) {
    final s = _student;
    if (s == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text('بطاقة الطالب')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Theme.of(context).dividerColor),
                  color: Theme.of(context).cardColor,
                ),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                              const SizedBox(height: 8),
                              Text('كود الطالب: ${s.code}'),
                              Text('الصف: ${_grade?.name ?? '-'}'),
                              Text('المجموعة: ${_group?.name ?? '-'}'),
                              Text('الهاتف: ${s.phone ?? '-'}'),
                              Text('ولي الأمر: ${s.parentPhone ?? '-'}'),
                            ],
                          ),
                        ),
                        QrImageView(data: _qrData, size: 100),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.print_rounded),
                      label: const Text('طباعة'),
                      onPressed: () async => Printing.layoutPdf(onLayout: (format) => _buildPdf()),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: PrimaryButton(
                      icon: Icons.picture_as_pdf_rounded,
                      label: 'حفظ PDF / مشاركة',
                      onPressed: () async {
                        final bytes = await _buildPdf();
                        await Printing.sharePdf(bytes: bytes, filename: 'بطاقة_${s.name}.pdf');
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
