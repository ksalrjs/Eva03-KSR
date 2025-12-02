import 'package:cloud_firestore/cloud_firestore.dart';

/// Define los roles de usuario permitidos en la aplicación.
/// Corresponde al requerimiento E1.
enum UserRole {
  admin, // 'Socias' con acceso total
  collaborator, // 'Otros Colaboradores' con acceso limitado
  unknown, // Rol por defecto o en caso de error
}

/// Representa a un usuario de la aplicación en la base de datos de Firestore.
/// Almacena información adicional a la de Firebase Auth, como el rol.
class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final UserRole role;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
  });

  /// Convierte la instancia de [UserModel] a un mapa para Firestore.
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      // Guardamos el rol como un string (ej: 'admin') para que sea legible en Firestore.
      'role': role.name,
    };
  }

  /// Crea una instancia de [UserModel] desde un [DocumentSnapshot] de Firestore.
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Convierte el string del rol desde Firestore a nuestro enum UserRole.
    UserRole role;
    switch (data['role']) {
      case 'admin':
        role = UserRole.admin;
        break;
      case 'collaborator':
        role = UserRole.collaborator;
        break;
      default:
        role = UserRole.unknown;
    }

    return UserModel(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      role: role,
    );
  }
}