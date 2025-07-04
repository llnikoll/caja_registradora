import 'package:flutter/material.dart';

class NumericKeypad extends StatelessWidget {
  final Function(String) onNumberPressed;
  final VoidCallback onDecimalPressed;
  final VoidCallback onClear;
  final VoidCallback onClearAll;
  final VoidCallback onEqualsPressed;
  final Function(String) onOperationPressed;
  final bool showOperations;
  final List<int> quickAmounts;
  final void Function(int) onQuickAmountPressed;

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
    this.quickAmounts = const [15000, 18000, 20000],
    required this.onQuickAmountPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(
              (colorScheme.shadow.r * 255.0).round() & 0xff,
              (colorScheme.shadow.g * 255.0).round() & 0xff,
              (colorScheme.shadow.b * 255.0).round() & 0xff,
              0.1,
            ),
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
                      context,
                      '7',
                      fontSize,
                      iconSize,
                      onPressed: () => onNumberPressed('7'),
                    ),
                    _buildButton(
                      context,
                      '8',
                      fontSize,
                      iconSize,
                      onPressed: () => onNumberPressed('8'),
                    ),
                    _buildButton(
                      context,
                      '9',
                      fontSize,
                      iconSize,
                      onPressed: () => onNumberPressed('9'),
                    ),
                    _buildOperationButton(
                      context,
                      operations[0],
                      fontSize,
                      iconSize,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Row 2: 4 5 6 -
              Expanded(
                child: Row(
                  children: [
                    _buildButton(
                      context,
                      '4',
                      fontSize,
                      iconSize,
                      onPressed: () => onNumberPressed('4'),
                    ),
                    _buildButton(
                      context,
                      '5',
                      fontSize,
                      iconSize,
                      onPressed: () => onNumberPressed('5'),
                    ),
                    _buildButton(
                      context,
                      '6',
                      fontSize,
                      iconSize,
                      onPressed: () => onNumberPressed('6'),
                    ),
                    _buildOperationButton(
                      context,
                      operations[1],
                      fontSize,
                      iconSize,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Row 3: 1 2 3 ×
              Expanded(
                child: Row(
                  children: [
                    _buildButton(
                      context,
                      '1',
                      fontSize,
                      iconSize,
                      onPressed: () => onNumberPressed('1'),
                    ),
                    _buildButton(
                      context,
                      '2',
                      fontSize,
                      iconSize,
                      onPressed: () => onNumberPressed('2'),
                    ),
                    _buildButton(
                      context,
                      '3',
                      fontSize,
                      iconSize,
                      onPressed: () => onNumberPressed('3'),
                    ),
                    _buildOperationButton(
                      context,
                      operations[2],
                      fontSize,
                      iconSize,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Row 4: C 0 . =
              Expanded(
                child: Row(
                  children: [
                    _buildButton(
                      context,
                      'C',
                      fontSize,
                      iconSize,
                      color: colorScheme.errorContainer,
                      textColor: colorScheme.onErrorContainer,
                      onPressed: onClearAll,
                    ),
                    _buildButton(
                      context,
                      '0',
                      fontSize,
                      iconSize,
                      onPressed: () => onNumberPressed('0'),
                    ),
                    _buildButton(
                      context,
                      '.',
                      fontSize,
                      iconSize,
                      onPressed: onDecimalPressed,
                    ),
                    _buildButton(
                      context,
                      '=',
                      fontSize,
                      iconSize,
                      color: colorScheme.primary,
                      textColor: colorScheme.onPrimary,
                      onPressed: onEqualsPressed,
                    ),
                  ],
                ),
              ),
              // Row 5: Quick Amounts + Delete (backspace)
              if (showOperations) ...[
                const SizedBox(height: 8),
                Expanded(
                  child: Row(
                    children: [
                      for (final amount in quickAmounts)
                        _buildButton(
                          context,
                          '₲${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                          fontSize * 0.9,
                          iconSize * 0.9,
                          color: colorScheme.tertiaryContainer,
                          textColor: colorScheme.onTertiaryContainer,
                          onPressed: () => onQuickAmountPressed(amount),
                        ),
                      _buildButton(
                        context,
                        '⌫',
                        fontSize,
                        iconSize,
                        color: colorScheme.secondaryContainer,
                        textColor: colorScheme.onSecondaryContainer,
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
    BuildContext context,
    Map<String, dynamic> operation,
    double fontSize,
    double iconSize,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return _buildButton(
      context,
      operation['symbol'] as String,
      fontSize,
      iconSize,
      color: colorScheme.primaryContainer,
      textColor: colorScheme.onPrimaryContainer,
      onPressed: () => onOperationPressed(operation['symbol'] as String),
    );
  }

  Widget _buildButton(
    BuildContext context,
    String text,
    double fontSize,
    double iconSize, {
    Color? color,
    Color? textColor,
    VoidCallback? onPressed,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
        child: Material(
          color: color ?? colorScheme.surface,
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
                  color: textColor ?? colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
