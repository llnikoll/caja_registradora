import 'package:intl/intl.dart';

class Caja {
  int? id;
  DateTime fechaApertura;
  DateTime? fechaCierre;
  double montoInicial;
  double? montoFinal;
  String estado; // 'abierta' o 'cerrada'

  Caja({
    this.id,
    required this.montoInicial,
    required this.estado,
    DateTime? fechaApertura,
    this.fechaCierre,
    this.montoFinal,
  }) : fechaApertura = fechaApertura ?? DateTime.now();

  // Convertir un Map a Caja
  factory Caja.fromMap(Map<String, dynamic> map) => Caja(
        id: map['id'],
        montoInicial: map['monto_inicial'] is double 
            ? map['monto_inicial'] 
            : (map['monto_inicial'] as num).toDouble(),
        montoFinal: map['monto_final'] != null
            ? (map['monto_final'] is double
                ? map['monto_final']
                : (map['monto_final'] as num).toDouble())
            : null,
        estado: map['estado'],
        fechaApertura: DateTime.parse(map['fecha_apertura']),
        fechaCierre: map['fecha_cierre'] != null
            ? DateTime.parse(map['fecha_cierre'])
            : null,
      );

  // Convertir Caja a Map
  Map<String, dynamic> toMap() => {
        'id': id,
        'monto_inicial': montoInicial,
        'monto_final': montoFinal,
        'estado': estado,
        'fecha_apertura': fechaApertura.toIso8601String(),
        'fecha_cierre': fechaCierre?.toIso8601String(),
      };

  // Verificar si la caja está abierta
  bool get estaAbierta => estado == 'abierta';

  // Formatear fechas para mostrar en la UI
  String get fechaAperturaFormateada {
    return DateFormat('dd/MM/yyyy HH:mm').format(fechaApertura);
  }

  String? get fechaCierreFormateada {
    return fechaCierre != null 
        ? DateFormat('dd/MM/yyyy HH:mm').format(fechaCierre!) 
        : null;
  }

  // Formatear montos como moneda
  String get montoInicialFormateado {
    return '₲${montoInicial.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        )}';
  }

  String? get montoFinalFormateado {
    if (montoFinal == null) return null;
    return '₲${montoFinal!.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        )}';
  }
}
