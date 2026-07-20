import 'package:flutter/material.dart';
import '../db/app_database.dart';
import '../db/app_models.dart';
import '../theme.dart';

class CategoriaGasto {
  static const compraInventario = 'Compra de inventario';
  static const servicios = 'Servicios';
  static const nomina = 'Nómina';
  static const otros = 'Otros';
  static const todas = [compraInventario, servicios, nomina, otros];
}

class GastosScreen extends StatelessWidget {
  const GastosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = AppDatabase.instance;

    return Scaffold(
      appBar: AppBar(title: const Text('Gastos')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.amarillo,
        foregroundColor: Colors.black,
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: AppColors.fondo,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (_) => const _NuevoGastoSheet(),
        ),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<Gasto>>(
        stream: db.watchGastos(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(
                child:
                    CircularProgressIndicator(color: AppColors.amarillo));
          }
          final gastos = snap.data!;
          if (gastos.isEmpty) {
            return const Center(
              child: Text('No hay gastos registrados',
                  style: TextStyle(color: AppColors.textoGris)),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: gastos.length,
            itemBuilder: (context, index) {
              final g = gastos[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.tarjeta,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.azulOscuro,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.receipt_long_outlined,
                          color: AppColors.amarillo, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(g.categoria,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13)),
                          if (g.descripcion.isNotEmpty)
                            Text(g.descripcion,
                                style: const TextStyle(
                                    color: AppColors.textoGris,
                                    fontSize: 11)),
                          Text(
                            '${g.fecha.day.toString().padLeft(2, '0')}/'
                            '${g.fecha.month.toString().padLeft(2, '0')}/'
                            '${g.fecha.year}',
                            style: const TextStyle(
                                color: AppColors.textoGris, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '\$${g.monto.toStringAsFixed(2)}',
                      style: const TextStyle(
                          color: AppColors.rojo,
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Sheet para nuevo gasto
// ─────────────────────────────────────────────────────────────────────────
class _NuevoGastoSheet extends StatefulWidget {
  const _NuevoGastoSheet();

  @override
  State<_NuevoGastoSheet> createState() => _NuevoGastoSheetState();
}

class _NuevoGastoSheetState extends State<_NuevoGastoSheet> {
  final _db = AppDatabase.instance;
  final _formKey = GlobalKey<FormState>();
  final _montoController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _cantidadController = TextEditingController(text: '1');

  String _categoria = CategoriaGasto.compraInventario;
  List<Producto> _productos = [];
  Producto? _productoSeleccionado;
  List<Usuario> _usuarios = [];
  Usuario? _usuarioSeleccionado;
  bool _cargando = true;

  bool get _esCompraInventario =>
      _categoria == CategoriaGasto.compraInventario;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  @override
  void dispose() {
    _montoController.dispose();
    _descripcionController.dispose();
    _cantidadController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    final productos = await _db.obtenerProductos();
    final usuarios = await _db.obtenerUsuarios();
    if (mounted) {
      setState(() {
        _productos = productos.where((p) => !p.esServicio).toList();
        _usuarios = usuarios;
        _usuarioSeleccionado = usuarios.isNotEmpty ? usuarios.first : null;
        _cargando = false;
      });
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    if (_esCompraInventario) {
      if (_productoSeleccionado == null) {
        _snack('Selecciona el producto que recibiste');
        return;
      }
      final cantidad = int.tryParse(_cantidadController.text) ?? 0;
      if (cantidad <= 0) {
        _snack('La cantidad debe ser mayor a 0');
        return;
      }
      await _db.registrarCompraInventario(
        usuarioId: _usuarioSeleccionado?.id,
        productoId: _productoSeleccionado!.id,
        cantidadRecibida: cantidad,
        monto: double.parse(_montoController.text),
        descripcion: _descripcionController.text.trim(),
      );
    } else {
      await _db.crearGasto(
        categoria: _categoria,
        monto: double.parse(_montoController.text),
        usuarioId: _usuarioSeleccionado?.id,
        observaciones: _descripcionController.text.trim(),
      );
    }

    if (mounted) Navigator.pop(context, true);
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.rojo),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
            child: CircularProgressIndicator(color: AppColors.amarillo)),
      );
    }
    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nuevo gasto',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            if (_usuarios.isNotEmpty)
              DropdownButtonFormField<Usuario>(
                value: _usuarioSeleccionado,
                dropdownColor: AppColors.tarjeta,
                decoration: const InputDecoration(labelText: 'Registrado por'),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                items: _usuarios
                    .map((u) => DropdownMenuItem(value: u, child: Text(u.nombre)))
                    .toList(),
                onChanged: (u) => setState(() => _usuarioSeleccionado = u),
              ),
            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: _categoria,
              dropdownColor: AppColors.tarjeta,
              decoration: const InputDecoration(labelText: 'Categoría'),
              style: const TextStyle(color: Colors.white),
              items: CategoriaGasto.todas
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() {
                _categoria = v ?? _categoria;
                _productoSeleccionado = null;
                _cantidadController.text = '1';
              }),
            ),
            const SizedBox(height: 12),

            if (_esCompraInventario) ...[
              DropdownButtonFormField<Producto>(
                value: _productoSeleccionado,
                dropdownColor: AppColors.tarjeta,
                decoration: const InputDecoration(
                    labelText: 'Producto recibido'),
                style: const TextStyle(
                    color: Colors.white, fontSize: 13),
                isExpanded: true,
                hint: const Text('Seleccionar producto',
                    style: TextStyle(
                        color: AppColors.textoGris, fontSize: 13)),
                items: _productos
                    .map((p) => DropdownMenuItem(
                          value: p,
                          child: Text(
                            '${p.nombre} (stock: ${p.stock})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ))
                    .toList(),
                onChanged: (p) =>
                    setState(() => _productoSeleccionado = p),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cantidadController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Cantidad recibida',
                  prefixIcon: Icon(Icons.add_box_outlined,
                      color: AppColors.textoGris),
                ),
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  if (!_esCompraInventario) return null;
                  final n = int.tryParse(v ?? '');
                  if (n == null || n <= 0) return 'Ingresa una cantidad válida';
                  return null;
                },
              ),
              if (_productoSeleccionado != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.azulOscuro,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.inventory_2_outlined,
                          color: AppColors.amarillo, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Stock: ${_productoSeleccionado!.stock} → '
                        '${_productoSeleccionado!.stock + (int.tryParse(_cantidadController.text) ?? 0)} uds',
                        style: const TextStyle(
                            color: AppColors.verde, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
            ],

            TextFormField(
              controller: _montoController,
              style: const TextStyle(color: Colors.white),
              decoration:
                  const InputDecoration(labelText: 'Monto del gasto'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (v) =>
                  (v == null || double.tryParse(v) == null)
                      ? 'Monto inválido'
                      : null,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _descripcionController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Descripción (opcional)',
                hintText: _esCompraInventario
                    ? 'Se genera automáticamente si la dejas vacía'
                    : null,
                hintStyle: const TextStyle(
                    color: AppColors.textoGris, fontSize: 11),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _guardar,
              child: Text(_esCompraInventario
                  ? 'Registrar gasto y actualizar stock'
                  : 'Guardar gasto'),
            ),
          ],
        ),
      ),
    );
  }
}