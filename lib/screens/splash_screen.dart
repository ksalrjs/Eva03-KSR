import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Importaciones temporales para el flujo de navegación
import '../services/auth_service.dart'; // Necesitamos acceder al estado de autenticación
import 'home_screen.dart'; // Pantalla a la que irá si está autenticado
import 'auth_screen.dart'; // Pantalla a la que irá si NO está autenticado

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  
  @override
  void initState() {
    super.initState();
    // Llamamos a la lógica de navegación después de que el widget se haya construido
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthenticationStatus(context);
    });
  }

  // Método clave para decidir a dónde enrutar al usuario
  void _checkAuthenticationStatus(BuildContext context) async {
    // Usamos el 'listen: false' porque solo queremos llamar a un método del servicio
    final authService = Provider.of<AuthService>(context, listen: false);

    // 1. Esperamos a que el Stream de Firebase Auth emita el estado actual.
    // Esto es crucial para saber si hay un usuario logueado.
    final user = await authService.initialAuthCheck;

    // 2. Navegación basada en el estado:
    // Utilizamos un reemplazo (pushReplacement) para que el usuario no pueda volver
    // a esta pantalla de splash con el botón de atrás.
    if (user != null) {
      // Usuario autenticado, navegar a la pantalla principal
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      // Usuario NO autenticado, navegar a la pantalla de Login/Registro
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // UI simple que se muestra mientras se verifica el estado de autenticación
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Podemos poner aquí el logo de la aplicación
            Text(
              'Eva03',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 30),
            CircularProgressIndicator(
              color: Colors.indigo,
            ),
            SizedBox(height: 10),
            Text('Verificando sesión...'),
          ],
        ),
      ),
    );
  }
}