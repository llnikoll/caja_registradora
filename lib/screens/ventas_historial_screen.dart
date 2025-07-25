import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/caja.dart';
import '../models/transaccion.dart';
import '../utils/formato_moneda.dart';
import '../providers/sales_history_provider.dart'; // Import the new provider

class VentasHistorialScreen extends StatefulWidget {
  const VentasHistorialScreen({super.key});

  @override
  State<VentasHistorialScreen> createState() => _VentasHistorialScreenState();
}

class _VentasHistorialScreenState extends State<VentasHistorialScreen> {
  @override
  void initState() {
    super.initState();
    // Load data using the provider
    Provider.of<SalesHistoryProvider>(context, listen: false).loadSalesHistory();
  }

  String _formatearMonto(double monto) {
    return FormatoMoneda.formatear(monto);
  }

  @override
  Widget build(BuildContext context) {
    final salesHistoryProvider = Provider.of<SalesHistoryProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Historial de Ventas por Sesión')),
      body: salesHistoryProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : salesHistoryProvider.cajas.isEmpty
              ? const Center(child: Text('No hay sesiones de caja registradas'))
              : ListView.builder(
                  itemCount: salesHistoryProvider.cajas.length,
                  itemBuilder: (context, index) {
                    final caja = salesHistoryProvider.cajas[index];
                    return ListTile(
                      title: Text(
                        'Caja #${caja.id} - ${caja.fechaAperturaFormateada}',
                      ),
                      subtitle: Text(caja.estaAbierta ? 'Abierta' : 'Cerrada'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        final transacciones = await salesHistoryProvider
                            .getTransactionsForCaja(
                                caja.fechaApertura,
                                caja.fechaCierre,
                              );
                        if (!mounted) return;
                        showModalBottomSheet(
                          context: this.context,
                          isScrollControlled: true,
                          builder: (_) => _buildDetalleSesion(caja, transacciones),
                        );
                      },
                    );
                  },
                ),
    );
  }

  Widget _buildDetalleSesion(Caja caja, List<Transaccion> transacciones) {
    double totalEfectivo = 0;
    double totalTransferencia = 0;
    for (var t in transacciones) {
      if (t.metodoPago == 'efectivo') {
        totalEfectivo += t.montoTotal;
      } else if (t.metodoPago == 'transferencia') {
        totalTransferencia += t.montoTotal;
      }
    }
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Caja #${caja.id}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          Text('Apertura: ${caja.fechaAperturaFormateada}'),
          if (caja.fechaCierre != null)
            Text('Cierre: ${caja.fechaCierreFormateada}'),
          const Divider(),
          Text('Monto Inicial: ${caja.montoInicialFormateado}'),
          Text('Total Efectivo: ${_formatearMonto(totalEfectivo)}'),
          Text('Total Transferencia: ${_formatearMonto(totalTransferencia)}'),
          Text(
            'Total Sesión: ${_formatearMonto(caja.montoInicial + totalEfectivo + totalTransferencia)}',
          ),
          const Divider(),
          const Text(
            'Transacciones:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(
            height: 300,
            child: ListView.builder(
              itemCount: transacciones.length,
              itemBuilder: (context, i) {
                final t = transacciones[i];
                return ListTile(
                  leading: Icon(
                    t.metodoPago == 'efectivo'
                        ? Icons.money
                        : Icons.account_balance_wallet,
                    color: t.metodoPago == 'efectivo'
                        ? Colors.green
                        : Colors.blue,
                  ),
                  title: Text(t.nombreCliente ?? 'Sin nombre'),
                  subtitle: Text(t.fechaFormateada),
                  trailing: Text(
                    t.montoFormateado,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}