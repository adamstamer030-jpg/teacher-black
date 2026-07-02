import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/di/service_locator.dart';
import '../../core/utils/helpers.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/models/models.dart';
import '../payments/payment_form_screen.dart';
import 'student_card_screen.dart';
import 'student_form_screen.dart';

class StudentDetailScreen extends StatefulWidget {
  final int studentId;
  const StudentDetailScreen({super.key, required this.studentId});

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  final _studentRepo = Locator.instance.studentRepository;
  final _groupRepo = Locator.instance.groupRepository;
  final _gradeRepo = Locator.instance.gradeRepository;
  final _paymentRepo = Locator.instance.paymentRepository;
  final _attendanceRepo = Locator.instance.attendanceRepository;
  final _examRepo = Locator.instance.examRepository;

  Student? _student;
  StudyGroup? _group;
  Grade? _grade;
  double _totalPaid = 0;
  double _remaining = 0;
  double _attendancePct = 0;
  int _absenceCount = 0;
  Map<String, double> _scoreStats = {'avg': 0, 'max': 0, 'min': 0};
  List<Payment> _payments = [];
  List<AttendanceRecord> _attendanceHistory = [];
  List<ExamResult> _examResults = [];
  List<StudentExtraFee> _extraFees = [];
  List<StudentNote> _notes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final student = await _studentRepo.getById(widget.studentId);
    if (student == null) {
      setState(() => _loading = false);
      return;
    }
    final group = student.groupId != null ? await _groupRepo.getById(student.groupId!) : null;
    final grade = student.gradeId != null ? await _gradeRepo.getById(student.gradeId!) : null;
    final totalPaid = await _paymentRepo.totalPaidForStudent(student.id!);
    final remaining = await _paymentRepo.totalRemainingForStudent(student.id!);
    final attendancePct = await _attendanceRepo.attendancePercentage(student.id!);
    final absences = await _attendanceRepo.absenceCount(student.id!);
    final scoreStats = await _examRepo.studentScoreStats(student.id!);
    final payments = await _paymentRepo.getForStudent(student.id!);
    final attendanceHistory = await _attendanceRepo.getHistoryForStudent(student.id!);
    final examResults = await _examRepo.getResultsForStudent(student.id!);
    final extraFees = await _paymentRepo.getStudentExtraFees(student.id!);
    final notes = await _studentRepo.getNotes(student.id!);

    setState(() {
      _student = student;
      _group = group;
      _grade = grade;
      _totalPaid = totalPaid;
      _remaining = remaining;
      _attendancePct = attendancePct;
      _absenceCount = absences;
      _scoreStats = scoreStats;
      _payments = payments;
      _attendanceHistory = attendanceHistory;
      _examResults = examResults;
      _extraFees = extraFees;
      _notes = notes;
      _loading = false;
    });
  }

  Future<void> _changeStatus() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppConstants.studentStatuses
              .map((s) => ListTile(title: Text(s), onTap: () => Navigator.pop(ctx, s)))
              .toList(),
        ),
      ),
    );
    if (selected != null) {
      await _studentRepo.setStatus(widget.studentId, selected);
      _load();
    }
  }

  Future<void> _transfer() async {
    final grades = await _gradeRepo.getAll();
    int? newGradeId = _student?.gradeId;
    int? newGroupId;
    List<StudyGroup> groups = newGradeId != null ? await _groupRepo.getByGrade(newGradeId) : [];

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
        child: StatefulBuilder(
          builder: (ctx, setSheetState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('نقل الطالب', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              AppDropdown<int>(
                label: 'الصف الدراسي الجديد',
                value: newGradeId,
                items: grades.map((g) => DropdownMenuItem(value: g.id, child: Text(g.name))).toList(),
                onChanged: (v) async {
                  final newGroups = v != null ? await _groupRepo.getByGrade(v) : <StudyGroup>[];
                  setSheetState(() {
                    newGradeId = v;
                    groups = newGroups;
                    newGroupId = null;
                  });
                },
              ),
              const SizedBox(height: 12),
              AppDropdown<int>(
                label: 'المجموعة الجديدة',
                value: newGroupId,
                items: groups.map((g) => DropdownMenuItem(value: g.id, child: Text(g.name))).toList(),
                onChanged: (v) => setSheetState(() => newGroupId = v),
              ),
              const SizedBox(height: 20),
              PrimaryButton(label: 'تأكيد النقل', onPressed: () => Navigator.pop(ctx, true)),
            ],
          ),
        ),
      ),
    );

    if (result == true) {
      await _studentRepo.transfer(widget.studentId, newGradeId: newGradeId, newGroupId: newGroupId);
      showAppSnackBar(context, 'تم نقل الطالب بنجاح');
      _load();
    }
  }

  Future<void> _archive() async {
    final confirmed = await showConfirmDialog(context,
        title: 'أرشفة الطالب', message: 'سيتم نقل الطالب للأرشيف مع الاحتفاظ بكل بياناته. يمكن استرجاعه لاحقاً.', danger: false);
    if (!confirmed) return;
    await _studentRepo.setArchived(widget.studentId, true);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final confirmed = await showConfirmDialog(context,
        title: 'حذف الطالب نهائياً', message: 'سيتم حذف كل بيانات الطالب نهائياً ولا يمكن التراجع. يفضل استخدام الأرشفة بدلاً من الحذف.');
    if (!confirmed) return;
    await _studentRepo.delete(widget.studentId);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _addNote() async {
    final ctrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة ملاحظة'),
        content: TextField(controller: ctrl, maxLines: 3, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حفظ')),
        ],
      ),
    );
    if (result == true && ctrl.text.trim().isNotEmpty) {
      await _studentRepo.addNote(widget.studentId, ctrl.text.trim());
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _student;
    if (_loading || s == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          title: Text(s.name),
          actions: [
            IconButton(
              icon: const Icon(Icons.qr_code_rounded),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StudentCardScreen(studentId: s.id!))),
            ),
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'edit') {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => StudentFormScreen(student: s))).then((_) => _load());
                } else if (v == 'status') {
                  _changeStatus();
                } else if (v == 'transfer') {
                  _transfer();
                } else if (v == 'archive') {
                  _archive();
                } else if (v == 'delete') {
                  _delete();
                }
              },
              itemBuilder: (ctx) => const [
                PopupMenuItem(value: 'edit', child: Text('تعديل البيانات')),
                PopupMenuItem(value: 'status', child: Text('تغيير الحالة')),
                PopupMenuItem(value: 'transfer', child: Text('نقل لمجموعة/صف آخر')),
                PopupMenuItem(value: 'archive', child: Text('أرشفة الطالب')),
                PopupMenuItem(value: 'delete', child: Text('حذف نهائي')),
              ],
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'البيانات'),
              Tab(text: 'المدفوعات'),
              Tab(text: 'الحضور'),
              Tab(text: 'الاختبارات'),
              Tab(text: 'الرسوم الإضافية'),
              Tab(text: 'الملاحظات'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildInfoTab(s),
            _buildPaymentsTab(s),
            _buildAttendanceTab(),
            _buildExamsTab(),
            _buildExtraFeesTab(s),
            _buildNotesTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTab(Student s) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: CircleAvatar(
            radius: 46,
            backgroundImage: s.photoPath != null ? FileImage(File(s.photoPath!)) : null,
            child: s.photoPath == null ? Text(s.name.isNotEmpty ? s.name[0] : '?', style: const TextStyle(fontSize: 28)) : null,
          ),
        ),
        const SizedBox(height: 12),
        Center(child: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
        const SizedBox(height: 4),
        Center(
          child: Wrap(spacing: 8, alignment: WrapAlignment.center, children: [
            StatusBadge(label: 'كود: ${s.code}', color: Colors.indigo),
            StatusBadge(label: s.status, color: s.status == 'نشط' ? Colors.green : Colors.orange),
          ]),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            if (s.phone != null) ...[
              Expanded(child: OutlinedButton.icon(onPressed: () => AppHelpers.callPhone(s.phone!), icon: const Icon(Icons.call_rounded, size: 18), label: const Text('اتصال'))),
              const SizedBox(width: 8),
              Expanded(child: OutlinedButton.icon(onPressed: () => AppHelpers.openWhatsApp(s.phone!), icon: const Icon(Icons.chat_rounded, size: 18), label: const Text('واتساب الطالب'))),
            ],
          ],
        ),
        if (s.parentPhone != null) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => AppHelpers.openWhatsApp(s.parentPhone!),
            icon: const Icon(Icons.chat_rounded, size: 18),
            label: const Text('واتساب ولي الأمر'),
          ),
        ],
        const SizedBox(height: 20),
        _infoRow('الصف الدراسي', _grade?.name ?? '-'),
        _infoRow('المجموعة', _group?.name ?? '-'),
        _infoRow('رقم الهاتف', s.phone ?? '-'),
        _infoRow('رقم ولي الأمر', s.parentPhone ?? '-'),
        _infoRow('المدرسة', s.school ?? '-'),
        _infoRow('العنوان', s.address ?? '-'),
        _infoRow('النوع', s.gender ?? '-'),
        _infoRow('تاريخ الميلاد', s.birthDate != null ? AppHelpers.formatDate(s.birthDate!) : '-'),
        _infoRow('تاريخ الاشتراك', AppHelpers.formatDate(s.subscriptionDate)),
        if (s.notes != null && s.notes!.isNotEmpty) _infoRow('ملاحظات عامة', s.notes!),
        const SizedBox(height: 20),
        SectionTitle(title: 'تقرير سريع', icon: Icons.insights_rounded),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.6,
          children: [
            StatCard(title: 'متوسط الدرجات', value: _scoreStats['avg']!.toStringAsFixed(1), icon: Icons.grade_rounded, color: Colors.blue),
            StatCard(title: 'نسبة الحضور', value: '${_attendancePct.toStringAsFixed(0)}%', icon: Icons.fact_check_rounded, color: Colors.teal),
            StatCard(title: 'إجمالي المدفوعات', value: AppHelpers.formatMoney(_totalPaid), icon: Icons.payments_rounded, color: Colors.green),
            StatCard(title: 'المتبقي عليه', value: AppHelpers.formatMoney(_remaining), icon: Icons.warning_amber_rounded, color: Colors.red),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 130, child: Text(label, style: TextStyle(color: Theme.of(context).disabledColor, fontWeight: FontWeight.w600))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }

  Widget _buildPaymentsTab(Student s) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: PrimaryButton(
            label: 'تسجيل دفعة جديدة',
            icon: Icons.add_circle_outline_rounded,
            onPressed: () async {
              final added = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => PaymentFormScreen(studentId: s.id, groupId: s.groupId)));
              if (added == true) _load();
            },
          ),
        ),
        Expanded(
          child: _payments.isEmpty
              ? const EmptyState(message: 'لا توجد مدفوعات مسجلة', icon: Icons.payments_rounded)
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: _payments.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    final p = _payments[i];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(backgroundColor: Colors.green.withOpacity(0.1), child: const Icon(Icons.payments_rounded, color: Colors.green)),
                        title: Text(p.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${p.type} • ${AppHelpers.formatDate(p.paymentDate)}'),
                        trailing: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(AppHelpers.formatMoney(p.amount), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                            if (p.remaining > 0) Text('متبقي ${AppHelpers.formatMoney(p.remaining)}', style: const TextStyle(fontSize: 11, color: Colors.red)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildAttendanceTab() {
    if (_attendanceHistory.isEmpty) {
      return const EmptyState(message: 'لا يوجد سجل حضور بعد', icon: Icons.fact_check_rounded);
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: StatusBadge(label: 'إجمالي مرات الغياب: $_absenceCount', color: Colors.red),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: _attendanceHistory.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) {
              final a = _attendanceHistory[i];
              final color = a.status == 'حاضر'
                  ? Colors.green
                  : a.status == 'غائب'
                      ? Colors.red
                      : a.status == 'متأخر'
                          ? Colors.orange
                          : Colors.blue;
              return Card(
                child: ListTile(
                  leading: Icon(Icons.calendar_today_rounded, color: color),
                  title: Text(AppHelpers.formatDate(a.date)),
                  trailing: StatusBadge(label: a.status, color: color),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildExamsTab() {
    if (_examResults.isEmpty) {
      return const EmptyState(message: 'لا توجد نتائج اختبارات بعد', icon: Icons.assignment_rounded);
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _examResults.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) {
        final r = _examResults[i];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.assignment_rounded),
            title: Text('الدرجة: ${r.score?.toStringAsFixed(1) ?? '-'}'),
            subtitle: r.notes != null ? Text(r.notes!) : null,
          ),
        );
      },
    );
  }

  Widget _buildExtraFeesTab(Student s) {
    return Column(
      children: [
        Expanded(
          child: _extraFees.isEmpty
              ? const EmptyState(message: 'لا توجد رسوم إضافية مخصصة لهذا الطالب', icon: Icons.receipt_long_rounded)
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _extraFees.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    final f = _extraFees[i];
                    return Card(
                      child: ListTile(
                        leading: Icon(Icons.receipt_rounded, color: f.isPaid ? Colors.green : Colors.orange),
                        title: Text(f.name),
                        subtitle: Text(AppHelpers.formatMoney(f.price)),
                        trailing: StatusBadge(label: f.isPaid ? 'مدفوع' : 'غير مدفوع', color: f.isPaid ? Colors.green : Colors.red),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildNotesTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: PrimaryButton(label: 'إضافة ملاحظة', icon: Icons.note_add_rounded, onPressed: _addNote),
        ),
        Expanded(
          child: _notes.isEmpty
              ? const EmptyState(message: 'لا توجد ملاحظات بعد', icon: Icons.sticky_note_2_rounded)
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: _notes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    final n = _notes[i];
                    return Card(
                      child: ListTile(
                        title: Text(n.text),
                        subtitle: Text(AppHelpers.formatDate(n.date)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () async {
                            await _studentRepo.deleteNote(n.id!);
                            _load();
                          },
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
