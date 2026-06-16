class Categoria {
  final int? id;
  final String nombre;

  Categoria({this.id, required this.nombre});

  Map<String, dynamic> toMap() => {'id': id, 'nombre': nombre};

  factory Categoria.fromMap(Map<String, dynamic> map) => Categoria(
        id: map['id'] as int?,
        nombre: map['nombre'] as String,
      );
}
