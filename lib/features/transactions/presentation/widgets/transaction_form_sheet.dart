import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../dashboard/providers/dashboard_providers.dart';
import '../../providers/transactions_providers.dart';

/// نموذج إضافة / تعديل / حذف عملية مالية.
/// عند تمرير [existing] يتحول إلى وضع التعديل (ولا يمكن تغيير نوع العملية).
class TransactionFormSheet extends ConsumerStatefulWidget {
  final FinancialTransaction? existing;

  const TransactionFormSheet({super.key, this.existing});

  @override
  ConsumerState<TransactionFormSheet> createState() =>
      _TransactionFormSheetState();
}

class _TransactionFormSheetState extends ConsumerState<TransactionFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;

  late String _type;
  int? _accountId;
  int? _destinationAccountId;
  int? _categoryId;
  late DateTime _date;

  bool _isSaving = false;
  String? _errorMessage;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();

    final existing = widget.existing;

    _type = existing?.type ?? 'expense';
    _accountId = existing?.accountId;
    _destinationAccountId = existing?.destinationAccountId;
    _categoryId = existing?.categoryId;
    _date = existing?.transactionDate ?? DateTime.now();

    _amountController = TextEditingController(
      text: existing?.amount.toString() ?? '',
    );
    _descriptionController = TextEditingController(
      text: existing?.description ?? '',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked == null) return;

    setState(() {
      // نحافظ على الوقت الحالي للعملية ونغير اليوم فقط.
      _date = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _date.hour,
        _date.minute,
      );
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final repository = ref.read(financeRepositoryProvider);
    final amount = int.parse(_amountController.text);
    final description = _descriptionController.text.trim().isEmpty
        ? null
        : _descriptionController.text.trim();

    try {
      final existing = widget.existing;

      if (_type == 'transfer') {
        if (existing == null) {
          await repository.transfer(
            sourceAccountId: _accountId!,
            destinationAccountId: _destinationAccountId!,
            amount: amount,
            description: description,
            transactionDate: _date,
          );
        } else {
          await repository.updateTransfer(
            transactionId: existing.id,
            sourceAccountId: _accountId!,
            destinationAccountId: _destinationAccountId!,
            amount: amount,
            description: description,
            transactionDate: _date,
          );
        }
      } else {
        final isIncome = _type == 'income';

        if (existing == null) {
          final add = isIncome ? repository.addIncome : repository.addExpense;

          await add(
            accountId: _accountId!,
            amount: amount,
            categoryId: _categoryId!,
            description: description,
            transactionDate: _date,
          );
        } else {
          final update = isIncome
              ? repository.updateIncome
              : repository.updateExpense;

          await update(
            transactionId: existing.id,
            accountId: _accountId!,
            amount: amount,
            categoryId: _categoryId!,
            description: description,
            transactionDate: _date,
          );
        }
      }

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
        _errorMessage = error is ArgumentError
            ? error.message?.toString() ?? 'تعذر حفظ العملية'
            : 'تعذر حفظ العملية. حاول مرة أخرى.';
      });
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف العملية'),
        content: const Text(
          'سيتم حذف هذه العملية وتحديث الأرصدة. لا يمكن التراجع عن ذلك.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(financeRepositoryProvider)
          .deleteTransaction(widget.existing!.id);

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
        _errorMessage = 'تعذر حذف العملية. حاول مرة أخرى.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final accounts = (ref.watch(accountsProvider).value ?? const <Account>[])
        .where((a) => a.isActive || a.id == widget.existing?.accountId)
        .toList();

    final categories =
        (ref.watch(categoriesProvider).value ?? const <Category>[])
            .where(
              (c) =>
                  c.type == _type && (c.isActive || c.id == _categoryId),
            )
            .toList();

    final isTransfer = _type == 'transfer';

    final canSave =
        !_isSaving && accounts.length >= (isTransfer ? 2 : 1);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isEditing ? 'تعديل العملية' : 'عملية جديدة',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'expense', label: Text('مصروف')),
                  ButtonSegment(value: 'income', label: Text('إيراد')),
                  ButtonSegment(value: 'transfer', label: Text('تحويل')),
                ],
                selected: {_type},
                onSelectionChanged: (_isEditing || _isSaving)
                    ? null
                    : (selection) {
                        setState(() {
                          _type = selection.first;
                          _categoryId = null;
                          _destinationAccountId = null;
                        });
                      },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'المبلغ',
                  suffixText: 'FCFA',
                  prefixIcon: Icon(Icons.payments_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final amount = int.tryParse(value ?? '');

                  if (amount == null || amount <= 0) {
                    return 'أدخل مبلغاً أكبر من صفر';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),

              if (accounts.isEmpty)
                const Text(
                  'أضف حساباً من صفحة الحسابات أولاً.',
                  style: TextStyle(color: Colors.red),
                )
              else ...[
                DropdownButtonFormField<int>(
                  initialValue: _accountId,
                  decoration: InputDecoration(
                    labelText: isTransfer ? 'من حساب' : 'الحساب',
                    prefixIcon: const Icon(Icons.account_balance_wallet),
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    for (final account in accounts)
                      DropdownMenuItem(
                        value: account.id,
                        child: Text(account.name),
                      ),
                  ],
                  onChanged: (value) => setState(() {
                    _accountId = value;

                    if (_destinationAccountId == value) {
                      _destinationAccountId = null;
                    }
                  }),
                  validator: (value) => value == null ? 'اختر الحساب' : null,
                ),
                const SizedBox(height: 16),
              ],

              if (isTransfer)
                DropdownButtonFormField<int>(
                  key: ValueKey('destination-$_accountId'),
                  initialValue: _destinationAccountId,
                  decoration: const InputDecoration(
                    labelText: 'إلى حساب',
                    prefixIcon: Icon(Icons.swap_horiz),
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final account in accounts)
                      if (account.id != _accountId)
                        DropdownMenuItem(
                          value: account.id,
                          child: Text(account.name),
                        ),
                  ],
                  onChanged: (value) =>
                      setState(() => _destinationAccountId = value),
                  validator: (value) =>
                      value == null ? 'اختر حساب الوجهة' : null,
                )
              else
                DropdownButtonFormField<int>(
                  key: ValueKey('category-$_type'),
                  initialValue: _categoryId,
                  decoration: const InputDecoration(
                    labelText: 'التصنيف',
                    prefixIcon: Icon(Icons.category_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final category in categories)
                      DropdownMenuItem(
                        value: category.id,
                        child: Text(category.name),
                      ),
                  ],
                  onChanged: (value) => setState(() => _categoryId = value),
                  validator: (value) => value == null ? 'اختر التصنيف' : null,
                ),
              const SizedBox(height: 16),

              InkWell(
                onTap: _isSaving ? null : _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'التاريخ',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                    border: OutlineInputBorder(),
                  ),
                  child: Text(DateFormatter.format(_date)),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'ملاحظة (اختياري)',
                  prefixIcon: Icon(Icons.notes),
                  border: OutlineInputBorder(),
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              ],

              const SizedBox(height: 20),

              FilledButton(
                onPressed: canSave ? _save : null,
                child: _isSaving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isEditing ? 'حفظ التعديلات' : 'حفظ العملية'),
              ),

              if (_isEditing) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _isSaving ? null : _delete,
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: const Text(
                    'حذف العملية',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
