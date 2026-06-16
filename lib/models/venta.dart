class Venta {
  final int? id;
  final DateTime fecha;
  final int usuarioId;
  final int? clienteId;
  final double total;

  Venta({
    this.id,
    required this.fecha,
    required this.usuarioId,
    this.clienteId,
    required this.total,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'fecha': fecha.toIso8601String(),
        'usuarioId': usuarioId,
        'clienteId': clienteId,
        'total': total,
      };

  factory Venta.fromMap(Map<String, dynamic> map) => Venta(
        id: map['id'] as int?,
        fecha: DateTime.parse(map['fecha'] as String),
        usuarioId: map['usuarioId'] as int,
        clienteId: map['clienteId'] as int?,
        total: (map['total'] as num).toDouble(),
      );
}

class DetalleVenta {
  final int? id;
  final int ventaId;
  final int productoId;
  final int cantidad;
  final double precioUnitario;

  DetalleVenta({
    this.id,
    required this.ventaId,
    required this.productoId,
    required this.cantidad,
    required this.precioUnitario,
  });

  double get subtotal => cantidad * precioUnitario;

  Map<String, dynamic> toMap() => {
        'id': id,
        'ventaId': ventaId,
        'productoId': productoId,
        'cantidad': cantidad,
        'precioUnitario': precioUnitario,
      };

  factory DetalleVenta.fromMap(Map<String, dynamic> map) => DetalleVenta(
        id: map['id'] as int?,
        ventaId: map['ventaId'] as int,
        productoId: map['productoId'] as int,
        cantidad: map['cantidad'] as int,
        precioUnitario: (map['precioUnitario'] as num).toDouble(),
      );
}

// Estructura usada en memoria para armar una venta antes de guardarla
class ItemCarrito {
  final int productoId;
  final String nombreProducto;
  final double precioUnitario;
  int cantidad;

  ItemCarrito({
    required this.productoId,
    required this.nombreProducto,
    required this.precioUnitario,
    this.cantidad = 1,
  });

  double get subtotal => cantidad * precioUnitario;
}
