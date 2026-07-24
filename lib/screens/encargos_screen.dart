import 'package:flutter/material.dart';
import '../db/app_database.dart';
import '../db/app_models.dart';
import '../theme.dart';

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
  bool _verArchivados = false;

  Stream<List<PedidoDetallado>> get _pedidosStream =>
      _db.watchPedidosEncargo(estado: _filtroEstado, soloArchivados: _verArchivados);

  Future<void> _cambiarEstado(PedidoDetallado p) async {
    if (p.archivado) return; // un pedido archivado ya no cambia de estado
    final idx = EstadoPedido.todos.indexOf(p.estado);
    final siguiente =
        EstadoPedido.todos[(idx + 1) % EstadoPedido.todos.length];
    await _db.actualizarEstadoPedido(p.id, siguiente);
    // El stream ya es reactivo (se refresca solo), no hace falta setState.
  }

  Future<void> _archivar(PedidoDetallado p) async {
    await _db.archivarPedido(p.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pedido archivado')),
      );
    }
  }

  Future<void> _desarchivar(PedidoDetallado p) async {
    await _db.desarchivarPedido(p.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pedido restaurado')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondo,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.amarillo,
        foregroundColor: Colors.black,
        onPressed: () async {
          await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            backgroundColor: AppColors.fondo,
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
            builder: (_) => const NuevoEncargoSheet(),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // ── Toggle Activos / Archivados ──────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: _toggleBtn(
                    'Activos',
                    Icons.local_shipping_outlined,
                    !_verArchivados,
                    () => setState(() => _verArchivados = false),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _toggleBtn(
                    'Archivados',
                    Icons.archive_outlined,
                    _verArchivados,
                    () => setState(() => _verArchivados = true),
                  ),
                ),
              ],
            ),
          ),
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
                  return Center(
                    child: Text(
                      _verArchivados
                          ? 'No hay pedidos archivados'
                          : 'No hay pedidos por encargo',
                      style: const TextStyle(color: AppColors.textoGris),
                    ),
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

  Widget _toggleBtn(
      String texto, IconData icono, bool activo, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: activo ? AppColors.azulMedio : AppColors.tarjeta,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icono,
                size: 16,
                color: activo ? const Color(0xFF9DC4FF) : AppColors.textoGris),
            const SizedBox(width: 6),
            Text(texto,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: activo ? FontWeight.bold : FontWeight.normal,
                    color: activo
                        ? const Color(0xFF9DC4FF)
                        : AppColors.textoGris)),
          ],
        ),
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
                child: Text(p.descripcion,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 14)),
              ),
              GestureDetector(
                onTap: () => _cambiarEstado(p),
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
                      if (!p.archivado) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.swap_horiz, size: 12, color: color),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
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
          if (p.total > 0) ...[
            const SizedBox(height: 4),
            Text('Total: \$${p.total.toStringAsFixed(2)}',
                style: const TextStyle(
                    color: AppColors.amarillo, fontSize: 12)),
          ],
          const SizedBox(height: 4),
          Text(
            'Solicitado: ${_fmt(p.fechaSolicitud)}'
            '${p.fechaEntrega != null ? '  ·  Entrega: ${_fmt(p.fechaEntrega!)}' : ''}',
            style: const TextStyle(
                color: AppColors.textoGris, fontSize: 11),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (!p.archivado && p.estado == EstadoPedido.entregado)
                TextButton.icon(
                  onPressed: () => _archivar(p),
                  icon: const Icon(Icons.archive_outlined,
                      size: 16, color: AppColors.textoGris),
                  label: const Text('Archivar',
                      style: TextStyle(
                          color: AppColors.textoGris, fontSize: 12)),
                ),
              if (p.archivado)
                TextButton.icon(
                  onPressed: () => _desarchivar(p),
                  icon: const Icon(Icons.unarchive_outlined,
                      size: 16, color: AppColors.amarillo),
                  label: const Text('Restaurar',
                      style: TextStyle(
                          color: AppColors.amarillo, fontSize: 12)),
                ),
            ],
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
// Sheet para nuevo encargo (sin producto de inventario: solo descripción libre)
// ─────────────────────────────────────────────────────────────────────────────
class NuevoEncargoSheet extends StatefulWidget {
  const NuevoEncargoSheet({super.key});

  @override
  State<NuevoEncargoSheet> createState() => _NuevoEncargoSheetState();
}

class _NuevoEncargoSheetState extends State<NuevoEncargoSheet> {
  final _db = AppDatabase.instance;
  final _formKey = GlobalKey<FormState>();
  final _descripcionController = TextEditingController();
  final _nombreClienteController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _totalController = TextEditingController();
  DateTime? _fechaEntrega;

  @override
  void dispose() {
    _descripcionController.dispose();
    _nombreClienteController.dispose();
    _telefonoController.dispose();
    _totalController.dispose();
    super.dispose();
  }

  Future<void> _elegirFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 3)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (fecha != null) setState(() => _fechaEntrega = fecha);
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final clienteId = await _db.crearCliente(
      nombre: _nombreClienteController.text.trim(),
      telefono: _telefonoController.text.trim(),
    );

    await _db.crearPedidoEncargo(
      clienteId: clienteId,
      descripcion: _descripcionController.text.trim(),
      fechaEntrega: _fechaEntrega,
      total: double.tryParse(_totalController.text),
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
              controller: _descripcionController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                  labelText: 'Qué se encargó', hintText: 'Ej: Batería 12V para Sonata 2015'),
              maxLines: 2,
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
            const SizedBox(height: 12),
            TextFormField(
              controller: _totalController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Total estimado (opcional)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _elegirFecha,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.tarjeta,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 16, color: AppColors.textoGris),
                    const SizedBox(width: 8),
                    Text(
                      _fechaEntrega == null
                          ? 'Fecha estimada de entrega (opcional)'
                          : 'Entrega: ${_fechaEntrega!.day}/${_fechaEntrega!.month}/${_fechaEntrega!.year}',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ],
                ),
              ),
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