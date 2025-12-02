// Este modelo representa un registro individual de estudio.
class StudyLogModel {
  // ID único del documento en Firestore (generado por Firestore).
  final String id; 
  
  // ID del usuario al que pertenece este registro (para consultas de seguridad).
  final String userId; 
  
  // Tema o materia estudiada (ej. "Matemáticas", "Flutter", "Historia").
  final String subject;
  
  // Duración de la sesión en minutos.
  final int durationMinutes; 
  
  // Fecha y hora exacta de cuándo se registró la sesión.
  final DateTime date; 
  
  // Campo opcional para notas o descripción.
  final String? notes; 

  // Constructor constante
  const StudyLogModel({
    required this.id,
    required this.userId,
    required this.subject,
    required this.durationMinutes,
    required this.date,
    this.notes,
  });

  // ==========================================================
  //                MÉTODOS DE MANEJO DE DATOS
  // ==========================================================

  /// Crea una instancia de StudyLogModel a partir de un mapa de datos (usado para Firestore).
  factory StudyLogModel.fromMap(Map<String, dynamic> data) {
    // Aseguramos que la fecha se convierta correctamente de Timestamp o de String
    DateTime parsedDate;
    if (data['date'] is String) {
      parsedDate = DateTime.parse(data['date'] as String);
    } else {
      // Asume que es un Timestamp de Firestore
      final timestamp = data['date'] as dynamic;
      parsedDate = timestamp.toDate();
    }
    
    return StudyLogModel(
      id: data['id'] as String,
      userId: data['userId'] as String,
      subject: data['subject'] as String,
      durationMinutes: data['durationMinutes'] as int,
      date: parsedDate,
      notes: data['notes'] as String?,
    );
  }

  /// Convierte la instancia de StudyLogModel a un mapa (usado para subir a Firestore).
  /// Nota: NO incluimos el 'id' aquí ya que será el ID del documento en Firestore,
  /// pero lo necesitamos en el modelo de Dart.
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'subject': subject,
      'durationMinutes': durationMinutes,
      'date': date, // Firestore manejará automáticamente este DateTime como Timestamp
      'notes': notes,
    };
  }

  /// Método para copiar el objeto con posibles cambios, manteniendo la inmutabilidad.
  StudyLogModel copyWith({
    String? id,
    String? userId,
    String? subject,
    int? durationMinutes,
    DateTime? date,
    String? notes,
  }) {
    return StudyLogModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      subject: subject ?? this.subject,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      date: date ?? this.date,
      notes: notes ?? this.notes,
    );
  }
}