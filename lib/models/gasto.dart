class CategoriaGasto {
  static const compraInventario = 'Compra de inventario';
  static const servicios = 'Servicios';
  static const nomina = 'Nómina';
  static const otros = 'Otros';

  static const todas = [compraInventario, servicios, nomina, otros];
}

class Gasto {
  final int? id;
  final DateTime fecha;
  final String categoria;
  final String descripcion;
  final double monto;
  final int usuarioId;

  Gasto({
    this.id,
    required this.fecha,
    required this.categoria,
    this.descripcion = '',
    required this.monto,
    required this.usuarioId,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'fecha': fecha.toIso8601String(),
        'categoria': categoria,
        'descripcion': descripcion,
        'monto': monto,
        'usuarioId': usuarioId,
      };

  factory Gasto.fromMap(Map<String, dynamic> map) => Gasto(
        id: map['id'] as int?,
        fecha: DateTime.parse(map['fecha'] as String),
        categoria: map['categoria'] as String,
        descripcion: map['descripcion'] as String? ?? '',
        monto: (map['monto'] as num).toDouble(),
        usuarioId: map['usuarioId'] as int,
      );
}
