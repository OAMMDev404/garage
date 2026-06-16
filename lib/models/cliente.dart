class Cliente {
  final int? id;
  final String nombre;
  final String telefono;

  Cliente({this.id, required this.nombre, this.telefono = ''});

  Map<String, dynamic> toMap() => {
        'id': id,
        'nombre': nombre,
        'telefono': telefono,
      };

  factory Cliente.fromMap(Map<String, dynamic> map) => Cliente(
        id: map['id'] as int?,
        nombre: map['nombre'] as String,
        telefono: map['telefono'] as String? ?? '',
      );
}
