import 'app_models.dart';
import 'supabase_service.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  final SupabaseService _supabase = SupabaseService.instance;

  Future<void> initialize({required String url, required String anonKey}) async {
    await _supabase.initialize(url: url, anonKey: anonKey);
    await _seedData();
  }

  Future<void> _seedData() async {
    final categorias = await obtenerCategorias();
    if (categorias.isEmpty) {
      for (final nombre in ['Repuestos', 'Lubricantes', 'Herramientas', 'Eléctrico', 'Llantas', 'Otros']) {
        await crearCategoria(nombre);
      }
    }

    final usuarios = await _supabase.select('usuarios');
    if (usuarios.isEmpty) {
      await _supabase.insert(
        'usuarios',
        UsuariosCompanion.insert(
          nombre: 'Administrador',
          correo: 'admin@taller.com',
          rol: 'admin',
        ).toSupabaseMap(),
      );
    }
  }

  // ── USUARIOS / TRABAJADORES ─────────────────────────────────────────────
  // No hay autenticación por contraseña en el esquema actual: se trabaja
  // seleccionando el usuario/trabajador de una lista (mientras se implementa
  // login real con RLS por rol).

  Stream<List<Usuario>> watchUsuarios() async* {
    yield await obtenerUsuarios();
  }

  Future<List<Usuario>> obtenerUsuarios() async {
    final rows = await _supabase.select('usuarios');
    return rows.map((r) => Usuario.fromSupabase(r)).toList();
  }

  Future<String> crearUsuario({required String nombre, String? correo, String? telefono, String rol = 'trabajador'}) async {
    final row = await _supabase.insert(
      'usuarios',
      UsuariosCompanion.insert(nombre: nombre, correo: correo, telefono: telefono, rol: rol).toSupabaseMap(),
    );
    return supabaseToString(row?['id']);
  }

  // ── CATEGORIAS ───────────────────────────────────────────────────────────
  Stream<List<Categoria>> watchCategorias() async* {
    yield await obtenerCategorias();
  }

  Future<List<Categoria>> obtenerCategorias() async {
    final rows = await _supabase.select('categorias');
    return rows.map((r) => Categoria.fromSupabase(r)).toList();
  }

  Future<String> crearCategoria(String nombre) async {
    final row = await _supabase.insert('categorias', CategoriasCompanion.insert(nombre: nombre).toSupabaseMap());
    return supabaseToString(row?['id']);
  }

  // ── PRODUCTOS Y SERVICIOS ────────────────────────────────────────────────
  Stream<List<Producto>> watchProductos({
    String? busqueda,
    String? categoriaId,
    bool soloBajoStock = false,
    bool soloServicios = false,
  }) async* {
    yield await obtenerProductos(
      busqueda: busqueda,
      categoriaId: categoriaId,
      soloBajoStock: soloBajoStock,
      soloServicios: soloServicios,
    );
  }

  Stream<List<Producto>> watchProductosBajoStock() async* {
    yield await obtenerProductos(soloBajoStock: true);
  }

  Future<List<Producto>> obtenerProductos({
    String? busqueda,
    String? categoriaId,
    bool soloBajoStock = false,
    bool soloServicios = false,
  }) async {
    final rows = await _supabase.select('productos');
    final productos = rows.map((r) => Producto.fromSupabase(r)).toList();
    return productos.where((p) {
      final matchesBusqueda = busqueda == null || busqueda.trim().isEmpty
          ? true
          : p.nombre.toLowerCase().contains(busqueda.toLowerCase()) ||
              p.codigo.toLowerCase().contains(busqueda.toLowerCase());
      final matchesCategoria = categoriaId == null || p.categoriaId == categoriaId;
      final matchesStock = !soloBajoStock || (!p.esServicio && p.stock <= p.stockMinimo);
      final matchesTipo = !soloServicios || p.esServicio;
      return matchesBusqueda && matchesCategoria && matchesStock && matchesTipo;
    }).toList();
  }

  Future<Producto?> obtenerProductoPorId(String id) async {
    final rows = await _supabase.select('productos', column: 'id', filter: 'eq', value: id);
    if (rows.isEmpty) return null;
    return Producto.fromSupabase(rows.first);
  }

  Future<String> generarSiguienteCodigo() async {
    final productos = await obtenerProductos();
    final next = productos.length + 1;
    return 'PROD-${next.toString().padLeft(4, '0')}';
  }

  Future<String> crearProducto(ProductosCompanion p) async {
    final row = await _supabase.insert('productos', p.toSupabaseMap());
    return supabaseToString(row?['id']);
  }

  Future<bool> actualizarProducto(ProductosCompanion p) async {
    final id = p.id;
    if (id == null) return false;
    await _supabase.update('productos', p.toSupabaseMap(), column: 'id', value: id);
    return true;
  }

  Future<int> eliminarProducto(String id) async {
    await _supabase.delete('productos', column: 'id', value: id);
    return 1;
  }

  // ── CLIENTES ─────────────────────────────────────────────────────────────
  Future<String> crearCliente({required String nombre, String telefono = '', String correo = '', String direccion = ''}) async {
    final row = await _supabase.insert(
      'clientes',
      ClientesCompanion.insert(nombre: nombre, telefono: telefono, correo: correo, direccion: direccion).toSupabaseMap(),
    );
    return supabaseToString(row?['id']);
  }

  Future<List<Cliente>> obtenerClientes() async {
    final rows = await _supabase.select('clientes');
    return rows.map((r) => Cliente.fromSupabase(r)).toList();
  }

  // ── PEDIDOS POR ENCARGO (sin producto asociado) ──────────────────────────
  Stream<List<PedidoDetallado>> watchPedidosEncargo({String? estado}) async* {
    yield await obtenerPedidosEncargo(estado: estado);
  }

  Future<List<PedidoDetallado>> obtenerPedidosEncargo({String? estado}) async {
    final rows = await _supabase.select('pedidos_encargo');
    final clientes = await obtenerClientes();
    final result = <PedidoDetallado>[];
    for (final row in rows) {
      if (estado != null && row['estado'] != estado) continue;
      final cliente = clientes.where((c) => c.id == supabaseToString(row['cliente_id'])).firstOrNull ??
          const Cliente(id: '', nombre: 'Cliente sin registrar', telefono: '');
      result.add(PedidoDetallado(
        id: supabaseToString(row['id']),
        estado: row['estado'] as String? ?? 'pendiente',
        fechaSolicitud: DateTime.tryParse(row['fecha']?.toString() ?? '') ?? DateTime.now(),
        fechaEntrega: row['fecha_entrega'] == null ? null : DateTime.tryParse(row['fecha_entrega'].toString()),
        descripcion: row['descripcion'] as String? ?? '',
        total: supabaseToDouble(row['total']),
        observaciones: row['observaciones'] as String? ?? '',
        clienteId: cliente.id,
        clienteNombre: cliente.nombre,
        clienteTelefono: cliente.telefono,
      ));
    }
    result.sort((a, b) => b.fechaSolicitud.compareTo(a.fechaSolicitud));
    return result;
  }

  Future<String> crearPedidoEncargo({
    required String clienteId,
    required String descripcion,
    DateTime? fechaEntrega,
    double? total,
    String? observaciones,
  }) async {
    final row = await _supabase.insert(
      'pedidos_encargo',
      PedidosEncargoCompanion.insert(
        clienteId: clienteId,
        descripcion: descripcion,
        fechaEntrega: fechaEntrega?.toIso8601String().substring(0, 10),
        total: total,
        observaciones: observaciones,
      ).toSupabaseMap(),
    );
    return supabaseToString(row?['id']);
  }

  Future<void> actualizarEstadoPedido(String id, String nuevoEstado) async {
    await _supabase.update('pedidos_encargo', {'estado': nuevoEstado}, column: 'id', value: id);
  }

  // ── VENTAS (productos y/o servicios en la misma venta) ───────────────────
  Future<String> registrarVenta({
    String? usuarioId,
    String? clienteId,
    required List<ItemCarrito> items,
    double descuento = 0,
    String metodoPago = 'Efectivo',
  }) async {
    final subtotal = items.fold<double>(0, (s, i) => s + i.subtotal);
    final total = subtotal - descuento;
    final ventaRow = await _supabase.insert(
      'ventas',
      VentasCompanion.insert(
        fecha: DateTime.now(),
        usuarioId: usuarioId,
        clienteId: clienteId,
        subtotal: subtotal,
        descuento: descuento,
        total: total,
        metodoPago: metodoPago,
      ).toSupabaseMap(),
    );
    final ventaId = supabaseToString(ventaRow?['id']);

    for (final item in items) {
      await _supabase.insert(
        'detalles_venta',
        DetallesVentaCompanion.insert(
          ventaId: ventaId,
          productoId: item.productoId,
          trabajadorId: item.trabajadorId,
          cantidad: item.cantidad,
          precio: item.precioUnitario,
          subtotal: item.subtotal,
        ).toSupabaseMap(),
      );

      // Los servicios no afectan inventario
      if (item.esServicio) continue;

      final producto = await obtenerProductoPorId(item.productoId);
      if (producto == null) continue;
      final nuevoStock = producto.stock - item.cantidad;
      await _supabase.update('productos', {'stock': nuevoStock}, column: 'id', value: item.productoId);
      await _supabase.insert(
        'movimientos_inventario',
        MovimientosInventarioCompanion.insert(
          productoId: item.productoId,
          usuarioId: usuarioId,
          fecha: DateTime.now(),
          tipo: TipoMovimiento.salidaVenta,
          cantidad: item.cantidad,
          stockAnterior: producto.stock,
          stockNuevo: nuevoStock,
          referencia: ventaId,
          observacion: 'Venta #$ventaId',
        ).toSupabaseMap(),
      );
    }
    return ventaId;
  }

  // ── GASTOS ───────────────────────────────────────────────────────────────
  Stream<List<Gasto>> watchGastos({DateTime? desde, DateTime? hasta}) async* {
    yield await obtenerGastos(desde: desde, hasta: hasta);
  }

  Future<List<Gasto>> obtenerGastos({DateTime? desde, DateTime? hasta}) async {
    final rows = await _supabase.select('gastos');
    final gastos = rows.map((r) => Gasto.fromSupabase(r)).toList();
    return gastos.where((g) {
      final after = desde == null || !g.fecha.isBefore(desde);
      final before = hasta == null || !g.fecha.isAfter(hasta);
      return after && before;
    }).toList();
  }

  Future<String> crearGasto({
    required String categoria,
    required double monto,
    String? usuarioId,
    String concepto = '',
    String observaciones = '',
  }) async {
    final row = await _supabase.insert(
      'gastos',
      GastosCompanion.insert(
        categoria: categoria,
        valor: monto,
        usuarioId: usuarioId,
        concepto: concepto,
        observaciones: observaciones,
      ).toSupabaseMap(),
    );
    return supabaseToString(row?['id']);
  }

  Future<void> registrarCompraInventario({
    String? usuarioId,
    required String productoId,
    required int cantidadRecibida,
    required double monto,
    String descripcion = '',
  }) async {
    final producto = await obtenerProductoPorId(productoId);
    if (producto == null) throw Exception('Producto no encontrado');
    final desc = descripcion.isNotEmpty ? descripcion : 'Entrada de stock: ${producto.nombre} (+$cantidadRecibida uds)';

    await _supabase.insert(
      'gastos',
      GastosCompanion.insert(
        categoria: 'Compra de inventario',
        concepto: producto.nombre,
        observaciones: desc,
        valor: monto,
        usuarioId: usuarioId,
      ).toSupabaseMap(),
    );

    final nuevoStock = producto.stock + cantidadRecibida;
    await _supabase.update('productos', {'stock': nuevoStock}, column: 'id', value: productoId);
    await _supabase.insert(
      'movimientos_inventario',
      MovimientosInventarioCompanion.insert(
        productoId: productoId,
        usuarioId: usuarioId,
        fecha: DateTime.now(),
        tipo: TipoMovimiento.entradaCompra,
        cantidad: cantidadRecibida,
        stockAnterior: producto.stock,
        stockNuevo: nuevoStock,
        observacion: desc,
      ).toSupabaseMap(),
    );
  }

  // ── MOVIMIENTOS DE INVENTARIO ────────────────────────────────────────────
  Stream<List<MovimientosInventario>> watchMovimientosProducto(String productoId) async* {
    yield await obtenerMovimientosProducto(productoId);
  }

  Future<List<MovimientosInventario>> obtenerMovimientosProducto(String productoId) async {
    final rows = await _supabase.select('movimientos_inventario', column: 'producto_id', filter: 'eq', value: productoId);
    return rows.map((r) => MovimientosInventario.fromSupabase(r)).toList();
  }

  Future<void> registrarAjusteStock({
    required String productoId,
    String? usuarioId,
    required int cantidad,
    required bool esEntrada,
    required String motivo,
  }) async {
    final producto = await obtenerProductoPorId(productoId);
    if (producto == null) throw Exception('Producto no encontrado');
    final nuevoStock = esEntrada ? producto.stock + cantidad : producto.stock - cantidad;
    if (nuevoStock < 0) throw Exception('Stock insuficiente para el ajuste');
    await _supabase.update('productos', {'stock': nuevoStock}, column: 'id', value: productoId);
    await _supabase.insert(
      'movimientos_inventario',
      MovimientosInventarioCompanion.insert(
        productoId: productoId,
        usuarioId: usuarioId,
        fecha: DateTime.now(),
        tipo: esEntrada ? TipoMovimiento.ajusteEntrada : TipoMovimiento.ajusteSalida,
        cantidad: cantidad,
        stockAnterior: producto.stock,
        stockNuevo: nuevoStock,
        observacion: motivo,
      ).toSupabaseMap(),
    );
  }

  // ── REPORTES ─────────────────────────────────────────────────────────────
  Stream<ResumenFinanciero> watchResumenFinanciero({DateTime? desde}) async* {
    final ingresos = await obtenerIngresos(desde: desde);
    final gastos = await obtenerGastos(desde: desde);
    yield ResumenFinanciero(
      ingresos: ingresos,
      gastos: gastos.fold<double>(0, (s, g) => s + g.valor),
      utilidad: ingresos - gastos.fold<double>(0, (s, g) => s + g.valor),
    );
  }

  Future<double> obtenerIngresos({DateTime? desde}) async {
    final rows = await _supabase.select('ventas');
    final ventas = rows.where((r) {
      if (desde == null) return true;
      final fecha = DateTime.tryParse(r['fecha']?.toString() ?? '') ?? DateTime.now();
      return !fecha.isBefore(desde);
    });
    return ventas.fold<double>(0, (s, r) => s + supabaseToDouble(r['total']));
  }

  Stream<List<ProductoMasVendido>> watchProductosMasVendidos({DateTime? desde, int limite = 5}) async* {
    final rows = await _supabase.select('detalles_venta');
    final ventas = await _supabase.select('ventas');
    final productosMap = <String, Producto>{};
    for (final producto in await obtenerProductos()) {
      productosMap[producto.id] = producto;
    }
    final summary = <String, ProductoMasVendido>{};
    for (final row in rows) {
      final venta = ventas.where((v) => v['id'] == row['venta_id']).firstOrNull;
      final fecha = venta == null || venta['fecha'] == null ? null : DateTime.tryParse(venta['fecha'].toString());
      if (desde != null && (fecha == null || fecha.isBefore(desde))) continue;
      final producto = productosMap[supabaseToString(row['producto_id'])];
      if (producto == null) continue;
      final current = summary[producto.id];
      final cantidad = supabaseToInt(row['cantidad']);
      final total = supabaseToDouble(row['precio']) * cantidad;
      if (current == null) {
        summary[producto.id] = ProductoMasVendido(
          nombre: producto.nombre,
          codigo: producto.codigo,
          cantidadVendida: cantidad,
          totalVendido: total,
        );
      } else {
        summary[producto.id] = ProductoMasVendido(
          nombre: producto.nombre,
          codigo: producto.codigo,
          cantidadVendida: current.cantidadVendida + cantidad,
          totalVendido: current.totalVendido + total,
        );
      }
    }
    final list = summary.values.toList()..sort((a, b) => b.cantidadVendida.compareTo(a.cantidadVendida));
    yield list.take(limite).toList();
  }
}