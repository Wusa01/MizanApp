class DefaultCategory {
  final String name;
  final String type;

  const DefaultCategory(this.name, this.type);
}

const defaultCategories = [
  // الإيرادات
  DefaultCategory('الراتب', 'income'),
  DefaultCategory('مبيعات', 'income'),
  DefaultCategory('أرباح تجارية', 'income'),
  DefaultCategory('هدايا', 'income'),
  DefaultCategory('إيرادات أخرى', 'income'),

  // المصروفات
  DefaultCategory('الطعام', 'expense'),
  DefaultCategory('المواصلات', 'expense'),
  DefaultCategory('السكن', 'expense'),
  DefaultCategory('الفواتير', 'expense'),
  DefaultCategory('الصحة', 'expense'),
  DefaultCategory('التعليم', 'expense'),
  DefaultCategory('التسوق', 'expense'),
  DefaultCategory('ترفيه', 'expense'),
  DefaultCategory('مشتريات المتجر', 'expense'),
  DefaultCategory('مصروفات أخرى', 'expense'),
];
