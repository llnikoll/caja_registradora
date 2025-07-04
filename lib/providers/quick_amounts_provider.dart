import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuickAmountsProvider extends ChangeNotifier {
  List<int> _amounts = [15000, 18000, 20000];

  List<int> get amounts => List.unmodifiable(_amounts);

  QuickAmountsProvider() {
    loadFromPrefs();
  }

  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _amounts = [
      prefs.getInt('quick_amount_1') ?? 15000,
      prefs.getInt('quick_amount_2') ?? 18000,
      prefs.getInt('quick_amount_3') ?? 20000,
    ];
    notifyListeners();
  }

  Future<void> setAmounts(List<int> newAmounts) async {
    if (newAmounts.length != 3) return;
    _amounts = List.from(newAmounts);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('quick_amount_1', newAmounts[0]);
    await prefs.setInt('quick_amount_2', newAmounts[1]);
    await prefs.setInt('quick_amount_3', newAmounts[2]);
    notifyListeners();
  }
}
