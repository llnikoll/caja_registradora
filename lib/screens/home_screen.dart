import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/numeric_keypad.dart';
import '../database/repositories/transaccion_repository.dart';
import '../models/transaccion.dart';
import '../database/repositories/caja_repository.dart';
import '../utils/formato_moneda.dart';
import '../providers/quick_amounts_provider.dart';
import '../providers/calculator_provider.dart';

enum PaymentType { cash, bank }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _Home2ScreenState();
}

class _Home2ScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final TransaccionRepository _transaccionRepository = TransaccionRepository();
  final CajaRepository _cajaRepository = CajaRepository();

  String _formatNumber(double number) {
    return FormatoMoneda.formatear(number);
  }

  Future<void> _onSubmit(CalculatorProvider calculatorProvider) async {
    calculatorProvider.onSubmit();
    final total = calculatorProvider.total;

    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 400;

    final paymentType = await showDialog<PaymentType>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'MÉTODO DE PAGO',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 18 : 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2D3748),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Seleccione cómo desea realizar el pago:',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    color: const Color(0xFF4A5568),
                  ),
                ),
                const SizedBox(height: 24),
                _buildPaymentMethodButton(
                  context: context,
                  icon: Icons.money,
                  title: 'EFECTIVO',
                  color: const Color(0xFF38B2AC),
                  onTap: () => Navigator.pop(context, PaymentType.cash),
                  isSmallScreen: isSmallScreen,
                ),
                const SizedBox(height: 16),
                _buildPaymentMethodButton(
                  context: context,
                  icon: Icons.credit_card,
                  title: 'TRANSFERENCIA BANCARIA',
                  color: const Color(0xFF4299E1),
                  onTap: () => Navigator.pop(context, PaymentType.bank),
                  isSmallScreen: isSmallScreen,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'CANCELAR',
                      style: TextStyle(
                        color: Color(0xFF718096),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (paymentType == null) return;

    if (paymentType == PaymentType.cash) {
      await _showPaymentDialog(total, calculatorProvider.onClearAll);
    } else {
      await _showBankPaymentDialog(total, calculatorProvider.onClearAll);
    }
  }

  Future<void> _showPaymentDialog(double total, VoidCallback onClearAll) async {
    if (total <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El total debe ser mayor a cero'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final amountController = TextEditingController();
    final clientNameController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    double receivedAmountValue = 0;

    final dialogContext = context;
    final result = await showDialog<Map<String, dynamic>>(
      context: dialogContext,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Pago en Efectivo'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Total: ${_formatNumber(total)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: clientNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del cliente (opcional)',
                        hintText: 'Cliente ocasional',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Monto recibido',
                        prefixText: '₲',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        counterText: '',
                      ),
                      maxLength: 13,
                      style: const TextStyle(fontSize: 16),
                      onChanged: (value) {
                        final cursorPos = amountController.selection.baseOffset;
                        final cleanValue = value.replaceAll(
                          RegExp(r'[^\d]'),
                          '',
                        );
                        receivedAmountValue = cleanValue.isEmpty
                            ? 0
                            : double.parse(cleanValue);
                        String formatted = '';
                        if (cleanValue.isNotEmpty) {
                          final number = int.parse(cleanValue);
                          formatted = number.toString().replaceAllMapped(
                            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                            (Match m) => '${m[1]}.',
                          );
                        }
                        int newCursorPos = cursorPos;
                        if (value.length < formatted.length) {
                          newCursorPos += (formatted.length - value.length);
                        } else if (value.length > formatted.length) {
                          newCursorPos -= (value.length - formatted.length);
                        }
                        newCursorPos = newCursorPos.clamp(0, formatted.length);
                        amountController.value = TextEditingValue(
                          text: formatted,
                          selection: TextSelection.collapsed(
                            offset: newCursorPos,
                          ),
                        );
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 12),
                    Builder(
                      builder: (context) {
                        final change = receivedAmountValue - total;
                        final changeText = 'Vuelto: ${_formatNumber(change)}';
                        return Column(
                          children: [
                            Text(
                              'Recibido: ${_formatNumber(receivedAmountValue)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              changeText,
                              style: TextStyle(
                                fontSize: 18,
                                color: change >= 0 ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: const Text('CANCELAR'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (amountController.text.isEmpty ||
                      receivedAmountValue >= total) {
                    final double finalReceivedAmount =
                        amountController.text.isEmpty
                        ? total
                        : receivedAmountValue;
                    Navigator.pop(context, {
                      'amount': finalReceivedAmount,
                      'clientName': clientNameController.text,
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'El monto recibido (₲${receivedAmountValue.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}) debe ser mayor o igual al total (₲${total.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')})',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                child: const Text('ACEPTAR', style: TextStyle(fontSize: 16)),
              ),
            ],
          );
        },
      ),
    );

    final receivedAmount = result?['amount'] as double?;

    if (receivedAmount != null && receivedAmount >= total) {
      final change = receivedAmount - total;

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (alertContext) => AlertDialog(
          title: const Text(
            'Venta Realizada',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildAmountRow(
                'Cliente:',
                result?['clientName'] ?? 'Sin nombre',
              ),
              const SizedBox(height: 8),
              _buildAmountRow('Total:', _formatNumber(total)),
              _buildAmountRow('Recibido:', _formatNumber(receivedAmount)),
              const SizedBox(height: 8),
              _buildAmountRow('VUELTO:', _formatNumber(change), isTotal: true),
            ],
          ),
          actions: [
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                onPressed: () async {
                  Navigator.pop(alertContext);
                  if (!mounted) return;
                  var cajaAbierta = await _cajaRepository.getCajaAbierta();
                  if (cajaAbierta == null) {
                    if (!mounted) return;
                    final bool success = await _cajaRepository
                        .promptAndOpenCaja(context);
                    if (!mounted) return;
                    if (success) {
                      cajaAbierta = await _cajaRepository.getCajaAbierta();
                    }
                  }

                  if (cajaAbierta != null) {
                    final newTransaccion = Transaccion(
                      id: null,
                      numeroTransaccion: DateTime.now().millisecondsSinceEpoch
                          .toString(),
                      montoTotal: total,
                      metodoPago: 'efectivo',
                      nombreCliente: result?['clientName'],
                    );
                    await _transaccionRepository.insertTransaccion(
                      newTransaccion,
                    );
                  }
                  onClearAll();
                },
                child: const Text('ACEPTAR', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      );
    } else if (receivedAmount != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'El monto recibido (₲${receivedAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}) es menor al total (₲${total.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')})',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showBankPaymentDialog(
    double total,
    VoidCallback onClearAll,
  ) async {
    final clientNameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final dialogContext = context;
    final result = await showDialog<bool>(
      context: dialogContext,
      builder: (dialogBuilderContext) => AlertDialog(
        title: const Text('Pago Bancario'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Total: ${_formatNumber(total)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: clientNameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del cliente o transacción',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese un nombre';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogBuilderContext, false),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogBuilderContext, true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('CONFIRMAR'),
          ),
        ],
      ),
    );

    if (result == true) {
      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (alertContext) {
          return AlertDialog(
            title: const Text(
              'Pago Realizado',
              style: TextStyle(color: Colors.green),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Pago bancario realizado con éxito',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                _buildAmountRow('Cliente:', clientNameController.text),
                _buildAmountRow('Monto:', _formatNumber(total)),
                const SizedBox(height: 8),
                const Text(
                  'Gracias por su compra!',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.pop(alertContext);
                  if (!mounted) return;
                  var cajaAbierta = await _cajaRepository.getCajaAbierta();
                  if (cajaAbierta == null) {
                    if (!mounted) return;
                    final bool success = await _cajaRepository
                        .promptAndOpenCaja(context);
                    if (!mounted) return;
                    if (success) {
                      cajaAbierta = await _cajaRepository.getCajaAbierta();
                    }
                  }

                  if (cajaAbierta != null) {
                    final newTransaccion = Transaccion(
                      id: null,
                      numeroTransaccion: DateTime.now().millisecondsSinceEpoch
                          .toString(),
                      montoTotal: total,
                      metodoPago: 'transferencia',
                      nombreCliente: clientNameController.text,
                    );
                    await _transaccionRepository.insertTransaccion(
                      newTransaccion,
                    );
                  }
                  onClearAll();
                },
                child: const Text('ACEPTAR'),
              ),
            ],
          );
        },
      );
    }
  }

  Widget _buildPaymentMethodButton({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
    required bool isSmallScreen,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: isSmallScreen ? 14 : 18,
            horizontal: isSmallScreen ? 12 : 16,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color, width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: isSmallScreen ? 20 : 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.w600,
                    color: Color.fromARGB(
                      (color.a * 255).round(),
                      (color.r * 255).round(),
                      (color.g * 255).round(),
                      ((color.b * 255).round() - 20).clamp(0, 255),
                    ),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Color.fromARGB(
                  (color.a * 255).round(),
                  (color.r * 255).round(),
                  (color.g * 255).round(),
                  ((color.b * 255).round() - 20).clamp(0, 255),
                ),
                size: isSmallScreen ? 20 : 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmountRow(String label, String amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 18 : 16,
            color: isTotal ? Colors.grey[800] : Colors.grey[600],
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: isTotal ? 20 : 18,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? Colors.green : Colors.black87,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final quickProvider = Provider.of<QuickAmountsProvider>(context);
    final calculatorProvider = Provider.of<CalculatorProvider>(context);
    final quickAmounts = quickProvider.amounts;
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (calculatorProvider.firstOperand != null ||
                    calculatorProvider.pendingOperation != null)
                  Text(
                    '${calculatorProvider.firstOperand != null ? _formatNumber(calculatorProvider.firstOperand!) : ''} ${calculatorProvider.pendingOperation ?? ''} ${calculatorProvider.currentInput.isNotEmpty ? _formatNumber(double.parse(calculatorProvider.currentInput)) : ''}',
                    style: const TextStyle(fontSize: 20, color: Colors.grey),
                    textAlign: TextAlign.right,
                  ),
                Text(
                  _formatNumber(
                    double.tryParse(calculatorProvider.display) ?? 0,
                  ),
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                  textAlign: TextAlign.right,
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromRGBO(0, 0, 0, 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: NumericKeypad(
                onNumberPressed: calculatorProvider.onNumberPressed,
                onDecimalPressed: calculatorProvider.onDecimalPressed,
                onClear: calculatorProvider.onClear,
                onClearAll: calculatorProvider.onClearAll,
                onEqualsPressed: () => _onSubmit(calculatorProvider),
                onOperationPressed: calculatorProvider.onOperationPressed,
                quickAmounts: quickAmounts,
                onQuickAmountPressed: calculatorProvider.onQuickAmountPressed,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
