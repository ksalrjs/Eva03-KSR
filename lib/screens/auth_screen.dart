import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLoading = false;

  void _signIn() async {
    setState(() {
      _isLoading = true;
    });

    final authService = Provider.of<AuthService>(context, listen: false);

    try {
      // Llamamos al método actualizado de Google Sign-In
      await authService.signInWithGoogle();
      
      // Nota: Si el inicio de sesión es exitoso, el usuario será redirigido
      // automáticamente por el flujo de navegación de nuestro SplashScreen.

    } catch (e) {
      // Manejo de errores
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al iniciar sesión con Google: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // Logo/Icono de la Aplicación
              const Icon(
                Icons.schedule, 
                size: 100,
                color: Colors.indigo,
              ),
              const SizedBox(height: 10),
              
              const Text(
                'Eva03',
                style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
              ),
              const Text(
                'Registro de Hábito de Estudio',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 50),

              // Botón de Google Sign-In
              if (_isLoading)
                const CircularProgressIndicator(color: Colors.indigo)
              else
                // Usamos un botón con el color de Google para mayor claridad
                ElevatedButton.icon(
                  onPressed: _signIn,
                  icon: const Icon(Icons.g_mobiledata, size: 28),
                  label: const Text(
                    'Iniciar Sesión con Google',
                    style: TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
              const SizedBox(height: 30),
              
              // Pequeña nota informativa
              const Text(
                'Utiliza tu cuenta de Google para comenzar a registrar tu progreso de estudio.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}