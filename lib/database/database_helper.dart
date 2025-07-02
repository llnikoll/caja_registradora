import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;
  static const String _databaseName = 'caja_registradora.db';
  static const int _databaseVersion = 2;

  // Nombres de tablas
  static const String tableTransacciones = 'transacciones';
  static const String tableCaja = 'caja';
  static const String tableMovimientosCaja = 'movimientos_caja';

  // Columnas comunes
  static const String columnId = 'id';

  // Columnas de transacciones
  static const String columnNumeroTransaccion = 'numero_transaccion';
  static const String columnMontoTotal = 'monto_total';
  static const String columnFechaHora = 'fecha_hora';
  static const String columnMetodoPago = 'metodo_pago';
  static const String columnNombreCliente = 'nombre_cliente';
  static const String columnNotas = 'notas';

  // Columnas de caja
  static const String columnFechaApertura = 'fecha_apertura';
  static const String columnFechaCierre = 'fecha_cierre';
  static const String columnMontoInicial = 'monto_inicial';
  static const String columnMontoFinal = 'monto_final';
  static const String columnEstado = 'estado';

  // Columnas de movimientos de caja
  static const String columnCajaId = 'caja_id';
  static const String columnTransaccionId = 'transaccion_id';
  static const String columnTipo = 'tipo';
  static const String columnMonto = 'monto';
  static const String columnDescripcion = 'descripcion';

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Initialize FFI for desktop platforms
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      // Initialize FFI
      sqfliteFfiInit();
      // Change the default factory
      databaseFactory = databaseFactoryFfi;
    }
    
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Agregar la columna observaciones a la tabla caja
          await db.execute('ALTER TABLE $tableCaja ADD COLUMN observaciones TEXT');
        }
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Crear tabla de caja
    await db.execute('''
      CREATE TABLE $tableCaja (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnFechaApertura TEXT NOT NULL,
        $columnFechaCierre TEXT,
        $columnMontoInicial REAL NOT NULL,
        $columnMontoFinal REAL,
        $columnEstado TEXT NOT NULL,
        observaciones TEXT
      )
    ''');

    // Crear tabla de transacciones
    await db.execute('''
      CREATE TABLE $tableTransacciones (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnNumeroTransaccion TEXT UNIQUE NOT NULL,
        $columnMontoTotal REAL NOT NULL,
        $columnFechaHora TEXT NOT NULL,
        $columnMetodoPago TEXT NOT NULL,
        $columnNombreCliente TEXT,
        $columnNotas TEXT
      )
    ''');

    // Crear tabla de movimientos de caja
    await db.execute('''
      CREATE TABLE $tableMovimientosCaja (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnCajaId INTEGER NOT NULL,
        $columnTransaccionId INTEGER,
        $columnTipo TEXT NOT NULL,
        $columnMonto REAL NOT NULL,
        $columnDescripcion TEXT,
        $columnFechaHora TEXT NOT NULL,
        FOREIGN KEY ($columnCajaId) REFERENCES $tableCaja($columnId),
        FOREIGN KEY ($columnTransaccionId) REFERENCES $tableTransacciones($columnId)
      )
    ''');
  }

  // Cerrar la base de datos
  Future<void> closeDatabase() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
