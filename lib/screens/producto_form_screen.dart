import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import '../db/app_database.dart';
import '../db/app_models.dart';
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
  late TextEditingController _marcaController;
  late TextEditingController _costoController;
  late TextEditingController _precioController;
  late TextEditingController _stockController;
  late TextEditingController _stockMinimoController;

  String _tipo = TipoProducto.producto;
  String? _categoriaId;
  List<Categoria> _categorias = [];
  bool _cargando = true;
  bool _guardando = false;

  bool get _esEdicion => widget.producto != null;
  bool get _esServicio => _tipo == TipoProducto.servicio;

  @override
  void initState() {
    super.initState();
    final p = widget.producto;
    _codigoController = TextEditingController(text: p?.codigo ?? '');
    _nombreController = TextEditingController(text: p?.nombre ?? '');
    _marcaController = TextEditingController(text: p?.marca ?? '');
    _costoController = TextEditingController(text: p?.costo.toString() ?? '0');
    _precioController = TextEditingController(text: p?.precio.toString() ?? '');
    _stockController = TextEditingController(text: p?.stock.toString() ?? '0');
    _stockMinimoController =
        TextEditingController(text: p?.stockMinimo.toString() ?? '5');
    _tipo = p?.tipo ?? TipoProducto.producto;
    _categoriaId = p?.categoriaId;
    _inicializar();
  }

  Future<void> _inicializar() async {
    final cats = await _db.obtenerCategorias();
    String codigo = _codigoController.text;
    // Si es un producto nuevo, sugerimos el siguiente código disponible,
    // pero el usuario lo puede cambiar libremente (ver TextFormField abajo).
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
    _marcaController.dispose();
    _costoController.dispose();
    _precioController.dispose();
    _stockController.dispose();
    _stockMinimoController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoriaId == null) return;

    setState(() => _guardando = true);

    final companion = ProductosCompanion(
      id: _esEdicion ? Value(widget.producto!.id) : const Value.absent(),
      codigo: Value(_codigoController.text.trim()),
      nombre: Value(_nombreController.text.trim()),
      categoriaId: Value(_categoriaId!),
      marca: Value(_marcaController.text.trim()),
      costo: Value(double.parse(_costoController.text)),
      precio: Value(double.parse(_precioController.text)),
      stock: _esServicio ? const Value(0) : Value(int.parse(_stockController.text)),
      stockMinimo: Value(int.parse(_stockMinimoController.text)),
      tipo: Value(_tipo),
      activo: const Value(true),
    );

    try {
      if (_esEdicion) {
        await _db.actualizarProducto(companion);
      } else {
        await _db.crearProducto(companion);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _guardando = false);
        final mensaje = e.toString().toLowerCase().contains('duplicate') ||
                e.toString().toLowerCase().contains('unique')
            ? 'Ese código ya existe. Usa uno diferente.'
            : 'No se pudo guardar: $e';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensaje), backgroundColor: AppColors.rojo),
        );
      }
    }
  }

  Future<void> _eliminar() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.tarjeta,
        title: const Text('Eliminar', style: TextStyle(color: Colors.white)),
        content: const Text(
          '¿Seguro que deseas eliminar este ítem? Esta acción no se puede deshacer.',
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
        title: Text(_esEdicion
            ? (_esServicio ? 'Editar servicio' : 'Editar producto')
            : (_esServicio ? 'Nuevo servicio' : 'Nuevo producto')),
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
            // ── Tipo: Producto o Servicio ────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _tipoBtn('Producto', _tipo == TipoProducto.producto,
                      () => setState(() => _tipo = TipoProducto.producto)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _tipoBtn('Servicio', _tipo == TipoProducto.servicio,
                      () => setState(() => _tipo = TipoProducto.servicio)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _codigoController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Código',
                // El código se sugiere automáticamente al crear un producto
                // nuevo, pero siempre se puede editar libremente.
                helperText: !_esEdicion
                    ? 'Sugerido automáticamente, puedes cambiarlo'
                    : null,
                helperStyle: const TextStyle(
                    color: AppColors.textoGris, fontSize: 11),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nombreController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                  labelText: _esServicio ? 'Nombre del servicio' : 'Nombre del producto'),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 12),
            if (!_esServicio) ...[
              TextFormField(
                controller: _marcaController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Marca (opcional)'),
              ),
              const SizedBox(height: 12),
            ],
            DropdownButtonFormField<String>(
              value: _categoriaId,
              dropdownColor: AppColors.tarjeta,
              decoration: const InputDecoration(labelText: 'Categoría'),
              style: const TextStyle(color: Colors.white),
              items: _categorias
                  .map((c) => DropdownMenuItem<String>(
                      value: c.id, child: Text(c.nombre)))
                  .toList(),
              onChanged: (v) => setState(() => _categoriaId = v),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (!_esServicio) ...[
                  Expanded(
                    child: TextFormField(
                      controller: _costoController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Costo'),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) =>
                          (v == null || double.tryParse(v) == null)
                              ? 'Inválido'
                              : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: TextFormField(
                    controller: _precioController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                        labelText: _esServicio ? 'Precio del servicio' : 'Precio de venta'),
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
            if (!_esServicio) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _stockController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Stock actual'),
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
                      decoration: const InputDecoration(labelText: 'Stock mínimo'),
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          (v == null || int.tryParse(v) == null)
                              ? 'Inválido'
                              : null,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _guardando ? null : _guardar,
              child: _guardando
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black),
                    )
                  : Text(_esEdicion ? 'Guardar cambios' : 'Agregar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tipoBtn(String texto, bool activo, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: activo ? AppColors.amarillo : AppColors.tarjeta,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(texto,
            style: TextStyle(
                color: activo ? Colors.black : AppColors.textoGris,
                fontWeight: activo ? FontWeight.bold : FontWeight.normal,
                fontSize: 13)),
      ),
    );
  }
}