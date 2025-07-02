import '../database_helper.dart';
import '../../models/transaccion.dart';

class TransaccionRepositoryExt {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  // Obtener transacciones por caja (por fecha de apertura/cierre)
  Future<List<Transaccion>> getTransaccionesPorCaja(
    DateTime apertura,
    DateTime? cierre,
  ) async {
    final db = await _databaseHelper.database;
    final desde = apertura;
    final hasta = cierre ?? DateTime.now();
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableTransacciones,
      where: '${DatabaseHelper.columnFechaHora} BETWEEN ? AND ?',
      whereArgs: [desde.toIso8601String(), hasta.toIso8601String()],
      orderBy: '${DatabaseHelper.columnFechaHora} ASC',
    );
    return List.generate(maps.length, (i) => Transaccion.fromMap(maps[i]));
  }
}
