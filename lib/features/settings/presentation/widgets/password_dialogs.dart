import 'package:material_ui/material_ui.dart';

/// كلمة مرور جديدة (مع تأكيدها) لتشفير نسخة احتياطية.
Future<String?> askNewPassword(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (_) =>
        const _PasswordDialog(title: 'تشفير النسخة الاحتياطية', confirm: true),
  );
}

/// كلمة مرور نسخة مشفرة موجودة.
Future<String?> askPassword(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (_) =>
        const _PasswordDialog(title: 'كلمة مرور النسخة', confirm: false),
  );
}

class _PasswordDialog extends StatefulWidget {
  final String title;
  final bool confirm;

  const _PasswordDialog({required this.title, required this.confirm});

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop(_passwordController.text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.confirm) ...[
                const Text(
                  'ستحتاج كلمة المرور عند الاستعادة. إذا نسيتها فلا توجد '
                  'أي طريقة لاسترجاع بيانات النسخة.',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _passwordController,
                obscureText: _obscure,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'كلمة المرور',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: (value) {
                  final text = value ?? '';

                  if (text.isEmpty) return 'أدخل كلمة المرور';

                  if (widget.confirm && text.length < 8) {
                    return 'ثمانية أحرف على الأقل';
                  }

                  return null;
                },
              ),
              if (widget.confirm) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmController,
                  obscureText: _obscure,
                  decoration: const InputDecoration(
                    labelText: 'تأكيد كلمة المرور',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'كلمتا المرور غير متطابقتين';
                    }

                    return null;
                  },
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(widget.confirm ? 'تشفير وحفظ' : 'استعادة'),
        ),
      ],
    );
  }
}