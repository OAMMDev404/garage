import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import '../db/app_database.dart';
import '../theme.dart';

class ProductoFormScreen extends StatefulWidget {
  final Producto? producto;
  const ProductoFormScreen({super.key, this.producto});

  @override
  State<ProductoFormScreen> createState() => _ProductoFormScreenState();
}

class _ProductoFormScreenState extends State<ProductoFormScreen> {
  final _db = AppDatabase.instance;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _codigoController;
  late TextEditingController _nombreController;
  late TextEditingController _descripcionController;
  late TextEditingController _precioCompraController;
  late TextEditingController _precioVentaController;
  late TextEditingController _stockController;
  late TextEditingController _stockMinimoController;

  bool _porEncargo = false;
  int? _categoriaId;
  List<Categoria> _categorias = [];
  bool _cargando = true;

  bool get _esEdicion => widget.producto != null;

  @override
  void initState() {
    super.initState();
    final p = widget.producto;
    _codigoController = TextEditingController(text: p?.codigo ?? '');
    _nombreController = TextEditingController(text: p?.nombre ?? '');
    _descripcionController = TextEditingController(text: p?.descripcion ?? '');
    _precioCompraController =
        TextEditingController(text: p?.precioCompra.toString() ?? '');
    _precioVentaController =
        TextEditingController(text: p?.precioVenta.toString() ?? '');
    _stockController =
        TextEditingController(text: p?.stockActual.toString() ?? '0');
    _stockMinimoController =
        TextEditingController(text: p?.stockMinimo.toString() ?? '5');
    _porEncargo = p?.porEncargo ?? false;
    _categoriaId = p?.categoriaId;
    _inicializar();
  }

  Future<void> _inicializar() async {
    final cats = await _db.obtenerCategorias();
    String codigo = _codigoController.text;
    if (!_esEdicion) codigo = await _db.generarSiguienteCodigo();
    setState(() {
      _categorias = cats;
      _categoriaId ??= cats.isNotEmpty ? cats.first.id : null;
      _codigoController.text = codigo;
      _cargando = false;
    });
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _nombreController.dispose();
    _descripcionController.dispose();
    _precioCompraController.dispose();
    _precioVentaController.dispose();
    _stockController.dispose();
    _stockMinimoController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoriaId == null) return;

    final companion = ProductosCompanion(
      id: _esEdicion ? Value(widget.producto!.id) : const Value.absent(),
      codigo: Value(_codigoController.text.trim()),
      nombre: Value(_nombreController.text.trim()),
      descripcion: Value(_descripcionController.text.trim()),
      precioCompra: Value(double.parse(_precioCompraController.text)),
      precioVenta: Value(double.parse(_precioVentaController.text)),
      stockActual: Value(int.parse(_stockController.text)),
      stockMinimo: Value(int.parse(_stockMinimoController.text)),
      porEncargo: Value(_porEncargo),
      categoriaId: Value(_categoriaId!),
    );

    if (_esEdicion) {
      await _db.actualizarProducto(companion);
    } else {
      await _db.crearProducto(companion);
    }

    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _eliminar() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.tarjeta,
        title: const Text('Eliminar producto',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          '¿Seguro que deseas eliminar este producto? Esta acción no se puede deshacer.',
          style: TextStyle(color: AppColors.textoGris),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar',
                  style: TextStyle(color: AppColors.rojo))),
        ],
      ),
    );

    if (confirmar == true && widget.producto?.id != null) {
      await _db.eliminarProducto(widget.producto!.id);
      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(
        body: Center(
            child: CircularProgressIndicator(color: AppColors.amarillo)),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar producto' : 'Nuevo producto'),
        actions: [
          if (_esEdicion)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.rojo),
              onPressed: _eliminar,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _codigoController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Código'),
              readOnly: !_esEdicion,
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nombreController,
              style: const TextStyle(color: Colors.white),
              decoration:
                  const InputDecoration(labelText: 'Nombre del producto'),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descripcionController,
              style: const TextStyle(color: Colors.white),
              decoration:
                  const InputDecoration(labelText: 'Descripción (opcional)'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: _categoriaId,
              dropdownColor: AppColors.tarjeta,
              decoration: const InputDecoration(labelText: 'Categoría'),
              style: const TextStyle(color: Colors.white),
              items: _categorias
                  .map((c) => DropdownMenuItem(
                      value: c.id, child: Text(c.nombre)))
                  .toList(),
              onChanged: (v) => setState(() => _categoriaId = v),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _precioCompraController,
                    style: const TextStyle(color: Colors.white),
                    decoration:
                        const InputDecoration(labelText: 'Precio compra'),
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    validator: (v) =>
                        (v == null || double.tryParse(v) == null)
                            ? 'Inválido'
                            : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _precioVentaController,
                    style: const TextStyle(color: Colors.white),
                    decoration:
                        const InputDecoration(labelText: 'Precio venta'),
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    validator: (v) =>
                        (v == null || double.tryParse(v) == null)
                            ? 'Inválido'
                            : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _stockController,
                    style: const TextStyle(color: Colors.white),
                    decoration:
                        const InputDecoration(labelText: 'Stock actual'),
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                        (v == null || int.tryParse(v) == null)
                            ? 'Inválido'
                            : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _stockMinimoController,
                    style: const TextStyle(color: Colors.white),
                    decoration:
                        const InputDecoration(labelText: 'Stock mínimo'),
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                        (v == null || int.tryParse(v) == null)
                            ? 'Inválido'
                            : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              value: _porEncargo,
              activeColor: AppColors.amarillo,
              tileColor: AppColors.tarjeta,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              title: const Text('Producto solo por encargo',
                  style: TextStyle(color: Colors.white, fontSize: 13)),
              subtitle: const Text(
                'No se mantiene en stock, se manda a traer cuando un cliente lo pide',
                style: TextStyle(color: AppColors.textoGris, fontSize: 11),
              ),
              onChanged: (v) => setState(() => _porEncargo = v),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _guardar,
              child: Text(
                  _esEdicion ? 'Guardar cambios' : 'Agregar producto'),
            ),
          ],
        ),
      ),
    );
  }
}