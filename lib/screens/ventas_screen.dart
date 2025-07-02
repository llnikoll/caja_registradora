import 'package:flutter/material.dart';
import '../database/repositories/caja_repository.dart';
import '../database/repositories/transaccion_repository_ext.dart';
import '../models/caja.dart';
import '../models/transaccion.dart';
import 'package:intl/intl.dart';
import '../utils/formato_moneda.dart';

class VentasScreen extends StatefulWidget {
  const VentasScreen({super.key});

  @override
  State<VentasScreen> createState() => _VentasScreenState();
}

class _VentasScreenState extends State<VentasScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final CajaRepository _cajaRepository = CajaRepository();
  final TransaccionRepositoryExt _transaccionRepositoryExt =
      TransaccionRepositoryExt();
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  List<Caja> _cajas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarCajas();
  }

  Future<void> _cargarCajas() async {
    setState(() => _isLoading = true);
    final cajas = await _cajaRepository.getHistorialCajas();
    setState(() {
      _cajas = cajas;
      _isLoading = false;
    });
  }

  String _formatearMonto(double monto) {
    return FormatoMoneda.formatear(monto);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Necesario para AutomaticKeepAliveClientMixin
    return Scaffold(
      appBar: AppBar(title: const Text('Historial de Sesiones de Caja')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cajas.isEmpty
          ? const Center(child: Text('No hay sesiones de caja registradas'))
          : ListView.builder(
              itemCount: _cajas.length,
              itemBuilder: (context, index) {
                final caja = _cajas[index];
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
                      final transacciones = await _transaccionRepositoryExt
                          .getTransaccionesPorCaja(
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
                  title: Text(
                    '${t.nombreCliente ?? 'Sin nombre'} - ${t.numeroTransaccion}',
                  ),
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
