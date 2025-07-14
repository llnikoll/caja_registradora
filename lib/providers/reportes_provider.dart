import 'package:flutter/foundation.dart';
import 'dart:async'; // Import for StreamSubscription
import '../database/repositories/caja_repository.dart';
import '../database/repositories/transaccion_repository.dart';
import '../models/caja.dart';
import '../models/transaccion.dart';
import '../services/caja_events.dart';

class ReportesProvider with ChangeNotifier {
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
  late StreamSubscription _cajaEventsSubscription;

  Caja? get cajaAbierta => _cajaAbierta;
  List<Transaccion> get transaccionesHoy => _transaccionesHoy;
  Map<String, dynamic> get resumenHoy => _resumenHoy;
  bool get isLoading => _isLoading;

  ReportesProvider() {
    _cajaEventsSubscription = CajaEvents().stream.listen((_) {
      loadReportData();
    });
    loadReportData();
  }

  @override
  void dispose() {
    _cajaEventsSubscription.cancel();
    super.dispose();
  }

  Future<void> loadReportData() async {
    try {
      _cajaAbierta = await _cajaRepository.getCajaAbierta();

      if (_cajaAbierta != null) {
        final desde = _cajaAbierta!.fechaApertura;
        final hasta = _cajaAbierta!.fechaCierre ?? DateTime.now();
        _transaccionesHoy = await _transaccionRepository
            .getTransaccionesPorRangoFechas(desde, hasta);
        _resumenHoy = await _transaccionRepository.getResumenVentas(
          desde,
          hasta,
        );
      } else {
        _transaccionesHoy = [];
        _resumenHoy = {
          'totalEfectivo': 0.0,
          'totalTransferencia': 0.0,
          'totalGeneral': 0.0,
          'cantidadTransacciones': 0,
        };
      }
    } catch (e) {
      // Optionally, handle error state
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
