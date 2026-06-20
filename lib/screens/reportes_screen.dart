import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

import '../db/database_helper.dart';
import '../models/gasto.dart';
import '../theme.dart';

enum PeriodoReporte { semana, mes, trimestre, anio }

extension on PeriodoReporte {
  String get label {
    switch (this) {
      case PeriodoReporte.semana:
        return 'Semana';
      case PeriodoReporte.mes:
        return 'Mes';
      case PeriodoReporte.trimestre:
        return 'Trimestre';
      case PeriodoReporte.anio:
        return 'Año';
    }
  }

  DateTime fechaInicio(DateTime ahora) {
    switch (this) {
      case PeriodoReporte.semana:
        return ahora.subtract(const Duration(days: 7));
      case PeriodoReporte.mes:
        return DateTime(ahora.year, ahora.month, 1);
      case PeriodoReporte.trimestre:
        return DateTime(ahora.year, ahora.month - 3, ahora.day);
      case PeriodoReporte.anio:
        return DateTime(ahora.year, 1, 1);
    }
  }
}

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  final _db = DatabaseHelper.instance;

  PeriodoReporte _periodo = PeriodoReporte.mes;
  Map<String, double> _resumen = {'ingresos': 0, 'gastos': 0, 'utilidad': 0};
  List<Map<String, dynamic>> _topProductos = [];
  List<Gasto> _gastos = [];
  bool _cargando = true;
  String? _error;

  DateTime get _desde => _periodo.fechaInicio(DateTime.now());

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final resumen = await _db.obtenerResumenFinanciero(desde: _desde);
      final top = await _db.productosMasVendidos(desde: _desde);
      final gastos = await _db.obtenerGastos(desde: _desde);
      if (!mounted) return;
      setState(() {
        _resumen = resumen;
        _topProductos = top;
        _gastos = gastos;
      });
    } catch (e, st) {
      debugPrint('Error cargando reportes: $e\n$st');
      if (mounted) {
        setState(() => _error = 'No se pudieron cargar los reportes: $e');
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  double get _margen {
    final ingresos = _resumen['ingresos'] ?? 0;
    if (ingresos == 0) return 0;
    return ((_resumen['utilidad'] ?? 0) / ingresos) * 100;
  }

  Future<void> _exportarPDF() async {
    final pdf = pw.Document();
    final ahora = DateTime.now();

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text('Informe Financiero - Taller Mecánico',
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          ),
          pw.Text('Período: ${_periodo.label}'),
          pw.Text('Generado el: ${ahora.day}/${ahora.month}/${ahora.year}'),
          pw.SizedBox(height: 16),
          pw.Text('Resumen', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.Table(
            border: pw.TableBorder.all(width: 0.5),
            children: [
              _filaTabla('Ingresos', '\$${_resumen['ingresos']!.toStringAsFixed(2)}'),
              _filaTabla('Gastos', '\$${_resumen['gastos']!.toStringAsFixed(2)}'),
              _filaTabla('Utilidad', '\$${_resumen['utilidad']!.toStringAsFixed(2)}'),
              _filaTabla('Margen', '${_margen.toStringAsFixed(1)}%'),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Text('Productos más vendidos',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.Table(
            border: pw.TableBorder.all(width: 0.5),
            children: [
              pw.TableRow(children: [
                _celda('Código', bold: true),
                _celda('Producto', bold: true),
                _celda('Cantidad', bold: true),
                _celda('Total', bold: true),
              ]),
              ..._topProductos.map((p) => pw.TableRow(children: [
                    _celda(p['codigo'] as String),
                    _celda(p['nombre'] as String),
                    _celda('${p['cantidadVendida']}'),
                    _celda('\$${(p['totalVendido'] as num).toStringAsFixed(2)}'),
                  ])),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Text('Gastos del período',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.Table(
            border: pw.TableBorder.all(width: 0.5),
            children: [
              pw.TableRow(children: [
                _celda('Fecha', bold: true),
                _celda('Categoría', bold: true),
                _celda('Descripción', bold: true),
                _celda('Monto', bold: true),
              ]),
              ..._gastos.map((g) => pw.TableRow(children: [
                    _celda('${g.fecha.day}/${g.fecha.month}/${g.fecha.year}'),
                    _celda(g.categoria),
                    _celda(g.descripcion),
                    _celda('\$${g.monto.toStringAsFixed(2)}'),
                  ])),
            ],
          ),
        ],
      ),
    );

    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/informe_${ahora.millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(await pdf.save());
      await OpenFilex.open(file.path);
    } catch (e) {
      debugPrint('Error exportando PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo exportar el PDF: $e')),
        );
      }
    }
  }

  pw.TableRow _filaTabla(String label, String valor) {
    return pw.TableRow(children: [_celda(label, bold: true), _celda(valor)]);
  }

  pw.Widget _celda(String texto, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(texto,
          style: pw.TextStyle(fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.fondo,
      child: _cargando
          ? const Center(child: CircularProgressIndicator(color: AppColors.amarillo))
          : _error != null
              ? _vistaError()
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _selectorPeriodo(),
                    const SizedBox(height: 16),
                    _tarjetaResumen(),
                    const SizedBox(height: 16),
                    _graficaIngresosGastos(),
                    const SizedBox(height: 16),
                    _seccionTopProductos(),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _exportarPDF,
                      icon: const Icon(Icons.download),
                      label: const Text('Exportar informe en PDF'),
                    ),
                  ],
                ),
    );
  }

  Widget _vistaError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.rojo, size: 40),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Ocurrió un error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textoGris, fontSize: 13),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _cargar,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _selectorPeriodo() {
    return Row(
      children: PeriodoReporte.values.map((p) {
        final activo = p == _periodo;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() => _periodo = p);
              _cargar();
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: activo ? AppColors.azulMedio : AppColors.tarjeta,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                p.label,
                style: TextStyle(
                  fontSize: 12,
                  color: activo ? const Color(0xFF6AA8FF) : AppColors.textoGris,
                  fontWeight: activo ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _tarjetaResumen() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 2.2,
      children: [
        _metrica('Ingresos', '\$${_resumen['ingresos']!.toStringAsFixed(2)}', AppColors.amarillo),
        _metrica('Gastos', '\$${_resumen['gastos']!.toStringAsFixed(2)}', Colors.white),
        _metrica('Utilidad', '\$${_resumen['utilidad']!.toStringAsFixed(2)}', AppColors.verde),
        _metrica('Margen', '${_margen.toStringAsFixed(1)}%', Colors.white),
      ],
    );
  }

  Widget _metrica(String label, String valor, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.tarjeta,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textoGris, fontSize: 11)),
          Text(valor,
              style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _graficaIngresosGastos() {
    final ingresos = _resumen['ingresos'] ?? 0;
    final gastos = _resumen['gastos'] ?? 0;
    final maxValor = (ingresos > gastos ? ingresos : gastos) * 1.2;

    return Container(
      height: 180,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.tarjeta,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ingresos vs Gastos',
              style: TextStyle(color: AppColors.textoGris, fontSize: 11)),
          const SizedBox(height: 8),
          Expanded(
            child: BarChart(
              BarChartData(
                maxY: maxValor == 0 ? 100 : maxValor,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) => Text(
                        value == 0 ? 'Ingresos' : 'Gastos',
                        style: const TextStyle(color: AppColors.textoGris, fontSize: 10),
                      ),
                    ),
                  ),
                ),
                barGroups: [
                  BarChartGroupData(x: 0, barRods: [
                    BarChartRodData(
                      toY: ingresos,
                      color: AppColors.amarillo,
                      width: 40,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ]),
                  BarChartGroupData(x: 1, barRods: [
                    BarChartRodData(
                      toY: gastos,
                      color: AppColors.azulMedio,
                      width: 40,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _seccionTopProductos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Productos más vendidos',
            style: TextStyle(color: AppColors.textoGris, fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (_topProductos.isEmpty)
          const Text('Sin ventas en este período',
              style: TextStyle(color: AppColors.textoGris, fontSize: 12))
        else
          ..._topProductos.map((p) => Container(
                margin: const EdgeInsets.only(bottom: 6),
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
                          Text(p['nombre'] as String,
                              style: const TextStyle(color: Colors.white, fontSize: 13)),
                          Text(p['codigo'] as String,
                              style: const TextStyle(color: AppColors.textoGris, fontSize: 11)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${p['cantidadVendida']} uds',
                            style: const TextStyle(color: Colors.white, fontSize: 12)),
                        Text('\$${(p['totalVendido'] as num).toStringAsFixed(2)}',
                            style: const TextStyle(color: AppColors.amarillo, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              )),
      ],
    );
  }
}