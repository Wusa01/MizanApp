import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core/services/app_lock_service.dart';
import '../core/settings/app_lock_provider.dart';

/// يغطي التطبيق بشاشة قفل عند الفتح، وبعد البقاء في الخلفية أكثر من 30 ثانية.
class AppLockGate extends ConsumerStatefulWidget {
  final Widget child;

  const AppLockGate({super.key, required this.child});

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate>
    with WidgetsBindingObserver {
  static const _gracePeriod = Duration(seconds: 30);

  final _service = AppLockService();

  late bool _locked;
  bool _authenticating = false;
  DateTime? _backgroundedAt;

  @override
  void initState() {
    super.initState();

    _locked = ref.read(appLockProvider);

    WidgetsBinding.instance.addObserver(this);

    if (_locked) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!ref.read(appLockProvider) || _authenticating) return;

    if (state == AppLifecycleState.paused) {
      _backgroundedAt ??= DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final since = _backgroundedAt;
      _backgroundedAt = null;

      if (since != null && DateTime.now().difference(since) >= _gracePeriod) {
        setState(() => _locked = true);
        _unlock();
      }
    }
  }

  Future<void> _unlock() async {
    if (_authenticating) return;

    _authenticating = true;

    try {
      // إذا أزال المستخدم قفل الشاشة من الهاتف لا يمكن التحقق أبداً،
      // فنفتح التطبيق بدل أن يُحبس خارج بياناته.
      final supported = await _service.isSupported();
      final ok =
          !supported || await _service.authenticate('افتح ميزان للمتابعة');

      if (ok && mounted) {
        setState(() => _locked = false);
      }
    } finally {
      _authenticating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Offstage(offstage: _locked, child: widget.child),
        if (_locked) Positioned.fill(child: _LockScreen(onUnlock: _unlock)),
      ],
    );
  }
}

class _LockScreen extends StatelessWidget {
  final VoidCallback onUnlock;

  const _LockScreen({required this.onUnlock});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'ميزان مقفل',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onUnlock,
              icon: const Icon(Icons.fingerprint),
              label: const Text('فتح'),
            ),
          ],
        ),
      ),
    );
  }
}