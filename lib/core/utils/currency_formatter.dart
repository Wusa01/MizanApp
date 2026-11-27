import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _formatter = NumberFormat.decimalPattern('fr_FR');

  static String format(int amount) {
    return '${_formatter.format(amount)} FCFA';
  }
}
