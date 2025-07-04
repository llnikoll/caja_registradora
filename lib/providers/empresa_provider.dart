import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EmpresaProvider extends ChangeNotifier {
  static const _iconKey = 'empresa_icon_code_point';
  static const _colorKey = 'empresa_icon_color';

  IconData _iconData = Icons.store;
  Color _iconColor = Colors.blue;

  IconData get iconData => _iconData;
  Color get iconColor => _iconColor;

  // Lista de iconos sugeridos para la empresa
  List<IconData> get listaIconos => const [
    Icons.store,
    Icons.shopping_cart,
    Icons.local_cafe,
    Icons.fastfood,
    Icons.restaurant,
    Icons.local_grocery_store,
    Icons.business,
    Icons.home,
    Icons.star,
    Icons.attach_money,
  ];

  // Lista de colores sugeridos
  List<Color> get listaColores => const [
    Colors.blue,
    Colors.green,
    Colors.red,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.brown,
    Colors.indigo,
    Colors.pink,
    Colors.cyan,
  ];

  EmpresaProvider() {
    _loadIcon();
  }

  Future<void> _loadIcon() async {
    final prefs = await SharedPreferences.getInstance();
    final codePoint = prefs.getInt(_iconKey);
    final colorValue = prefs.getInt(_colorKey);
    if (codePoint != null) {
      _iconData = IconData(codePoint, fontFamily: 'MaterialIcons');
    }
    if (colorValue != null) {
      _iconColor = Color(colorValue);
    }
    notifyListeners();
  }

  Future<void> setIcon(IconData icon, Color color) async {
    _iconData = icon;
    _iconColor = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_iconKey, icon.codePoint);
    // Usar toARGB32() para guardar el color de forma explícita
    await prefs.setInt(_colorKey, color.toARGB32());
    notifyListeners();
  }

  void cambiarIcono(IconData icon) {
    setIcon(icon, _iconColor);
  }

  void cambiarColor(Color color) {
    setIcon(_iconData, color);
  }
}
