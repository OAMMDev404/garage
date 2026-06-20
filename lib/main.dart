import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'theme.dart';
import 'screens/main_shell.dart';

void main() {
  // sqflite (el paquete original) solo tiene implementación nativa para
  // Android e iOS. En escritorio (Windows/macOS/Linux) no existe ese canal
  // nativo, así que hay que registrar manualmente la fábrica de base de
  // datos basada en FFI (sqflite_common_ffi) ANTES de llamar a runApp().
  //
  // Sin esto, cualquier llamada a openDatabase() falla con:
  // "Bad state: databaseFactory not initialized..."
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const TallerApp());
}

class TallerApp extends StatelessWidget {
  const TallerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Taller Mecánico',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const MainShell(),
    );
  }
}
