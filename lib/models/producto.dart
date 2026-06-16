class Producto {
  final int? id;
  final String codigo;
  final String nombre;
  final String descripcion;
  final double precioCompra;
  final double precioVenta;
  final int stockActual;
  final int stockMinimo;
  final bool porEncargo;
  final int categoriaId;

  Producto({
    this.id,
    required this.codigo,
    required this.nombre,
    this.descripcion = '',
    required this.precioCompra,
    required this.precioVenta,
    this.stockActual = 0,
    this.stockMinimo = 5,
    this.porEncargo = false,
    required this.categoriaId,
  });

  bool get bajoStock => stockActual <= stockMinimo;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'codigo': codigo,
      'nombre': nombre,
      'descripcion': descripcion,
      'precioCompra': precioCompra,
      'precioVenta': precioVenta,
      'stockActual': stockActual,
      'stockMinimo': stockMinimo,
      'porEncargo': porEncargo ? 1 : 0,
      'categoriaId': categoriaId,
    };
  }

  factory Producto.fromMap(Map<String, dynamic> map) {
    return Producto(
      id: map['id'] as int?,
      codigo: map['codigo'] as String,
      nombre: map['nombre'] as String,
      descripcion: map['descripcion'] as String? ?? '',
      precioCompra: (map['precioCompra'] as num).toDouble(),
      precioVenta: (map['precioVenta'] as num).toDouble(),
      stockActual: map['stockActual'] as int,
      stockMinimo: map['stockMinimo'] as int,
      porEncargo: (map['porEncargo'] as int) == 1,
      categoriaId: map['categoriaId'] as int,
    );
  }

  Producto copyWith({
    int? id,
    String? codigo,
    String? nombre,
    String? descripcion,
    double? precioCompra,
    double? precioVenta,
    int? stockActual,
    int? stockMinimo,
    bool? porEncargo,
    int? categoriaId,
  }) {
    return Producto(
      id: id ?? this.id,
      codigo: codigo ?? this.codigo,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      precioCompra: precioCompra ?? this.precioCompra,
      precioVenta: precioVenta ?? this.precioVenta,
      stockActual: stockActual ?? this.stockActual,
      stockMinimo: stockMinimo ?? this.stockMinimo,
      porEncargo: porEncargo ?? this.porEncargo,
      categoriaId: categoriaId ?? this.categoriaId,
    );
  }
}
