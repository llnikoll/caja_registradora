import 'package:flutter/foundation.dart';
import '../database/repositories/caja_repository.dart';
import '../database/repositories/transaccion_repository_ext.dart';
import '../models/caja.dart';
import '../models/transaccion.dart';

class SalesHistoryProvider with ChangeNotifier {
  final CajaRepository _cajaRepository = CajaRepository();
  final TransaccionRepositoryExt _transaccionRepositoryExt =
      TransaccionRepositoryExt();

  List<Caja> _cajas = [];
  bool _isLoading = true;

  List<Caja> get cajas => _cajas;
  bool get isLoading => _isLoading;

  SalesHistoryProvider() {
    loadSalesHistory();
  }

  Future<void> loadSalesHistory() async {
    try {
      _cajas = await _cajaRepository.getHistorialCajas();
    } catch (e) {
      // Optionally, handle error state
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<Transaccion>> getTransactionsForCaja(
    DateTime fechaApertura,
    DateTime? fechaCierre,
  ) async {
    return await _transaccionRepositoryExt.getTransaccionesPorCaja(
      fechaApertura,
      fechaCierre,
    );
  }
}
