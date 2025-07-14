import 'package:caja_registradora/services/caja_events.dart';
import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../../models/transaccion.dart';

class TransaccionRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  // Insertar una nueva transacción
  Future<int> insertTransaccion(Transaccion transaccion) async {
    final db = await _databaseHelper.database;
    final id = await db.insert(
      DatabaseHelper.tableTransacciones,
      transaccion.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    CajaEvents().notificar(CajaStateEvent.transaccionRealizada);
    return id;
  }

  // Obtener todas las transacciones
  Future<List<Transaccion>> getTransacciones() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableTransacciones,
      orderBy: '${DatabaseHelper.columnFechaHora} DESC',
    );
    return List.generate(maps.length, (i) => Transaccion.fromMap(maps[i]));
  }

  // Obtener transacciones por rango de fechas
  Future<List<Transaccion>> getTransaccionesPorRangoFechas(
      DateTime desde, DateTime hasta) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableTransacciones,
      where: '${DatabaseHelper.columnFechaHora} BETWEEN ? AND ?',
      whereArgs: [desde.toIso8601String(), hasta.toIso8601String()],
      orderBy: '${DatabaseHelper.columnFechaHora} DESC',
    );
    return List.generate(maps.length, (i) => Transaccion.fromMap(maps[i]));
  }

  // Obtener transacciones del día actual
  Future<List<Transaccion>> getTransaccionesHoy() async {
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final manana = hoy.add(const Duration(days: 1));
    return await getTransaccionesPorRangoFechas(hoy, manana);
  }

  // Obtener total de ventas por rango de fechas
  Future<Map<String, dynamic>> getResumenVentas(DateTime desde, DateTime hasta) async {
    final transacciones = await getTransaccionesPorRangoFechas(desde, hasta);
    
    double totalEfectivo = 0;
    double totalTransferencia = 0;
    
    for (var transaccion in transacciones) {
      if (transaccion.metodoPago == 'efectivo') {
        totalEfectivo += transaccion.montoTotal;
      } else if (transaccion.metodoPago == 'transferencia') {
        totalTransferencia += transaccion.montoTotal;
      }
    }
    
    return {
      'totalEfectivo': totalEfectivo,
      'totalTransferencia': totalTransferencia,
      'totalGeneral': totalEfectivo + totalTransferencia,
      'cantidadTransacciones': transacciones.length,
    };
  }
}
