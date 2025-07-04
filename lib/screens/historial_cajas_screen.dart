import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/repositories/caja_repository.dart';
import '../database/repositories/transaccion_repository_ext.dart';
import '../models/caja.dart';
import '../models/transaccion.dart';
import '../services/caja_events.dart';
import '../utils/formato_moneda.dart';

class HistorialCajasScreen extends StatefulWidget {
  const HistorialCajasScreen({super.key});

  @override
  State<HistorialCajasScreen> createState() => _HistorialCajasScreenState();
}

class _HistorialCajasScreenState extends State<HistorialCajasScreen> {
  final CajaRepository _cajaRepository = CajaRepository();
  final TransaccionRepositoryExt _transaccionRepositoryExt =
      TransaccionRepositoryExt();
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  List<Caja> _cajas = [];
  bool _isLoading = true;
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 7)),
    end: DateTime.now(),
  );

  @override
  void initState() {
    super.initState();
    _cargarCajas();
  }

  Future<void> _cargarCajas() async {
    setState(() => _isLoading = true);
    try {
      final cajas = await _cajaRepository.getHistorialCajas();
      setState(() {
        _cajas = cajas;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar el historial: $e')),
        );
      }
    }
  }

  Future<void> _seleccionarRangoFechas() async {
    final DateTimeRange? nuevoRango = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _dateRange,
    );

    if (nuevoRango != null) {
      setState(() {
        _dateRange = nuevoRango;
      });
      _filtrarCajas();
    }
  }

  void _filtrarCajas() {
    // Filtra las cajas por el rango de fechas seleccionado
    setState(() {
      _cajas = _cajas.where((caja) {
        final apertura = caja.fechaApertura;
        return apertura.isAfter(
              _dateRange.start.subtract(const Duration(seconds: 1)),
            ) &&
            apertura.isBefore(_dateRange.end.add(const Duration(days: 1)));
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Cajas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _seleccionarRangoFechas,
            tooltip: 'Seleccionar rango de fechas',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarCajas,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cajas.isEmpty
          ? const Center(child: Text('No hay registros de cajas'))
          : ListView.builder(
              itemCount: _cajas.length,
              itemBuilder: (context, index) {
                final caja = _cajas[index];
                return _buildCajaCard(caja);
              },
            ),
    );
  }

  Widget _buildCajaCard(Caja caja) {
    final bool estaAbierta = caja.estado == 'abierta';
    final Color colorEstado = estaAbierta ? Colors.green : Colors.grey;
    final String estado = estaAbierta ? 'Abierta' : 'Cerrada';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _mostrarDetalleCaja(caja),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Caja #${caja.id}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorEstado.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      estado,
                      style: TextStyle(
                        color: colorEstado,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                'Apertura:',
                _dateFormat.format(caja.fechaApertura),
              ),
              if (caja.fechaCierre != null) ...[
                _buildInfoRow('Cierre:', _dateFormat.format(caja.fechaCierre!)),
                _buildInfoRow(
                  'Duración:',
                  _calcularDuracion(caja.fechaApertura, caja.fechaCierre!),
                ),
              ],
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMontoInfo('Inicial', caja.montoInicial),
                  const VerticalDivider(),
                  if (caja.montoFinal != null)
                    _buildMontoInfo('Final', caja.montoFinal!),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildMontoInfo(String label, double monto) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          FormatoMoneda.formatear(monto),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  String _calcularDuracion(DateTime inicio, DateTime fin) {
    final duracion = fin.difference(inicio);
    final horas = duracion.inHours;
    final minutos = duracion.inMinutes.remainder(60);

    if (horas > 0) {
      return '$horas h $minutos min';
    } else {
      return '$minutos min';
    }
  }

  void _mostrarDetalleCaja(Caja caja) async {
    final transacciones = await _transaccionRepositoryExt
        .getTransaccionesPorCaja(caja.fechaApertura, caja.fechaCierre);
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _buildDetalleCaja(caja, transacciones),
    );
  }

  Widget _buildDetalleCaja(Caja caja, List<Transaccion> transacciones) {
    final bool estaAbierta = caja.estado == 'abierta';
    final Color colorEstado = estaAbierta ? Colors.green : Colors.grey;
    final String estado = estaAbierta ? 'Abierta' : 'Cerrada';

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, controller) => SingleChildScrollView(
        controller: controller,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Detalle de Caja #${caja.id}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorEstado.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      estado,
                      style: TextStyle(
                        color: colorEstado,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildDetalleRow(
                'Apertura:',
                _dateFormat.format(caja.fechaApertura),
              ),
              if (caja.fechaCierre != null) ...[
                _buildDetalleRow(
                  'Cierre:',
                  _dateFormat.format(caja.fechaCierre!),
                ),
                _buildDetalleRow(
                  'Duración:',
                  _calcularDuracion(caja.fechaApertura, caja.fechaCierre!),
                ),
              ],
              const Divider(height: 32),
              _buildMontoDetalle('Monto Inicial', caja.montoInicial),
              if (caja.montoFinal != null)
                _buildMontoDetalle('Monto Final', caja.montoFinal!),
              if (caja.montoFinal != null)
                _buildMontoDetalle(
                  'Diferencia',
                  caja.montoFinal! - caja.montoInicial,
                  isDifference: true,
                ),
              const SizedBox(height: 24),
              // Se eliminó la sección de observaciones ya que no está en el modelo
              const SizedBox(height: 24),
              if (estaAbierta)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _mostrarDialogoCerrarCaja(caja),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('CERRAR CAJA'),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      // Aquí podrías mostrar un resumen o ticket de la caja
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('VER TICKET'),
                  ),
                ),
              if (transacciones.isNotEmpty) ...[
                const Divider(height: 32),
                const Text(
                  'Transacciones del día',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                ListView.separated(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: transacciones.length,
                  separatorBuilder: (_, __) => Divider(height: 1),
                  itemBuilder: (context, index) {
                    final t = transacciones[index];
                    return ListTile(
                      leading: Icon(
                        t.metodoPago == 'efectivo'
                            ? Icons.money
                            : Icons.account_balance_wallet,
                        color: t.metodoPago == 'efectivo'
                            ? Colors.green
                            : Colors.blue,
                      ),
                      title: Text('${t.nombreCliente ?? 'Sin nombre'}'),
                      subtitle: Text(t.fechaFormateada),
                      trailing: Text(
                        t.montoFormateado,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetalleRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 16)),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildMontoDetalle(
    String label,
    double monto, {
    bool isDifference = false,
  }) {
    final bool esPositivo = monto >= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '${esPositivo ? '+' : ''}₲${monto.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.')}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDifference
                  ? (esPositivo ? Colors.green : Colors.red)
                  : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _mostrarDialogoCerrarCaja(Caja caja) async {
    final montoController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    if (!mounted) return;
    Navigator.pop(context); // Cierra el sheet de detalles

    final bool? cajaCerrada = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Cerrar Caja #${caja.id}'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: montoController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Monto Final en Caja',
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
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              // Capture values needed after async gap
              final currentMounted = mounted;
              if (!currentMounted) return;

              final scaffoldMessenger = ScaffoldMessenger.of(dialogContext);
              final navigator = Navigator.of(dialogContext);

              try {
                final montoFinal = double.parse(montoController.text);
                await _cajaRepository.cerrarCaja(montoFinal);
                CajaEvents().notificar(CajaStateEvent.cerrada);
                navigator.pop(true);
              } catch (e) {
                navigator.pop(false);
                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text('Error al cerrar caja: $e')),
                );
              }
            },
            child: const Text('Confirmar Cierre'),
          ),
        ],
      ),
    );

    if (cajaCerrada == true) {
      _cargarCajas(); // Recargar la lista de cajas
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Caja cerrada exitosamente')),
        );
      }
    }
  }

  // Se eliminó el método _buildObservaciones ya que no se usa
}
