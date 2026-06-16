import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/producto.dart';
import '../models/venta.dart';
import '../theme.dart';

class VentaScreen extends StatefulWidget {
  const VentaScreen({super.key});

  @override
  State<VentaScreen> createState() => _VentaScreenState();
}

class _VentaScreenState extends State<VentaScreen> {
  final _db = DatabaseHelper.instance;
  final _busquedaController = TextEditingController();

  List<Producto> _resultados = [];
  final List<ItemCarrito> _carrito = [];

  // TODO: reemplazar por el id del usuario autenticado en la sesión
  static const int _usuarioIdActual = 1;

  @override
  void initState() {
    super.initState();
    _buscar();
  }

  Future<void> _buscar() async {
    final productos = await _db.obtenerProductos(busqueda: _busquedaController.text);
    setState(() => _resultados = productos.where((p) => !p.porEncargo).toList());
  }

  void _agregarAlCarrito(Producto p) {
    final existente = _carrito.where((i) => i.productoId == p.id).firstOrNull;
    if (existente != null) {
      setState(() => existente.cantidad++);
    } else {
      setState(() => _carrito.add(ItemCarrito(
            productoId: p.id!,
            nombreProducto: p.nombre,
            precioUnitario: p.precioVenta,
          )));
    }
  }

  void _quitarDelCarrito(ItemCarrito item) {
    setState(() {
      if (item.cantidad > 1) {
        item.cantidad--;
      } else {
        _carrito.remove(item);
      }
    });
  }

  double get _total => _carrito.fold(0, (sum, item) => sum + item.subtotal);

  Future<void> _confirmarVenta() async {
    if (_carrito.isEmpty) return;

    await _db.registrarVenta(
      usuarioId: _usuarioIdActual,
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _busquedaController,
              onChanged: (_) => _buscar(),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Buscar producto por nombre o código...',
                hintStyle: TextStyle(color: AppColors.textoGris),
                prefixIcon: Icon(Icons.search, color: AppColors.textoGris),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _resultados.length,
              itemBuilder: (context, index) {
                final p = _resultados[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.tarjeta,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.nombre,
                                style: const TextStyle(color: Colors.white, fontSize: 13)),
                            Text(
                              '${p.codigo} · Stock: ${p.stockActual} · \$${p.precioVenta.toStringAsFixed(2)}',
                              style: const TextStyle(color: AppColors.textoGris, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: AppColors.amarillo),
                        onPressed: p.stockActual > 0 ? () => _agregarAlCarrito(p) : null,
                      ),
                    ],
                  ),
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
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 150),
            child: ListView(
              shrinkWrap: true,
              children: _carrito
                  .map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(item.nombreProducto,
                                  style: const TextStyle(color: Colors.white, fontSize: 12)),
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline,
                                  size: 18, color: AppColors.textoGris),
                              onPressed: () => _quitarDelCarrito(item),
                            ),
                            Text('${item.cantidad}',
                                style: const TextStyle(color: Colors.white, fontSize: 12)),
                            const SizedBox(width: 8),
                            Text('\$${item.subtotal.toStringAsFixed(2)}',
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
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Text('\$${_total.toStringAsFixed(2)}',
                  style: const TextStyle(
                      color: AppColors.amarillo, fontSize: 18, fontWeight: FontWeight.bold)),
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
