import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/di/service_locator.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'data/repositories/settings_repository.dart';
import 'presentation/settings/security/lock_screen.dart';
import 'presentation/splash/splash_screen.dart';

/// شاشة خطأ مرئية بسيطة تُستخدم بدل الانهيار الصامت.
/// بدون أي وصول لـ adb/logcat، هذه أسهل طريقة لمعرفة سبب أي مشكلة:
/// تصوير الشاشة وقراءة النص مباشرة.
class _FatalErrorScreen extends StatelessWidget {
  final Object error;
  final StackTrace? stack;
  const _FatalErrorScreen({required this.error, this.stack});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFF1E1E1E),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('حدث خطأ غير متوقع',
                      style: TextStyle(color: Colors.redAccent, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text('من فضلك صوّر هذه الشاشة وأرسلها للمطوّر',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 16),
                  SelectableText(error.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'monospace')),
                  if (stack != null) ...[
                    const SizedBox(height: 16),
                    SelectableText(stack.toString(),
                        style: const TextStyle(color: Colors.white38, fontSize: 11, fontFamily: 'monospace')),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void main() {
  // عرض أي خطأ widget-build (حتى في وضع release الذي يخفي التفاصيل افتراضياً)
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return _FatalErrorScreen(error: details.exception, stack: details.stack);
  };

  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // أي خطأ Flutter framework عادي (build/layout/paint) يُعرض بدل الانهيار
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
    };

    // أي خطأ غير متوقع على مستوى المنصة (Platform/Engine) يفتح شاشة الخطأ المرئية
    WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
      runApp(_FatalErrorScreen(error: error, stack: stack));
      return true;
    };

    try {
      await initializeDateFormatting('ar');
    } catch (_) {
      // فشل تحميل صيغ التاريخ العربية لا يجب أن يمنع تشغيل التطبيق بالكامل
    }

    runApp(const TutorManagerApp());
  }, (error, stack) {
    // أي خطأ غير متوقع خارج شجرة الـ widgets (مثل خطأ أثناء فتح قاعدة البيانات)
    runApp(_FatalErrorScreen(error: error, stack: stack));
    if (kDebugMode) {
      debugPrint('FATAL: $error\n$stack');
    }
  });
}

class TutorManagerApp extends StatelessWidget {
  const TutorManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ThemeCubit(Locator.instance.settingsRepository),
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, themeState) {
          return MaterialApp(
            title: 'منظم الدروس',
            debugShowCheckedModeBanner: false,
            themeMode: themeState.mode,
            theme: AppTheme.light(themeState.seedColor, themeState.fontScale),
            darkTheme: AppTheme.dark(themeState.seedColor, themeState.fontScale),
            locale: const Locale('ar'),
            supportedLocales: const [Locale('ar'), Locale('en')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            builder: (context, child) {
              return Directionality(
                textDirection: TextDirection.rtl,
                child: AppLockWrapper(child: child ?? const SizedBox()),
              );
            },
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}

/// غلاف يراقب دورة حياة التطبيق ويعرض شاشة القفل (PIN/بصمة) عند الرجوع للتطبيق
/// إذا كانت ميزة الأمان مفعّلة من الإعدادات.
class AppLockWrapper extends StatefulWidget {
  final Widget child;
  const AppLockWrapper({super.key, required this.child});

  @override
  State<AppLockWrapper> createState() => _AppLockWrapperState();
}

class _AppLockWrapperState extends State<AppLockWrapper> with WidgetsBindingObserver {
  bool _locked = false;
  bool _shouldLockOnResume = false;
  final _settings = Locator.instance.settingsRepository;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkInitialLock();
  }

  Future<void> _checkInitialLock() async {
    final enabled = await _settings.get(SettingsRepository.keyPinEnabled);
    if (enabled == 'true' && mounted) {
      setState(() => _locked = true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    final enabled = await _settings.get(SettingsRepository.keyPinEnabled);
    if (enabled != 'true') return;

    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _shouldLockOnResume = true;
    } else if (state == AppLifecycleState.resumed && _shouldLockOnResume) {
      _shouldLockOnResume = false;
      if (mounted) setState(() => _locked = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_locked)
          LockScreen(onUnlocked: () => setState(() => _locked = false)),
      ],
    );
  }
}
