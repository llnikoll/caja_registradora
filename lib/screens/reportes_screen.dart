import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/repositories/caja_repository.dart';
import '../database/repositories/transaccion_repository.dart';
import '../models/caja.dart';
import '../models/transaccion.dart';

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  ReportesScreenState createState() => ReportesScreenState();
}

class ReportesScreenState extends State<ReportesScreen> {
  final CajaRepository _cajaRepository = CajaRepository();
  final TransaccionRepository _transaccionRepository = TransaccionRepository();

  Caja? _cajaAbierta;
  List<Transaccion> _transaccionesHoy = [];
  Map<String, dynamic> _resumenHoy = {
    'totalEfectivo': 0.0,
    'totalTransferencia': 0.0,
    'totalGeneral': 0.0,
    'cantidadTransacciones': 0,
  };

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);

    try {
      _cajaAbierta = await _cajaRepository.getCajaAbierta();

      if (_cajaAbierta != null) {
        _transaccionesHoy = await _transaccionRepository.getTransaccionesHoy();
        _resumenHoy = await _transaccionRepository.getResumenVentas(
          DateTime.now().subtract(const Duration(days: 1)),
          DateTime.now().add(const Duration(days: 1)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al cargar datos: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _cargarDatos),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cajaAbierta == null
          ? _buildSinCajaAbierta()
          : _buildContenido(),
      floatingActionButton: _cajaAbierta != null
          ? FloatingActionButton.extended(
              onPressed: _mostrarDialogoCerrarCaja,
              icon: const Icon(Icons.point_of_sale),
              label: const Text('Cerrar Caja'),
            )
          : FloatingActionButton.extended(
              onPressed: _mostrarDialogoAbrirCaja,
              icon: const Icon(Icons.add),
              label: const Text('Abrir Caja'),
            ),
    );
  }

  Widget _buildSinCajaAbierta() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.point_of_sale_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'No hay caja abierta',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Para ver los reportes, abre una caja primero',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _mostrarDialogoAbrirCaja,
            icon: const Icon(Icons.add),
            label: const Text('Abrir Caja'),
          ),
        ],
      ),
    );
  }

  Widget _buildContenido() {
    return RefreshIndicator(
      onRefresh: _cargarDatos,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildResumenCaja(),
            const SizedBox(height: 24),
            _buildResumenVentas(),
            const SizedBox(height: 24),
            _buildUltimasTransacciones(),
          ],
        ),
      ),
    );
  }

  Widget _buildResumenCaja() {
    return Card(
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
            ListTile(
              title: const Text('Estado'),
              trailing: Chip(
                label: Text(
                  _cajaAbierta?.estaAbierta == true ? 'Abierta' : 'Cerrada',
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor: _cajaAbierta?.estaAbierta == true
                    ? Colors.green
                    : Colors.red,
              ),
            ),
            ListTile(
              title: const Text('Fecha Apertura'),
              trailing: Text(
                _cajaAbierta?.fechaAperturaFormateada ?? 'N/A',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            ListTile(
              title: const Text('Monto Inicial'),
              trailing: Text(
                _cajaAbierta?.montoInicialFormateado ?? '₲0',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumenVentas() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumen de Ventas Hoy',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _buildItemResumen(
              'Efectivo',
              _resumenHoy['totalEfectivo'],
              Icons.money,
              Colors.green,
            ),
            _buildItemResumen(
              'Transferencia',
              _resumenHoy['totalTransferencia'],
              Icons.account_balance_wallet,
              Colors.blue,
            ),
            const Divider(),
            _buildItemResumen(
              'Total General',
              _resumenHoy['totalGeneral'],
              Icons.attach_money,
              Colors.blueAccent,
              isTotal: true,
            ),
            const SizedBox(height: 8),
            Text(
              '${_resumenHoy['cantidadTransacciones']} transacciones realizadas hoy',
              style: const TextStyle(color: Colors.grey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemResumen(
    String titulo,
    double monto,
    IconData icono,
    Color color, {
    bool isTotal = false,
  }) {
    final formatter = NumberFormat.currency(
      symbol: '₲',
      decimalDigits: 0,
      locale: 'es_PY',
    );

    return ListTile(
      leading: Icon(icono, color: color),
      title: Text(
        titulo,
        style: TextStyle(
          fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          fontSize: isTotal ? 16 : 14,
        ),
      ),
      trailing: Text(
        formatter.format(monto),
        style: TextStyle(
          fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          fontSize: isTotal ? 18 : 16,
          color: isTotal ? Theme.of(context).primaryColor : null,
        ),
      ),
    );
  }

  Widget _buildUltimasTransacciones() {
    if (_transaccionesHoy.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: Text('No hay transacciones registradas hoy')),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Últimas Transacciones',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            const SizedBox(height: 16),
            SizedBox(
              height: 200, // Fixed height for the list
              child: ListView.builder(
                shrinkWrap: true,
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: _transaccionesHoy.length > 5
                    ? 5
                    : _transaccionesHoy.length,
                itemBuilder: (context, index) {
                  final transaccion = _transaccionesHoy[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: transaccion.metodoPago == 'efectivo'
                          ? Colors.green[100]
                          : Colors.blue[100],
                      child: Icon(
                        transaccion.metodoPago == 'efectivo'
                            ? Icons.money
                            : Icons.account_balance_wallet,
                        color: transaccion.metodoPago == 'efectivo'
                            ? Colors.green
                            : Colors.blue,
                      ),
                    ),
                    title: Text(
                      '${transaccion.nombreCliente ?? "Sin nombre"} - ${transaccion.numeroTransaccion}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(transaccion.fechaFormateada),
                    trailing: Text(
                      transaccion.montoFormateado,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_transaccionesHoy.length > 5)
              TextButton(
                onPressed: () {
                  // Navegar a pantalla de todas las transacciones
                },
                child: const Text('Ver todas las transacciones'),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _mostrarDialogoAbrirCaja() async {
    final montoController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    if (!mounted) return;

    await showDialog(
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
              prefixText: '₲',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingrese un monto';
              }
              if (double.tryParse(value) == null) {
                return 'Ingrese un monto válido';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              final monto = double.parse(montoController.text);

              try {
                await _cajaRepository.abrirCaja(monto);
                if (!mounted) return;

                Navigator.pop(context, true);
                await _cargarDatos();

                if (!mounted) return;
                final messenger = ScaffoldMessenger.of(context);
                messenger.showSnackBar(
                  const SnackBar(content: Text('Caja abierta exitosamente')),
                );
              } catch (e) {
                if (!mounted) return;
                final messenger = ScaffoldMessenger.of(context);
                messenger.showSnackBar(
                  SnackBar(content: Text('Error al abrir caja: $e')),
                );
              }
            },
            child: const Text('Abrir'),
          ),
        ],
      ),
    );

    await _cargarDatos();
  }

  Future<void> _mostrarDialogoCerrarCaja() async {
    final montoController = TextEditingController(
      text: _resumenHoy['totalGeneral'].toStringAsFixed(0),
    );
    final formKey = GlobalKey<FormState>();

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cerrar Caja'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Resumen del día:'),
                const SizedBox(height: 16),
                _buildResumenItem('Efectivo', _resumenHoy['totalEfectivo']),
                _buildResumenItem(
                  'Transferencia',
                  _resumenHoy['totalTransferencia'],
                ),
                const Divider(),
                _buildResumenItem(
                  'Total General',
                  _resumenHoy['totalGeneral'],
                  isTotal: true,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: montoController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Monto en Caja',
                    prefixText: '₲',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese el monto en caja';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Ingrese un monto válido';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              final monto = double.parse(montoController.text);
              try {
                await _cajaRepository.cerrarCaja(monto);
                if (!mounted) return;

                Navigator.pop(context, true);
                await _cargarDatos();

                if (!mounted) return;
                final messenger = ScaffoldMessenger.of(context);
                messenger.showSnackBar(
                  const SnackBar(content: Text('Caja cerrada exitosamente')),
                );
              } catch (e) {
                if (!mounted) return;
                final messenger = ScaffoldMessenger.of(context);
                messenger.showSnackBar(
                  SnackBar(content: Text('Error al cerrar caja: $e')),
                );
              }
            },
            child: const Text('Cerrar Caja'),
          ),
        ],
      ),
    );

    await _cargarDatos();
  }

  Widget _buildResumenItem(String label, double monto, {bool isTotal = false}) {
    final formatter = NumberFormat.currency(
      symbol: '₲',
      decimalDigits: 0,
      locale: 'es_PY',
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            formatter.format(monto),
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Theme.of(context).primaryColor : null,
            ),
          ),
        ],
      ),
    );
  }
}
