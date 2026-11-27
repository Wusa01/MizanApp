import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../dashboard/providers/dashboard_providers.dart';

class AccountsPage extends ConsumerWidget {
  const AccountsPage({super.key});

  Future<void> _showAddAccountDialog(BuildContext context) async {
    await showDialog<bool>(
      context: context,
      builder: (_) => const AddAccountDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('الحسابات')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'حساباتك',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () => _showAddAccountDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة حساب'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: accountsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 42,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 12),
                      const Text('تعذر تحميل الحسابات'),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          ref.invalidate(accountsProvider);
                        },
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                ),
                data: (accounts) {
                  if (accounts.isEmpty) {
                    return _buildEmptyState(context);
                  }

                  return ListView.separated(
                    itemCount: accounts.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      return AccountListItem(account: accounts[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddAccountDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('حساب جديد'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          const Text(
            'لا توجد حسابات حتى الآن',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'أضف حسابك الأول للبدء في إدارة أموالك',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => _showAddAccountDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('إضافة حساب'),
          ),
        ],
      ),
    );
  }
}

class AccountListItem extends ConsumerWidget {
  final Account account;

  const AccountListItem({super.key, required this.account});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(accountBalanceProvider(account.id));

    final isPersonal = account.type == 'personal';
    final color = isPersonal ? Colors.blue : Colors.teal;
    final icon = isPersonal ? Icons.person_outline : Icons.business_outlined;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showDialog<bool>(
          context: context,
          builder: (_) => AddAccountDialog(account: account),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      isPersonal ? 'حساب شخصي' : 'حساب تجاري',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                    if (!account.isActive)
                      const Padding(
                        padding: EdgeInsets.only(top: 5),
                        child: Text(
                          'غير نشط',
                          style: TextStyle(color: Colors.orange, fontSize: 12),
                        ),
                      ),
                    const SizedBox(height: 10),
                    balanceAsync.when(
                      loading: () => const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      error: (_, _) => const Text(
                        'تعذر تحميل الرصيد',
                        style: TextStyle(color: Colors.red),
                      ),
                      data: (balance) => Text(
                        CurrencyFormatter.format(balance),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.edit_outlined, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// حوار إضافة حساب، أو تعديله عند تمرير [account].
class AddAccountDialog extends ConsumerStatefulWidget {
  final Account? account;

  const AddAccountDialog({super.key, this.account});

  @override
  ConsumerState<AddAccountDialog> createState() => _AddAccountDialogState();
}

class _AddAccountDialogState extends ConsumerState<AddAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _balanceController;

  late String _type;
  bool _isSaving = false;
  String? _errorMessage;

  bool get _isEditing => widget.account != null;

  @override
  void initState() {
    super.initState();

    final account = widget.account;

    _nameController = TextEditingController(text: account?.name ?? '');
    _balanceController = TextEditingController(
      text: (account?.openingBalance ?? 0).toString(),
    );
    _type = account?.type ?? 'personal';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action, String failure) async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await action();

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
        _errorMessage = failure;
      });
    }
  }

  Future<void> _saveAccount() async {
    if (!_formKey.currentState!.validate()) return;

    final repository = ref.read(financeRepositoryProvider);
    final name = _nameController.text.trim();
    final balance = int.parse(_balanceController.text);

    await _run(() async {
      final account = widget.account;

      if (account == null) {
        await repository.createAccount(
          name: name,
          type: _type,
          openingBalance: balance,
        );
      } else {
        await repository.updateAccount(
          accountId: account.id,
          name: name,
          type: _type,
          openingBalance: balance,
        );
      }
    }, 'تعذر حفظ الحساب. حاول مرة أخرى.');
  }

  Future<void> _toggleActive() {
    final account = widget.account!;
    final repository = ref.read(financeRepositoryProvider);

    return _run(
      () => repository.setAccountActive(account.id, !account.isActive),
      'تعذر تغيير حالة الحساب.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'تعديل الحساب' : 'إضافة حساب جديد'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم الحساب',
                  hintText: 'مثال: حسابي الشخصي',
                  prefixIcon: Icon(Icons.account_balance_wallet),
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'يرجى إدخال اسم الحساب';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(
                  labelText: 'نوع الحساب',
                  prefixIcon: Icon(Icons.category_outlined),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'personal', child: Text('شخصي')),
                  DropdownMenuItem(value: 'business', child: Text('تجاري')),
                ],
                onChanged: _isSaving
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() => _type = value);
                        }
                      },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _balanceController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'الرصيد الافتتاحي',
                  suffixText: 'FCFA',
                  prefixIcon: Icon(Icons.payments_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال الرصيد الافتتاحي';
                  }

                  if (int.tryParse(value) == null) {
                    return 'أدخل مبلغاً صحيحاً';
                  }

                  return null;
                },
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              ],
              if (_isEditing) ...[
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: _isSaving ? null : _toggleActive,
                  icon: Icon(
                    widget.account!.isActive
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  label: Text(
                    widget.account!.isActive
                        ? 'تعطيل الحساب'
                        : 'إعادة تفعيل الحساب',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _saveAccount,
          child: _isSaving
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_isEditing ? 'حفظ التعديلات' : 'حفظ الحساب'),
        ),
      ],
    );
  }
}
