import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/mizan_app.dart';
import 'core/settings/app_lock_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final lockEnabled = await readInitialAppLock();

  runApp(
    ProviderScope(
      overrides: [initialAppLockProvider.overrideWithValue(lockEnabled)],
      child: const MizanApp(),
    ),
  );
}