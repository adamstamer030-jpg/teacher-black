import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_auth/local_auth.dart';

import '../../core/constants/app_colors.dart';
import '../../core/di/service_locator.dart';
import '../../core/theme/theme_cubit.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/repositories/settings_repository.dart';
import 'export/backup_service.dart';
import 'security/pin_setup_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _settings = Locator.instance.settingsRepository;
  late TextEditingController _teacherNameCtrl;
  late TextEditingController _teacherPhoneCtrl;
  late TextEditingController _centerNameCtrl;
  bool _pinEnabled = false;
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _teacherNameCtrl = TextEditingController();
    _teacherPhoneCtrl = TextEditingController();
    _centerNameCtrl = TextEditingController();
    _load();
  }

  Future<void> _load() async {
    final teacherName = await _settings.get(SettingsRepository.keyTeacherName);
    final teacherPhone = await _settings.get(SettingsRepository.keyTeacherPhone);
    final centerName = await _settings.get(SettingsRepository.keyCenterName);
    final pinEnabled = await _settings.get(SettingsRepository.keyPinEnabled);
    final bioEnabled = await _settings.get(SettingsRepository.keyBiometricEnabled);
    bool bioAvailable = false;
    try {
      bioAvailable = await LocalAuthentication().canCheckBiometrics;
    } catch (_) {}

    setState(() {
      _teacherNameCtrl.text = teacherName ?? '';
      _teacherPhoneCtrl.text = teacherPhone ?? '';
      _centerNameCtrl.text = centerName ?? '';
      _pinEnabled = pinEnabled == 'true';
      _biometricEnabled = bioEnabled == 'true';
      _biometricAvailable = bioAvailable;
    });
  }

  Future<void> _saveTeacherInfo() async {
    await _settings.set(SettingsRepository.keyTeacherName, _teacherNameCtrl.text.trim());
    await _settings.set(SettingsRepository.keyTeacherPhone, _teacherPhoneCtrl.text.trim());
    await _settings.set(SettingsRepository.keyCenterName, _centerNameCtrl.text.trim());
    if (mounted) showAppSnackBar(context, 'تم حفظ البيانات بنجاح');
  }

  Future<void> _togglePin(bool value) async {
    if (value) {
      final result = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const PinSetupScreen()));
      if (result == true) setState(() => _pinEnabled = true);
    } else {
      await _settings.set(SettingsRepository.keyPinEnabled, 'false');
      setState(() => _pinEnabled = false);
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    await _settings.set(SettingsRepository.keyBiometricEnabled, value.toString());
    setState(() => _biometricEnabled = value);
  }

  Future<void> _backup() async {
    await BackupService.shareFullJsonBackup();
  }

  Future<void> _restore() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'استعادة نسخة احتياطية',
      message: 'سيتم استبدال جميع البيانات الحالية بالبيانات الموجودة في النسخة الاحتياطية. هل تريد الاستمرار؟',
    );
    if (!confirmed) return;
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
    if (result == null || result.files.single.path == null) return;
    await BackupService.restoreFromJson(File(result.files.single.path!));
    if (mounted) showAppSnackBar(context, 'تمت الاستعادة بنجاح، يفضل إعادة تشغيل التطبيق');
  }

  Future<void> _exportCsvTable() async {
    final table = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: const Text('الطلاب'), leading: const Icon(Icons.groups_rounded), onTap: () => Navigator.pop(ctx, 'students')),
            ListTile(title: const Text('المدفوعات'), leading: const Icon(Icons.payments_rounded), onTap: () => Navigator.pop(ctx, 'payments')),
            ListTile(title: const Text('الحجوزات'), leading: const Icon(Icons.calendar_month_rounded), onTap: () => Navigator.pop(ctx, 'reservations')),
            ListTile(title: const Text('الحضور'), leading: const Icon(Icons.fact_check_rounded), onTap: () => Navigator.pop(ctx, 'attendance')),
          ],
        ),
      ),
    );
    if (table != null) await BackupService.exportTableAsCsv(table);
  }

  @override
  Widget build(BuildContext context) {
    final themeCubit = context.watch<ThemeCubit>();
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionTitle(title: 'بيانات المدرس والسنتر', icon: Icons.person_rounded),
          const SizedBox(height: 12),
          AppTextField(controller: _teacherNameCtrl, label: 'اسم المدرس'),
          const SizedBox(height: 12),
          AppTextField(controller: _teacherPhoneCtrl, label: 'رقم الهاتف', keyboardType: TextInputType.phone),
          const SizedBox(height: 12),
          AppTextField(controller: _centerNameCtrl, label: 'اسم السنتر'),
          const SizedBox(height: 14),
          PrimaryButton(label: 'حفظ البيانات', icon: Icons.save_rounded, onPressed: _saveTeacherInfo),
          const SizedBox(height: 28),

          SectionTitle(title: 'المظهر', icon: Icons.palette_rounded),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('الوضع الداكن', style: TextStyle(fontWeight: FontWeight.w700)),
            value: themeCubit.state.mode == ThemeMode.dark,
            onChanged: (v) => themeCubit.setDarkMode(v),
          ),
          const SizedBox(height: 8),
          Text('لون التطبيق', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            children: AppColors.appSeedColors.entries.map((e) {
              final selected = themeCubit.state.colorName == e.key;
              return GestureDetector(
                onTap: () => themeCubit.setColor(e.key),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(color: e.value, shape: BoxShape.circle, border: selected ? Border.all(width: 2.5) : null),
                  child: selected ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text('حجم الخط', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
          Slider(
            value: themeCubit.state.fontScale,
            min: 0.85,
            max: 1.25,
            divisions: 4,
            label: themeCubit.state.fontScale.toStringAsFixed(2),
            onChanged: (v) => themeCubit.setFontScale(v),
          ),
          const SizedBox(height: 28),

          SectionTitle(title: 'الأمان', icon: Icons.shield_rounded),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('قفل التطبيق برمز PIN', style: TextStyle(fontWeight: FontWeight.w700)),
            value: _pinEnabled,
            onChanged: _togglePin,
          ),
          if (_pinEnabled && _biometricAvailable)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('السماح بفتح التطبيق ببصمة الإصبع', style: TextStyle(fontWeight: FontWeight.w700)),
              value: _biometricEnabled,
              onChanged: _toggleBiometric,
            ),
          const SizedBox(height: 28),

          SectionTitle(title: 'تصدير واستيراد البيانات', icon: Icons.import_export_rounded),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.backup_rounded),
            title: const Text('نسخ احتياطي كامل (JSON)'),
            subtitle: const Text('يحافظ على كل العلاقات بين البيانات'),
            trailing: const Icon(Icons.chevron_left_rounded),
            onTap: _backup,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.restore_rounded),
            title: const Text('استعادة نسخة احتياطية'),
            trailing: const Icon(Icons.chevron_left_rounded),
            onTap: _restore,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.table_chart_rounded),
            title: const Text('تصدير CSV (لفتحه في Excel)'),
            trailing: const Icon(Icons.chevron_left_rounded),
            onTap: _exportCsvTable,
          ),
          const SizedBox(height: 30),
          Center(
            child: Text('منظم الدروس - الإصدار 1.0.0', style: TextStyle(color: Theme.of(context).disabledColor, fontSize: 12)),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
