import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/di/service_locator.dart';
import '../../../data/repositories/settings_repository.dart';

String hashPin(String pin) => sha256.convert(utf8.encode(pin)).toString();

class LockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;
  const LockScreen({super.key, required this.onUnlocked});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final _settings = Locator.instance.settingsRepository;
  String _entered = '';
  String? _error;
  bool _checkingBiometric = false;

  @override
  void initState() {
    super.initState();
    _tryBiometric();
  }

  Future<void> _tryBiometric() async {
    final enabled = await _settings.get(SettingsRepository.keyBiometricEnabled);
    if (enabled != 'true') return;
    setState(() => _checkingBiometric = true);
    try {
      final auth = LocalAuthentication();
      final canCheck = await auth.canCheckBiometrics;
      if (canCheck) {
        final ok = await auth.authenticate(
          localizedReason: 'فتح التطبيق ببصمة الإصبع',
          options: const AuthenticationOptions(biometricOnly: true),
        );
        if (ok) {
          widget.onUnlocked();
          return;
        }
      }
    } catch (_) {
      // تجاهل: سيستخدم المستخدم رمز PIN بدلاً من ذلك
    } finally {
      if (mounted) setState(() => _checkingBiometric = false);
    }
  }

  Future<void> _onDigit(String digit) async {
    if (_entered.length >= 4) return;
    setState(() {
      _entered += digit;
      _error = null;
    });
    if (_entered.length == 4) {
      final savedHash = await _settings.get(SettingsRepository.keyPinHash);
      if (savedHash == hashPin(_entered)) {
        widget.onUnlocked();
      } else {
        setState(() {
          _error = 'الرمز غير صحيح';
          _entered = '';
        });
      }
    }
  }

  void _onBackspace() {
    if (_entered.isEmpty) return;
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primaryDark,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              const Icon(Icons.lock_outline, color: Colors.white, size: 48),
              const SizedBox(height: 16),
              const Text('التطبيق مقفول',
                  style: TextStyle(
                      color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(_checkingBiometric ? 'جارِ التحقق من البصمة...' : 'أدخل رمز PIN لمتابعة الاستخدام',
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) {
                  final filled = i < _entered.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled ? Colors.white : Colors.white24,
                    ),
                  );
                }),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              ],
              const Spacer(),
              _buildKeypad(),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _tryBiometric,
                child: const Text('استخدام بصمة الإصبع',
                    style: TextStyle(color: Colors.white70)),
              ),
            ],
          ),
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
      childAspectRatio: 1.6,
      children: keys.map((k) {
        if (k.isEmpty) return const SizedBox();
        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => k == '⌫' ? _onBackspace() : _onDigit(k),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Text(k,
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          ),
        );
      }).toList(),
    );
  }
}
