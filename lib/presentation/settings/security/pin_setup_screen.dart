import 'package:flutter/material.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../data/repositories/settings_repository.dart';
import 'lock_screen.dart';

class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final _settings = Locator.instance.settingsRepository;
  String _first = '';
  String _confirm = '';
  bool _confirming = false;
  String? _error;

  void _onDigit(String d) {
    setState(() {
      _error = null;
      if (!_confirming) {
        if (_first.length < 4) _first += d;
        if (_first.length == 4) _confirming = true;
      } else {
        if (_confirm.length < 4) _confirm += d;
        if (_confirm.length == 4) _checkMatch();
      }
    });
  }

  void _onBackspace() {
    setState(() {
      if (_confirming) {
        if (_confirm.isNotEmpty) {
          _confirm = _confirm.substring(0, _confirm.length - 1);
        } else {
          _confirming = false;
        }
      } else if (_first.isNotEmpty) {
        _first = _first.substring(0, _first.length - 1);
      }
    });
  }

  Future<void> _checkMatch() async {
    if (_first == _confirm) {
      await _settings.set(SettingsRepository.keyPinHash, hashPin(_first));
      await _settings.set(SettingsRepository.keyPinEnabled, 'true');
      if (mounted) {
        showAppSnackBar(context, 'تم تفعيل رمز PIN بنجاح');
        Navigator.pop(context, true);
      }
    } else {
      setState(() {
        _error = 'الرمزان غير متطابقين، حاول مرة أخرى';
        _first = '';
        _confirm = '';
        _confirming = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = _confirming ? _confirm : _first;
    return Scaffold(
      appBar: AppBar(title: const Text('تعيين رمز PIN')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Text(_confirming ? 'أعد كتابة الرمز للتأكيد' : 'اكتب رمز PIN من 4 أرقام',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) {
                final filled = i < current.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
                  ),
                );
              }),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ],
            const Spacer(),
            _buildKeypad(),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    final keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', '⌫'];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.8,
      children: keys.map((k) {
        if (k.isEmpty) return const SizedBox();
        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => k == '⌫' ? _onBackspace() : _onDigit(k),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Text(k, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
        );
      }).toList(),
    );
  }
}
