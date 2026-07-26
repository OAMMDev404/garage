import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../db/app_database.dart';
import '../db/app_models.dart';
import '../theme.dart';

enum PeriodoReporte { semana, mes, trimestre, anio }

extension on PeriodoReporte {
  String get label {
    switch (this) {
      case PeriodoReporte.semana: return 'Semana';
      case PeriodoReporte.mes: return 'Mes';
      case PeriodoReporte.trimestre: return 'Trimestre';
      case PeriodoReporte.anio: return 'Año';
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
  final _db = AppDatabase.instance;
  PeriodoReporte _periodo = PeriodoReporte.mes;

  DateTime get _desde => _periodo.fechaInicio(DateTime.now());

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.fondo,
      child: StreamBuilder<ResumenFinanciero>(
        stream: _db.watchResumenFinanciero(desde: _desde),
        builder: (context, snapResumen) {
          return StreamBuilder<List<ProductoMasVendido>>(
            stream: _db.watchProductosMasVendidos(desde: _desde),
            builder: (context, snapTop) {
              return StreamBuilder<List<Gasto>>(
                stream: _db.watchGastos(desde: _desde),
                builder: (context, snapGastos) {
                  return StreamBuilder<List<PedidoDetallado>>(
                    stream: _db.watchEncargosEntregados(desde: _desde),
                    builder: (context, snapEncargos) {
                      if (!snapResumen.hasData ||
                          !snapTop.hasData ||
                          !snapGastos.hasData ||
                          !snapEncargos.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.amarillo),
                        );
                      }

                      final resumen = snapResumen.data!;
                      final top = snapTop.data!;
                      final gastos = snapGastos.data!;
                      final encargos = snapEncargos.data!;
                      final margen = resumen.ingresos == 0
                          ? 0.0
                          : (resumen.utilidad / resumen.ingresos) * 100;
                      final totalEncargos = encargos.fold<double>(
                          0, (s, e) => s + e.total);

                      return ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _selectorPeriodo(),
                          const SizedBox(height: 16),
                          _tarjetaResumen(resumen, margen),
                          const SizedBox(height: 16),
                          _graficaIngresosGastos(resumen),
                          const SizedBox(height: 16),
                          _seccionTopProductos(top),
                          const SizedBox(height: 24),
                          _seccionEncargosEntregados(encargos, totalEncargos),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => _exportarPDF(
                                resumen, margen, top, gastos, encargos),
                            icon: const Icon(Icons.download),
                            label: const Text('Exportar informe en PDF'),
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _selectorPeriodo() {
    return Row(
      children: PeriodoReporte.values.map((p) {
        final activo = p == _periodo;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _periodo = p),
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
                  color: activo
                      ? const Color(0xFF6AA8FF)
                      : AppColors.textoGris,
                  fontWeight:
                      activo ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _tarjetaResumen(ResumenFinanciero r, double margen) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 2.2,
      children: [
        _metrica('Ingresos', '\$${r.ingresos.toStringAsFixed(2)}',
            AppColors.amarillo),
        _metrica(
            'Gastos', '\$${r.gastos.toStringAsFixed(2)}', Colors.white),
        _metrica('Utilidad', '\$${r.utilidad.toStringAsFixed(2)}',
            AppColors.verde),
        _metrica('Margen', '${margen.toStringAsFixed(1)}%', Colors.white),
      ],
    );
  }

  Widget _metrica(String label, String valor, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: AppColors.tarjeta,
          borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.textoGris, fontSize: 11)),
          Text(valor,
              style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _graficaIngresosGastos(ResumenFinanciero r) {
    final maxValor =
        (r.ingresos > r.gastos ? r.ingresos : r.gastos) * 1.2;
    return Container(
      height: 180,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: AppColors.tarjeta,
          borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ingresos vs Gastos',
              style:
                  TextStyle(color: AppColors.textoGris, fontSize: 11)),
          const SizedBox(height: 8),
          Expanded(
            child: BarChart(
              BarChartData(
                maxY: maxValor == 0 ? 100 : maxValor,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) => Text(
                        value == 0 ? 'Ingresos' : 'Gastos',
                        style: const TextStyle(
                            color: AppColors.textoGris, fontSize: 10),
                      ),
                    ),
                  ),
                ),
                barGroups: [
                  BarChartGroupData(x: 0, barRods: [
                    BarChartRodData(
                        toY: r.ingresos,
                        color: AppColors.amarillo,
                        width: 40,
                        borderRadius: BorderRadius.circular(4)),
                  ]),
                  BarChartGroupData(x: 1, barRods: [
                    BarChartRodData(
                        toY: r.gastos,
                        color: AppColors.azulMedio,
                        width: 40,
                        borderRadius: BorderRadius.circular(4)),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _seccionTopProductos(List<ProductoMasVendido> top) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Productos más vendidos',
            style: TextStyle(
                color: AppColors.textoGris,
                fontSize: 11,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (top.isEmpty)
          const Text('Sin ventas en este período',
              style:
                  TextStyle(color: AppColors.textoGris, fontSize: 12))
        else
          ...top.map((p) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: AppColors.tarjeta,
                    borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.nombre,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 13)),
                          Text(p.codigo,
                              style: const TextStyle(
                                  color: AppColors.textoGris,
                                  fontSize: 11)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${p.cantidadVendida} uds',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12)),
                        Text(
                            '\$${p.totalVendido.toStringAsFixed(2)}',
                            style: const TextStyle(
                                color: AppColors.amarillo,
                                fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              )),
      ],
    );
  }

  Widget _seccionEncargosEntregados(
      List<PedidoDetallado> encargos, double totalEncargos) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Encargos entregados',
                style: TextStyle(
                    color: AppColors.textoGris,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
            if (encargos.isNotEmpty)
              Text('\$${totalEncargos.toStringAsFixed(2)}',
                  style: const TextStyle(
                      color: AppColors.amarillo,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        if (encargos.isEmpty)
          const Text('Sin encargos entregados en este período',
              style:
                  TextStyle(color: AppColors.textoGris, fontSize: 12))
        else
          ...encargos.map((e) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: AppColors.tarjeta,
                    borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.descripcion,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          Row(
                            children: [
                              Flexible(
                                child: Text(e.clienteNombre,
                                    style: const TextStyle(
                                        color: AppColors.textoGris,
                                        fontSize: 11),
                                    overflow: TextOverflow.ellipsis),
                              ),
                              if (e.archivado) ...[
                                const SizedBox(width: 6),
                                const Icon(Icons.archive_outlined,
                                    size: 11, color: AppColors.textoGris),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                            '\$${e.total.toStringAsFixed(2)}',
                            style: const TextStyle(
                                color: AppColors.amarillo,
                                fontSize: 13,
                                fontWeight: FontWeight.bold)),
                        Text(
                          _fmtFecha(e.fechaEntrega ?? e.fechaSolicitud),
                          style: const TextStyle(
                              color: AppColors.textoGris, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              )),
      ],
    );
  }

  String _fmtFecha(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _exportarPDF(
    ResumenFinanciero resumen,
    double margen,
    List<ProductoMasVendido> top,
    List<Gasto> gastos,
    List<PedidoDetallado> encargos,
  ) async {
    final pdf = pw.Document();
    final ahora = DateTime.now();

    pdf.addPage(pw.MultiPage(
      build: (context) => [
        pw.Header(
          level: 0,
          child: pw.Text('Informe Financiero - TOVIR\'S GARAGE',
              style: pw.TextStyle(
                  fontSize: 20, fontWeight: pw.FontWeight.bold)),
        ),
        pw.Text('Período: ${_periodo.label}'),
        pw.Text(
            'Generado el: ${ahora.day}/${ahora.month}/${ahora.year}'),
        pw.SizedBox(height: 16),
        pw.Text('Resumen',
            style: pw.TextStyle(
                fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.Table(
          border: pw.TableBorder.all(width: 0.5),
          children: [
            _fila('Ingresos',
                '\$${resumen.ingresos.toStringAsFixed(2)}'),
            _fila('Gastos', '\$${resumen.gastos.toStringAsFixed(2)}'),
            _fila('Utilidad',
                '\$${resumen.utilidad.toStringAsFixed(2)}'),
            _fila('Margen', '${margen.toStringAsFixed(1)}%'),
          ],
        ),
        pw.SizedBox(height: 16),
        pw.Text('Productos más vendidos',
            style: pw.TextStyle(
                fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.Table(
          border: pw.TableBorder.all(width: 0.5),
          children: [
            pw.TableRow(children: [
              _celda('Código', bold: true),
              _celda('Producto', bold: true),
              _celda('Cantidad', bold: true),
              _celda('Total', bold: true),
            ]),
            ...top.map((p) => pw.TableRow(children: [
                  _celda(p.codigo),
                  _celda(p.nombre),
                  _celda('${p.cantidadVendida}'),
                  _celda('\$${p.totalVendido.toStringAsFixed(2)}'),
                ])),
          ],
        ),
        pw.SizedBox(height: 16),
        pw.Text('Encargos entregados',
            style: pw.TextStyle(
                fontSize: 14, fontWeight: pw.FontWeight.bold)),
        if (encargos.isEmpty)
          pw.Text('Sin encargos entregados en este período')
        else
          pw.Table(
            border: pw.TableBorder.all(width: 0.5),
            children: [
              pw.TableRow(children: [
                _celda('Cliente', bold: true),
                _celda('Descripción', bold: true),
                _celda('Fecha entrega', bold: true),
                _celda('Total', bold: true),
              ]),
              ...encargos.map((e) => pw.TableRow(children: [
                    _celda(e.clienteNombre),
                    _celda(e.descripcion),
                    _celda(_fmtFecha(e.fechaEntrega ?? e.fechaSolicitud)),
                    _celda('\$${e.total.toStringAsFixed(2)}'),
                  ])),
            ],
          ),
        pw.SizedBox(height: 16),
        pw.Text('Gastos del período',
            style: pw.TextStyle(
                fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.Table(
          border: pw.TableBorder.all(width: 0.5),
          children: [
            pw.TableRow(children: [
              _celda('Fecha', bold: true),
              _celda('Categoría', bold: true),
              _celda('Descripción', bold: true),
              _celda('Monto', bold: true),
            ]),
            ...gastos.map((g) => pw.TableRow(children: [
                  _celda(
                      '${g.fecha.day}/${g.fecha.month}/${g.fecha.year}'),
                  _celda(g.categoria),
                  _celda(g.descripcion),
                  _celda('\$${g.monto.toStringAsFixed(2)}'),
                ])),
          ],
        ),
      ],
    ));

    // Usamos `printing` en vez de escribir a disco directamente:
    // funciona igual en Windows (abre diálogo de impresión/guardar),
    // en el navegador/PWA (descarga el archivo) y en celular (comparte).
    try {
      final bytes = await pdf.save();
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'informe_tovirsgarage_${ahora.millisecondsSinceEpoch}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo exportar el PDF: $e')),
        );
      }
    }
  }

  pw.TableRow _fila(String label, String valor) =>
      pw.TableRow(children: [
        _celda(label, bold: true),
        _celda(valor),
      ]);

  pw.Widget _celda(String texto, {bool bold = false}) => pw.Padding(
        padding: const pw.EdgeInsets.all(4),
        child: pw.Text(texto,
            style: pw.TextStyle(
                fontWeight:
                    bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
      );
}