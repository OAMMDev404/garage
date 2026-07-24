import 'dart:async';
import 'app_models.dart';
import 'supabase_service.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  final SupabaseService _supabase = SupabaseService.instance;

  // ── BUS DE CAMBIOS ───────────────────────────────────────────────────────
  // Como los métodos watch* no usan Supabase Realtime (streams verdaderos),
  // usamos este StreamController como señal de "algo cambió en la BD".
  // Cada watch* se resuscribe a _cambios y vuelve a consultar cuando se
  // dispara. Cada método que inserta/actualiza/elimina llama a _notificar()
  // al terminar. Así la UI se refresca sola sin tener que cerrar la app.
  final StreamController<void> _cambios = StreamController<void>.broadcast();

  void _notificar() {
    if (!_cambios.isClosed) _cambios.add(null);
  }

  Future<void> initialize({required String url, required String anonKey}) async {
    await _supabase.initialize(url: url, anonKey: anonKey);
    // _seedData() ya NO se llama aquí. Las categorías y el usuario admin
    // base ya existen en la BD desde hace meses, y ahora esa inserción
    // requeriría una sesión autenticada (RLS), que todavía no existe en
    // este punto del arranque (el login ocurre después de initialize()).
    // Si alguna vez necesitas volver a sembrar datos, llama a seedData()
    // manualmente después de haber iniciado sesión.
  }

  Future<void> seedData() async {
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
      _notificar();
    }
  }

  // ── USUARIOS / TRABAJADORES ─────────────────────────────────────────────
  Stream<List<Usuario>> watchUsuarios() async* {
    yield await obtenerUsuarios();
    yield* _cambios.stream.asyncMap((_) => obtenerUsuarios());
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
    _notificar();
    return supabaseToString(row?['id']);
  }

  // ── CATEGORIAS ───────────────────────────────────────────────────────────
  Stream<List<Categoria>> watchCategorias() async* {
    yield await obtenerCategorias();
    yield* _cambios.stream.asyncMap((_) => obtenerCategorias());
  }

  Future<List<Categoria>> obtenerCategorias() async {
    final rows = await _supabase.select('categorias');
    return rows.map((r) => Categoria.fromSupabase(r)).toList();
  }

  Future<String> crearCategoria(String nombre) async {
    final row = await _supabase.insert('categorias', CategoriasCompanion.insert(nombre: nombre).toSupabaseMap());
    _notificar();
    return supabaseToString(row?['id']);
  }

  // ── PRODUCTOS Y SERVICIOS ────────────────────────────────────────────────
  Stream<List<Producto>> watchProductos({
    String? busqueda,
    String? categoriaId,
    bool soloBajoStock = false,
    bool soloServicios = false,
  }) async* {
    Future<List<Producto>> consultar() => obtenerProductos(
          busqueda: busqueda,
          categoriaId: categoriaId,
          soloBajoStock: soloBajoStock,
          soloServicios: soloServicios,
        );
    yield await consultar();
    yield* _cambios.stream.asyncMap((_) => consultar());
  }

  Stream<List<Producto>> watchProductosBajoStock() async* {
    yield await obtenerProductos(soloBajoStock: true);
    yield* _cambios.stream.asyncMap((_) => obtenerProductos(soloBajoStock: true));
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
    _notificar();
    return supabaseToString(row?['id']);
  }

  Future<bool> actualizarProducto(ProductosCompanion p) async {
    final id = p.id;
    if (id == null) return false;
    await _supabase.update('productos', p.toSupabaseMap(), column: 'id', value: id);
    _notificar();
    return true;
  }

  Future<int> eliminarProducto(String id) async {
    await _supabase.delete('productos', column: 'id', value: id);
    _notificar();
    return 1;
  }

  // ── CLIENTES ─────────────────────────────────────────────────────────────
  Future<String> crearCliente({required String nombre, String telefono = '', String correo = '', String direccion = ''}) async {
    final row = await _supabase.insert(
      'clientes',
      ClientesCompanion.insert(nombre: nombre, telefono: telefono, correo: correo, direccion: direccion).toSupabaseMap(),
    );
    _notificar();
    return supabaseToString(row?['id']);
  }

  Future<List<Cliente>> obtenerClientes() async {
    final rows = await _supabase.select('clientes');
    return rows.map((r) => Cliente.fromSupabase(r)).toList();
  }

  // ── PEDIDOS POR ENCARGO (sin producto asociado) ──────────────────────────
  // soloArchivados=false (default) → muestra los activos (no archivados).
  // soloArchivados=true → muestra solo los que ya archivaste.
  // En ambos casos el registro sigue existiendo y sigue contando en reportes.
  Stream<List<PedidoDetallado>> watchPedidosEncargo({String? estado, bool soloArchivados = false}) async* {
    Future<List<PedidoDetallado>> consultar() =>
        obtenerPedidosEncargo(estado: estado, soloArchivados: soloArchivados);
    yield await consultar();
    yield* _cambios.stream.asyncMap((_) => consultar());
  }

  Future<List<PedidoDetallado>> obtenerPedidosEncargo({String? estado, bool soloArchivados = false}) async {
    final rows = await _supabase.select('pedidos_encargo');
    final clientes = await obtenerClientes();
    final result = <PedidoDetallado>[];
    for (final row in rows) {
      final archivado = supabaseToBool(row['archivado']);
      if (archivado != soloArchivados) continue;
      if (estado != null && row['estado'] != estado) continue;
      result.add(_mapPedido(row, clientes));
    }
    result.sort((a, b) => b.fechaSolicitud.compareTo(a.fechaSolicitud));
    return result;
  }

  // Para reportes: TODOS los pedidos entregados en el período, sin importar
  // si están archivados o no (archivar solo los saca de la lista activa,
  // nunca del historial/reporte). Se ordenan por fecha de entrega/solicitud.
  Stream<List<PedidoDetallado>> watchEncargosEntregados({DateTime? desde}) async* {
    yield await obtenerEncargosEntregados(desde: desde);
    yield* _cambios.stream.asyncMap((_) => obtenerEncargosEntregados(desde: desde));
  }

  Future<List<PedidoDetallado>> obtenerEncargosEntregados({DateTime? desde}) async {
    final rows = await _supabase.select('pedidos_encargo');
    final clientes = await obtenerClientes();
    final result = <PedidoDetallado>[];
    for (final row in rows) {
      if (row['estado'] != 'entregado') continue;
      final fechaRef = row['fecha_entrega'] ?? row['fecha'];
      final fecha = DateTime.tryParse(fechaRef?.toString() ?? '') ?? DateTime.now();
      if (desde != null && fecha.isBefore(desde)) continue;
      result.add(_mapPedido(row, clientes));
    }
    result.sort((a, b) {
      final fechaA = a.fechaEntrega ?? a.fechaSolicitud;
      final fechaB = b.fechaEntrega ?? b.fechaSolicitud;
      return fechaB.compareTo(fechaA);
    });
    return result;
  }

  PedidoDetallado _mapPedido(Map<String, dynamic> row, List<Cliente> clientes) {
    final cliente = clientes.where((c) => c.id == supabaseToString(row['cliente_id'])).firstOrNull ??
        const Cliente(id: '', nombre: 'Cliente sin registrar', telefono: '');
    return PedidoDetallado(
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
      archivado: supabaseToBool(row['archivado']),
    );
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
    _notificar();
    return supabaseToString(row?['id']);
  }

  Future<void> actualizarEstadoPedido(String id, String nuevoEstado) async {
    await _supabase.update('pedidos_encargo', {'estado': nuevoEstado}, column: 'id', value: id);
    _notificar();
  }

  // Archiva el pedido (sale de la lista de activos, pero sigue contando en
  // reportes e ingresos si está entregado). No se borra ningún dato.
  Future<void> archivarPedido(String id) async {
    await _supabase.update('pedidos_encargo', {'archivado': true}, column: 'id', value: id);
    _notificar();
  }

  Future<void> desarchivarPedido(String id) async {
    await _supabase.update('pedidos_encargo', {'archivado': false}, column: 'id', value: id);
    _notificar();
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
    _notificar();
    return ventaId;
  }

  // ── GASTOS ───────────────────────────────────────────────────────────────
  Stream<List<Gasto>> watchGastos({DateTime? desde, DateTime? hasta}) async* {
    yield await obtenerGastos(desde: desde, hasta: hasta);
    yield* _cambios.stream.asyncMap((_) => obtenerGastos(desde: desde, hasta: hasta));
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
    _notificar();
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
    _notificar();
  }

  // ── MOVIMIENTOS DE INVENTARIO ────────────────────────────────────────────
  Stream<List<MovimientosInventario>> watchMovimientosProducto(String productoId) async* {
    yield await obtenerMovimientosProducto(productoId);
    yield* _cambios.stream.asyncMap((_) => obtenerMovimientosProducto(productoId));
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
    _notificar();
  }

  // ── REPORTES ─────────────────────────────────────────────────────────────
  Stream<ResumenFinanciero> watchResumenFinanciero({DateTime? desde}) async* {
    Future<ResumenFinanciero> consultar() async {
      final ingresos = await obtenerIngresos(desde: desde);
      final gastos = await obtenerGastos(desde: desde);
      return ResumenFinanciero(
        ingresos: ingresos,
        gastos: gastos.fold<double>(0, (s, g) => s + g.valor),
        utilidad: ingresos - gastos.fold<double>(0, (s, g) => s + g.valor),
      );
    }

    yield await consultar();
    yield* _cambios.stream.asyncMap((_) => consultar());
  }

  // Ingresos = ventas + pedidos por encargo ya entregados (estén archivados
  // o no: archivar solo los quita de la lista activa, nunca del reporte).
  Future<double> obtenerIngresos({DateTime? desde}) async {
    final rows = await _supabase.select('ventas');
    final ventas = rows.where((r) {
      if (desde == null) return true;
      final fecha = DateTime.tryParse(r['fecha']?.toString() ?? '') ?? DateTime.now();
      return !fecha.isBefore(desde);
    });
    final totalVentas = ventas.fold<double>(0, (s, r) => s + supabaseToDouble(r['total']));
    final encargos = await obtenerEncargosEntregados(desde: desde);
    final totalEncargos = encargos.fold<double>(0, (s, p) => s + p.total);
    return totalVentas + totalEncargos;
  }

  Stream<List<ProductoMasVendido>> watchProductosMasVendidos({DateTime? desde, int limite = 5}) async* {
    Future<List<ProductoMasVendido>> consultar() => _obtenerProductosMasVendidos(desde: desde, limite: limite);
    yield await consultar();
    yield* _cambios.stream.asyncMap((_) => consultar());
  }

  Future<List<ProductoMasVendido>> _obtenerProductosMasVendidos({DateTime? desde, int limite = 5}) async {
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
    return list.take(limite).toList();
  }
}