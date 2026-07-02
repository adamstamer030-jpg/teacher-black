import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/constants/app_constants.dart';
import '../../core/di/service_locator.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/models/models.dart';
import 'reservation_form_screen.dart';

class ReservationsScreen extends StatefulWidget {
  const ReservationsScreen({super.key});

  @override
  State<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends State<ReservationsScreen> {
  final _repo = Locator.instance.reservationRepository;
  final _gradeRepo = Locator.instance.gradeRepository;
  List<Reservation> _reservations = [];
  Map<int, String> _gradeNames = {};
  String? _statusFilter;
  String _search = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final grades = await _gradeRepo.getAll();
    _gradeNames = {for (final g in grades) g.id!: g.name};
    final list = await _repo.getAll(status: _statusFilter, search: _search);
    setState(() {
      _reservations = list;
      _loading = false;
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'جديد':
        return Colors.blue;
      case 'تم التواصل':
        return Colors.orange;
      case 'تم التسجيل':
        return Colors.green;
      default:
        return Colors.red;
    }
  }

  Future<void> _exportPdf() async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        build: (ctx) => [
          pw.Text('تقرير الحجوزات', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 16),
          pw.Table.fromTextArray(
            headers: ['الاسم', 'الهاتف', 'الصف', 'النظام', 'الحالة'],
            data: _reservations
                .map((r) => [
                      r.studentName,
                      r.phone ?? '-',
                      _gradeNames[r.gradeId] ?? '-',
                      r.studySystem ?? '-',
                      r.status,
                    ])
                .toList(),
          ),
        ],
      ),
    );
    await Printing.sharePdf(bytes: await doc.save(), filename: 'تقرير_الحجوزات.pdf');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الحجوزات'),
        actions: [IconButton(icon: const Icon(Icons.picture_as_pdf_rounded), onPressed: _exportPdf)],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final added = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const ReservationFormScreen()));
          if (added == true) _load();
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(hintText: 'بحث بالاسم أو الهاتف...', prefixIcon: Icon(Icons.search_rounded)),
              onChanged: (v) {
                _search = v;
                _load();
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: ChoiceChip(label: const Text('الكل'), selected: _statusFilter == null, onSelected: (_) { setState(() => _statusFilter = null); _load(); }),
                  ),
                  ...AppConstants.reservationStatuses.map((s) => Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: ChoiceChip(label: Text(s), selected: _statusFilter == s, onSelected: (_) { setState(() => _statusFilter = s); _load(); }),
                      )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _reservations.isEmpty
                    ? const EmptyState(message: 'لا توجد حجوزات بعد', icon: Icons.calendar_month_rounded)
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: _reservations.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (ctx, i) {
                          final r = _reservations[i];
                          final color = _statusColor(r.status);
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(backgroundColor: color.withOpacity(0.12), child: Icon(Icons.event_note_rounded, color: color)),
                              title: Text(r.studentName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('${_gradeNames[r.gradeId] ?? ''} • ${r.studySystem ?? ''}'),
                              trailing: PopupMenuButton<String>(
                                onSelected: (status) async {
                                  await _repo.updateStatus(r.id!, status);
                                  _load();
                                },
                                itemBuilder: (ctx) => AppConstants.reservationStatuses
                                    .map((s) => PopupMenuItem(value: s, child: Text(s)))
                                    .toList(),
                                child: StatusBadge(label: r.status, color: color),
                              ),
                              onTap: () async {
                                final updated = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => ReservationFormScreen(reservation: r)));
                                if (updated == true) _load();
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
