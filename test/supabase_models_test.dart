import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taller_app/db/app_models.dart';

void main() {
  test('ProductosCompanion serializa campos a formato Supabase', () {
    final companion = ProductosCompanion.insert(
      codigo: 'P-001',
      nombre: 'Pastillas',
      descripcion: const Value('Pastillas de freno'),
      precioCompra: 10.0,
      precioVenta: 15.0,
      stockActual: const Value(4),
      stockMinimo: const Value(2),
      categoriaId: 1,
    );

    final data = companion.toSupabaseMap();

    expect(data['codigo'], 'P-001');
    expect(data['nombre'], 'Pastillas');
    expect(data['descripcion'], 'Pastillas de freno');
    expect(data['stock_actual'], 4);
    expect(data['categoria_id'], 1);
  });
}
