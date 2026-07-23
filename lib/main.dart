import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'db/app_database.dart';
import 'theme.dart';
import 'screens/main_shell.dart';
import 'screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  String? errorInicializacion;

  if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
    try {
      await AppDatabase.instance.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
    } catch (e, stack) {
      errorInicializacion = e.toString();
      // ignore: avoid_print
      print('Error inicializando Supabase: $e\n$stack');
    }
  } else {
    errorInicializacion = 'Faltan SUPABASE_URL o SUPABASE_ANON_KEY (--dart-define).';
  }

  runApp(TallerApp(errorInicializacion: errorInicializacion));
}

class TallerApp extends StatelessWidget {
  final String? errorInicializacion;
  const TallerApp({super.key, this.errorInicializacion});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "TOVIR'S GARAGE",
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: errorInicializacion != null
          ? _ErrorScreen(mensaje: errorInicializacion!)
          : const _AuthGate(),
    );
  }
}

/// Escucha el estado de autenticación de Supabase y muestra
/// LoginScreen o MainShell según si hay una sesión activa.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = snapshot.data?.session ?? Supabase.instance.client.auth.currentSession;
        if (session != null) {
          return const MainShell();
        }
        return const LoginScreen();
      },
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  final String mensaje;
  const _ErrorScreen({required this.mensaje});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondo,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.rojo, size: 48),
              const SizedBox(height: 16),
              const Text(
                'No se pudo inicializar la app',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                mensaje,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textoGris, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}