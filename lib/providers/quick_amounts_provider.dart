import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuickAmountsProvider extends ChangeNotifier {
  static const String _quickAmount1Key = 'quick_amount_1';
  static const String _quickAmount2Key = 'quick_amount_2';
  static const String _quickAmount3Key = 'quick_amount_3';

  List<int> _amounts = [15000, 18000, 20000];

  List<int> get amounts => List.unmodifiable(_amounts);

  QuickAmountsProvider() {
    loadFromPrefs();
  }

  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _amounts = [
      prefs.getInt(_quickAmount1Key) ?? 15000,
      prefs.getInt(_quickAmount2Key) ?? 18000,
      prefs.getInt(_quickAmount3Key) ?? 20000,
    ];
    notifyListeners();
  }

  Future<void> setAmounts(List<int> newAmounts) async {
    if (newAmounts.length != 3) return;
    _amounts = List.from(newAmounts);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_quickAmount1Key, newAmounts[0]);
    await prefs.setInt(_quickAmount2Key, newAmounts[1]);
    await prefs.setInt(_quickAmount3Key, newAmounts[2]);
    notifyListeners();
  }
}
