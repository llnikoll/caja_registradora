import 'package:flutter/material.dart';

class CierreCajaDialog extends StatefulWidget {
  final double montoInicial;
  final double totalVentas;
  final Function(double montoFinal, String? observaciones) onCerrarCaja;

  const CierreCajaDialog({
    super.key,
    required this.montoInicial,
    required this.totalVentas,
    required this.onCerrarCaja,
  });

  @override
  State<CierreCajaDialog> createState() => _CierreCajaDialogState();
}

class _CierreCajaDialogState extends State<CierreCajaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _montoFinalController = TextEditingController();
  final _observacionesController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Calcular el monto final esperado
    final montoFinal = widget.montoInicial + widget.totalVentas;
    _montoFinalController.text = montoFinal.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _montoFinalController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cierre de Caja'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInfoRow('Monto Inicial:', widget.montoInicial),
              _buildInfoRow('Total de Ventas:', widget.totalVentas),
              _buildInfoRow(
                'Total Esperado:',
                widget.montoInicial + widget.totalVentas,
                isTotal: true,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _montoFinalController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Monto Final en Caja',
                  prefixText: '₲',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingrese el monto final';
                  }
                  final monto = double.tryParse(value);
                  if (monto == null || monto <= 0) {
                    return 'Ingrese un monto válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _observacionesController,
                decoration: const InputDecoration(
                  labelText: 'Observaciones (opcional)',
                  hintText: 'Ingrese observaciones sobre el cierre de caja',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('CANCELAR'),
        ),
        ElevatedButton(
          onPressed: _isLoading
              ? null
              : () async {
                  if (_formKey.currentState!.validate()) {
                    setState(() => _isLoading = true);

                    // Obtener el Navigator antes del await
                    final navigator = Navigator.of(context);
                    final montoFinal = double.parse(_montoFinalController.text);
                    final observaciones =
                        _observacionesController.text.trim().isEmpty
                        ? null
                        : _observacionesController.text.trim();

                    try {
                      await widget.onCerrarCaja(montoFinal, observaciones);

                      // Si llegamos aquí, la operación fue exitosa y podemos hacer pop
                      if (mounted) {
                        navigator.pop();
                      }
                    } catch (e) {
                      // Si hay un error, lo relanzamos para que el llamador pueda manejarlo
                      rethrow;
                    } finally {
                      if (mounted) {
                        setState(() => _isLoading = false);
                      }
                    }
                  }
                },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('CERRAR CAJA'),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, double monto, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Text(
            '₲${monto.toStringAsFixed(0)}',
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 18 : 14,
              color: isTotal ? Colors.green : null,
            ),
          ),
        ],
      ),
    );
  }
}
