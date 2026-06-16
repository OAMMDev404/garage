import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/gasto.dart';
import '../theme.dart';

class GastosScreen extends StatefulWidget {
  const GastosScreen({super.key});

  @override
  State<GastosScreen> createState() => _GastosScreenState();
}

class _GastosScreenState extends State<GastosScreen> {
  final _db = DatabaseHelper.instance;
  List<Gasto> _gastos = [];

  // TODO: reemplazar por el id del usuario autenticado en la sesión
  static const int _usuarioIdActual = 1;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final gastos = await _db.obtenerGastos();
    setState(() => _gastos = gastos);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gastos')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.amarillo,
        foregroundColor: Colors.black,
        onPressed: () async {
          final creado = await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            backgroundColor: AppColors.fondo,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            builder: (_) => const _NuevoGastoSheet(usuarioId: _usuarioIdActual),
          );
          if (creado == true) _cargar();
        },
        child: const Icon(Icons.add),
      ),
      body: _gastos.isEmpty
          ? const Center(
              child: Text('No hay gastos registrados',
                  style: TextStyle(color: AppColors.textoGris)),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _gastos.length,
              itemBuilder: (context, index) {
                final g = _gastos[index];
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
                                    color: Colors.white, fontWeight: FontWeight.w500, fontSize: 13)),
                            if (g.descripcion.isNotEmpty)
                              Text(g.descripcion,
                                  style: const TextStyle(color: AppColors.textoGris, fontSize: 11)),
                            Text(
                              '${g.fecha.day.toString().padLeft(2, '0')}/${g.fecha.month.toString().padLeft(2, '0')}/${g.fecha.year}',
                              style: const TextStyle(color: AppColors.textoGris, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '\$${g.monto.toStringAsFixed(2)}',
                        style: const TextStyle(
                            color: AppColors.rojo, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

// ---------------------------------------------------------------------
// Formulario rápido para registrar un nuevo gasto
// ---------------------------------------------------------------------
class _NuevoGastoSheet extends StatefulWidget {
  final int usuarioId;

  const _NuevoGastoSheet({required this.usuarioId});

  @override
  State<_NuevoGastoSheet> createState() => _NuevoGastoSheetState();
}

class _NuevoGastoSheetState extends State<_NuevoGastoSheet> {
  final _db = DatabaseHelper.instance;
  final _formKey = GlobalKey<FormState>();

  final _montoController = TextEditingController();
  final _descripcionController = TextEditingController();
  String _categoria = CategoriaGasto.compraInventario;

  @override
  void dispose() {
    _montoController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    await _db.crearGasto(Gasto(
      fecha: DateTime.now(),
      categoria: _categoria,
      descripcion: _descripcionController.text.trim(),
      monto: double.parse(_montoController.text),
      usuarioId: widget.usuarioId,
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
              'Nuevo gasto',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _categoria,
              dropdownColor: AppColors.tarjeta,
              decoration: const InputDecoration(labelText: 'Categoría'),
              style: const TextStyle(color: Colors.white),
              items: CategoriaGasto.todas
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _categoria = v ?? _categoria),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _montoController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Monto'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) =>
                  (v == null || double.tryParse(v) == null) ? 'Monto inválido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descripcionController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Descripción (opcional)'),
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _guardar,
              child: const Text('Guardar gasto'),
            ),
          ],
        ),
      ),
    );
  }
}
