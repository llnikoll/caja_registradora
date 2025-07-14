import 'dart:async';

enum CajaStateEvent { abierta, cerrada, transaccionRealizada }

class CajaEvents {
  static final _instance = CajaEvents._internal();
  factory CajaEvents() => _instance;
  CajaEvents._internal();

  final _streamController = StreamController<CajaStateEvent>.broadcast();

  Stream<CajaStateEvent> get stream => _streamController.stream;

  void notificar(CajaStateEvent event) {
    _streamController.add(event);
  }

  void dispose() {
    _streamController.close();
  }
}
