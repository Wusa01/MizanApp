import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';
import '../../transactions/providers/transactions_providers.dart';

class CategoriesPage extends ConsumerStatefulWidget {
  const CategoriesPage({super.key});

  @override
  ConsumerState<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends ConsumerState<CategoriesPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // التبويب الأول: المصروفات، الثاني: الدخل.
  String get _currentType => _tabController.index == 0 ? 'expense' : 'income';

  Future<void> _openDialog({Category? category}) {
    return showDialog<bool>(
      context: context,
      builder: (_) => _CategoryDialog(type: _currentType, category: category),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('التصنيفات'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'المصروفات'),
            Tab(text: 'الدخل'),
          ],
        ),
      ),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            const Center(child: Text('تعذر تحميل التصنيفات')),
        data: (all) => TabBarView(
          controller: _tabController,
          children: [
            _buildList(all.where((c) => c.type == 'expense').toList()),
            _buildList(all.where((c) => c.type == 'income').toList()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openDialog(),
        icon: const Icon(Icons.add),
        label: const Text('تصنيف جديد'),
      ),
    );
  }

  Widget _buildList(List<Category> items) {
    if (items.isEmpty) {
      return const Center(child: Text('لا توجد تصنيفات'));
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final category = items[index];

        return Card(
          child: ListTile(
            onTap: () => _openDialog(category: category),
            leading: Icon(
              Icons.label_outline,
              color: category.isActive ? null : Colors.grey,
            ),
            title: Text(
              category.name,
              style: TextStyle(color: category.isActive ? null : Colors.grey),
            ),
            subtitle: category.isActive ? null : const Text('غير نشط'),
            trailing: const Icon(Icons.edit_outlined, size: 20),
          ),
        );
      },
    );
  }
}

class _CategoryDialog extends ConsumerStatefulWidget {
  final String type;
  final Category? category;

  const _CategoryDialog({required this.type, this.category});

  @override
  ConsumerState<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends ConsumerState<_CategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;

  bool _isSaving = false;
  String? _errorMessage;

  bool get _isEditing => widget.category != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
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
        _errorMessage = error is ArgumentError
            ? error.message?.toString()
            : 'تعذر الحفظ. حاول مرة أخرى.';
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final repository = ref.read(financeRepositoryProvider);
    final name = _nameController.text.trim();
    final category = widget.category;

    await _run(() async {
      if (category == null) {
        await repository.createCategory(name: name, type: widget.type);
      } else {
        await repository.updateCategory(categoryId: category.id, name: name);
      }
    });
  }

  Future<void> _toggleActive() {
    final category = widget.category!;
    final repository = ref.read(financeRepositoryProvider);

    return _run(
      () => repository.setCategoryActive(category.id, !category.isActive),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'تعديل التصنيف' : 'تصنيف جديد'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'اسم التصنيف',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'يرجى إدخال اسم التصنيف';
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
                  widget.category!.isActive
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                label: Text(
                  widget.category!.isActive
                      ? 'تعطيل التصنيف'
                      : 'إعادة تفعيل التصنيف',
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: Text(_isEditing ? 'حفظ التعديلات' : 'حفظ'),
        ),
      ],
    );
  }
}
