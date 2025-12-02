import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

/// Servicio para gestionar la autenticación de usuarios con Firebase.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Un stream que emite el [UserModel] actual cuando el estado de autenticación cambia.
  ///
  /// Emite el objeto [UserModel] si el usuario está logueado, o `null` si no lo está.
  /// Esto es fundamental para que la UI reaccione a los inicios y cierres de sesión.
  Stream<UserModel?> get userStream {
    return _auth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) {
        return null;
      }
      // Si hay un usuario en Firebase Auth, buscamos su documento en Firestore.
      final userDoc =
          await _firestore.collection('users').doc(firebaseUser.uid).get();

      if (userDoc.exists) {
        // Si encontramos el documento, lo convertimos a nuestro UserModel.
        return UserModel.fromFirestore(userDoc);
      }
      return null;
    });
  }

  /// Inicia el flujo de inicio de sesión con Google.
  ///
  /// Si el usuario es nuevo, crea un registro para él en la colección 'users'
  /// de Firestore con el rol por defecto de 'collaborator'.
  /// Devuelve el [UserModel] si el inicio de sesión es exitoso, de lo contrario `null`.
  Future<UserModel?> signInWithGoogle() async {
    try {
      // 1. Iniciar el flujo de Google Sign In.
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // El usuario canceló el proceso.
        return null;
      }

      // 2. Obtener las credenciales de autenticación de la cuenta de Google.
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 3. Usar las credenciales para iniciar sesión en Firebase Auth.
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      final User? firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        // 4. Verificar si es un usuario nuevo o existente en nuestra DB de Firestore.
        final userDoc =
            await _firestore.collection('users').doc(firebaseUser.uid).get();

        if (!userDoc.exists) {
          // Es un usuario nuevo: lo creamos en Firestore.
          final newUser = UserModel(
            uid: firebaseUser.uid,
            email: firebaseUser.email ?? '',
            displayName: firebaseUser.displayName ?? 'Sin Nombre',
            role: UserRole.collaborator, // Rol por defecto para nuevos usuarios.
          );
          await _firestore
              .collection('users')
              .doc(firebaseUser.uid)
              .set(newUser.toJson());
          return newUser;
        } else {
          // Es un usuario existente: devolvemos su información desde Firestore.
          return UserModel.fromFirestore(userDoc);
        }
      }
    } catch (e) {
      // Manejo de errores (en un proyecto real, usarías un logger).
      print('Error en signInWithGoogle: $e');
      return null;
    }
    return null;
  }

  /// Cierra la sesión del usuario actual tanto en Firebase como en Google.
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}