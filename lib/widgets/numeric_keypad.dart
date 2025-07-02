import 'package:flutter/material.dart';

class NumericKeypad extends StatelessWidget {
  final Function(String) onNumberPressed;
  final VoidCallback onDecimalPressed;
  final VoidCallback onClear;
  final VoidCallback onClearAll;
  final VoidCallback onEqualsPressed;
  final Function(String) onOperationPressed;
  final bool showOperations;

  // Available operations
  static const List<Map<String, dynamic>> operations = [
    {'symbol': '+', 'icon': Icons.add},
    {'symbol': '-', 'icon': Icons.remove},
    {'symbol': '×', 'icon': Icons.close},
  ];

  const NumericKeypad({
    super.key,
    required this.onNumberPressed,
    required this.onDecimalPressed,
    required this.onClear,
    required this.onClearAll,
    required this.onEqualsPressed,
    required this.onOperationPressed,
    this.showOperations = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(0, 0, 0, 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Calculate button size based on available height
          final buttonHeight =
              (constraints.maxHeight - 48) / 5; // 5 rows with padding
          final fontSize = buttonHeight * 0.4; // Responsive font size
          final iconSize = buttonHeight * 0.5; // Responsive icon size

          return Column(
            children: [
              // Row 1: 7 8 9 +
              Expanded(
                child: Row(
                  children: [
                    _buildButton(
                      '7',
                      fontSize,
                      iconSize,
                      onPressed: () => onNumberPressed('7'),
                    ),
                    _buildButton(
                      '8',
                      fontSize,
                      iconSize,
                      onPressed: () => onNumberPressed('8'),
                    ),
                    _buildButton(
                      '9',
                      fontSize,
                      iconSize,
                      onPressed: () => onNumberPressed('9'),
                    ),
                    _buildOperationButton(operations[0], fontSize, iconSize),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Row 2: 4 5 6 -
              Expanded(
                child: Row(
                  children: [
                    _buildButton(
                      '4',
                      fontSize,
                      iconSize,
                      onPressed: () => onNumberPressed('4'),
                    ),
                    _buildButton(
                      '5',
                      fontSize,
                      iconSize,
                      onPressed: () => onNumberPressed('5'),
                    ),
                    _buildButton(
                      '6',
                      fontSize,
                      iconSize,
                      onPressed: () => onNumberPressed('6'),
                    ),
                    _buildOperationButton(operations[1], fontSize, iconSize),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Row 3: 1 2 3 ×
              Expanded(
                child: Row(
                  children: [
                    _buildButton(
                      '1',
                      fontSize,
                      iconSize,
                      onPressed: () => onNumberPressed('1'),
                    ),
                    _buildButton(
                      '2',
                      fontSize,
                      iconSize,
                      onPressed: () => onNumberPressed('2'),
                    ),
                    _buildButton(
                      '3',
                      fontSize,
                      iconSize,
                      onPressed: () => onNumberPressed('3'),
                    ),
                    _buildOperationButton(operations[2], fontSize, iconSize),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Row 4: C 0 . =
              Expanded(
                child: Row(
                  children: [
                    _buildButton(
                      'C',
                      fontSize,
                      iconSize,
                      color: Colors.red[50],
                      textColor: Colors.red,
                      onPressed: onClearAll,
                    ),
                    _buildButton(
                      '0',
                      fontSize,
                      iconSize,
                      onPressed: () => onNumberPressed('0'),
                    ),
                    _buildButton(
                      '.',
                      fontSize,
                      iconSize,
                      onPressed: onDecimalPressed,
                    ),
                    _buildButton(
                      '=',
                      fontSize,
                      iconSize,
                      color: Colors.blue,
                      textColor: Colors.white,
                      onPressed: onEqualsPressed,
                    ),
                  ],
                ),
              ),
              // Row 5: Delete (backspace)
              if (showOperations) ...[
                const SizedBox(height: 8),
                Expanded(
                  child: Row(
                    children: [
                      _buildButton(
                        '⌫',
                        fontSize,
                        iconSize,
                        color: Colors.orange[50],
                        textColor: Colors.orange,
                        onPressed: onClear,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildOperationButton(
    Map<String, dynamic> operation,
    double fontSize,
    double iconSize,
  ) {
    return _buildButton(
      operation['symbol'] as String,
      fontSize,
      iconSize,
      color: Colors.blue[50],
      textColor: Colors.blue,
      onPressed: () => onOperationPressed(operation['symbol'] as String),
    );
  }

  Widget _buildButton(
    String text,
    double fontSize,
    double iconSize, {
    Color? color,
    Color? textColor,
    VoidCallback? onPressed,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
        child: Material(
          color: color ?? Colors.white,
          borderRadius: BorderRadius.circular(8),
          elevation: 2,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              alignment: Alignment.center,
              child: Text(
                text,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w500,
                  color: textColor ?? Colors.black87,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
