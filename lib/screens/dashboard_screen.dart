import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/producto.dart';
import '../theme.dart';
import 'venta_screen.dart';
import 'gastos_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _db = DatabaseHelper.instance;

  Map<String, double> _resumen = {'ingresos': 0, 'gastos': 0, 'utilidad': 0};
  List<Producto> _bajoStock = [];
  int _totalProductos = 0;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    try {
      final ahora = DateTime.now();
      final inicioMes = DateTime(ahora.year, ahora.month, 1);
      final resumen = await _db.obtenerResumenFinanciero(desde: inicioMes);
      final bajoStock = await _db.obtenerProductosBajoStock();
      final todos = await _db.obtenerProductos();
      setState(() {
        _resumen = resumen;
        _bajoStock = bajoStock;
        _totalProductos = todos.length;
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.fondo,
      child: _cargando
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.amarillo))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _tarjetaIngresos(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _tarjetaMini(
                        icono: Icons.inventory_2_outlined,
                        valor: '$_totalProductos',
                        etiqueta: 'Productos',
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _tarjetaMini(
                        icono: Icons.warning_amber_rounded,
                        valor: '${_bajoStock.length}',
                        etiqueta: 'Stock bajo',
                        color: _bajoStock.isNotEmpty
                            ? AppColors.amarillo
                            : Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _tarjetaMini(
                        icono: Icons.receipt_long_outlined,
                        valor:
                            '\$${_resumen['gastos']!.toStringAsFixed(0)}',
                        etiqueta: 'Gastos del mes',
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _tarjetaMini(
                        icono: Icons.trending_up,
                        valor:
                            '\$${_resumen['utilidad']!.toStringAsFixed(0)}',
                        etiqueta: 'Utilidad del mes',
                        color: AppColors.verde,
                      ),
                    ),
                  ],
                ),
                if (_bajoStock.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _seccionAlertas(),
                ],
                const SizedBox(height: 20),
                _botonesAccion(context),
              ],
            ),
    );
  }

  Widget _tarjetaIngresos() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.amarillo,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('INGRESOS DEL MES',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF5A4200),
                  letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(
            '\$${_resumen['ingresos']!.toStringAsFixed(2)}',
            style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A00)),
          ),
        ],
      ),
    );
  }

  Widget _tarjetaMini({
    required IconData icono,
    required String valor,
    required String etiqueta,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.tarjeta,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, color: AppColors.amarillo, size: 22),
          const SizedBox(height: 8),
          Text(valor,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(etiqueta,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textoGris)),
        ],
      ),
    );
  }

  Widget _seccionAlertas() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ALERTAS DE STOCK',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textoGris,
                letterSpacing: 0.5)),
        const SizedBox(height: 8),
        ..._bajoStock.map((p) => Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1000),
                borderRadius: BorderRadius.circular(6),
                border: const Border(
                    left: BorderSide(color: AppColors.amarillo, width: 3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active,
                      color: AppColors.amarillo, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${p.nombre} — stock crítico (${p.stockActual} uds)',
                      style: const TextStyle(
                          color: Color(0xFFFFDC5A), fontSize: 12),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _botonesAccion(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ACCIONES RÁPIDAS',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textoGris,
                letterSpacing: 0.5)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _botonAccion(
                icono: Icons.point_of_sale,
                texto: 'Nueva venta',
                onTap: () async {
                  await Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const VentaScreen()));
                  _cargarDatos();
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _botonAccion(
                icono: Icons.receipt_long_outlined,
                texto: 'Registrar gasto',
                onTap: () async {
                  await Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const GastosScreen()));
                  _cargarDatos();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _botonAccion({
    required IconData icono,
    required String texto,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.tarjeta,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icono, color: AppColors.amarillo, size: 26),
            const SizedBox(height: 6),
            Text(texto,
                style: const TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
