class Usuario {
  final int? id;
  final String nombre;
  final String correo;
  final String passwordHash;

  Usuario({
    this.id,
    required this.nombre,
    required this.correo,
    required this.passwordHash,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'nombre': nombre,
        'correo': correo,
        'passwordHash': passwordHash,
      };

  factory Usuario.fromMap(Map<String, dynamic> map) => Usuario(
        id: map['id'] as int?,
        nombre: map['nombre'] as String,
        correo: map['correo'] as String,
        passwordHash: map['passwordHash'] as String,
      );
}
