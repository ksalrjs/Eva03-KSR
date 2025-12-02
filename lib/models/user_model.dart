// Este modelo representa la información del usuario en nuestra aplicación,
// desacoplada del objeto 'User' nativo de Firebase.
class UserModel {
  // Identificador único del usuario, el mismo que el UID de Firebase Auth.
  final String uid; 
  
  // Información básica del perfil.
  final String email;
  final String? displayName;
  
  // Campo que podemos usar para personalizar la experiencia.
  final DateTime? memberSince; 

  // Constructor constante
  const UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.memberSince,
  });

  // ==========================================================
  //                MÉTODOS DE MANEJO DE DATOS
  // ==========================================================

  /// Crea una instancia de UserModel a partir de un mapa de datos (usado para Firestore).
  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'] as String,
      email: data['email'] as String,
      displayName: data['displayName'] as String?,
      // Los Timestamps de Firestore se deben convertir a DateTime en Dart
      memberSince: data['memberSince'] != null 
          ? DateTime.parse(data['memberSince'] as String) 
          : null,
    );
  }

  /// Convierte la instancia de UserModel a un mapa (usado para subir a Firestore).
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'memberSince': memberSince?.toIso8601String(), // Guardamos como String ISO
    };
  }

  /// Método para copiar el objeto con posibles cambios, manteniendo la inmutabilidad.
  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    DateTime? memberSince,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      memberSince: memberSince ?? this.memberSince,
    );
  }
}