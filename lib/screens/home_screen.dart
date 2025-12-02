import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'study_log_form_screen.dart'; // Crearemos esta pantalla para el CRUD
import 'history_screen.dart';        // Crearemos esta pantalla para el detalle/historial

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Escuchamos el modelo de usuario para mostrar su nombre
    final user = Provider.of<AuthService>(context).currentUserModel;
    
    // Lista de acciones principales para el Dashboard (usando el patrón CARDS)
    final List<Map<String, dynamic>> actions = [
      {
        'title': 'Registrar Sesión',
        'subtitle': 'Añade un nuevo registro de estudio (CRUD).',
        'icon': Icons.edit_calendar,
        'color': Colors.indigo,
        'destination': const StudyLogFormScreen(),
      },
      {
        'title': 'Ver Historial',
        'subtitle': 'Revisa el detalle de todas tus sesiones.',
        'icon': Icons.bar_chart,
        'color': Colors.teal,
        'destination': const HistoryScreen(),
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard de Estudio'),
        backgroundColor: Colors.indigo,
        actions: [
          // Botón de Cerrar Sesión
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            tooltip: 'Cerrar Sesión',
            onPressed: () async {
              // Llamada al método de cierre de sesión del servicio
              await Provider.of<AuthService>(context, listen: false).signOut();
              // La navegación se manejará volviendo al SplashScreen/AuthScreen
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // CARD de Bienvenida y Resumen del Usuario
            _buildWelcomeCard(user?.displayName ?? user?.email ?? 'Usuario', context),
            const SizedBox(height: 25),

            const Text(
              'Acciones Principales',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),

            // Grilla de Tarjetas de Funcionalidad
            GridView.builder(
              shrinkWrap: true, // Importante para usarlo dentro de SingleChildScrollView
              physics: const NeverScrollableScrollPhysics(), // Deshabilita el scroll interno
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // 2 tarjetas por fila
                crossAxisSpacing: 15.0,
                mainAxisSpacing: 15.0,
                childAspectRatio: 0.9, // Ajuste para que las tarjetas no sean demasiado anchas
              ),
              itemCount: actions.length,
              itemBuilder: (context, index) {
                final action = actions[index];
                return _buildActionCard(
                  title: action['title'],
                  subtitle: action['subtitle'],
                  icon: action['icon'],
                  color: action['color'],
                  onTap: () {
                    // Navegamos a la pantalla de destino
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (ctx) => action['destination']),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Widget para la tarjeta de bienvenida
  Widget _buildWelcomeCard(String userName, BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: Colors.indigo.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hola, ${userName.split(' ').first}!',
              style: TextStyle(
                fontSize: 26, 
                fontWeight: FontWeight.bold,
                color: Colors.indigo.shade800
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '¡Es hora de registrar tu progreso y analizar tus hábitos de estudio!',
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 15),
            // Aquí podríamos agregar una métrica rápida (Ej: "Total de horas este mes: 0h")
          ],
        ),
      ),
    );
  }

  // Widget genérico para las tarjetas de acción
  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 15),
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}