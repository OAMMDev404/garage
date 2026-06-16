// Estados posibles de un pedido por encargo
class EstadoPedido {
  static const pendiente = 'pendiente';
  static const enCamino = 'en_camino';
  static const entregado = 'entregado';

  static const todos = [pendiente, enCamino, entregado];

  static String label(String estado) {
    switch (estado) {
      case pendiente:
        return 'Pendiente';
      case enCamino:
        return 'En camino';
      case entregado:
        return 'Entregado';
      default:
        return estado;
    }
  }
}

class PedidoEncargo {
  final int? id;
  final int productoId;
  final int clienteId;
  final String estado;
  final DateTime fechaSolicitud;
  final DateTime? fechaEstimada;

  PedidoEncargo({
    this.id,
    required this.productoId,
    required this.clienteId,
    this.estado = EstadoPedido.pendiente,
    required this.fechaSolicitud,
    this.fechaEstimada,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'productoId': productoId,
        'clienteId': clienteId,
        'estado': estado,
        'fechaSolicitud': fechaSolicitud.toIso8601String(),
        'fechaEstimada': fechaEstimada?.toIso8601String(),
      };

  factory PedidoEncargo.fromMap(Map<String, dynamic> map) => PedidoEncargo(
        id: map['id'] as int?,
        productoId: map['productoId'] as int,
        clienteId: map['clienteId'] as int,
        estado: map['estado'] as String,
        fechaSolicitud: DateTime.parse(map['fechaSolicitud'] as String),
        fechaEstimada: map['fechaEstimada'] != null
            ? DateTime.parse(map['fechaEstimada'] as String)
            : null,
      );

  PedidoEncargo copyWith({String? estado}) => PedidoEncargo(
        id: id,
        productoId: productoId,
        clienteId: clienteId,
        estado: estado ?? this.estado,
        fechaSolicitud: fechaSolicitud,
        fechaEstimada: fechaEstimada,
      );
}
