import 'package:drift/drift.dart' show Value;

int supabaseToInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

double supabaseToDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

bool supabaseToBool(dynamic value) {
  if (value is bool) return value;
  if (value is String) {
    final lower = value.toLowerCase();
    return lower == 'true' || lower == '1' || lower == 'yes';
  }
  if (value is num) return value != 0;
  return false;
}

bool _toBool(dynamic value) => supabaseToBool(value);

String supabaseToString(dynamic value) {
  if (value == null) return '';
  return value.toString();
}

String _toString(dynamic value) {
  if (value == null) return '';
  return value.toString();
}

DateTime? _toDateOrNull(dynamic value) {
  if (value == null) return null;
  final s = value.toString();
  if (s.isEmpty) return null;
  return DateTime.tryParse(s);
}

DateTime _toDate(dynamic value) {
  return _toDateOrNull(value) ?? DateTime.now();
}

// Tipos de item en productos (columna `tipo`)
class TipoProducto {
  static const producto = 'Producto';
  static const servicio = 'Servicio';
}

dynamic _unwrap(Object? value) {
  if (value is Value) {
    return value.present ? value.value : null;
  }
  return value;
}

void _maybeAdd(Map<String, dynamic> data, String key, Object? value) {
  final unwrapped = _unwrap(value);
  if (unwrapped != null) {
    data[key] = unwrapped;
  }
}

// ─────────────────────────────────────────────────────────────────────────
// USUARIOS
// ─────────────────────────────────────────────────────────────────────────
class UsuariosCompanion {
  final Object? id;
  final Object? nombre;
  final Object? correo;
  final Object? telefono;
  final Object? rol;
  final Object? activo;

  const UsuariosCompanion({
    this.id,
    this.nombre,
    this.correo,
    this.telefono,
    this.rol,
    this.activo,
  });

  factory UsuariosCompanion.insert({
    required String nombre,
    String? correo,
    String? telefono,
    String rol = 'trabajador',
    bool activo = true,
  }) {
    return UsuariosCompanion(
      nombre: nombre,
      correo: correo,
      telefono: telefono,
      rol: rol,
      activo: activo,
    );
  }

  Map<String, dynamic> toSupabaseMap() {
    final data = <String, dynamic>{};
    _maybeAdd(data, 'id', id);
    _maybeAdd(data, 'nombre', nombre);
    _maybeAdd(data, 'correo', correo);
    _maybeAdd(data, 'telefono', telefono);
    _maybeAdd(data, 'rol', rol);
    _maybeAdd(data, 'activo', activo);
    return data;
  }
}

class Usuario {
  final String id;
  final String nombre;
  final String correo;
  final String telefono;
  final String rol;
  final bool activo;

  const Usuario({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.telefono,
    required this.rol,
    required this.activo,
  });

  factory Usuario.fromSupabase(Map<String, dynamic> row) {
    return Usuario(
      id: _toString(row['id']),
      nombre: _toString(row['nombre']),
      correo: _toString(row['correo']),
      telefono: _toString(row['telefono']),
      rol: _toString(row['rol']),
      activo: row['activo'] == null ? true : _toBool(row['activo']),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// CATEGORIAS
// ─────────────────────────────────────────────────────────────────────────
class CategoriasCompanion {
  final Object? id;
  final Object? nombre;

  const CategoriasCompanion({this.id, this.nombre});

  factory CategoriasCompanion.insert({required String nombre}) {
    return CategoriasCompanion(nombre: nombre);
  }

  Map<String, dynamic> toSupabaseMap() {
    final data = <String, dynamic>{};
    _maybeAdd(data, 'id', id);
    _maybeAdd(data, 'nombre', nombre);
    return data;
  }
}

class Categoria {
  final String id;
  final String nombre;

  const Categoria({required this.id, required this.nombre});

  factory Categoria.fromSupabase(Map<String, dynamic> row) {
    return Categoria(
      id: _toString(row['id']),
      nombre: _toString(row['nombre']),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// PRODUCTOS (incluye tipo='Servicio')
// ─────────────────────────────────────────────────────────────────────────
class ProductosCompanion {
  final Object? id;
  final Object? codigo;
  final Object? nombre;
  final Object? categoriaId;
  final Object? marca;
  final Object? costo;
  final Object? precio;
  final Object? stock;
  final Object? stockMinimo;
  final Object? tipo;
  final Object? activo;

  const ProductosCompanion({
    this.id,
    this.codigo,
    this.nombre,
    this.categoriaId,
    this.marca,
    this.costo,
    this.precio,
    this.stock,
    this.stockMinimo,
    this.tipo,
    this.activo,
  });

  factory ProductosCompanion.insert({
    required String codigo,
    required String nombre,
    String? categoriaId,
    String? marca,
    double costo = 0,
    double precio = 0,
    Object? stock,
    Object? stockMinimo,
    String tipo = TipoProducto.producto,
    bool activo = true,
  }) {
    return ProductosCompanion(
      codigo: codigo,
      nombre: nombre,
      categoriaId: categoriaId,
      marca: marca,
      costo: costo,
      precio: precio,
      stock: stock,
      stockMinimo: stockMinimo,
      tipo: tipo,
      activo: activo,
    );
  }

  Map<String, dynamic> toSupabaseMap() {
    final data = <String, dynamic>{};
    _maybeAdd(data, 'id', id);
    _maybeAdd(data, 'codigo', codigo);
    _maybeAdd(data, 'nombre', nombre);
    _maybeAdd(data, 'categoria_id', categoriaId);
    _maybeAdd(data, 'marca', marca);
    _maybeAdd(data, 'costo', costo);
    _maybeAdd(data, 'precio', precio);
    _maybeAdd(data, 'stock', stock);
    _maybeAdd(data, 'stock_minimo', stockMinimo);
    _maybeAdd(data, 'tipo', tipo);
    _maybeAdd(data, 'activo', activo);
    return data;
  }
}

class Producto {
  final String id;
  final String codigo;
  final String nombre;
  final String categoriaId;
  final String marca;
  final double costo;
  final double precio;
  final int stock;
  final int stockMinimo;
  final String tipo;
  final bool activo;

  const Producto({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.categoriaId,
    required this.marca,
    required this.costo,
    required this.precio,
    required this.stock,
    required this.stockMinimo,
    required this.tipo,
    required this.activo,
  });

  bool get esServicio => tipo == TipoProducto.servicio;

  factory Producto.fromSupabase(Map<String, dynamic> row) {
    return Producto(
      id: _toString(row['id']),
      codigo: _toString(row['codigo']),
      nombre: _toString(row['nombre']),
      categoriaId: _toString(row['categoria_id']),
      marca: _toString(row['marca']),
      costo: supabaseToDouble(row['costo']),
      precio: supabaseToDouble(row['precio']),
      stock: supabaseToInt(row['stock']),
      stockMinimo: supabaseToInt(row['stock_minimo']),
      tipo: row['tipo'] == null || _toString(row['tipo']).isEmpty
          ? TipoProducto.producto
          : _toString(row['tipo']),
      activo: row['activo'] == null ? true : _toBool(row['activo']),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// CLIENTES
// ─────────────────────────────────────────────────────────────────────────
class ClientesCompanion {
  final Object? id;
  final Object? nombre;
  final Object? telefono;
  final Object? correo;
  final Object? direccion;

  const ClientesCompanion({
    this.id,
    this.nombre,
    this.telefono,
    this.correo,
    this.direccion,
  });

  factory ClientesCompanion.insert({
    required String nombre,
    String? telefono,
    String? correo,
    String? direccion,
  }) {
    return ClientesCompanion(
      nombre: nombre,
      telefono: telefono,
      correo: correo,
      direccion: direccion,
    );
  }

  Map<String, dynamic> toSupabaseMap() {
    final data = <String, dynamic>{};
    _maybeAdd(data, 'id', id);
    _maybeAdd(data, 'nombre', nombre);
    _maybeAdd(data, 'telefono', telefono);
    _maybeAdd(data, 'correo', correo);
    _maybeAdd(data, 'direccion', direccion);
    return data;
  }
}

class Cliente {
  final String id;
  final String nombre;
  final String telefono;
  final String correo;
  final String direccion;

  const Cliente({
    required this.id,
    required this.nombre,
    required this.telefono,
    this.correo = '',
    this.direccion = '',
  });

  factory Cliente.fromSupabase(Map<String, dynamic> row) {
    return Cliente(
      id: _toString(row['id']),
      nombre: _toString(row['nombre']),
      telefono: _toString(row['telefono']),
      correo: _toString(row['correo']),
      direccion: _toString(row['direccion']),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// PEDIDOS_ENCARGO (sin producto_id: descripcion libre, con archivado)
// ─────────────────────────────────────────────────────────────────────────
class PedidosEncargoCompanion {
  final Object? id;
  final Object? clienteId;
  final Object? descripcion;
  final Object? fecha;
  final Object? fechaEntrega;
  final Object? estado;
  final Object? total;
  final Object? observaciones;
  final Object? archivado;

  const PedidosEncargoCompanion({
    this.id,
    this.clienteId,
    this.descripcion,
    this.fecha,
    this.fechaEntrega,
    this.estado,
    this.total,
    this.observaciones,
    this.archivado,
  });

  factory PedidosEncargoCompanion.insert({
    required String clienteId,
    required String descripcion,
    Object? fecha,
    Object? fechaEntrega,
    double? total,
    String? observaciones,
  }) {
    return PedidosEncargoCompanion(
      clienteId: clienteId,
      descripcion: descripcion,
      fecha: fecha ?? DateTime.now().toIso8601String(),
      fechaEntrega: fechaEntrega,
      estado: 'pendiente',
      total: total,
      observaciones: observaciones,
      archivado: false,
    );
  }

  Map<String, dynamic> toSupabaseMap() {
    final data = <String, dynamic>{};
    _maybeAdd(data, 'id', id);
    _maybeAdd(data, 'cliente_id', clienteId);
    _maybeAdd(data, 'descripcion', descripcion);
    _maybeAdd(data, 'fecha', fecha);
    _maybeAdd(data, 'fecha_entrega', fechaEntrega);
    _maybeAdd(data, 'estado', estado);
    _maybeAdd(data, 'total', total);
    _maybeAdd(data, 'observaciones', observaciones);
    _maybeAdd(data, 'archivado', archivado);
    return data;
  }
}

class PedidoDetallado {
  final String id;
  final String estado;
  final DateTime fechaSolicitud;
  final DateTime? fechaEntrega;
  final String descripcion;
  final double total;
  final String observaciones;
  final String clienteId;
  final String clienteNombre;
  final String clienteTelefono;
  final bool archivado;

  const PedidoDetallado({
    required this.id,
    required this.estado,
    required this.fechaSolicitud,
    required this.fechaEntrega,
    required this.descripcion,
    required this.total,
    required this.observaciones,
    required this.clienteId,
    required this.clienteNombre,
    required this.clienteTelefono,
    this.archivado = false,
  });
}

// ─────────────────────────────────────────────────────────────────────────
// VENTAS / DETALLES_VENTA (con trabajador_id por línea)
// ─────────────────────────────────────────────────────────────────────────
class VentasCompanion {
  final Object? id;
  final Object? clienteId;
  final Object? usuarioId;
  final Object? fecha;
  final Object? subtotal;
  final Object? descuento;
  final Object? total;
  final Object? metodoPago;
  final Object? observaciones;

  const VentasCompanion({
    this.id,
    this.clienteId,
    this.usuarioId,
    this.fecha,
    this.subtotal,
    this.descuento,
    this.total,
    this.metodoPago,
    this.observaciones,
  });

  factory VentasCompanion.insert({
    required DateTime fecha,
    String? usuarioId,
    String? clienteId,
    required double subtotal,
    double descuento = 0,
    required double total,
    String metodoPago = 'Efectivo',
    String? observaciones,
  }) {
    return VentasCompanion(
      fecha: fecha.toIso8601String(),
      usuarioId: usuarioId,
      clienteId: clienteId,
      subtotal: subtotal,
      descuento: descuento,
      total: total,
      metodoPago: metodoPago,
      observaciones: observaciones,
    );
  }

  Map<String, dynamic> toSupabaseMap() {
    final data = <String, dynamic>{};
    _maybeAdd(data, 'id', id);
    _maybeAdd(data, 'cliente_id', clienteId);
    _maybeAdd(data, 'usuario_id', usuarioId);
    _maybeAdd(data, 'fecha', fecha);
    _maybeAdd(data, 'subtotal', subtotal);
    _maybeAdd(data, 'descuento', descuento);
    _maybeAdd(data, 'total', total);
    _maybeAdd(data, 'metodo_pago', metodoPago);
    _maybeAdd(data, 'observaciones', observaciones);
    return data;
  }
}

class DetallesVentaCompanion {
  final Object? id;
  final Object? ventaId;
  final Object? productoId;
  final Object? trabajadorId;
  final Object? cantidad;
  final Object? precio;
  final Object? subtotal;

  const DetallesVentaCompanion({
    this.id,
    this.ventaId,
    this.productoId,
    this.trabajadorId,
    this.cantidad,
    this.precio,
    this.subtotal,
  });

  factory DetallesVentaCompanion.insert({
    required String ventaId,
    required String productoId,
    String? trabajadorId,
    required int cantidad,
    required double precio,
    required double subtotal,
  }) {
    return DetallesVentaCompanion(
      ventaId: ventaId,
      productoId: productoId,
      trabajadorId: trabajadorId,
      cantidad: cantidad,
      precio: precio,
      subtotal: subtotal,
    );
  }

  Map<String, dynamic> toSupabaseMap() {
    final data = <String, dynamic>{};
    _maybeAdd(data, 'id', id);
    _maybeAdd(data, 'venta_id', ventaId);
    _maybeAdd(data, 'producto_id', productoId);
    _maybeAdd(data, 'trabajador_id', trabajadorId);
    _maybeAdd(data, 'cantidad', cantidad);
    _maybeAdd(data, 'precio', precio);
    _maybeAdd(data, 'subtotal', subtotal);
    return data;
  }
}

// Item en el carrito de venta (producto o servicio)
class ItemCarrito {
  final String productoId;
  int cantidad;
  final double precioUnitario;
  final String nombreProducto;
  final bool esServicio;
  String? trabajadorId;
  late double subtotal;

  ItemCarrito({
    required this.productoId,
    this.cantidad = 1,
    required this.precioUnitario,
    required this.nombreProducto,
    this.esServicio = false,
    this.trabajadorId,
    double? subtotal,
  }) {
    this.subtotal = subtotal ?? (cantidad * precioUnitario);
  }

  void actualizarSubtotal() {
    subtotal = cantidad * precioUnitario;
  }
}

// ─────────────────────────────────────────────────────────────────────────
// GASTOS
// ─────────────────────────────────────────────────────────────────────────
class GastosCompanion {
  final Object? id;
  final Object? usuarioId;
  final Object? concepto;
  final Object? categoria;
  final Object? valor;
  final Object? fecha;
  final Object? observaciones;

  const GastosCompanion({
    this.id,
    this.usuarioId,
    this.concepto,
    this.categoria,
    this.valor,
    this.fecha,
    this.observaciones,
  });

  factory GastosCompanion.insert({
    String? usuarioId,
    String? concepto,
    required String categoria,
    required double valor,
    Object? fecha,
    String? observaciones,
  }) {
    return GastosCompanion(
      usuarioId: usuarioId,
      concepto: concepto,
      categoria: categoria,
      valor: valor,
      fecha: fecha ?? DateTime.now().toIso8601String(),
      observaciones: observaciones,
    );
  }

  Map<String, dynamic> toSupabaseMap() {
    final data = <String, dynamic>{};
    _maybeAdd(data, 'id', id);
    _maybeAdd(data, 'usuario_id', usuarioId);
    _maybeAdd(data, 'concepto', concepto);
    _maybeAdd(data, 'categoria', categoria);
    _maybeAdd(data, 'valor', valor);
    _maybeAdd(data, 'fecha', fecha);
    _maybeAdd(data, 'observaciones', observaciones);
    return data;
  }
}

class Gasto {
  final String id;
  final DateTime fecha;
  final String categoria;
  final String concepto;
  final String observaciones;
  final double valor;
  final String usuarioId;

  const Gasto({
    required this.id,
    required this.fecha,
    required this.categoria,
    required this.concepto,
    required this.observaciones,
    required this.valor,
    required this.usuarioId,
  });

  // Compatibilidad con pantallas que aún llaman `descripcion` / `monto`
  String get descripcion => observaciones.isNotEmpty ? observaciones : concepto;
  double get monto => valor;

  factory Gasto.fromSupabase(Map<String, dynamic> row) {
    return Gasto(
      id: _toString(row['id']),
      fecha: _toDate(row['fecha']),
      categoria: _toString(row['categoria']),
      concepto: _toString(row['concepto']),
      observaciones: _toString(row['observaciones']),
      valor: supabaseToDouble(row['valor']),
      usuarioId: _toString(row['usuario_id']),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// MOVIMIENTOS_INVENTARIO
// ─────────────────────────────────────────────────────────────────────────
class MovimientosInventarioCompanion {
  final Object? id;
  final Object? productoId;
  final Object? usuarioId;
  final Object? tipo;
  final Object? cantidad;
  final Object? stockAnterior;
  final Object? stockNuevo;
  final Object? referencia;
  final Object? observacion;
  final Object? fecha;

  const MovimientosInventarioCompanion({
    this.id,
    this.productoId,
    this.usuarioId,
    this.tipo,
    this.cantidad,
    this.stockAnterior,
    this.stockNuevo,
    this.referencia,
    this.observacion,
    this.fecha,
  });

  factory MovimientosInventarioCompanion.insert({
    required String productoId,
    String? usuarioId,
    required DateTime fecha,
    required TipoMovimiento tipo,
    required int cantidad,
    required int stockAnterior,
    required int stockNuevo,
    String? referencia,
    String? observacion,
  }) {
    return MovimientosInventarioCompanion(
      productoId: productoId,
      usuarioId: usuarioId,
      fecha: fecha.toIso8601String(),
      tipo: tipo.name,
      cantidad: cantidad,
      stockAnterior: stockAnterior,
      stockNuevo: stockNuevo,
      referencia: referencia,
      observacion: observacion,
    );
  }

  Map<String, dynamic> toSupabaseMap() {
    final data = <String, dynamic>{};
    _maybeAdd(data, 'id', id);
    _maybeAdd(data, 'producto_id', productoId);
    _maybeAdd(data, 'usuario_id', usuarioId);
    _maybeAdd(data, 'tipo', tipo);
    _maybeAdd(data, 'cantidad', cantidad);
    _maybeAdd(data, 'stock_anterior', stockAnterior);
    _maybeAdd(data, 'stock_nuevo', stockNuevo);
    _maybeAdd(data, 'referencia', referencia);
    _maybeAdd(data, 'observacion', observacion);
    _maybeAdd(data, 'fecha', fecha);
    return data;
  }
}

class MovimientosInventario {
  final String id;
  final String productoId;
  final String usuarioId;
  final DateTime fecha;
  final TipoMovimiento tipo;
  final int cantidad;
  final int stockAntes;
  final int stockDespues;
  final String? referencia;
  final String motivo;

  const MovimientosInventario({
    required this.id,
    required this.productoId,
    required this.usuarioId,
    required this.fecha,
    required this.tipo,
    required this.cantidad,
    required this.stockAntes,
    required this.stockDespues,
    required this.referencia,
    required this.motivo,
  });

  factory MovimientosInventario.fromSupabase(Map<String, dynamic> row) {
    return MovimientosInventario(
      id: _toString(row['id']),
      productoId: _toString(row['producto_id']),
      usuarioId: _toString(row['usuario_id']),
      fecha: _toDate(row['fecha']),
      tipo: TipoMovimiento.fromString(_toString(row['tipo'])),
      cantidad: supabaseToInt(row['cantidad']),
      stockAntes: supabaseToInt(row['stock_anterior']),
      stockDespues: supabaseToInt(row['stock_nuevo']),
      referencia: row['referencia'] == null ? null : _toString(row['referencia']),
      motivo: _toString(row['observacion']),
    );
  }
}

enum TipoMovimiento {
  entradaCompra,
  salidaVenta,
  ajusteEntrada,
  ajusteSalida;

  static TipoMovimiento fromString(String value) {
    return TipoMovimiento.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TipoMovimiento.entradaCompra,
    );
  }

  static bool esEntrada(TipoMovimiento tipo) {
    return tipo == TipoMovimiento.entradaCompra ||
        tipo == TipoMovimiento.ajusteEntrada;
  }

  static String label(TipoMovimiento tipo) {
    switch (tipo) {
      case TipoMovimiento.entradaCompra:
        return 'Entrada por Compra';
      case TipoMovimiento.salidaVenta:
        return 'Salida por Venta';
      case TipoMovimiento.ajusteEntrada:
        return 'Ajuste de Entrada';
      case TipoMovimiento.ajusteSalida:
        return 'Ajuste de Salida';
    }
  }
}

class ResumenFinanciero {
  final double ingresos;
  final double gastos;
  final double utilidad;

  const ResumenFinanciero({
    required this.ingresos,
    required this.gastos,
    required this.utilidad,
  });
}

class ProductoMasVendido {
  final String nombre;
  final String codigo;
  final int cantidadVendida;
  final double totalVendido;

  const ProductoMasVendido({
    required this.nombre,
    required this.codigo,
    required this.cantidadVendida,
    required this.totalVendido,
  });
}