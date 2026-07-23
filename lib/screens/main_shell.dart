import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme.dart';
import 'dashboard_screen.dart';
import 'inventario_screen.dart';
import 'reportes_screen.dart';
import 'encargos_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _tabActual = 0;

  final List<Widget> _pantallas = const [
    DashboardScreen(),
    InventarioScreen(),
    ReportesScreen(),
    EncargosScreen(),
  ];

  Future<void> _cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.tarjeta,
        title: const Text('Cerrar sesión', style: TextStyle(color: Colors.white)),
        content: const Text(
          '¿Seguro que deseas cerrar sesión?',
          style: TextStyle(color: AppColors.textoGris),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Cerrar sesión',
                  style: TextStyle(color: AppColors.rojo))),
        ],
      ),
    );
    if (confirmar == true) {
      await Supabase.instance.client.auth.signOut();
      // El _AuthGate en main.dart detecta el cambio de sesión
      // y vuelve a mostrar LoginScreen automáticamente.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondo,
      appBar: AppBar(
        backgroundColor: AppColors.azulOscuro,
        title: const Text(
          "TOVIR'S GARAGE",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _cerrarSesion,
          ),
        ],
      ),
      body: IndexedStack(index: _tabActual, children: _pantallas),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppColors.fondoNav,
        selectedItemColor: AppColors.amarillo,
        unselectedItemColor: AppColors.textoGris,
        currentIndex: _tabActual,
        type: BottomNavigationBarType.fixed,
        onTap: (i) => setState(() => _tabActual = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2),
            label: 'Inventario',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Reportes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_shipping_outlined),
            activeIcon: Icon(Icons.local_shipping),
            label: 'Encargos',
          ),
        ],
      ),
    );
  }
}