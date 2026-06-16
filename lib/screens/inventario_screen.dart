import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/producto.dart';
import '../models/categoria.dart';
import '../theme.dart';
import 'producto_form_screen.dart';

class InventarioScreen extends StatefulWidget {
  const InventarioScreen({super.key});

  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen> {
  final _db = DatabaseHelper.instance;
  final _busquedaController = TextEditingController();

  List<Producto> _productos = [];
  List<Categoria> _categorias = [];
  int? _categoriaSeleccionada;
  String _filtro = 'todos'; // todos | bajo_stock | encargo

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final categorias = await _db.obtenerCategorias();
    await _buscar();
    setState(() => _categorias = categorias);
  }

  Future<void> _buscar() async {
    final productos = await _db.obtenerProductos(
      busqueda: _busquedaController.text,
      categoriaId: _categoriaSeleccionada,
      soloBajoStock: _filtro == 'bajo_stock',
    );

    final filtrados = _filtro == 'encargo'
        ? productos.where((p) => p.porEncargo).toList()
        : productos;

    setState(() => _productos = filtrados);
  }

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
              onChanged: (_) => _buscar(),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Buscar por nombre o código...',
                hintStyle: TextStyle(color: AppColors.textoGris),
                prefixIcon: Icon(Icons.search, color: AppColors.textoGris),
              ),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _chip('Todos', _filtro == 'todos', () {
                  setState(() => _filtro = 'todos');
                  _buscar();
                }),
                const SizedBox(width: 6),
                _chip('Bajo stock', _filtro == 'bajo_stock', () {
                  setState(() => _filtro = 'bajo_stock');
                  _buscar();
                }),
                const SizedBox(width: 6),
                _chip('Por encargo', _filtro == 'encargo', () {
                  setState(() => _filtro = 'encargo');
                  _buscar();
                }),
                const SizedBox(width: 12),
                Container(width: 1, color: AppColors.tarjeta),
                const SizedBox(width: 12),
                ..._categorias.map((c) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: _chip(
                        c.nombre,
                        _categoriaSeleccionada == c.id,
                        () {
                          setState(() {
                            _categoriaSeleccionada =
                                _categoriaSeleccionada == c.id ? null : c.id;
                          });
                          _buscar();
                        },
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _productos.isEmpty
                ? const Center(
                    child: Text(
                      'No se encontraron productos',
                      style: TextStyle(color: AppColors.textoGris),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                    itemCount: _productos.length,
                    itemBuilder: (context, index) {
                      final p = _productos[index];
                      return _itemProducto(p);
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
      onTap: () async {
        final actualizado = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (_) => ProductoFormScreen(producto: p)),
        );
        if (actualizado == true) _buscar();
      },
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
                p.porEncargo ? Icons.local_shipping_outlined : Icons.inventory_2_outlined,
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
                          color: Colors.white, fontWeight: FontWeight.w500, fontSize: 13)),
                  Text(p.codigo,
                      style: const TextStyle(color: AppColors.textoGris, fontSize: 11)),
                  if (p.porEncargo)
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.azulMedio,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Solo por encargo',
                        style: TextStyle(fontSize: 9, color: Color(0xFF9DC4FF)),
                      ),
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
                    color: p.bajoStock ? AppColors.amarillo : Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '\$${p.precioVenta.toStringAsFixed(2)}',
                  style: const TextStyle(color: AppColors.textoGris, fontSize: 11),
                ),
                if (p.bajoStock)
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3A1500),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Bajo',
                      style: TextStyle(fontSize: 9, color: AppColors.amarillo),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
