import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/pedido_encargo.dart';
import '../models/producto.dart';
import '../models/cliente.dart';
import '../theme.dart';

class EncargosScreen extends StatefulWidget {
  const EncargosScreen({super.key});

  @override
  State<EncargosScreen> createState() => _EncargosScreenState();
}

class _EncargosScreenState extends State<EncargosScreen> {
  final _db = DatabaseHelper.instance;

  List<Map<String, dynamic>> _pedidos = [];
  String? _filtroEstado;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final pedidos = await _db.obtenerPedidosEncargoDetallados(estado: _filtroEstado);
    setState(() => _pedidos = pedidos);
  }

  Future<void> _cambiarEstado(int id, String estadoActual) async {
    final idx = EstadoPedido.todos.indexOf(estadoActual);
    final siguiente = EstadoPedido.todos[(idx + 1) % EstadoPedido.todos.length];
    await _db.actualizarEstadoPedido(id, siguiente);
    _cargar();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.fondo,
      child: Column(
        children: [
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _chip('Todos', _filtroEstado == null, () {
                  setState(() => _filtroEstado = null);
                  _cargar();
                }),
                const SizedBox(width: 6),
                ...EstadoPedido.todos.map((e) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: _chip(EstadoPedido.label(e), _filtroEstado == e, () {
                        setState(() => _filtroEstado = e);
                        _cargar();
                      }),
                    )),
              ],
            ),
          ),
          Expanded(
            child: _pedidos.isEmpty
                ? const Center(
                    child: Text('No hay pedidos por encargo',
                        style: TextStyle(color: AppColors.textoGris)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: _pedidos.length,
                    itemBuilder: (context, index) => _itemPedido(_pedidos[index]),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

  Widget _itemPedido(Map<String, dynamic> p) {
    final estado = p['estado'] as String;
    final colores = {
      EstadoPedido.pendiente: AppColors.amarillo,
      EstadoPedido.enCamino: AppColors.azulMedio,
      EstadoPedido.entregado: AppColors.verde,
    };

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
                child: Text(
                  p['productoNombre'] as String,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14),
                ),
              ),
              GestureDetector(
                onTap: () => _cambiarEstado(p['id'] as int, estado),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (colores[estado] ?? AppColors.textoGris).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Text(
                        EstadoPedido.label(estado),
                        style: TextStyle(
                          fontSize: 11,
                          color: colores[estado] ?? AppColors.textoGris,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.swap_horiz, size: 12, color: colores[estado]),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Código: ${p['productoCodigo']}',
            style: const TextStyle(color: AppColors.textoGris, fontSize: 11),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.person_outline, size: 14, color: AppColors.textoGris),
              const SizedBox(width: 4),
              Text(
                p['clienteNombre'] as String,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              if ((p['clienteTelefono'] as String?)?.isNotEmpty == true) ...[
                const SizedBox(width: 8),
                const Icon(Icons.phone_outlined, size: 14, color: AppColors.textoGris),
                const SizedBox(width: 4),
                Text(
                  p['clienteTelefono'] as String,
                  style: const TextStyle(color: AppColors.textoGris, fontSize: 12),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Solicitado: ${_formatearFecha(p['fechaSolicitud'] as String)}',
            style: const TextStyle(color: AppColors.textoGris, fontSize: 11),
          ),
        ],
      ),
    );
  }

  String _formatearFecha(String iso) {
    final d = DateTime.parse(iso);
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}

// ---------------------------------------------------------------------
// Formulario rápido para crear un nuevo pedido por encargo
// ---------------------------------------------------------------------
class _NuevoEncargoSheet extends StatefulWidget {
  const _NuevoEncargoSheet();

  @override
  State<_NuevoEncargoSheet> createState() => _NuevoEncargoSheetState();
}

class _NuevoEncargoSheetState extends State<_NuevoEncargoSheet> {
  final _db = DatabaseHelper.instance;
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

    // Buscar categoría "Otros" como categoría por defecto para encargos
    final categorias = await _db.obtenerCategorias();
    final categoriaOtros = categorias.firstWhere(
      (c) => c.nombre == 'Otros',
      orElse: () => categorias.first,
    );

    // Crear el producto marcado como "por encargo" con stock 0
    final codigo = await _db.generarSiguienteCodigo();
    final productoId = await _db.crearProducto(Producto(
      codigo: codigo,
      nombre: _nombreProductoController.text.trim(),
      descripcion: 'Producto por encargo',
      precioCompra: 0,
      precioVenta: 0,
      stockActual: 0,
      stockMinimo: 0,
      porEncargo: true,
      categoriaId: categoriaOtros.id!,
    ));

    // Crear el cliente
    final clienteId = await _db.crearCliente(Cliente(
      nombre: _nombreClienteController.text.trim(),
      telefono: _telefonoController.text.trim(),
    ));

    // Crear el pedido por encargo
    await _db.crearPedidoEncargo(PedidoEncargo(
      productoId: productoId,
      clienteId: clienteId,
      fechaSolicitud: DateTime.now(),
    ));

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
            const Text(
              'Nuevo pedido por encargo',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nombreProductoController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Producto solicitado'),
              validator: (v) => (v == null || v.isEmpty) ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nombreClienteController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Nombre del cliente'),
              validator: (v) => (v == null || v.isEmpty) ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _telefonoController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Teléfono (opcional)'),
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
