import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

import '../models/producto.dart';
import '../models/categoria.dart';
import '../models/cliente.dart';
import '../models/pedido_encargo.dart';
import '../models/venta.dart';
import '../models/gasto.dart';
import '../models/usuario.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  DatabaseHelper._internal();

  static Database? _database;

  // Guarda la Future de inicialización en curso. Si varias pantallas piden
  // la base de datos al mismo tiempo (por ejemplo, los 4 tabs del
  // IndexedStack en MainShell, que se construyen todos de una vez),
  // todas esperan ESTA MISMA Future en lugar de disparar openDatabase()
  // varias veces en paralelo, lo que podía causar errores como
  // "table producto already exists" durante un onUpgrade concurrente.
  static Future<Database>? _initializing;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _initializing ??= _initDB();
    _database = await _initializing;
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'taller_app.db');

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: (db, oldVersion, newVersion) async {
        // Borrar todas las tablas y recrear
        await db.execute('DROP TABLE IF EXISTS detalle_venta');
        await db.execute('DROP TABLE IF EXISTS venta');
        await db.execute('DROP TABLE IF EXISTS pedido_encargo');
        await db.execute('DROP TABLE IF EXISTS gasto');
        await db.execute('DROP TABLE IF EXISTS producto');
        await db.execute('DROP TABLE IF EXISTS cliente');
        await db.execute('DROP TABLE IF EXISTS usuario');
        await db.execute('DROP TABLE IF EXISTS categoria');

        // Recrear la BD con datos iniciales
        await _createDB(db, newVersion);
      },
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE usuario (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        correo TEXT NOT NULL UNIQUE,
        passwordHash TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE categoria (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL UNIQUE
      )
    ''');

    await db.execute('''
      CREATE TABLE producto (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        codigo TEXT NOT NULL UNIQUE,
        nombre TEXT NOT NULL,
        descripcion TEXT,
        precioCompra REAL NOT NULL,
        precioVenta REAL NOT NULL,
        stockActual INTEGER NOT NULL DEFAULT 0,
        stockMinimo INTEGER NOT NULL DEFAULT 5,
        porEncargo INTEGER NOT NULL DEFAULT 0,
        categoriaId INTEGER NOT NULL,
        FOREIGN KEY (categoriaId) REFERENCES categoria (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE cliente (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        telefono TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE pedido_encargo (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        productoId INTEGER NOT NULL,
        clienteId INTEGER NOT NULL,
        estado TEXT NOT NULL DEFAULT 'pendiente',
        fechaSolicitud TEXT NOT NULL,
        fechaEstimada TEXT,
        FOREIGN KEY (productoId) REFERENCES producto (id),
        FOREIGN KEY (clienteId) REFERENCES cliente (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE venta (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fecha TEXT NOT NULL,
        usuarioId INTEGER NOT NULL,
        clienteId INTEGER,
        total REAL NOT NULL,
        FOREIGN KEY (usuarioId) REFERENCES usuario (id),
        FOREIGN KEY (clienteId) REFERENCES cliente (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE detalle_venta (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ventaId INTEGER NOT NULL,
        productoId INTEGER NOT NULL,
        cantidad INTEGER NOT NULL,
        precioUnitario REAL NOT NULL,
        FOREIGN KEY (ventaId) REFERENCES venta (id),
        FOREIGN KEY (productoId) REFERENCES producto (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE gasto (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fecha TEXT NOT NULL,
        categoria TEXT NOT NULL,
        descripcion TEXT,
        monto REAL NOT NULL,
        usuarioId INTEGER NOT NULL,
        FOREIGN KEY (usuarioId) REFERENCES usuario (id)
      )
    ''');

    // Datos iniciales: categorías comunes de un taller mecánico
    final categoriasIniciales = [
      'Repuestos',
      'Lubricantes',
      'Herramientas',
      'Eléctrico',
      'Llantas',
      'Otros',
    ];
    for (final nombre in categoriasIniciales) {
      await db.insert('categoria', {'nombre': nombre});
    }

    // Datos de prueba simples
    try {
      // Crear usuario
      final usuarioId = await db.insert('usuario', {
        'nombre': 'Administrador',
        'correo': 'admin@taller.com',
        'passwordHash': sha256.convert(utf8.encode('123456')).toString(),
      });

      // Crear clientes
      final clienteId1 = await db.insert('cliente', {
        'nombre': 'Juan Pérez',
        'telefono': '555-0001',
      });

      // Crear productos de prueba
      final productId1 = await db.insert('producto', {
        'codigo': 'PROD-0001',
        'nombre': 'Pastillas de freno',
        'precioCompra': 50.0,
        'precioVenta': 80.0,
        'stockActual': 15,
        'stockMinimo': 5,
        'categoriaId': 1,
        'descripcion': 'Pastillas de freno',
      });

      final productId2 = await db.insert('producto', {
        'codigo': 'PROD-0002',
        'nombre': 'Aceite 10W-40',
        'precioCompra': 30.0,
        'precioVenta': 45.0,
        'stockActual': 2,
        'stockMinimo': 10,
        'categoriaId': 2,
        'descripcion': 'Aceite lubricante',
      });

      // Crear venta de prueba
      final ventaId = await db.insert('venta', {
        'fecha': DateTime.now().toIso8601String(),
        'usuarioId': usuarioId,
        'clienteId': clienteId1,
        'total': 160.0,
      });

      // Detalles de venta
      await db.insert('detalle_venta', {
        'ventaId': ventaId,
        'productoId': productId1,
        'cantidad': 2,
        'precioUnitario': 80.0,
      });

      // Descontar stock
      await db.rawUpdate(
        'UPDATE producto SET stockActual = stockActual - 2 WHERE id = ?',
        [productId1],
      );

      // Crear gasto de prueba
      await db.insert('gasto', {
        'fecha': DateTime.now().toIso8601String(),
        'categoria': 'Mantenimiento',
        'descripcion': 'Reparación de compresor',
        'monto': 150.0,
        'usuarioId': usuarioId,
      });
    } catch (e) {
      // Ignorar errores en datos de prueba
    }
  }

  // ---------------------------------------------------------------------
  // USUARIO
  // ---------------------------------------------------------------------
  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  Future<int> crearUsuario(String nombre, String correo, String password) async {
    final db = await database;
    return await db.insert('usuario', {
      'nombre': nombre,
      'correo': correo,
      'passwordHash': _hashPassword(password),
    });
  }

  Future<Usuario?> login(String correo, String password) async {
    final db = await database;
    final hash = _hashPassword(password);
    final result = await db.query(
      'usuario',
      where: 'correo = ? AND passwordHash = ?',
      whereArgs: [correo, hash],
    );
    if (result.isEmpty) return null;
    return Usuario.fromMap(result.first);
  }

  // ---------------------------------------------------------------------
  // CATEGORIA
  // ---------------------------------------------------------------------
  Future<List<Categoria>> obtenerCategorias() async {
    final db = await database;
    final result = await db.query('categoria', orderBy: 'nombre');
    return result.map((m) => Categoria.fromMap(m)).toList();
  }

  Future<int> crearCategoria(Categoria categoria) async {
    final db = await database;
    return await db.insert('categoria', categoria.toMap()..remove('id'));
  }

  // ---------------------------------------------------------------------
  // PRODUCTO
  // ---------------------------------------------------------------------
  Future<int> crearProducto(Producto producto) async {
    final db = await database;
    return await db.insert('producto', producto.toMap()..remove('id'));
  }

  Future<int> actualizarProducto(Producto producto) async {
    final db = await database;
    return await db.update(
      'producto',
      producto.toMap(),
      where: 'id = ?',
      whereArgs: [producto.id],
    );
  }

  Future<int> eliminarProducto(int id) async {
    final db = await database;
    return await db.delete('producto', where: 'id = ?', whereArgs: [id]);
  }

  /// Obtiene productos con filtros opcionales: texto de búsqueda
  /// (por nombre o código), categoría, y si solo se quieren los de bajo stock.
  Future<List<Producto>> obtenerProductos({
    String? busqueda,
    int? categoriaId,
    bool soloBajoStock = false,
  }) async {
    final db = await database;

    final where = <String>[];
    final args = <dynamic>[];

    if (busqueda != null && busqueda.trim().isNotEmpty) {
      where.add('(nombre LIKE ? OR codigo LIKE ?)');
      args.add('%$busqueda%');
      args.add('%$busqueda%');
    }
    if (categoriaId != null) {
      where.add('categoriaId = ?');
      args.add(categoriaId);
    }
    if (soloBajoStock) {
      where.add('stockActual <= stockMinimo');
    }

    final result = await db.query(
      'producto',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'nombre',
    );
    return result.map((m) => Producto.fromMap(m)).toList();
  }

  Future<Producto?> obtenerProductoPorId(int id) async {
    final db = await database;
    final result = await db.query('producto', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return Producto.fromMap(result.first);
  }

  /// Genera el siguiente código secuencial, ej: PROD-0001
  Future<String> generarSiguienteCodigo() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as total FROM producto');
    final total = (result.first['total'] as int) + 1;
    return 'PROD-${total.toString().padLeft(4, '0')}';
  }

  Future<List<Producto>> obtenerProductosBajoStock() async {
    return obtenerProductos(soloBajoStock: true);
  }

  // ---------------------------------------------------------------------
  // CLIENTE
  // ---------------------------------------------------------------------
  Future<int> crearCliente(Cliente cliente) async {
    final db = await database;
    return await db.insert('cliente', cliente.toMap()..remove('id'));
  }

  Future<List<Cliente>> obtenerClientes() async {
    final db = await database;
    final result = await db.query('cliente', orderBy: 'nombre');
    return result.map((m) => Cliente.fromMap(m)).toList();
  }

  // ---------------------------------------------------------------------
  // PEDIDO POR ENCARGO
  // ---------------------------------------------------------------------
  Future<int> crearPedidoEncargo(PedidoEncargo pedido) async {
    final db = await database;
    return await db.insert('pedido_encargo', pedido.toMap()..remove('id'));
  }

  Future<int> actualizarEstadoPedido(int id, String nuevoEstado) async {
    final db = await database;
    return await db.update(
      'pedido_encargo',
      {'estado': nuevoEstado},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Devuelve los pedidos por encargo junto con datos del producto y cliente
  Future<List<Map<String, dynamic>>> obtenerPedidosEncargoDetallados({
    String? estado,
  }) async {
    final db = await database;
    String sql = '''
      SELECT
        pe.id as id,
        pe.estado as estado,
        pe.fechaSolicitud as fechaSolicitud,
        pe.fechaEstimada as fechaEstimada,
        p.id as productoId,
        p.nombre as productoNombre,
        p.codigo as productoCodigo,
        c.id as clienteId,
        c.nombre as clienteNombre,
        c.telefono as clienteTelefono
      FROM pedido_encargo pe
      INNER JOIN producto p ON p.id = pe.productoId
      INNER JOIN cliente c ON c.id = pe.clienteId
    ''';
    final args = <dynamic>[];
    if (estado != null) {
      sql += ' WHERE pe.estado = ?';
      args.add(estado);
    }
    sql += ' ORDER BY pe.fechaSolicitud DESC';

    return await db.rawQuery(sql, args);
  }

  // ---------------------------------------------------------------------
  // VENTAS
  // ---------------------------------------------------------------------
  /// Registra una venta completa: la cabecera, sus detalles y descuenta
  /// el stock de cada producto vendido. Todo dentro de una transacción.
  Future<int> registrarVenta({
    required int usuarioId,
    int? clienteId,
    required List<ItemCarrito> items,
  }) async {
    final db = await database;
    final total = items.fold<double>(0, (sum, item) => sum + item.subtotal);

    return await db.transaction((txn) async {
      final ventaId = await txn.insert('venta', {
        'fecha': DateTime.now().toIso8601String(),
        'usuarioId': usuarioId,
        'clienteId': clienteId,
        'total': total,
      });

      for (final item in items) {
        await txn.insert('detalle_venta', {
          'ventaId': ventaId,
          'productoId': item.productoId,
          'cantidad': item.cantidad,
          'precioUnitario': item.precioUnitario,
        });

        // Descontar stock
        await txn.rawUpdate(
          'UPDATE producto SET stockActual = stockActual - ? WHERE id = ?',
          [item.cantidad, item.productoId],
        );
      }

      return ventaId;
    });
  }

  Future<List<Venta>> obtenerVentas({DateTime? desde, DateTime? hasta}) async {
    final db = await database;
    final where = <String>[];
    final args = <dynamic>[];

    if (desde != null) {
      where.add('fecha >= ?');
      args.add(desde.toIso8601String());
    }
    if (hasta != null) {
      where.add('fecha <= ?');
      args.add(hasta.toIso8601String());
    }

    final result = await db.query(
      'venta',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'fecha DESC',
    );
    return result.map((m) => Venta.fromMap(m)).toList();
  }

  // ---------------------------------------------------------------------
  // GASTOS
  // ---------------------------------------------------------------------
  Future<int> crearGasto(Gasto gasto) async {
    final db = await database;
    return await db.insert('gasto', gasto.toMap()..remove('id'));
  }

  Future<List<Gasto>> obtenerGastos({DateTime? desde, DateTime? hasta}) async {
    final db = await database;
    final where = <String>[];
    final args = <dynamic>[];

    if (desde != null) {
      where.add('fecha >= ?');
      args.add(desde.toIso8601String());
    }
    if (hasta != null) {
      where.add('fecha <= ?');
      args.add(hasta.toIso8601String());
    }

    final result = await db.query(
      'gasto',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'fecha DESC',
    );
    return result.map((m) => Gasto.fromMap(m)).toList();
  }

  // ---------------------------------------------------------------------
  // REPORTES / DASHBOARD
  // ---------------------------------------------------------------------
  /// Calcula ingresos, gastos y utilidad para un rango de fechas.
  /// Si no se especifican fechas, calcula sobre todo el historial.
  Future<Map<String, double>> obtenerResumenFinanciero({
    DateTime? desde,
    DateTime? hasta,
  }) async {
    final db = await database;

    final whereVenta = <String>[];
    final argsVenta = <dynamic>[];
    if (desde != null) {
      whereVenta.add('fecha >= ?');
      argsVenta.add(desde.toIso8601String());
    }
    if (hasta != null) {
      whereVenta.add('fecha <= ?');
      argsVenta.add(hasta.toIso8601String());
    }

    final sqlVentas = '''
      SELECT COALESCE(SUM(total), 0) as ingresos FROM venta
      ${whereVenta.isEmpty ? '' : 'WHERE ${whereVenta.join(' AND ')}'}
    ''';
    final ingresosResult = await db.rawQuery(sqlVentas, argsVenta);
    final ingresos = (ingresosResult.first['ingresos'] as num).toDouble();

    final whereGasto = <String>[];
    final argsGasto = <dynamic>[];
    if (desde != null) {
      whereGasto.add('fecha >= ?');
      argsGasto.add(desde.toIso8601String());
    }
    if (hasta != null) {
      whereGasto.add('fecha <= ?');
      argsGasto.add(hasta.toIso8601String());
    }

    final sqlGastos = '''
      SELECT COALESCE(SUM(monto), 0) as gastos FROM gasto
      ${whereGasto.isEmpty ? '' : 'WHERE ${whereGasto.join(' AND ')}'}
    ''';
    final gastosResult = await db.rawQuery(sqlGastos, argsGasto);
    final gastos = (gastosResult.first['gastos'] as num).toDouble();

    return {
      'ingresos': ingresos,
      'gastos': gastos,
      'utilidad': ingresos - gastos,
    };
  }

  /// Top de productos más vendidos en un rango de fechas (por cantidad)
  Future<List<Map<String, dynamic>>> productosMasVendidos({
    DateTime? desde,
    DateTime? hasta,
    int limite = 5,
  }) async {
    final db = await database;

    final where = <String>[];
    final args = <dynamic>[];
    if (desde != null) {
      where.add('v.fecha >= ?');
      args.add(desde.toIso8601String());
    }
    if (hasta != null) {
      where.add('v.fecha <= ?');
      args.add(hasta.toIso8601String());
    }

    final sql = '''
      SELECT
        p.nombre as nombre,
        p.codigo as codigo,
        SUM(dv.cantidad) as cantidadVendida,
        SUM(dv.cantidad * dv.precioUnitario) as totalVendido
      FROM detalle_venta dv
      INNER JOIN venta v ON v.id = dv.ventaId
      INNER JOIN producto p ON p.id = dv.productoId
      ${where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}'}
      GROUP BY dv.productoId
      ORDER BY cantidadVendida DESC
      LIMIT $limite
    ''';

    return await db.rawQuery(sql, args);
  }
}