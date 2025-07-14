import 'package:flutter/material.dart';
import '../database/repositories/caja_repository.dart'; // Import CajaRepository

class MontoInicialDialog extends StatefulWidget {
  // No longer needs onAceptar, as CajaRepository handles the action
  const MontoInicialDialog({super.key});

  @override
  State<MontoInicialDialog> createState() => _MontoInicialDialogState();
}

class _MontoInicialDialogState extends State<MontoInicialDialog> {
  final _formKey = GlobalKey<FormState>();
  final _montoController = TextEditingController();
  bool _isLoading = false;
  final CajaRepository _cajaRepository = CajaRepository(); // Instance of CajaRepository

  @override
  void dispose() {
    _montoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Apertura de Caja'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ingrese el monto inicial de la caja:'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _montoController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Monto Inicial',
                prefixText: '₲',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese un monto';
                }
                final monto = double.tryParse(value);
                if (monto == null || monto <= 0) {
                  return 'Ingrese un monto válido';
                }
                return null;
              },
            ),
          ],
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
                    try {
                      final monto = double.parse(_montoController.text);
                      await _cajaRepository.abrirCaja(monto);
                      // Notify CajaEvents if needed, or handle it within CajaRepository
                      // CajaEvents().notificar(CajaStateEvent.abierta);
                      if (mounted) {
                        Navigator.of(this.context).pop();
                      }
                    } finally {
                      if (mounted) {
                        setState(() => _isLoading = false);
                      }
                    }
                  }
                },
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('ACEPTAR'),
        ),
      ],
    );
  }
}