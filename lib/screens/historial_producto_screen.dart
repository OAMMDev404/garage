import 'package:flutter/material.dart';
import '../db/app_database.dart';
import '../db/app_models.dart';
import '../theme.dart';

class HistorialProductoScreen extends StatelessWidget {
  final Producto producto;

  const HistorialProductoScreen({super.key, required this.producto});

  @override
  Widget build(BuildContext context) {
    final db = AppDatabase.instance;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(producto.nombre,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            Text(producto.codigo,
                style: const TextStyle(fontSize: 11, color: AppColors.textoGris)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Ajustar stock',
            icon: const Icon(Icons.tune, color: AppColors.amarillo),
            onPressed: () => _mostrarAjuste(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.tarjeta,
              borderRadius: BorderRadius.circular(12),
            ),
            child: StreamBuilder<List<MovimientosInventario>>(
              stream: db.watchMovimientosProducto(producto.id),
              builder: (context, snap) {
                return StreamBuilder<List<Producto>>(
                  stream: db.watchProductos(),
                  builder: (context, snapP) {
                    final prod = snapP.data
                        ?.where((p) => p.id == producto.id)
                        .firstOrNull;
                    final stockActual = prod?.stock ?? producto.stock;
                    final bajoStock = stockActual <= (prod?.stockMinimo ?? producto.stockMinimo);

                    return Row(
                      children: [
                        Expanded(
                          child: _statCard(
                            'Stock actual',
                            '$stockActual uds',
                            bajoStock ? AppColors.amarillo : AppColors.verde,
                            bajoStock ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _statCard(
                            'Stock mínimo',
                            '${prod?.stockMinimo ?? producto.stockMinimo} uds',
                            AppColors.textoGris,
                            Icons.flag_outlined,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _statCard(
                            'Movimientos',
                            '${snap.data?.length ?? 0}',
                            Colors.white,
                            Icons.swap_vert,
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text('HISTORIAL DE MOVIMIENTOS',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textoGris,
                        letterSpacing: 0.5)),
              ],
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: StreamBuilder<List<MovimientosInventario>>(
              stream: db.watchMovimientosProducto(producto.id),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(
                      child: CircularProgressIndicator(color: AppColors.amarillo));
                }
                final movimientos = snap.data!;
                if (movimientos.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history, color: AppColors.textoGris, size: 40),
                        SizedBox(height: 8),
                        Text('Sin movimientos registrados',
                            style: TextStyle(color: AppColors.textoGris)),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: movimientos.length,
                  itemBuilder: (context, index) =>
                      _itemMovimiento(movimientos[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String valor, Color color, IconData icono) {
    return Column(
      children: [
        Icon(icono, color: color, size: 20),
        const SizedBox(height: 4),
        Text(valor,
            style: TextStyle(
                color: color, fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label,
            style: const TextStyle(color: AppColors.textoGris, fontSize: 10),
            textAlign: TextAlign.center),
      ],
    );
  }

  Widget _itemMovimiento(MovimientosInventario m) {
    final esEntrada = TipoMovimiento.esEntrada(m.tipo);
    final color = esEntrada ? AppColors.verde : AppColors.rojo;
    final icono = esEntrada ? Icons.arrow_downward : Icons.arrow_upward;
    final signo = esEntrada ? '+' : '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.tarjeta,
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: color,
            width: 3,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Icon(icono, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        TipoMovimiento.label(m.tipo),
                        style: TextStyle(
                            fontSize: 10,
                            color: color,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (m.motivo.isNotEmpty)
                  Text(m.motivo,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 12)),
                const SizedBox(height: 2),
                Text(
                  _formatFecha(m.fecha),
                  style: const TextStyle(
                      color: AppColors.textoGris, fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$signo${m.cantidad} uds',
                style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                '${m.stockAntes} → ${m.stockDespues}',
                style: const TextStyle(
                    color: AppColors.textoGris, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatFecha(DateTime d) {
    final hora = '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}  $hora';
  }

  void _mostrarAjuste(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.fondo,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _AjusteStockSheet(producto: producto),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Sheet de ajuste manual de stock
// ─────────────────────────────────────────────────────────────────────────
class _AjusteStockSheet extends StatefulWidget {
  final Producto producto;
  const _AjusteStockSheet({required this.producto});

  @override
  State<_AjusteStockSheet> createState() => _AjusteStockSheetState();
}

class _AjusteStockSheetState extends State<_AjusteStockSheet> {
  final _db = AppDatabase.instance;
  final _formKey = GlobalKey<FormState>();
  final _cantidadController = TextEditingController();
  final _motivoController = TextEditingController();

  List<Usuario> _usuarios = [];
  Usuario? _usuarioSeleccionado;
  bool _esEntrada = false;

  static const _motivosSalida = [
    'Producto dañado',
    'Producto vencido',
    'Pérdida / robo',
    'Corrección de conteo',
    'Otro',
  ];
  static const _motivosEntrada = [
    'Corrección de conteo',
    'Devolución de cliente',
    'Otro',
  ];

  String? _motivoSeleccionado;

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
        _usuarioSeleccionado = usuarios.isNotEmpty ? usuarios.first : null;
      });
    }
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    _motivoController.dispose();
    super.dispose();
  }

  List<String> get _motivos => _esEntrada ? _motivosEntrada : _motivosSalida;

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final motivo = _motivoSeleccionado == 'Otro' || _motivoSeleccionado == null
        ? _motivoController.text.trim()
        : _motivoSeleccionado!;

    if (motivo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Ingresa un motivo para el ajuste'),
          backgroundColor: AppColors.rojo));
      return;
    }

    try {
      await _db.registrarAjusteStock(
        productoId: widget.producto.id,
        usuarioId: _usuarioSeleccionado?.id,
        cantidad: int.parse(_cantidadController.text),
        esEntrada: _esEntrada,
        motivo: motivo,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Ajuste registrado correctamente')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e'), backgroundColor: AppColors.rojo));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
            Text('Ajuste de stock — ${widget.producto.nombre}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Stock actual: ${widget.producto.stock} uds',
                style: const TextStyle(color: AppColors.textoGris, fontSize: 12)),
            const SizedBox(height: 16),

            if (_usuarios.isNotEmpty)
              DropdownButtonFormField<Usuario>(
                value: _usuarioSeleccionado,
                dropdownColor: AppColors.tarjeta,
                decoration: const InputDecoration(labelText: 'Trabajador'),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                items: _usuarios
                    .map((u) => DropdownMenuItem(value: u, child: Text(u.nombre)))
                    .toList(),
                onChanged: (u) => setState(() => _usuarioSeleccionado = u),
              ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _tipoBtn(
                    'Salida',
                    'Daño, pérdida, corrección',
                    !_esEntrada,
                    AppColors.rojo,
                    Icons.remove_circle_outline,
                    () => setState(() {
                      _esEntrada = false;
                      _motivoSeleccionado = null;
                    }),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _tipoBtn(
                    'Entrada',
                    'Devolución, corrección',
                    _esEntrada,
                    AppColors.verde,
                    Icons.add_circle_outline,
                    () => setState(() {
                      _esEntrada = true;
                      _motivoSeleccionado = null;
                    }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _cantidadController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Cantidad a ajustar',
                prefixIcon: Icon(Icons.numbers, color: AppColors.textoGris),
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null || n <= 0) return 'Ingresa una cantidad válida';
                return null;
              },
            ),
            const SizedBox(height: 12),

            const Text('Motivo',
                style: TextStyle(color: AppColors.textoGris, fontSize: 12)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _motivos.map((m) {
                final activo = _motivoSeleccionado == m;
                return GestureDetector(
                  onTap: () => setState(() => _motivoSeleccionado = m),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: activo ? AppColors.amarillo : AppColors.tarjeta,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(m,
                        style: TextStyle(
                            fontSize: 12,
                            color:
                                activo ? Colors.black : AppColors.textoGris,
                            fontWeight: activo
                                ? FontWeight.bold
                                : FontWeight.normal)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            if (_motivoSeleccionado == 'Otro' || _motivoSeleccionado == null)
              TextFormField(
                controller: _motivoController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Describe el motivo',
                  hintText: 'Ej: Se rompió en bodega',
                  hintStyle: TextStyle(color: AppColors.textoGris, fontSize: 12),
                ),
              ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _guardar,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _esEntrada ? AppColors.verde : AppColors.rojo,
                foregroundColor: Colors.white,
              ),
              child: Text(_esEntrada
                  ? 'Registrar entrada de stock'
                  : 'Registrar salida de stock'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tipoBtn(String titulo, String sub, bool activo, Color color,
      IconData icono, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: activo ? color.withOpacity(0.15) : AppColors.tarjeta,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: activo ? color : Colors.transparent, width: 1.5),
        ),
        child: Column(
          children: [
            Icon(icono, color: activo ? color : AppColors.textoGris, size: 22),
            const SizedBox(height: 4),
            Text(titulo,
                style: TextStyle(
                    color: activo ? color : AppColors.textoGris,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
            Text(sub,
                style: const TextStyle(
                    color: AppColors.textoGris, fontSize: 10),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}