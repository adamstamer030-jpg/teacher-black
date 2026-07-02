import 'package:flutter/material.dart';
import '../../core/di/service_locator.dart';
import '../../core/utils/helpers.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/models/models.dart';
import '../attendance/attendance_screen.dart';
import '../exams/exams_screen.dart';
import '../students/student_detail_screen.dart';
import '../students/student_form_screen.dart';
import 'group_form_screen.dart';

class GroupDetailScreen extends StatefulWidget {
  final int groupId;
  const GroupDetailScreen({super.key, required this.groupId});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  final _groupRepo = Locator.instance.groupRepository;
  final _studentRepo = Locator.instance.studentRepository;
  StudyGroup? _group;
  List<GroupSchedule> _schedules = [];
  List<ExtraFeeTemplate> _fees = [];
  List<Student> _students = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final group = await _groupRepo.getById(widget.groupId);
    final schedules = await _groupRepo.getSchedules(widget.groupId);
    final fees = await _groupRepo.getExtraFees(widget.groupId);
    final students = await _studentRepo.getByGroup(widget.groupId);
    setState(() {
      _group = group;
      _schedules = schedules;
      _fees = fees;
      _students = students;
      _loading = false;
    });
  }

  Future<void> _addSchedule() async {
    String day = 'السبت';
    final startCtrl = TextEditingController();
    final endCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    const days = ['السبت', 'الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة'];

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16, right: 16, top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: StatefulBuilder(
          builder: (ctx, setSheetState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('إضافة ميعاد جديد', style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              AppDropdown<String>(
                label: 'يوم الأسبوع',
                value: day,
                items: days.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                onChanged: (v) => setSheetState(() => day = v ?? day),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: AppTextField(controller: startCtrl, label: 'وقت البداية', hint: '4:00 م')),
                  const SizedBox(width: 10),
                  Expanded(child: AppTextField(controller: endCtrl, label: 'وقت النهاية', hint: '5:30 م')),
                ],
              ),
              const SizedBox(height: 12),
              AppTextField(controller: locationCtrl, label: 'مكان الحصة', hint: 'قاعة 1'),
              const SizedBox(height: 20),
              PrimaryButton(label: 'إضافة الميعاد', onPressed: () => Navigator.pop(ctx, true)),
            ],
          ),
        ),
      ),
    );

    if (result == true && startCtrl.text.isNotEmpty && endCtrl.text.isNotEmpty) {
      await _groupRepo.addSchedule(GroupSchedule(
        groupId: widget.groupId,
        dayOfWeek: day,
        startTime: startCtrl.text.trim(),
        endTime: endCtrl.text.trim(),
        location: locationCtrl.text.trim().isEmpty ? null : locationCtrl.text.trim(),
        createdAt: AppHelpers.nowIso(),
      ));
      _load();
    }
  }

  Future<void> _addExtraFee() async {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة رسم إضافي'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(controller: nameCtrl, label: 'اسم الرسم', hint: 'ورق امتحان / ملازم...'),
            const SizedBox(height: 12),
            AppTextField(controller: priceCtrl, label: 'السعر', keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('إضافة')),
        ],
      ),
    );
    if (result == true && nameCtrl.text.trim().isNotEmpty) {
      await _groupRepo.addExtraFee(ExtraFeeTemplate(
        groupId: widget.groupId,
        name: nameCtrl.text.trim(),
        price: double.tryParse(priceCtrl.text.trim()) ?? 0,
        createdAt: AppHelpers.nowIso(),
      ));
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final group = _group;
    if (_loading || group == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final color = Color(int.parse(group.color.replaceFirst('#', '0xff')));

    return Scaffold(
      appBar: AppBar(
        title: Text(group.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              final updated = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => GroupFormScreen(group: group)));
              if (updated == true) _load();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final added = await Navigator.push<bool>(
              context, MaterialPageRoute(builder: (_) => StudentFormScreen(initialGroupId: group.id)));
          if (added == true) _load();
        },
        child: const Icon(Icons.person_add_alt_1_rounded),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  StatusBadge(label: '${_students.length} طالب', color: color),
                  const SizedBox(width: 8),
                  StatusBadge(label: AppHelpers.formatMoney(group.monthlyFee), color: Colors.green),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AttendanceScreen(groupId: group.id!, groupName: group.name))),
                    icon: const Icon(Icons.fact_check_rounded, size: 16),
                    label: const Text('الحضور'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          SectionTitle(title: 'مواعيد المجموعة', icon: Icons.schedule_rounded, actionLabel: 'إضافة', onAction: _addSchedule),
          const SizedBox(height: 8),
          if (_schedules.isEmpty)
            const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('لا توجد مواعيد محددة بعد'))
          else
            ..._schedules.map((s) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.event_rounded),
                    title: Text('${s.dayOfWeek}  •  ${s.startTime} - ${s.endTime}'),
                    subtitle: s.location != null ? Text(s.location!) : null,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () async {
                        await _groupRepo.deleteSchedule(s.id!);
                        _load();
                      },
                    ),
                  ),
                )),
          const SizedBox(height: 20),
          SectionTitle(title: 'الرسوم الإضافية للمجموعة', icon: Icons.receipt_long_rounded, actionLabel: 'إضافة', onAction: _addExtraFee),
          const SizedBox(height: 8),
          if (_fees.isEmpty)
            const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('لا توجد رسوم إضافية محددة'))
          else
            ..._fees.map((f) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.receipt_rounded),
                    title: Text(f.name),
                    trailing: Text(AppHelpers.formatMoney(f.price), style: const TextStyle(fontWeight: FontWeight.bold)),
                    onLongPress: () async {
                      await _groupRepo.deleteExtraFee(f.id!);
                      _load();
                    },
                  ),
                )),
          const SizedBox(height: 20),
          SectionTitle(
            title: 'اختبارات المجموعة',
            icon: Icons.assignment_rounded,
            actionLabel: 'عرض الكل',
            onAction: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GroupExamsScreen(groupId: group.id!, groupName: group.name))),
          ),
          const SizedBox(height: 20),
          SectionTitle(title: 'الطلاب المقيدون (${_students.length})', icon: Icons.groups_rounded),
          const SizedBox(height: 8),
          if (_students.isEmpty)
            const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('لا يوجد طلاب في هذه المجموعة بعد'))
          else
            ..._students.map((s) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: InitialAvatar(name: s.name),
                    title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('كود: ${s.code}'),
                    onTap: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (_) => StudentDetailScreen(studentId: s.id!)));
                      _load();
                    },
                  ),
                )),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
