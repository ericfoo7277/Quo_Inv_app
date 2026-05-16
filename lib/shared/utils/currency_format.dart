import 'package:intl/intl.dart';

class AppCurrencyFormat {
  const AppCurrencyFormat._();

  static String normalize(String? currency) {
    final code = currency?.trim().toUpperCase();
    return code == null || code.isEmpty ? 'MYR' : code;
  }

  static NumberFormat formatter(String? currency) {
    final code = normalize(currency);
    if (code == 'MYR') {
      return NumberFormat.currency(
        locale: 'ms_MY',
        name: 'MYR',
        symbol: 'RM ',
        decimalDigits: 2,
      );
    }
    return NumberFormat.simpleCurrency(name: code);
  }

  static String format(num amount, {String? currency}) {
    return formatter(currency).format(amount);
  }
}