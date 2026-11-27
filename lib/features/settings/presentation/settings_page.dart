import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/providers/database_provider.dart';
import '../../../core/services/app_lock_service.dart';
import '../../../core/services/backup_crypto.dart';
import '../../../core/services/file_saver.dart';
import '../../../core/settings/app_lock_provider.dart';
import '../../../core/settings/theme_mode_provider.dart';
import '../../../core/utils/csv_builder.dart';
import 'widgets/password_dialogs.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  // نأخذ الـ messenger قبل أي await حتى لا نستخدم BuildContext بعده.
  void _show(ScaffoldMessengerState messenger, String text) {
    messenger.showSnackBar(SnackBar(content: Text(text)));
  }

  // نافذة انتظار أثناء التشفير وفكه (يستغرق ثانية أو أكثر).
  Future<T> _withProgress<T>(
    BuildContext context,
    Future<T> Function() task,
  ) async {
    final navigator = Navigator.of(context, rootNavigator: true);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(child: CircularProgressIndicator()),
      ),
    );

    try {
      return await task();
    } finally {
      navigator.pop();
    }
  }

  Future<void> _toggleLock(
    BuildContext context,
    WidgetRef ref,
    bool enable,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final service = AppLockService();

    if (!await service.isSupported()) {
      _show(messenger, 'فعّل قفل الشاشة (بصمة أو رمز) في إعدادات الهاتف أولاً');
      return;
    }

    final ok = await service.authenticate(
      enable ? 'أكّد هويتك لتفعيل القفل' : 'أكّد هويتك لإلغاء القفل',
    );

    if (!ok || !context.mounted) return;

    await ref.read(appLockProvider.notifier).setEnabled(enable);

    _show(messenger, enable ? 'تم تفعيل قفل التطبيق' : 'تم إلغاء قفل التطبيق');
  }

  Future<void> _exportCsv(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      final items = await ref
          .read(financeRepositoryProvider)
          .getAllTransactionsDetailed();

      if (items.isEmpty) {
        _show(messenger, 'لا توجد عمليات لتصديرها');
        return;
      }

      final saved = await FileSaver.saveText(
        fileName: 'mizan-transactions-${FileSaver.dateStamp()}.csv',
        content: CsvBuilder.transactions(items),
        dialogTitle: 'حفظ ملف العمليات',
      );

      if (saved) _show(messenger, 'تم حفظ الملف');
    } catch (_) {
      _show(messenger, 'تعذر تصدير العمليات');
    }
  }

  Future<void> _backup(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);

    final password = await askNewPassword(context);

    if (password == null || !context.mounted) return;

    try {
      final json = await ref.read(backupRepositoryProvider).exportJson();

      if (!context.mounted) return;

      final encrypted = await _withProgress(
        context,
        () => BackupCrypto.encrypt(json, password),
      );

      final saved = await FileSaver.saveText(
        fileName: 'mizan-backup-${FileSaver.dateStamp()}.json',
        content: encrypted,
        dialogTitle: 'حفظ النسخة الاحتياطية',
      );

      if (saved) _show(messenger, 'تم حفظ النسخة الاحتياطية المشفرة');
    } catch (_) {
      _show(messenger, 'تعذر إنشاء النسخة الاحتياطية');
    }
  }

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('استعادة نسخة احتياطية'),
        content: const Text(
          'سيتم استبدال كل الحسابات والعمليات الحالية ببيانات النسخة '
          'المختارة. لا يمكن التراجع عن ذلك.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('متابعة'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final text = await FileSaver.pickJsonText();

      if (text == null || !context.mounted) return;

      var plain = text;

      // النسخ الجديدة مشفرة، والنسخ القديمة غير المشفرة تبقى مقبولة.
      if (BackupCrypto.isEncrypted(text)) {
        final password = await askPassword(context);

        if (password == null || !context.mounted) return;

        plain = await _withProgress(
          context,
          () => BackupCrypto.decrypt(text, password),
        );
      }

      if (!context.mounted) return;

      await ref.read(backupRepositoryProvider).importJson(plain);

      _show(messenger, 'تمت استعادة البيانات بنجاح');
    } on ArgumentError catch (error) {
      _show(messenger, error.message?.toString() ?? 'ملف غير صالح');
    } catch (_) {
      _show(messenger, 'تعذرت استعادة النسخة الاحتياطية');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final lockEnabled = ref.watch(appLockProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        children: [
          const ListTile(
            leading: Icon(Icons.language),
            title: Text('اللغة'),
            subtitle: Text('العربية'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('المظهر'),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.system,
                    label: Text('النظام'),
                    icon: Icon(Icons.brightness_auto),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    label: Text('فاتح'),
                    icon: Icon(Icons.light_mode_outlined),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text('داكن'),
                    icon: Icon(Icons.dark_mode_outlined),
                  ),
                ],
                selected: {themeMode},
                onSelectionChanged: (selection) {
                  ref
                      .read(themeModeProvider.notifier)
                      .setThemeMode(selection.first);
                },
              ),
            ),
          ),
          const Divider(),
          SwitchListTile(
            secondary: const Icon(Icons.lock_outline),
            title: const Text('قفل التطبيق'),
            subtitle: const Text('بصمة أو رمز الهاتف عند فتح التطبيق'),
            value: lockEnabled,
            onChanged: (value) => _toggleLock(context, ref, value),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.label_outline),
            title: const Text('التصنيفات'),
            subtitle: const Text('إضافة وتعديل تصنيفات الدخل والمصروفات'),
            onTap: () => context.push('/settings/categories'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.table_view_outlined),
            title: const Text('تصدير العمليات (CSV)'),
            subtitle: const Text('ملف يفتح في Excel (غير مشفر)'),
            onTap: () => _exportCsv(context, ref),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.backup_outlined),
            title: const Text('إنشاء نسخة احتياطية مشفرة'),
            subtitle: const Text('حفظ كل بياناتك في ملف محمي بكلمة مرور'),
            onTap: () => _backup(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.restore_outlined),
            title: const Text('استعادة نسخة احتياطية'),
            subtitle: const Text('استبدال البيانات الحالية بنسخة محفوظة'),
            onTap: () => _restore(context, ref),
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('حول ميزان'),
            subtitle: Text('الإصدار 1.0.0'),
          ),
        ],
      ),
    );
  }
}