import 'package:drift_flutter/drift_flutter.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'dart:convert';

import 'tables.dart';

part 'app_database.g.dart';

class PedidoDetallado {
  final int id;
  final String estado;
  final DateTime fechaSolicitud;
  final DateTime? fechaEstimada;
  final int productoId;
  final String productoNombre;
  final String productoCodigo;
  final int clienteId;
  final String clienteNombre;
  final String clienteTelefono;

  PedidoDetallado({
    required this.id,
    required this.estado,
    required this.fechaSolicitud,
    this.fechaEstimada,
    required this.productoId,
    required this.productoNombre,
    required this.productoCodigo,
    required this.clienteId,
    required this.clienteNombre,
    required this.clienteTelefono,
  });
}

class ProductoMasVendido {
  final String nombre;
  final String codigo;
  final int cantidadVendida;
  final double totalVendido;

  ProductoMasVendido({
    required this.nombre,
    required this.codigo,
    required this.cantidadVendida,
    required this.totalVendido,
  });
}

class ResumenFinanciero {
  final double ingresos;
  final double gastos;
  final double utilidad;

  ResumenFinanciero({
    required this.ingresos,
    required this.gastos,
    required this.utilidad,
  });
}

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

@DriftDatabase(tables: [
  Usuarios,
  Categorias,
  Productos,
  Clientes,
  PedidosEncargo,
  Ventas,
  DetallesVenta,
  Gastos,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  static final AppDatabase instance = AppDatabase._singleton();
  AppDatabase._singleton() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _seedData();
        },
      );

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'taller_app');
  }

  Future<void> _seedData() async {
    final categoriasIniciales = [
      'Repuestos', 'Lubricantes', 'Herramientas', 'Eléctrico', 'Llantas', 'Otros',
    ];
    for (final nombre in categoriasIniciales) {
      await into(categorias).insert(
        CategoriasCompanion.insert(nombre: nombre),
        mode: InsertMode.insertOrIgnore,
      );
    }

    final adminId = await into(usuarios).insertReturningOrNull(
      UsuariosCompanion.insert(
        nombre: 'Administrador',
        correo: 'admin@taller.com',
        passwordHash: _hashPassword('123456'),
      ),
      mode: InsertMode.insertOrIgnore,
    );
    if (adminId == null) return;

    final todasCats = await select(categorias).get();
    final catRepuestos = todasCats.firstWhere((c) => c.nombre == 'Repuestos');
    final catLubricantes = todasCats.firstWhere((c) => c.nombre == 'Lubricantes');

    final prod1Id = await into(productos).insertReturning(
      ProductosCompanion.insert(
        codigo: 'PROD-0001',
        nombre: 'Pastillas de freno',
        descripcion: const Value('Pastillas de freno'),
        precioCompra: 50.0,
        precioVenta: 80.0,
        stockActual: const Value(15),
        stockMinimo: const Value(5),
        categoriaId: catRepuestos.id,
      ),
    );

    await into(productos).insert(
      ProductosCompanion.insert(
        codigo: 'PROD-0002',
        nombre: 'Aceite 10W-40',
        descripcion: const Value('Aceite lubricante'),
        precioCompra: 30.0,
        precioVenta: 45.0,
        stockActual: const Value(2),
        stockMinimo: const Value(10),
        categoriaId: catLubricantes.id,
      ),
    );

    final cliente1Id = await into(clientes).insertReturning(
      ClientesCompanion.insert(
        nombre: 'Juan Pérez',
        telefono: const Value('555-0001'),
      ),
    );

    final ventaId = await into(ventas).insertReturning(
      VentasCompanion.insert(
        fecha: DateTime.now(),
        usuarioId: adminId.id,
        clienteId: Value(cliente1Id.id),
        total: 160.0,
      ),
    );

    await into(detallesVenta).insert(
      DetallesVentaCompanion.insert(
        ventaId: ventaId.id,
        productoId: prod1Id.id,
        cantidad: 2,
        precioUnitario: 80.0,
      ),
    );

    await (update(productos)..where((p) => p.id.equals(prod1Id.id)))
        .write(ProductosCompanion(stockActual: Value(prod1Id.stockActual - 2)));

    await into(gastos).insert(
      GastosCompanion.insert(
        fecha: DateTime.now(),
        categoria: 'Mantenimiento',
        descripcion: const Value('Reparación de compresor'),
        monto: 150.0,
        usuarioId: adminId.id,
      ),
    );
  }

  // ── USUARIOS ──────────────────────────────────────────────────────────────
  String _hashPassword(String password) =>
      sha256.convert(utf8.encode(password)).toString();

  Future<int> crearUsuario(String nombre, String correo, String password) =>
      into(usuarios).insert(UsuariosCompanion.insert(
        nombre: nombre,
        correo: correo,
        passwordHash: _hashPassword(password),
      ));

  Future<Usuario?> login(String correo, String password) async {
    final hash = _hashPassword(password);
    return (select(usuarios)
          ..where((u) => u.correo.equals(correo) & u.passwordHash.equals(hash)))
        .getSingleOrNull();
  }

  // ── CATEGORÍAS ────────────────────────────────────────────────────────────
  Stream<List<Categoria>> watchCategorias() =>
      (select(categorias)..orderBy([(c) => OrderingTerm.asc(c.nombre)])).watch();

  Future<List<Categoria>> obtenerCategorias() =>
      (select(categorias)..orderBy([(c) => OrderingTerm.asc(c.nombre)])).get();

  Future<int> crearCategoria(String nombre) =>
      into(categorias).insert(CategoriasCompanion.insert(nombre: nombre));

  // ── PRODUCTOS ─────────────────────────────────────────────────────────────
  Stream<List<Producto>> watchProductos({
    String? busqueda,
    int? categoriaId,
    bool soloBajoStock = false,
    bool soloEncargo = false,
  }) {
    return (select(productos)
          ..orderBy([(p) => OrderingTerm.asc(p.nombre)])
          ..where((p) {
            Expression<bool> filtro = const Constant(true);
            if (busqueda != null && busqueda.trim().isNotEmpty) {
              filtro = filtro &
                  (p.nombre.like('%$busqueda%') | p.codigo.like('%$busqueda%'));
            }
            if (categoriaId != null) {
              filtro = filtro & p.categoriaId.equals(categoriaId);
            }
            if (soloBajoStock) {
              filtro = filtro &
                  const CustomExpression<bool>('stock_actual <= stock_minimo');
            }
            if (soloEncargo) {
              filtro = filtro & p.porEncargo.equals(true);
            }
            return filtro;
          }))
        .watch();
  }

  Stream<List<Producto>> watchProductosBajoStock() {
    return (select(productos)
          ..where((p) =>
              const CustomExpression<bool>('stock_actual <= stock_minimo'))
          ..orderBy([(p) => OrderingTerm.asc(p.nombre)]))
        .watch();
  }

  Future<List<Producto>> obtenerProductos({
    String? busqueda,
    int? categoriaId,
    bool soloBajoStock = false,
  }) async {
    final query = select(productos)
      ..orderBy([(p) => OrderingTerm.asc(p.nombre)]);
    if (busqueda != null && busqueda.trim().isNotEmpty) {
      query.where(
          (p) => p.nombre.like('%$busqueda%') | p.codigo.like('%$busqueda%'));
    }
    if (categoriaId != null) {
      query.where((p) => p.categoriaId.equals(categoriaId));
    }
    if (soloBajoStock) {
      query.where(
          (p) => const CustomExpression<bool>('stock_actual <= stock_minimo'));
    }
    return query.get();
  }

  Future<Producto?> obtenerProductoPorId(int id) =>
      (select(productos)..where((p) => p.id.equals(id))).getSingleOrNull();

  Future<String> generarSiguienteCodigo() async {
    final count = await (selectOnly(productos)
          ..addColumns([productos.id.count()]))
        .map((r) => r.read(productos.id.count()))
        .getSingle();
    final siguiente = (count ?? 0) + 1;
    return 'PROD-${siguiente.toString().padLeft(4, '0')}';
  }

  Future<int> crearProducto(ProductosCompanion producto) =>
      into(productos).insert(producto);

  Future<bool> actualizarProducto(ProductosCompanion producto) =>
      update(productos).replace(producto);

  Future<int> eliminarProducto(int id) =>
      (delete(productos)..where((p) => p.id.equals(id))).go();

  // ── CLIENTES ──────────────────────────────────────────────────────────────
  Future<int> crearCliente({required String nombre, String telefono = ''}) =>
      into(clientes).insert(
          ClientesCompanion.insert(nombre: nombre, telefono: Value(telefono)));

  Future<List<Cliente>> obtenerClientes() =>
      (select(clientes)..orderBy([(c) => OrderingTerm.asc(c.nombre)])).get();

  // ── PEDIDOS POR ENCARGO ───────────────────────────────────────────────────
  Stream<List<PedidoDetallado>> watchPedidosEncargo({String? estado}) {
    final query = select(pedidosEncargo).join([
      innerJoin(productos, productos.id.equalsExp(pedidosEncargo.productoId)),
      innerJoin(clientes, clientes.id.equalsExp(pedidosEncargo.clienteId)),
    ]);
    if (estado != null) query.where(pedidosEncargo.estado.equals(estado));
    query.orderBy([OrderingTerm.desc(pedidosEncargo.fechaSolicitud)]);

    return query.watch().map((rows) => rows.map((row) {
          final pe = row.readTable(pedidosEncargo);
          final p = row.readTable(productos);
          final c = row.readTable(clientes);
          return PedidoDetallado(
            id: pe.id,
            estado: pe.estado,
            fechaSolicitud: pe.fechaSolicitud,
            fechaEstimada: pe.fechaEstimada,
            productoId: p.id,
            productoNombre: p.nombre,
            productoCodigo: p.codigo,
            clienteId: c.id,
            clienteNombre: c.nombre,
            clienteTelefono: c.telefono,
          );
        }).toList());
  }

  Future<int> crearPedidoEncargo({
    required int productoId,
    required int clienteId,
    DateTime? fechaEstimada,
  }) =>
      into(pedidosEncargo).insert(PedidosEncargoCompanion.insert(
        productoId: productoId,
        clienteId: clienteId,
        fechaSolicitud: DateTime.now(),
        fechaEstimada: Value(fechaEstimada),
      ));

  Future<void> actualizarEstadoPedido(int id, String nuevoEstado) =>
      (update(pedidosEncargo)..where((pe) => pe.id.equals(id)))
          .write(PedidosEncargoCompanion(estado: Value(nuevoEstado)));

  // ── VENTAS ────────────────────────────────────────────────────────────────
  Future<int> registrarVenta({
    required int usuarioId,
    int? clienteId,
    required List<ItemCarrito> items,
  }) async {
    final total = items.fold<double>(0, (s, i) => s + i.subtotal);
    return transaction(() async {
      final ventaId = await into(ventas).insert(VentasCompanion.insert(
        fecha: DateTime.now(),
        usuarioId: usuarioId,
        clienteId: Value(clienteId),
        total: total,
      ));
      for (final item in items) {
        await into(detallesVenta).insert(DetallesVentaCompanion.insert(
          ventaId: ventaId,
          productoId: item.productoId,
          cantidad: item.cantidad,
          precioUnitario: item.precioUnitario,
        ));
        final prod = await obtenerProductoPorId(item.productoId);
        await (update(productos)..where((p) => p.id.equals(item.productoId)))
            .write(ProductosCompanion(
                stockActual: Value(prod!.stockActual - item.cantidad)));
      }
      return ventaId;
    });
  }

  // ── GASTOS ────────────────────────────────────────────────────────────────
  Stream<List<Gasto>> watchGastos({DateTime? desde, DateTime? hasta}) {
    return (select(gastos)
          ..orderBy([(g) => OrderingTerm.desc(g.fecha)])
          ..where((g) {
            Expression<bool> filtro = const Constant(true);
            if (desde != null) filtro = filtro & g.fecha.isBiggerOrEqualValue(desde);
            if (hasta != null) filtro = filtro & g.fecha.isSmallerOrEqualValue(hasta);
            return filtro;
          }))
        .watch();
  }

  Future<int> crearGasto({
    required String categoria,
    required double monto,
    required int usuarioId,
    String descripcion = '',
  }) =>
      into(gastos).insert(GastosCompanion.insert(
        fecha: DateTime.now(),
        categoria: categoria,
        descripcion: Value(descripcion),
        monto: monto,
        usuarioId: usuarioId,
      ));

  Future<void> registrarCompraInventario({
    required int usuarioId,
    required int productoId,
    required int cantidadRecibida,
    required double monto,
    String descripcion = '',
  }) async {
    await transaction(() async {
      final producto = await obtenerProductoPorId(productoId);
      if (producto == null) throw Exception('Producto no encontrado');
      final desc = descripcion.isNotEmpty
          ? descripcion
          : 'Entrada de stock: ${producto.nombre} (+$cantidadRecibida uds)';
      await into(gastos).insert(GastosCompanion.insert(
        fecha: DateTime.now(),
        categoria: 'Compra de inventario',
        descripcion: Value(desc),
        monto: monto,
        usuarioId: usuarioId,
      ));
      await (update(productos)..where((p) => p.id.equals(productoId))).write(
          ProductosCompanion(
              stockActual: Value(producto.stockActual + cantidadRecibida)));
    });
  }

  // ── REPORTES ──────────────────────────────────────────────────────────────
  Stream<ResumenFinanciero> watchResumenFinanciero({DateTime? desde}) {
    final ventasStream = (selectOnly(ventas)
          ..addColumns([ventas.total.sum()])
          ..where(desde != null
              ? ventas.fecha.isBiggerOrEqualValue(desde)
              : const Constant(true)))
        .map((r) => r.read(ventas.total.sum()) ?? 0.0)
        .watchSingle();

    return ventasStream.asyncMap((ingresos) async {
      final totalGastos = await (selectOnly(gastos)
            ..addColumns([gastos.monto.sum()])
            ..where(desde != null
                ? gastos.fecha.isBiggerOrEqualValue(desde)
                : const Constant(true)))
          .map((r) => r.read(gastos.monto.sum()) ?? 0.0)
          .getSingle();
      return ResumenFinanciero(
        ingresos: ingresos,
        gastos: totalGastos,
        utilidad: ingresos - totalGastos,
      );
    });
  }

  Stream<List<ProductoMasVendido>> watchProductosMasVendidos({
    DateTime? desde,
    int limite = 5,
  }) {
    final cantidadSum = detallesVenta.cantidad.sum();
    // Usamos expresión SQL cruda para evitar el error de tipos int*double
    final totalSum =
        const CustomExpression<double>('SUM(detalles_venta.cantidad * detalles_venta.precio_unitario)');

    final query = select(detallesVenta).join([
      innerJoin(ventas, ventas.id.equalsExp(detallesVenta.ventaId)),
      innerJoin(productos, productos.id.equalsExp(detallesVenta.productoId)),
    ]);

    if (desde != null) {
      query.where(ventas.fecha.isBiggerOrEqualValue(desde));
    }

    query
      ..addColumns([cantidadSum, totalSum])
      ..groupBy([detallesVenta.productoId])
      ..orderBy([OrderingTerm.desc(cantidadSum)])
      ..limit(limite);

    return query.watch().map((rows) => rows.map((row) {
          final p = row.readTable(productos);
          return ProductoMasVendido(
            nombre: p.nombre,
            codigo: p.codigo,
            cantidadVendida: row.read(cantidadSum) ?? 0,
            totalVendido: row.read(totalSum) ?? 0.0,
          );
        }).toList());
  }
}