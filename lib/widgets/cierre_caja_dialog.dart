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
  final TextEditingController _montoFinalController = TextEditingController();
  final TextEditingController _observacionesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Calcular el monto sugerido (monto inicial + total ventas)
    final double montoSugerido = widget.montoInicial + widget.totalVentas;
    _montoFinalController.text = montoSugerido.toStringAsFixed(0); // Formato básico
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
      title: const Text('Cerrar Caja'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoRow('Monto Inicial:', '₲${widget.montoInicial.toStringAsFixed(0)}'),
              _buildInfoRow('Total Ventas:', '₲${widget.totalVentas.toStringAsFixed(0)}'),
              const Divider(),
              TextFormField(
                controller: _montoFinalController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Monto Final en Caja',
                  prefixText: '₲ ',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese el monto final';
                  }
                  if (double.tryParse(value) == null) {
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
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCELAR'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final montoFinal = double.parse(_montoFinalController.text);
              widget.onCerrarCaja(montoFinal, _observacionesController.text.isEmpty ? null : _observacionesController.text);
            }
          },
          child: const Text('CERRAR CAJA'),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }
}
