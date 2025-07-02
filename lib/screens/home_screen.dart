import 'package:flutter/material.dart';
import '../widgets/numeric_keypad.dart';
import 'reportes_screen.dart';

enum PaymentType { cash, bank }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _display = '0';
  String _currentInput = '';
  double _total = 0.0;
  String? _pendingOperation;
  double? _firstOperand;
  final TextEditingController _amountController = TextEditingController();

  // Formatear número con separadores de miles y símbolo de Guaraníes
  String _formatNumber(double number) {
    return '₲${number.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
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

    // Variable para mantener el estado del diálogo
    double receivedAmountValue = 0;

    final receivedAmount = await showDialog<double>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Monto Recibido'),
            content: Column(
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
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Monto recibido',
                    prefixText: '₲',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                  ),
                  style: const TextStyle(fontSize: 18),
                  onChanged: (value) {
                    // Remover todos los caracteres no numéricos excepto el punto
                    final cleanValue = value.replaceAll(RegExp(r'[^\d]'), '');

                    if (cleanValue.isNotEmpty) {
                      final parsed = int.tryParse(cleanValue) ?? 0;
                      receivedAmountValue = parsed.toDouble();

                      // Formatear el número con separadores de miles
                      final formatted = _formatNumber(
                        parsed.toDouble(),
                      ).substring(1); // Remover el símbolo ₲

                      // Actualizar el controlador sin notificar para evitar bucle infinito
                      if (_amountController.text != formatted) {
                        _amountController.text = formatted;
                        _amountController.selection = TextSelection.collapsed(
                          offset: formatted.length,
                        );
                      }
                    } else {
                      receivedAmountValue = 0;
                      if (_amountController.text.isNotEmpty) {
                        _amountController.clear();
                      }
                    }

                    // Actualizar solo el estado del diálogo
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
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: const Text('CANCELAR'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (receivedAmountValue >= _total) {
                    Navigator.pop(context, receivedAmountValue);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'El monto recibido debe ser mayor o igual al total',
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
              _buildAmountRow('Total:', _formatNumber(_total)),
              const SizedBox(height: 8),
              _buildAmountRow('Recibido:', _formatNumber(receivedAmount)),
              const SizedBox(height: 12),
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
                onPressed: () {
                  Navigator.pop(context);
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
              onPressed: () {
                Navigator.pop(context);
                _onClearAll();
              },
              child: const Text('ACEPTAR'),
            ),
          ],
        ),
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

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.blue),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 40, color: Colors.blue),
                ),
                const SizedBox(height: 10),
                Text(
                  'Usuario',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'usuario@ejemplo.com',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Inicio'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long),
            title: const Text('Ventas'),
            onTap: () {
              // Navegar a la pantalla de ventas
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: const Text('Reportes'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ReportesScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Configuración'),
            onTap: () {
              // Navegar a la pantalla de configuración
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Ayuda'),
            onTap: () {
              // Navegar a la pantalla de ayuda
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return PopScope(
      canPop: false, // Impide el retroceso
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        // Opcional: manejar el evento si didPop es true (aunque canPop: false lo previene)
        if (didPop) {
          // La pantalla fue desapilada (esto no debería ocurrir con canPop: false)
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.grey[50],
        drawer: isSmallScreen ? _buildDrawer() : null,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(56.0),
          child: AppBar(
            title: const Text('Caja Registradora'),
            elevation: 0,
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            leading: isSmallScreen
                ? IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  )
                : null,
          ),
        ),
        body: Row(
          children: [
            // Sidebar para pantallas más grandes
            if (!isSmallScreen)
              Container(
                width: 200, // Reduced width for larger screens
                color: Colors.white,
                child: _buildDrawer(),
              ),
            // Contenido principal
            Expanded(
              child: SafeArea(
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
                          if (_firstOperand != null ||
                              _pendingOperation != null)
                            Text(
                              '${_firstOperand != null ? _formatNumber(_firstOperand!) : ''} ${_pendingOperation ?? ''} ${_currentInput.isNotEmpty ? _formatNumber(double.parse(_currentInput)) : ''}',
                              style: const TextStyle(
                                fontSize: 20,
                                color: Colors.grey,
                              ),
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
