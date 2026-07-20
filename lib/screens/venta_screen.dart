import 'package:flutter/material.dart';
import '../db/app_database.dart';
import '../db/app_models.dart';
import '../theme.dart';

class VentaScreen extends StatefulWidget {
  const VentaScreen({super.key});

  @override
  State<VentaScreen> createState() => _VentaScreenState();
}

class _VentaScreenState extends State<VentaScreen> {
  final _db = AppDatabase.instance;
  final _busquedaController = TextEditingController();
  final List<ItemCarrito> _carrito = [];

  List<Usuario> _usuarios = [];
  Usuario? _trabajadorSeleccionado;

  String _busqueda = '';

  @override
  void initState() {
    super.initState();
    _cargarUsuarios();
  }

  Future<void> _cargarUsuarios() async {
    final usuarios = await _db.obtenerUsuarios();
    if (mounted) {
      setState(() {
        _usuarios = usuarios;
        _trabajadorSeleccionado = usuarios.isNotEmpty ? usuarios.first : null;
      });
    }
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  void _agregarAlCarrito(Producto p) {
    final existente =
        _carrito.where((i) => i.productoId == p.id).firstOrNull;
    if (existente != null && !p.esServicio) {
      setState(() => existente.cantidad++);
    } else {
      setState(() => _carrito.add(ItemCarrito(
            productoId: p.id,
            nombreProducto: p.nombre,
            precioUnitario: p.precio,
            esServicio: p.esServicio,
            trabajadorId: _trabajadorSeleccionado?.id,
          )));
    }
  }

  void _quitarDelCarrito(ItemCarrito item) {
    setState(() {
      if (item.cantidad > 1 && !item.esServicio) {
        item.cantidad--;
      } else {
        _carrito.remove(item);
      }
    });
  }

  double get _total =>
      _carrito.fold(0, (sum, item) => sum + item.subtotal);

  Future<void> _confirmarVenta() async {
    if (_carrito.isEmpty) return;
    await _db.registrarVenta(
      usuarioId: _trabajadorSeleccionado?.id,
      items: _carrito,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Venta registrada correctamente')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar venta')),
      body: Column(
        children: [
          if (_usuarios.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: DropdownButtonFormField<Usuario>(
                value: _trabajadorSeleccionado,
                dropdownColor: AppColors.tarjeta,
                decoration: const InputDecoration(labelText: 'Trabajador que atiende'),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                items: _usuarios
                    .map((u) => DropdownMenuItem(value: u, child: Text(u.nombre)))
                    .toList(),
                onChanged: (u) => setState(() => _trabajadorSeleccionado = u),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _busquedaController,
              onChanged: (v) => setState(() => _busqueda = v),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Buscar producto o servicio...',
                hintStyle: TextStyle(color: AppColors.textoGris),
                prefixIcon:
                    Icon(Icons.search, color: AppColors.textoGris),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Producto>>(
              stream: _db.watchProductos(busqueda: _busqueda),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.amarillo));
                }
                final resultados = snap.data!;

                return ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: resultados.length,
                  itemBuilder: (context, index) {
                    final p = resultados[index];
                    final disponible = p.esServicio || p.stock > 0;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.tarjeta,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          if (p.esServicio)
                            const Padding(
                              padding: EdgeInsets.only(right: 8),
                              child: Icon(Icons.build_circle_outlined,
                                  color: AppColors.amarillo, size: 18),
                            ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(p.nombre,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13)),
                                Text(
                                  p.esServicio
                                      ? '${p.codigo} · \$${p.precio.toStringAsFixed(2)}'
                                      : '${p.codigo} · Stock: ${p.stock} · \$${p.precio.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      color: AppColors.textoGris,
                                      fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle,
                                color: AppColors.amarillo),
                            onPressed: disponible
                                ? () => _agregarAlCarrito(p)
                                : null,
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (_carrito.isNotEmpty) _resumenCarrito(),
        ],
      ),
    );
  }

  Widget _resumenCarrito() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.azulOscuro,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Carrito',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 150),
            child: ListView(
              shrinkWrap: true,
              children: _carrito
                  .map((item) => Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(item.nombreProducto,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12)),
                            ),
                            if (!item.esServicio)
                              IconButton(
                                icon: const Icon(
                                    Icons.remove_circle_outline,
                                    size: 18,
                                    color: AppColors.textoGris),
                                onPressed: () =>
                                    _quitarDelCarrito(item),
                              ),
                            Text('${item.cantidad}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12)),
                            const SizedBox(width: 8),
                            Text(
                                '\$${item.subtotal.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    color: AppColors.amarillo,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
          const Divider(color: AppColors.textoGris),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold)),
              Text('\$${_total.toStringAsFixed(2)}',
                  style: const TextStyle(
                      color: AppColors.amarillo,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _confirmarVenta,
            child: const Text('Confirmar venta'),
          ),
        ],
      ),
    );
  }
}