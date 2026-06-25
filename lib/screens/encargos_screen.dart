import 'package:flutter/material.dart';
import '../db/app_database.dart';
import '../theme.dart';
import 'package:drift/drift.dart' show Value;
// Estados posibles de un pedido por encargo
class EstadoPedido {
  static const pendiente = 'pendiente';
  static const enCamino = 'en_camino';
  static const entregado = 'entregado';
  static const todos = [pendiente, enCamino, entregado];

  static String label(String estado) {
    switch (estado) {
      case pendiente:
        return 'Pendiente';
      case enCamino:
        return 'En camino';
      case entregado:
        return 'Entregado';
      default:
        return estado;
    }
  }
}

class EncargosScreen extends StatefulWidget {
  const EncargosScreen({super.key});

  @override
  State<EncargosScreen> createState() => _EncargosScreenState();
}

class _EncargosScreenState extends State<EncargosScreen> {
  final _db = AppDatabase.instance;
  String? _filtroEstado;

  Stream<List<PedidoDetallado>> get _pedidosStream =>
      _db.watchPedidosEncargo(estado: _filtroEstado);

  Future<void> _cambiarEstado(int id, String estadoActual) async {
    final idx = EstadoPedido.todos.indexOf(estadoActual);
    final siguiente =
        EstadoPedido.todos[(idx + 1) % EstadoPedido.todos.length];
    await _db.actualizarEstadoPedido(id, siguiente);
    // No hace falta llamar setState ni recargar: el stream se actualiza solo
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.fondo,
      child: Column(
        children: [
          // ── Chips de filtro por estado ────────────────────────────────
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _chip('Todos', _filtroEstado == null,
                    () => setState(() => _filtroEstado = null)),
                const SizedBox(width: 6),
                ...EstadoPedido.todos.map((e) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: _chip(
                        EstadoPedido.label(e),
                        _filtroEstado == e,
                        () => setState(() => _filtroEstado = e),
                      ),
                    )),
              ],
            ),
          ),
          // ── Lista reactiva ─────────────────────────────────────────────
          Expanded(
            child: StreamBuilder<List<PedidoDetallado>>(
              stream: _pedidosStream,
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.amarillo));
                }
                final pedidos = snap.data!;
                if (pedidos.isEmpty) {
                  return const Center(
                    child: Text('No hay pedidos por encargo',
                        style: TextStyle(color: AppColors.textoGris)),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: pedidos.length,
                  itemBuilder: (context, index) =>
                      _itemPedido(pedidos[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String texto, bool activo, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: activo ? AppColors.amarillo : AppColors.tarjeta,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: Text(
          texto,
          style: TextStyle(
            fontSize: 12,
            fontWeight: activo ? FontWeight.bold : FontWeight.normal,
            color: activo ? Colors.black : AppColors.textoGris,
          ),
        ),
      ),
    );
  }

  Widget _itemPedido(PedidoDetallado p) {
    final colores = {
      EstadoPedido.pendiente: AppColors.amarillo,
      EstadoPedido.enCamino: AppColors.azulMedio,
      EstadoPedido.entregado: AppColors.verde,
    };
    final color = colores[p.estado] ?? AppColors.textoGris;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.tarjeta,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(p.productoNombre,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 14)),
              ),
              GestureDetector(
                onTap: () => _cambiarEstado(p.id, p.estado),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Text(EstadoPedido.label(p.estado),
                          style: TextStyle(
                              fontSize: 11,
                              color: color,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(width: 4),
                      Icon(Icons.swap_horiz, size: 12, color: color),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Código: ${p.productoCodigo}',
              style: const TextStyle(
                  color: AppColors.textoGris, fontSize: 11)),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.person_outline,
                  size: 14, color: AppColors.textoGris),
              const SizedBox(width: 4),
              Text(p.clienteNombre,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 12)),
              if (p.clienteTelefono.isNotEmpty) ...[
                const SizedBox(width: 8),
                const Icon(Icons.phone_outlined,
                    size: 14, color: AppColors.textoGris),
                const SizedBox(width: 4),
                Text(p.clienteTelefono,
                    style: const TextStyle(
                        color: AppColors.textoGris, fontSize: 12)),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Solicitado: ${_fmt(p.fechaSolicitud)}',
            style: const TextStyle(
                color: AppColors.textoGris, fontSize: 11),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';
}

// ─────────────────────────────────────────────────────────────────────────────
// Sheet para nuevo encargo
// ─────────────────────────────────────────────────────────────────────────────
class NuevoEncargoSheet extends StatefulWidget {
  const NuevoEncargoSheet({super.key});

  @override
  State<NuevoEncargoSheet> createState() => _NuevoEncargoSheetState();
}

class _NuevoEncargoSheetState extends State<NuevoEncargoSheet> {
  final _db = AppDatabase.instance;
  final _formKey = GlobalKey<FormState>();
  final _nombreProductoController = TextEditingController();
  final _nombreClienteController = TextEditingController();
  final _telefonoController = TextEditingController();

  @override
  void dispose() {
    _nombreProductoController.dispose();
    _nombreClienteController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final categorias = await _db.obtenerCategorias();
    final catOtros = categorias.firstWhere(
      (c) => c.nombre == 'Otros',
      orElse: () => categorias.first,
    );

    final codigo = await _db.generarSiguienteCodigo();
    final productoId = await _db.crearProducto(
      ProductosCompanion.insert(
        codigo: codigo,
        nombre: _nombreProductoController.text.trim(),
        descripcion: Value('Producto por encargo'),
        precioCompra: 0,
        precioVenta: 0,
        porEncargo: Value(true),
        categoriaId: catOtros.id,
      ),
    );

    final clienteId = await _db.crearCliente(
      nombre: _nombreClienteController.text.trim(),
      telefono: _telefonoController.text.trim(),
    );

    await _db.crearPedidoEncargo(
      productoId: productoId,
      clienteId: clienteId,
    );

    if (mounted) Navigator.pop(context, true);
  }
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nuevo pedido por encargo',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nombreProductoController,
              style: const TextStyle(color: Colors.white),
              decoration:
                  const InputDecoration(labelText: 'Producto solicitado'),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nombreClienteController,
              style: const TextStyle(color: Colors.white),
              decoration:
                  const InputDecoration(labelText: 'Nombre del cliente'),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _telefonoController,
              style: const TextStyle(color: Colors.white),
              decoration:
                  const InputDecoration(labelText: 'Teléfono (opcional)'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _guardar,
              child: const Text('Guardar pedido'),
            ),
          ],
        ),
      ),
    );
  }
}