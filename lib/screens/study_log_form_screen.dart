import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Necesario para formatear la fecha

import '../models/study_log_model.dart';
import '../services/study_log_service.dart';
import '../services/auth_service.dart';

class StudyLogFormScreen extends StatefulWidget {
  // El logToEdit es opcional. Si es null -> CREAR. Si tiene valor -> EDITAR.
  final StudyLogModel? logToEdit; 

  const StudyLogFormScreen({super.key, this.logToEdit});

  @override
  State<StudyLogFormScreen> createState() => _StudyLogFormScreenState();
}

class _StudyLogFormScreenState extends State<StudyLogFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _durationController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 1. Inicializar el formulario si estamos en modo edición
    if (widget.logToEdit != null) {
      final log = widget.logToEdit!;
      _subjectController.text = log.subject;
      _durationController.text = log.durationMinutes.toString();
      _notesController.text = log.notes ?? '';
      _selectedDate = log.date;
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _durationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Abre el selector de fecha de Flutter
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'ES'), // Forzamos el idioma al español
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // 2. Lógica de Envío del Formulario (Crear o Actualizar)
  void _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return; // Detenemos si la validación falla
    }
    
    final authService = Provider.of<AuthService>(context, listen: false);
    final logService = Provider.of<StudyLogService>(context, listen: false);
    final userId = authService.currentUserModel?.uid;
    
    if (userId == null) {
      _showSnackbar('Error: Usuario no autenticado.', Colors.red);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final logData = StudyLogModel(
        id: widget.logToEdit?.id ?? '', // ID vacío si es nuevo, ID existente si es edición
        userId: userId,
        subject: _subjectController.text.trim(),
        durationMinutes: int.parse(_durationController.text.trim()),
        date: _selectedDate,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      if (widget.logToEdit == null) {
        // CREAR (C)
        await logService.addLog(logData);
        _showSnackbar('Registro de estudio creado con éxito.', Colors.green);
      } else {
        // ACTUALIZAR (U)
        await logService.updateLog(logData);
        _showSnackbar('Registro de estudio actualizado con éxito.', Colors.green);
      }

      // Volver a la pantalla anterior (HistoryScreen)
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('Error al guardar/actualizar: $e');
      _showSnackbar('Ocurrió un error al guardar los datos.', Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Utilidad para mostrar mensajes
  void _showSnackbar(String message, Color color) {
     if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: color,
          ),
        );
      }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.logToEdit != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Registro' : 'Nuevo Registro'),
        backgroundColor: Colors.indigo,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Campo 1: Materia/Tema
              TextFormField(
                controller: _subjectController,
                decoration: const InputDecoration(
                  labelText: 'Materia o Tema',
                  hintText: 'Ej: Cálculo Avanzado, Flutter BLoC',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.menu_book),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El tema de estudio es obligatorio.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              // Campo 2: Duración en minutos (Validación para números > 0)
              TextFormField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Duración (Minutos)',
                  hintText: 'Ej: 120',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.timer),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La duración es obligatoria.';
                  }
                  final duration = int.tryParse(value);
                  if (duration == null || duration <= 0) {
                    return 'Ingresa una duración válida (mayor a 0).';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              // Campo 3: Selector de Fecha
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Fecha de la Sesión'),
                subtitle: Text(
                  // Usamos 'es_ES' para el formato en español
                  DateFormat('EEEE, d MMM yyyy', 'es_ES').format(_selectedDate),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                trailing: const Icon(Icons.calendar_today, color: Colors.indigo),
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 15),
              
              // Campo 4: Notas Opcionales
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notas (Opcional)',
                  hintText: 'Ej: Revisé el capítulo 5 y practiqué ejercicios.',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.notes),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 30),

              // Botón de Guardar/Actualizar
              _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.indigo))
                  : ElevatedButton.icon(
                      onPressed: _submitForm,
                      icon: Icon(isEditing ? Icons.save : Icons.add),
                      label: Text(isEditing ? 'GUARDAR CAMBIOS' : 'REGISTRAR SESIÓN'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}