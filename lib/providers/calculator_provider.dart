import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // Necesario para IconData, Color, etc.

class CalculatorProvider with ChangeNotifier {
  String _display = '0';
  String _currentInput = '';
  double _total = 0.0;
  String? _pendingOperation;
  double? _firstOperand;
  final List<int> _quickAmountHistory = [];

  String get display => _display;
  double get total => _total;
  String get currentInput => _currentInput;
  String? get pendingOperation => _pendingOperation;
  double? get firstOperand => _firstOperand;

  void _updateDisplay() {
    if (_currentInput.isEmpty) {
      _display = '0';
    } else {
      _display = _currentInput;
    }
    notifyListeners();
  }

  void onNumberPressed(String number) {
    if (_pendingOperation != null && _firstOperand == null) {
      _firstOperand = double.tryParse(_currentInput) ?? 0;
      _currentInput = number;
    } else {
      _currentInput = _currentInput == '0' ? number : _currentInput + number;
    }
    _updateDisplay();
  }

  void onDecimalPressed() {
    if (!_currentInput.contains('.')) {
      _currentInput += _currentInput.isEmpty ? '0.' : '.';
      _updateDisplay();
    }
  }

  void onQuickAmountPressed(int amount) {
    final currentValue = double.tryParse(_currentInput) ?? 0;
    final newValue = currentValue + amount;
    _currentInput = newValue.toStringAsFixed(0);
    _total = newValue.toDouble();
    _quickAmountHistory.add(amount);
    _updateDisplay();
  }

  void onClear() {
    if (_quickAmountHistory.isNotEmpty) {
      final lastQuick = _quickAmountHistory.removeLast();
      final currentValue = double.tryParse(_currentInput) ?? 0;
      final newValue = (currentValue - lastQuick).clamp(0, double.infinity);
      _currentInput = newValue == 0 ? '' : newValue.toStringAsFixed(0);
      _total = newValue.toDouble();
      _updateDisplay();
    } else if (_currentInput.isNotEmpty) {
      _currentInput = _currentInput.substring(0, _currentInput.length - 1);
      if (_currentInput.isEmpty) _currentInput = '0';
      _updateDisplay();
    }
  }

  void onClearAll() {
    _currentInput = '';
    _display = '0';
    _firstOperand = null;
    _pendingOperation = null;
    _total = 0.0;
    _quickAmountHistory.clear();
    notifyListeners();
  }

  void onOperationPressed(String operation) {
    final currentValue = double.tryParse(_currentInput) ?? 0;

    if (_pendingOperation != null && _firstOperand != null) {
      final result = _performOperation(
        _firstOperand!,
        currentValue,
        _pendingOperation!,
      );
      _firstOperand = result;
      _total = result;
      _display = result.toString();
    } else if (_currentInput.isNotEmpty) {
      _firstOperand = currentValue;
      _total = currentValue;
    }

    _pendingOperation = operation;
    _currentInput = '';
    _updateDisplay();
  }

  double _performOperation(double a, double b, String operation) {
    switch (operation) {
      case '+':
        return a + b;
      case '-':
        return a - b;
      case '×':
        return a * b;
      default:
        return b;
    }
  }

  void onSubmit() {
    if (_pendingOperation != null && _firstOperand != null) {
      final currentValue = double.tryParse(_currentInput) ?? 0;
      final result = _performOperation(
        _firstOperand!,
        currentValue,
        _pendingOperation!,
      );
      _total = result;
      _currentInput = result.toString();
      _firstOperand = null;
      _pendingOperation = null;
      _updateDisplay();
    } else if (_currentInput.isNotEmpty) {
      final currentValue = double.tryParse(_currentInput) ?? 0;
      _total = currentValue;
      _currentInput = currentValue.toString();
      _firstOperand = null;
      _pendingOperation = null;
      _updateDisplay();
    }
  }
}
