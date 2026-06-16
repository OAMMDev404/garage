import 'package:flutter/material.dart';

/// Paleta de la empresa: amarillo, azul y negro.
class AppColors {
  static const amarillo = Color(0xFFF5C400);
  static const azulOscuro = Color(0xFF1A2C4E);
  static const azulMedio = Color(0xFF1A3870);
  static const negro = Color(0xFF0A0A0A);
  static const fondo = Color(0xFF0D1B2E);
  static const fondoNav = Color(0xFF0D1420);
  static const tarjeta = Color(0xFF162235);
  static const textoGris = Color(0xFF5A7A9A);
  static const verde = Color(0xFF4DD68C);
  static const rojo = Color(0xFFFF6B6B);
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.fondo,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.azulMedio,
      brightness: Brightness.dark,
      primary: AppColors.amarillo,
      secondary: AppColors.azulMedio,
      surface: AppColors.tarjeta,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.azulOscuro,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.tarjeta,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      labelStyle: const TextStyle(color: AppColors.textoGris),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.amarillo,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.tarjeta,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}
