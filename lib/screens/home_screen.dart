import 'package:flutter/material.dart';
import '../widgets/numeric_keypad.dart';
import '../database/repositories/transaccion_repository.dart'; // Import the repository
import '../models/transaccion.dart'; // Import the model
import '../database/repositories/caja_repository.dart'; // Import CajaRepository
import '../services/caja_events.dart';
import '../utils/formato_moneda.dart';

enum PaymentType { cash, bank }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  String _display = '0';
  String _currentInput = '';
  double _total = 0.0;
  String? _pendingOperation;
  double? _firstOperand;
  final TextEditingController _amountController = TextEditingController();
  final TransaccionRepository _transaccionRepository =
      TransaccionRepository(); // Add repository instance
  final CajaRepository _cajaRepository =
      CajaRepository(); // Add CajaRepository instance

  // Usar el formateador de moneda consistente
  String _formatNumber(double number) {
    return FormatoMoneda.formatear(number);
  }

  void _onNumberPressed(String number) {
    setState(() {
      if (_pendingOperation != null && _firstOperand == null) {
        _firstOperand = double.tryParse(_currentInput) ?? 0;
        _currentInput = number;
      } else {
        _currentInput = _currentInput == '0' ? number : _currentInput + number;
      }
      _updateDisplay();
    });
  }

  void _onDecimalPressed() {
    if (!_currentInput.contains('.')) {
      setState(() {
        _currentInput += _currentInput.isEmpty ? '0.' : '.';
        _updateDisplay();
      });
    }
  }

  void _onClear() {
    setState(() {
      if (_currentInput.isNotEmpty) {
        _currentInput = _currentInput.substring(0, _currentInput.length - 1);
        if (_currentInput.isEmpty) _currentInput = '0';
        _updateDisplay();
      }
    });
  }

  void _onClearAll() {
    setState(() {
      _currentInput = '';
      _display = '0';
      _firstOperand = null;
      _pendingOperation = null;
      _total = 0.0;
    });
  }

  void _updateDisplay() {
    if (_currentInput.isEmpty) {
      _display = '0';
    } else {
      _display = _currentInput;
    }
  }

  void _onOperationPressed(String operation) {
    final currentValue = double.tryParse(_currentInput) ?? 0;

    setState(() {
      if (_pendingOperation != null && _firstOperand != null) {
        // Realizar operación pendiente
        final result = _performOperation(
          _firstOperand!,
          currentValue,
          _pendingOperation!,
        );
        _firstOperand = result;
        _total = result; // Actualizar el total
        _display = result.toString();
      } else if (_currentInput.isNotEmpty) {
        _firstOperand = currentValue;
        _total = currentValue; // Establecer el total inicial
      }

      _pendingOperation = operation;
      _currentInput = ''; // Limpiar la entrada actual para el siguiente número
      _updateDisplay();
    });
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

  Future<void> _onSubmit() async {
    // Si hay una operación pendiente, realizarla primero
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
    } else if (_currentInput.isNotEmpty) {}

    // Show payment type selection dialog
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 400;

    final paymentType = await showDialog<PaymentType>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
            constraints: BoxConstraints(
              maxWidth: 500, // Maximum width for larger screens
            ),
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

                // Efectivo Button
                _buildPaymentMethodButton(
                  context: context,
                  icon: Icons.money,
                  title: 'EFECTIVO',
                  color: const Color(0xFF38B2AC),
                  onTap: () => Navigator.pop(context, PaymentType.cash),
                  isSmallScreen: isSmallScreen,
                ),

                const SizedBox(height: 16),

                // Bancario Button
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

    if (paymentType == null) return; // User dismissed the dialog

    if (paymentType == PaymentType.cash) {
      await _showPaymentDialog();
    } else {
      await _showBankPaymentDialog();
    }
  }

  Future<void> _showPaymentDialog() async {
    if (_total <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El total debe ser mayor a cero'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _amountController.clear();
    final clientNameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    // Variable para mantener el estado del diálogo
    double receivedAmountValue = 0;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
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
                      'Total: ${_formatNumber(_total)}',
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
                      controller: _amountController,
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
                      maxLength: 13, // Para manejar hasta 999,999,999
                      style: const TextStyle(fontSize: 16),
                      onChanged: (value) {
                        // Obtener posición actual del cursor
                        final cursorPos = _amountController.selection.baseOffset;
                        
                        // Limpiar el valor, mantener solo dígitos
                        final cleanValue = value.replaceAll(RegExp(r'[^\d]'), '');
                        
                        // Actualizar el valor numérico
                        receivedAmountValue = cleanValue.isEmpty ? 0 : double.parse(cleanValue);
                        
                        // Formatear con puntos como separadores de miles
                        String formatted = '';
                        if (cleanValue.isNotEmpty) {
                          final number = int.parse(cleanValue);
                          formatted = number.toString().replaceAllMapped(
                            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                            (Match m) => '${m[1]}.',
                          );
                        }
                        
                        // Calcular nueva posición del cursor
                        int newCursorPos = cursorPos;
                        if (value.length < formatted.length) {
                          // Se agregó un punto
                          newCursorPos += (formatted.length - value.length);
                        } else if (value.length > formatted.length) {
                          // Se eliminó un punto
                          newCursorPos -= (value.length - formatted.length);
                        }
                        
                        // Asegurar que la posición sea válida
                        newCursorPos = newCursorPos.clamp(0, formatted.length);
                        
                        // Actualizar el controlador
                        _amountController.value = TextEditingValue(
                          text: formatted,
                          selection: TextSelection.collapsed(offset: newCursorPos),
                        );
                        
                        // Actualizar el estado
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 12),
                    // Mostrar el vuelto en tiempo real
                    Builder(
                      builder: (context) {
                        final change = receivedAmountValue - _total;
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
                  if (receivedAmountValue >= _total) {
                    Navigator.pop(context, {
                      'amount': receivedAmountValue,
                      'clientName': clientNameController.text,
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'El monto recibido (₲${receivedAmountValue.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}) debe ser mayor o igual al total (₲${_total.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')})',
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

    if (receivedAmount != null && receivedAmount >= _total) {
      final change = receivedAmount - _total;

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
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
              _buildAmountRow('Total:', _formatNumber(_total)),
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
                  // Make onPressed async
                  Navigator.pop(context);
                  // Save the transaction
                  var cajaAbierta = await _cajaRepository.getCajaAbierta();
                  if (cajaAbierta == null) {
                    final bool success = await _promptAbrirCaja();
                    if (success) {
                      cajaAbierta = await _cajaRepository.getCajaAbierta();
                    }
                  }

                  if (cajaAbierta != null) {
                    final newTransaccion = Transaccion(
                      id: null, // Database will generate ID
                      numeroTransaccion: DateTime.now().millisecondsSinceEpoch
                          .toString(), // Generate a simple transaction number
                      montoTotal: _total, // Correct parameter name
                      metodoPago: 'efectivo',
                      // fechaHora defaults to DateTime.now()
                      nombreCliente:
                          result?['clientName'], // Client name for cash
                      // notas: null, // Optional
                    );
                    await _transaccionRepository.insertTransaccion(
                      newTransaccion,
                    );
                  }
                  _onClearAll();
                },
                child: const Text('Aceptar', style: TextStyle(fontSize: 16)),
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
            'El monto recibido (₲${receivedAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}) es menor al total (₲${_total.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')})',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showBankPaymentDialog() async {
    final clientNameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pago Bancario'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Total: ${_formatNumber(_total)}',
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
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
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

      // Show success dialog
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
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
              _buildAmountRow('Monto:', _formatNumber(_total)),
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
                // Make onPressed async
                Navigator.pop(context);
                // Save the transaction
                var cajaAbierta = await _cajaRepository.getCajaAbierta();
                if (cajaAbierta == null) {
                  final bool success = await _promptAbrirCaja();
                  if (success) {
                    cajaAbierta = await _cajaRepository.getCajaAbierta();
                  }
                }

                if (cajaAbierta != null) {
                  final newTransaccion = Transaccion(
                    id: null, // Database will generate ID
                    numeroTransaccion: DateTime.now().millisecondsSinceEpoch
                        .toString(), // Generate a simple transaction number
                    montoTotal: _total, // Correct parameter name
                    metodoPago: 'transferencia',
                    // fechaHora defaults to DateTime.now()
                    nombreCliente:
                        clientNameController.text, // Client name for bank
                    // notas: null, // Optional
                  );
                  await _transaccionRepository.insertTransaccion(
                    newTransaccion,
                  );
                }
                _onClearAll();
              },
              child: const Text('ACEPTAR'),
            ),
          ],
        ),
      );
    }
  }

  String _formatInput(String value, {bool format = false}) {
    // Solo permitir dígitos
    String digits = value.replaceAll(RegExp(r'[^\d]'), '');
    
    if (!format || digits.isEmpty) return digits;
    
    // Formatear con puntos como separadores de miles
    String formatted = '';
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        formatted += '.';
      }
      formatted += digits[i];
    }
    
    return formatted;
  }

  Future<bool> _promptAbrirCaja() async {
    final montoController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    
    // Variable para mantener el valor numérico real
    double montoReal = 0;

    if (!mounted) return false;

    final bool? cajaAbierta = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Abrir Caja'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: montoController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Monto Inicial',
              prefixText: '₲ ',
              border: OutlineInputBorder(),
              hintText: '0',
              counterText: '',
            ),
            maxLength: 10, // Límite razonable para montos
            onChanged: (value) {
              // Obtener la posición actual del cursor
              final cursorPos = montoController.selection.baseOffset;
              
              // Obtener solo los dígitos
              final cleanValue = _formatInput(value);
              
              // Formatear con puntos
              final formattedValue = _formatInput(cleanValue, format: true);
              
              // Calcular la nueva posición del cursor
              int newCursorPos = cursorPos;
              if (value.length < formattedValue.length) {
                // Se agregó un punto
                newCursorPos += (formattedValue.length - value.length);
              } else if (value.length > formattedValue.length) {
                // Se eliminó un punto
                newCursorPos -= (value.length - formattedValue.length);
              }
              
              // Asegurar que la posición del cursor sea válida
              newCursorPos = newCursorPos.clamp(0, formattedValue.length);
              
              // Actualizar el controlador con el valor formateado
              montoController.value = TextEditingValue(
                text: formattedValue,
                selection: TextSelection.collapsed(offset: newCursorPos),
              );
              
              // Actualizar el valor numérico real (sin formato)
              montoReal = double.tryParse(cleanValue) ?? 0.0;
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingrese un monto';
              }
              
              final cleanValue = _formatInput(value);
              final numericValue = double.tryParse(cleanValue);
              
              if (numericValue == null) {
                return 'Ingrese un monto válido';
              }
              
              if (numericValue <= 0) {
                return 'El monto debe ser mayor a cero';
              }
              
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              // Capture values needed after async gap
              final currentMounted = mounted;
              if (!currentMounted) return;
              
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(dialogContext);
              
              try {
                // Usar el valor numérico real que ya tenemos
                await _cajaRepository.abrirCaja(montoReal);
                CajaEvents().notificar(CajaStateEvent.abierta);
                
                navigator.pop(true);
                scaffoldMessenger.showSnackBar(
                  const SnackBar(content: Text('Caja abierta exitosamente')),
                );
              } catch (e) {
                navigator.pop(false);
                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text('Error al abrir caja: $e')),
                );
              }
            },
            child: const Text('Abrir'),
          ),
        ],
      ),
    );

    return cajaAbierta ?? false;
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

  @override
  void initState() {
    super.initState();
    // Inicializar con el teclado numérico listo para usar
    _onClearAll();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  // Widget auxiliar para mostrar filas de montos
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
    super.build(context); // Necesario para AutomaticKeepAliveClientMixin
    // Return only the body content
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Pantalla de visualización
          Container(
            padding: const EdgeInsets.all(24),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Operación actual
                if (_firstOperand != null || _pendingOperation != null)
                  Text(
                    '${_firstOperand != null ? _formatNumber(_firstOperand!) : ''} ${_pendingOperation ?? ''} ${_currentInput.isNotEmpty ? _formatNumber(double.parse(_currentInput)) : ''}',
                    style: const TextStyle(fontSize: 20, color: Colors.grey),
                    textAlign: TextAlign.right,
                  ),

                // Monto actual
                Text(
                  _formatNumber(double.tryParse(_display) ?? 0),
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

          // Teclado numérico
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
                onNumberPressed: _onNumberPressed,
                onDecimalPressed: _onDecimalPressed,
                onClear: _onClear,
                onClearAll: _onClearAll,
                onEqualsPressed: _onSubmit,
                onOperationPressed: _onOperationPressed,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
