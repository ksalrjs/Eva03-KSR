import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/study_log_model.dart';

// El servicio maneja todas las operaciones CRUD para los registros de estudio.
class StudyLogService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Referencia a la colección principal de registros
  final String _collectionName = 'study_logs';

  // ==========================================================
  //                OPERACIONES DE LECTURA (R - Read)
  // ==========================================================

  /// Obtiene un Stream de todos los registros de estudio para un usuario específico.
  /// Esto permite actualizar la UI en tiempo real.
  Stream<List<StudyLogModel>> getLogsStream(String userId) {
    // Consulta: Solo documentos donde 'userId' coincida, ordenados por fecha descendente.
    return _firestore
        .collection(_collectionName)
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots() // Obtiene el Stream de cambios
        .map((snapshot) {
      // Mapea la lista de DocumentSnapshots a una lista de StudyLogModel
      return snapshot.docs.map((doc) {
        final data = doc.data();
        // El ID del documento de Firestore se asigna al campo 'id' del modelo
        return StudyLogModel.fromMap({...data, 'id': doc.id});
      }).toList();
    });
  }

  // ==========================================================
  //                OPERACIÓN DE CREACIÓN (C - Create)
  // ==========================================================

  /// Agrega un nuevo registro de estudio a Firestore.
  Future<void> addLog(StudyLogModel log) async {
    try {
      // Usamos el toMap del modelo, que no incluye el ID, ya que Firestore lo generará.
      await _firestore.collection(_collectionName).add(log.toMap());
    } catch (e) {
      debugPrint('Error al agregar el registro: $e');
      rethrow; // Relanza la excepción para que la UI pueda manejar el error
    }
  }

  // ==========================================================
  //                OPERACIÓN DE ACTUALIZACIÓN (U - Update)
  // ==========================================================

  /// Actualiza un registro de estudio existente en Firestore.
  Future<void> updateLog(StudyLogModel log) async {
    if (log.id.isEmpty) {
      throw Exception('El ID del registro no puede estar vacío para actualizar.');
    }
    try {
      // Accedemos al documento por su ID y usamos el método set/update
      await _firestore.collection(_collectionName).doc(log.id).update(log.toMap());
    } catch (e) {
      debugPrint('Error al actualizar el registro con ID ${log.id}: $e');
      rethrow;
    }
  }

  // ==========================================================
  //                OPERACIÓN DE ELIMINACIÓN (D - Delete)
  // ==========================================================

  /// Elimina un registro de estudio de Firestore.
  Future<void> deleteLog(String logId) async {
    try {
      await _firestore.collection(_collectionName).doc(logId).delete();
    } catch (e) {
      debugPrint('Error al eliminar el registro con ID $logId: $e');
      rethrow;
    }
  }
}