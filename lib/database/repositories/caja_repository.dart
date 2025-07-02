import '../database_helper.dart';
import '../../models/caja.dart';

class CajaRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  /// Obtiene todas las cajas cerradas, ordenadas por fecha de cierre descendente
  Future<List<Caja>> getCajasCerradas() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableCaja,
      where: '${DatabaseHelper.columnEstado} = ?',
      whereArgs: ['cerrada'],
      orderBy: '${DatabaseHelper.columnFechaCierre} DESC',
    );
    return List.generate(maps.length, (i) => Caja.fromMap(maps[i]));
  }

  // Abrir caja
  Future<int> abrirCaja(double montoInicial) async {
    final db = await _databaseHelper.database;
    
    // Verificar si ya hay una caja abierta
    final cajaAbierta = await getCajaAbierta();
    if (cajaAbierta != null) {
      throw Exception('Ya hay una caja abierta');
    }
    
    final caja = Caja(
      montoInicial: montoInicial,
      estado: 'abierta',
    );
    
    final id = await db.insert(
      DatabaseHelper.tableCaja,
      caja.toMap(),
    );
    
    // Registrar movimiento de apertura
    await db.insert(
      DatabaseHelper.tableMovimientosCaja,
      {
        DatabaseHelper.columnCajaId: id,
        DatabaseHelper.columnTipo: 'apertura',
        DatabaseHelper.columnMonto: montoInicial,
        DatabaseHelper.columnDescripcion: 'Apertura de caja',
        DatabaseHelper.columnFechaHora: DateTime.now().toIso8601String(),
      },
    );
    
    return id;
  }

  // Cerrar la caja actual
  Future<void> cerrarCaja(double montoFinal, {String? observaciones}) async {
    final db = await _databaseHelper.database;
    final caja = await getCajaAbierta();
    
    if (caja == null) {
      throw Exception('No hay caja abierta para cerrar');
    }

    final updateData = <String, dynamic>{
      'estado': 'cerrada',
      'monto_final': montoFinal,
      'fecha_cierre': DateTime.now().toIso8601String(),
    };
    
    // Solo agregar observaciones si no es nulo
    if (observaciones != null) {
      updateData['observaciones'] = observaciones;
    }

    await db.update(
      DatabaseHelper.tableCaja,
      updateData,
      where: 'id = ?',
      whereArgs: [caja.id],
    );
    
    // Registrar movimiento de cierre
    await db.insert(
      DatabaseHelper.tableMovimientosCaja,
      {
        DatabaseHelper.columnCajaId: caja.id,
        DatabaseHelper.columnTipo: 'cierre',
        DatabaseHelper.columnMonto: montoFinal,
        DatabaseHelper.columnDescripcion: 'Cierre de caja',
        DatabaseHelper.columnFechaHora: DateTime.now().toIso8601String(),
      },
    );
  }

  // Obtener la caja actualmente abierta
  Future<Caja?> getCajaAbierta() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableCaja,
      where: '${DatabaseHelper.columnEstado} = ?',
      whereArgs: ['abierta'],
      limit: 1,
    );
    
    if (maps.isEmpty) return null;
    return Caja.fromMap(maps.first);
  }

  // Obtener historial de cajas
  Future<List<Caja>> getHistorialCajas() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableCaja,
      orderBy: '${DatabaseHelper.columnFechaApertura} DESC',
    );
    return List.generate(maps.length, (i) => Caja.fromMap(maps[i]));
  }

  // Registrar movimiento de caja (ingreso/egreso)
  Future<void> registrarMovimiento({
    required int cajaId,
    required String tipo,
    required double monto,
    String descripcion = '',
    int? transaccionId,
  }) async {
    final db = await _databaseHelper.database;
    
    await db.insert(
      DatabaseHelper.tableMovimientosCaja,
      {
        DatabaseHelper.columnCajaId: cajaId,
        DatabaseHelper.columnTransaccionId: transaccionId,
        DatabaseHelper.columnTipo: tipo,
        DatabaseHelper.columnMonto: monto,
        DatabaseHelper.columnDescripcion: descripcion,
        DatabaseHelper.columnFechaHora: DateTime.now().toIso8601String(),
      },
    );
  }
}
