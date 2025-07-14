import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart'; // Import Provider
import '../utils/formato_moneda.dart';

// Remove direct repository imports, use provider instead
// import '../database/repositories/caja_repository.dart';
// import '../database/repositories/transaccion_repository.dart';
// import '../models/caja.dart';
// import '../models/transaccion.dart';
// import '../services/caja_events.dart';

import '../providers/reportes_provider.dart'; // Import the new provider

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  ReportesScreenState createState() => ReportesScreenState();
}

class ReportesScreenState extends State<ReportesScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  // Remove local state, use provider instead
  // final CajaRepository _cajaRepository = CajaRepository();
  // final TransaccionRepository _transaccionRepository = TransaccionRepository();
  // Caja? _cajaAbierta;
  // List<Transaccion> _transaccionesHoy = [];
  // Map<String, dynamic> _resumenHoy = {
  //   'totalEfectivo': 0.0,
  //   'totalTransferencia': 0.0,
  //   'totalGeneral': 0.0,
  //   'cantidadTransacciones': 0,
  // };
  // bool _isLoading = true;
  // late StreamSubscription _cajaEventsSubscription;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('es');
    // Data loading and event subscription handled by ReportesProvider
    // _cargarDatos();
    // _cajaEventsSubscription = CajaEvents().stream.listen((event) {
    //   _cargarDatos();
    // });
  }

  @override
  void dispose() {
    // Event subscription handled by ReportesProvider
    // _cajaEventsSubscription.cancel();
    super.dispose();
  }

  // Data loading logic moved to ReportesProvider
  // Future<void> _cargarDatos() async {
  //   setState(() => _isLoading = true);
  //   try {
  //     _cajaAbierta = await _cajaRepository.getCajaAbierta();
  //     if (_cajaAbierta != null) {
  //       final desde = _cajaAbierta!.fechaApertura;
  //       final hasta = _cajaAbierta!.fechaCierre ?? DateTime.now();
  //       _transaccionesHoy = await _transaccionRepository
  //           .getTransaccionesPorRangoFechas(desde, hasta);
  //       _resumenHoy = await _transaccionRepository.getResumenVentas(
  //         desde,
  //         hasta,
  //       );
  //     }
  //   } catch (e) {
  //     if (mounted) {
  //       ScaffoldMessenger.of(
  //         context,
  //       ).showSnackBar(SnackBar(content: Text('Error al cargar datos: $e')));
  //     }
  //   } finally {
  //     if (mounted) {
  //       setState(() => _isLoading = false);
  //     }
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final reportesProvider = Provider.of<ReportesProvider>(context);

    if (reportesProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (reportesProvider.cajaAbierta == null) {
      return _buildSinCajaAbierta();
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Reportes de Caja')),
      body: _buildResumenTab(reportesProvider),
    );
  }

  Widget _buildSinCajaAbierta() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.point_of_sale_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No hay caja abierta',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              'Para ver los reportes, abre una caja desde la pantalla de Inicio.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumenTab(ReportesProvider reportesProvider) {
    return RefreshIndicator(
      onRefresh: reportesProvider.loadReportData, // Use provider method
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildResumenCaja(reportesProvider),
            const SizedBox(height: 24),
            _buildResumenVentas(reportesProvider),
            const SizedBox(height: 24),
            _buildUltimasTransacciones(reportesProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildResumenCaja(ReportesProvider reportesProvider) {
    final cajaAbierta = reportesProvider.cajaAbierta!;
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumen de Caja',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Estado:'),
                Chip(
                  label: Text(
                    cajaAbierta.fechaCierre == null ? 'Abierta' : 'Cerrada',
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: cajaAbierta.fechaCierre == null
                      ? Colors.green
                      : Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Apertura:'),
                Text(
                  DateFormat(
                    'dd/MM/yyyy HH:mm',
                  ).format(cajaAbierta.fechaApertura),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (cajaAbierta.fechaCierre != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Cierre:'),
                  Text(
                    DateFormat(
                      'dd/MM/yyyy HH:mm',
                    ).format(cajaAbierta.fechaCierre!),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Monto Inicial:'),
                Text(FormatoMoneda.formatear(cajaAbierta.montoInicial)),
              ],
            ),
            if (cajaAbierta.montoFinal != null) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Monto Final:'),
                  Text(FormatoMoneda.formatear(cajaAbierta.montoFinal!)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResumenVentas(ReportesProvider reportesProvider) {
    final resumenHoy = reportesProvider.resumenHoy;
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumen de Ventas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            const SizedBox(height: 8),
            _buildItemResumen(
              'Efectivo:',
              FormatoMoneda.formatear(resumenHoy['totalEfectivo'] ?? 0),
              Icons.money,
              Colors.green,
            ),
            const SizedBox(height: 8),
            _buildItemResumen(
              'Transferencia:',
              FormatoMoneda.formatear(resumenHoy['totalTransferencia'] ?? 0),
              Icons.account_balance_wallet,
              Colors.blue,
            ),
            const SizedBox(height: 8),
            _buildItemResumen(
              'Total General:',
              FormatoMoneda.formatear(resumenHoy['totalGeneral'] ?? 0),
              Icons.attach_money,
              Colors.purple,
              isTotal: true,
            ),
            const SizedBox(height: 8),
            _buildItemResumen(
              'N° de Transacciones:',
              '${resumenHoy['cantidadTransacciones'] ?? '0'}',
              Icons.receipt,
              Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemResumen(
    String titulo,
    String valor,
    IconData icono,
    Color color, {
    bool isTotal = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: isTotal ? color.withValues(alpha: 0.1) : null,
        borderRadius: BorderRadius.circular(8),
        border: isTotal ? Border.all(color: color, width: 1) : null,
      ),
      child: Row(
        children: [
          Icon(icono, color: color, size: 20),
          const SizedBox(width: 12),
          Text(
            titulo,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const Spacer(),
          Text(
            valor,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? color : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUltimasTransacciones(ReportesProvider reportesProvider) {
    final transaccionesHoy = reportesProvider.transaccionesHoy;
    if (transaccionesHoy.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No hay transacciones registradas.'),
        ),
      );
    }

    return Card(
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Últimas Transacciones',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 0),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: transaccionesHoy.length > 5
                ? 5
                : transaccionesHoy.length,
            separatorBuilder: (context, index) => const Divider(height: 0),
            itemBuilder: (context, index) {
              final transaccion = transaccionesHoy[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      transaccion.metodoPago.toLowerCase() == 'efectivo'
                      ? Colors.green
                      : Colors.blue,
                  child: Icon(
                    transaccion.metodoPago.toLowerCase() == 'efectivo'
                        ? Icons.money
                        : Icons.account_balance_wallet,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                title: Text(
                  'Transacción',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  DateFormat(
                    'dd/MM/yyyy HH:mm',
                    'es',
                  ).format(transaccion.fechaHora),
                ),
                trailing: Text(
                  '₲${transaccion.montoTotal.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
