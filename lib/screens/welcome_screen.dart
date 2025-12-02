import 'package:flutter/material.dart';

// Importación temporal para la navegación
import 'home_screen.dart'; 

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  // Método de navegación simple para ir al Home/Dashboard
  void _navigateToHome(BuildContext context) {
    // Usamos pushReplacement para que, una vez que el usuario inicia, no pueda
    // volver a la pantalla de bienvenida con el botón de atrás.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            // 1. Icono y Nombre
            const Icon(
              Icons.timer_sharp, 
              size: 120,
              color: Colors.indigo,
            ),
            const SizedBox(height: 20),
            Text(
              'Bienvenido a Eva03',
              style: TextStyle(
                fontSize: 32, 
                fontWeight: FontWeight.bold,
                color: Colors.indigo.shade800,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Tu compañero para registrar y analizar tus horas de estudio diarias.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.black54),
            ),
            const SizedBox(height: 80),
            
            // 2. Botón de Inicio
            ElevatedButton(
              onPressed: () => _navigateToHome(context),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 55),
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              child: const Text(
                'EMPEZAR A ESTUDIAR',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}