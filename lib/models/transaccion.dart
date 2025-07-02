import 'package:intl/intl.dart';

class Transaccion {
  int? id;
  String numeroTransaccion;
  double montoTotal;
  DateTime fechaHora;
  String metodoPago; // 'efectivo' o 'transferencia'
  String? nombreCliente;
  String? notas;

  Transaccion({
    this.id,
    required this.numeroTransaccion,
    required this.montoTotal,
    required this.metodoPago,
    DateTime? fechaHora,
    this.nombreCliente,
    this.notas,
  }) : fechaHora = fechaHora ?? DateTime.now();

  // Convertir un Map a Transaccion
  factory Transaccion.fromMap(Map<String, dynamic> map) => Transaccion(
        id: map['id'],
        numeroTransaccion: map['numero_transaccion'],
        montoTotal: map['monto_total'] is double 
            ? map['monto_total'] 
            : (map['monto_total'] as num).toDouble(),
        metodoPago: map['metodo_pago'],
        fechaHora: DateTime.parse(map['fecha_hora']),
        nombreCliente: map['nombre_cliente'],
        notas: map['notas'],
      );

  // Convertir Transaccion a Map
  Map<String, dynamic> toMap() => {
        'id': id,
        'numero_transaccion': numeroTransaccion,
        'monto_total': montoTotal,
        'metodo_pago': metodoPago,
        'fecha_hora': fechaHora.toIso8601String(),
        'nombre_cliente': nombreCliente,
        'notas': notas,
      };

  // Formatear fecha para mostrar en la UI
  String get fechaFormateada {
    return DateFormat('dd/MM/yyyy HH:mm').format(fechaHora);
  }

  // Formatear monto como moneda
  String get montoFormateado {
    return '₲${montoTotal.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        )}';
  }
}
