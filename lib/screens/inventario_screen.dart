import 'package:flutter/material.dart';
import '../db/app_database.dart';
import '../theme.dart';
import 'producto_form_screen.dart';

class InventarioScreen extends StatefulWidget {
  const InventarioScreen({super.key});

  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen> {
  final _db = AppDatabase.instance;
  final _busquedaController = TextEditingController();

  String _filtro = 'todos'; // todos | bajo_stock | encargo
  int? _categoriaSeleccionada;

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  /// Reconstruye el stream cada vez que cambian los filtros.
  Stream<List<Producto>> get _productosStream => _db.watchProductos(
        busqueda: _busquedaController.text,
        categoriaId: _categoriaSeleccionada,
        soloBajoStock: _filtro == 'bajo_stock',
        soloEncargo: _filtro == 'encargo',
      );

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.fondo,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _busquedaController,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Buscar por nombre o código...',
                hintStyle: TextStyle(color: AppColors.textoGris),
                prefixIcon: Icon(Icons.search, color: AppColors.textoGris),
              ),
            ),
          ),
          // ── Chips de filtro ──────────────────────────────────────────
          StreamBuilder<List<Categoria>>(
            stream: _db.watchCategorias(),
            builder: (context, snap) {
              final categorias = snap.data ?? [];
              return SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _chip('Todos', _filtro == 'todos',
                        () => setState(() => _filtro = 'todos')),
                    const SizedBox(width: 6),
                    _chip('Bajo stock', _filtro == 'bajo_stock',
                        () => setState(() => _filtro = 'bajo_stock')),
                    const SizedBox(width: 6),
                    _chip('Por encargo', _filtro == 'encargo',
                        () => setState(() => _filtro = 'encargo')),
                    const SizedBox(width: 12),
                    Container(width: 1, color: AppColors.tarjeta),
                    const SizedBox(width: 12),
                    ...categorias.map((c) => Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: _chip(
                            c.nombre,
                            _categoriaSeleccionada == c.id,
                            () => setState(() {
                              _categoriaSeleccionada =
                                  _categoriaSeleccionada == c.id
                                      ? null
                                      : c.id;
                            }),
                          ),
                        )),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          // ── Lista de productos reactiva ───────────────────────────────
          Expanded(
            child: StreamBuilder<List<Producto>>(
              stream: _productosStream,
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.amarillo));
                }
                final productos = snap.data!;
                if (productos.isEmpty) {
                  return const Center(
                    child: Text('No se encontraron productos',
                        style: TextStyle(color: AppColors.textoGris)),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  itemCount: productos.length,
                  itemBuilder: (context, index) =>
                      _itemProducto(productos[index]),
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

  Widget _itemProducto(Producto p) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ProductoFormScreen(producto: p)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.tarjeta,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.azulOscuro,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Icon(
                p.porEncargo
                    ? Icons.local_shipping_outlined
                    : Icons.inventory_2_outlined,
                color: AppColors.amarillo,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.nombre,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 13)),
                  Text(p.codigo,
                      style: const TextStyle(
                          color: AppColors.textoGris, fontSize: 11)),
                  if (p.porEncargo)
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.azulMedio,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('Solo por encargo',
                          style:
                              TextStyle(fontSize: 9, color: Color(0xFF9DC4FF))),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${p.stockActual} uds',
                  style: TextStyle(
                    color: p.stockActual <= p.stockMinimo
                        ? AppColors.amarillo
                        : Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                Text('\$${p.precioVenta.toStringAsFixed(2)}',
                    style: const TextStyle(
                        color: AppColors.textoGris, fontSize: 11)),
                if (p.stockActual <= p.stockMinimo)
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3A1500),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Bajo',
                        style: TextStyle(
                            fontSize: 9, color: AppColors.amarillo)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}