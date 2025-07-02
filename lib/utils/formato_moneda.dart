import 'package:intl/intl.dart';

class FormatoMoneda {
  static final NumberFormat _formatoGuarani = NumberFormat.currency(
    symbol: '₲',
    decimalDigits: 0,
    locale: 'es_PY',
  );

  static String formatear(num cantidad) {
    return _formatoGuarani.format(cantidad);
  }
}
