import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/caja.dart';
import '../models/transaccion.dart';
import 'package:intl/intl.dart';
import '../utils/formato_moneda.dart';
import '../providers/sales_history_provider.dart'; // Import the new provider

class VentasScreen extends StatefulWidget {
  const VentasScreen({super.key});

  @override
  State<VentasScreen> createState() => _VentasScreenState();
}

class _VentasScreenState extends State<VentasScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

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
    super.build(context); // Necesario para AutomaticKeepAliveClientMixin
    final salesHistoryProvider = Provider.of<SalesHistoryProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Historial de Sesiones de Caja')),
      body: salesHistoryProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : salesHistoryProvider.cajas.isEmpty
              ? const Center(child: Text('No hay sesiones de caja registradas'))
              : ListView.builder(
                  itemCount: salesHistoryProvider.cajas.length,
                  itemBuilder: (context, index) {
                    final caja = salesHistoryProvider.cajas[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        title: Text(
                          'Caja #${caja.id} - ${_dateFormat.format(caja.fechaApertura)}',
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
                            builder: (_) =>
                                _buildDetalleSesion(caja, transacciones),
                          );
                        },
                      ),
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
          Text('Apertura: ${_dateFormat.format(caja.fechaApertura)}'),
          if (caja.fechaCierre != null)
            Text('Cierre: ${_dateFormat.format(caja.fechaCierre!)}'),
          const Divider(),
          Text('Monto Inicial: ${_formatearMonto(caja.montoInicial)}'),
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
                  subtitle: Text(_dateFormat.format(t.fechaHora)),
                  trailing: Text(
                    _formatearMonto(t.montoTotal),
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