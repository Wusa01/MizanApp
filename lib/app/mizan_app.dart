import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core/settings/theme_mode_provider.dart';
import '../core/theme/app_theme.dart';
import 'app_lock_gate.dart';
import 'router/app_router.dart';

class MizanApp extends ConsumerWidget {
  const MizanApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'ميزان',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: appRouter,
      // واجهة عربية بالكامل، ومعها شاشة القفل فوق التطبيق.
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AppLockGate(child: child ?? const SizedBox.shrink()),
        );
      },
    );
  }
}