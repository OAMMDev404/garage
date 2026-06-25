import 'package:drift/drift.dart';

class Usuarios extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get nombre => text()();
  TextColumn get correo => text().unique()();
  TextColumn get passwordHash => text()();
}

class Categorias extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get nombre => text().unique()();
}

class Productos extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get codigo => text().unique()();
  TextColumn get nombre => text()();
  TextColumn get descripcion => text().withDefault(const Constant(''))();
  RealColumn get precioCompra => real()();
  RealColumn get precioVenta => real()();
  IntColumn get stockActual => integer().withDefault(const Constant(0))();
  IntColumn get stockMinimo => integer().withDefault(const Constant(5))();
  BoolColumn get porEncargo => boolean().withDefault(const Constant(false))();
  IntColumn get categoriaId => integer().references(Categorias, #id)();
}

class Clientes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get nombre => text()();
  TextColumn get telefono => text().withDefault(const Constant(''))();
}

class PedidosEncargo extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productoId => integer().references(Productos, #id)();
  IntColumn get clienteId => integer().references(Clientes, #id)();
  TextColumn get estado =>
      text().withDefault(const Constant('pendiente'))();
  DateTimeColumn get fechaSolicitud => dateTime()();
  DateTimeColumn get fechaEstimada => dateTime().nullable()();
}

class Ventas extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get fecha => dateTime()();
  IntColumn get usuarioId => integer().references(Usuarios, #id)();
  IntColumn get clienteId => integer().references(Clientes, #id).nullable()();
  RealColumn get total => real()();
}

class DetallesVenta extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get ventaId => integer().references(Ventas, #id)();
  IntColumn get productoId => integer().references(Productos, #id)();
  IntColumn get cantidad => integer()();
  RealColumn get precioUnitario => real()();
}

class Gastos extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get fecha => dateTime()();
  TextColumn get categoria => text()();
  TextColumn get descripcion => text().withDefault(const Constant(''))();
  RealColumn get monto => real()();
  IntColumn get usuarioId => integer().references(Usuarios, #id)();
}