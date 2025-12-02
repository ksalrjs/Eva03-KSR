import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/study_log_model.dart';
import '../services/study_log_service.dart';
import '../services/auth_service.dart';
import 'study_log_form_screen.dart'; // Para la edición (Update)

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  // Muestra un diálogo de confirmación para la eliminación
  Future<bool> _confirmDismiss(BuildContext context, String logId) async {
    return await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Confirmar Eliminación"),
          content: const Text("¿Estás seguro de que deseas eliminar este registro de estudio?"),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false), // No eliminar
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () {
                // Sí, eliminar
                Provider.of<StudyLogService>(context, listen: false).deleteLog(logId);
                Navigator.of(dialogContext).pop(true); // Eliminar
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text("Eliminar"),
            ),
          ],
        );
      },
    ) ?? false; // Retorna false si el diálogo se cierra sin seleccionar nada
  }

  // Crea la tarjeta individual para el registro
  Widget _buildLogItem(BuildContext context, StudyLogModel log) {
    // Usamos Dismissible para permitir deslizar y eliminar (D - Delete)
    return Dismissible(
      key: ValueKey(log.id), // Clave única para el Dismissible
      direction: DismissDirection.endToStart, // Solo deslizar de derecha a izquierda
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) => _confirmDismiss(context, log.id),
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
        child: ListTile(
          // Icono y duración
          leading: CircleAvatar(
            backgroundColor: Colors.indigo,
            child: Text(
              '${log.durationMinutes}m',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          // Tema y fecha
          title: Text(
            log.subject,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            DateFormat('EEEE, d MMM yyyy - h:mm a', 'es_ES').format(log.date),
          ),
          // Botón para ir a la edición (U - Update)
          trailing: IconButton(
            icon: const Icon(Icons.edit, color: Colors.teal),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => StudyLogFormScreen(logToEdit: log),
                ),
              );
            },
          ),
          onTap: () {
            // Podríamos implementar una vista de detalle más adelante
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Obtenemos el ID del usuario actual para filtrar los logs
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUserModel?.uid;

    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text("Error: ID de usuario no disponible.")),
      );
    }

    final logService = Provider.of<StudyLogService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Sesiones'),
        backgroundColor: Colors.indigo,
        actions: [
           IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Nuevo Registro',
            onPressed: () {
               Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const StudyLogFormScreen(), // Nuevo registro
                ),
              );
            },
          ),
        ],
      ),
      // El StreamBuilder es esencial para manejar los datos en tiempo real de Firestore
      body: StreamBuilder<List<StudyLogModel>>(
        stream: logService.getLogsStream(userId),
        builder: (context, snapshot) {
          // 1. Manejo del estado de error
          if (snapshot.hasError) {
            return Center(child: Text('Error al cargar los datos: ${snapshot.error}'));
          }

          // 2. Manejo del estado de carga
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.indigo));
          }

          // 3. Manejo de datos nulos o vacíos
          final logs = snapshot.data ?? [];
          if (logs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.inbox, size: 60, color: Colors.grey),
                    const SizedBox(height: 10),
                    const Text(
                      'Aún no tienes registros de estudio.',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    // Botón para crear el primer registro
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const StudyLogFormScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Comenzar a Registrar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // 4. Mostrar los datos
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              return _buildLogItem(context, logs[index]);
            },
          );
        },
      ),
    );
  }
}