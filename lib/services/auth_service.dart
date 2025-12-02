import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart'; // ¡Nueva Importación!

import '../models/user_model.dart';

// Este servicio centraliza toda la interacción con Firebase Auth y maneja el perfil en Firestore
class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(); // Instancia de Google Sign-In

  // El Stream ahora emite nuestro propio UserModel
  Stream<UserModel?> get authStateChanges => _auth.authStateChanges().asyncMap((user) async {
    if (user == null) {
      return null;
    }
    return await _getUserProfile(user.uid);
  });

  UserModel? _currentUserModel;
  UserModel? get currentUserModel => _currentUserModel;

  Future<UserModel?> get initialAuthCheck async {
    return authStateChanges.first;
  }
  
  Future<UserModel?> _getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        final userModel = UserModel.fromMap(doc.data()!);
        _currentUserModel = userModel;
        return userModel;
      }
      return null;
    } catch (e) {
      debugPrint('Error al obtener perfil de Firestore: $e');
      return null;
    }
  }

  // ==========================================================
  //                MÉTODOS DE AUTENTICACIÓN
  // ==========================================================

  /// 1. Inicio de Sesión o Registro usando Google
  Future<UserModel?> signInWithGoogle() async {
    try {
      // 1. Iniciar el flujo de autenticación de Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // El usuario canceló el inicio de sesión de Google
        return null;
      }

      // 2. Obtener los detalles de autenticación de la solicitud
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 3. Iniciar sesión en Firebase con las credenciales de Google
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        final uid = user.uid;
        
        // 4. Verificar si es un usuario nuevo (y crear su perfil en Firestore si lo es)
        final userProfile = await _getUserProfile(uid);

        if (userProfile == null) {
          // Crear un nuevo perfil en Firestore
          final newUser = UserModel(
            uid: uid,
            email: user.email ?? 'no-email@google.com',
            displayName: user.displayName,
            memberSince: DateTime.now(),
          );

          await _firestore.collection('users').doc(uid).set(newUser.toMap());
          _currentUserModel = newUser;
          notifyListeners();
          return newUser;
        } else {
          // Usuario existente, ya está cargado en _getUserProfile
          notifyListeners();
          return userProfile;
        }
      }
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint('Error de Firebase Auth con Google: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      debugPrint('Error desconocido al iniciar sesión con Google: $e');
      return null;
    }
  }

  /// 2. Cierre de Sesión (ahora también desconecta Google)
  Future<void> signOut() async {
    await _googleSignIn.signOut(); // Desconecta la sesión de Google
    await _auth.signOut();
    _currentUserModel = null;
    notifyListeners();
  }
}