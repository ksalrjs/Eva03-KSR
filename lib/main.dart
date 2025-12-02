import 'package:Eva03/firebase_options.dart';
import 'package:Eva03/models/user_model.dart';
import 'package:Eva03/screens/home_screen.dart';
import 'package:Eva03/screens/login_screen.dart';
import 'package:Eva03/services/auth_service.dart';
import 'package:Eva03/services/firestore_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async {
  // Asegurarse de que los bindings de Flutter estén inicializados.
  WidgetsFlutterBinding.ensureInitialized();
  // Inicializar Firebase con las opciones de configuración para cada plataforma.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MultiProvider permite que los widgets hijos accedan a nuestros servicios.
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<FirestoreService>(create: (_) => FirestoreService()),
      ],
      child: MaterialApp(
        title: 'FRACTAR',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.cyan),
          useMaterial3: true,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        debugShowCheckedModeBanner: false,
        home: Provider<UserModel>.value(
          value: UserModel(
            uid: 'test-user',
            email: 'test@example.com',
            displayName: 'Usuario Prueba',
            role: UserRole.admin,
          ),
          child: const HomeScreen(),
        ),
      ),
    );
  }
}

/// Un widget que decide qué pantalla mostrar basado en el estado de autenticación.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return StreamBuilder<UserModel?>(
      stream: authService.userStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Muestra un indicador de carga mientras se verifica el estado de auth.
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        } else if (snapshot.hasData && snapshot.data != null) {
          // Si el stream tiene datos (un UserModel), el usuario está logueado.
          // Proveemos el UserModel al árbol de widgets para que HomeScreen lo pueda usar.
          return Provider<UserModel>.value(
            value: snapshot.data!,
            child: const HomeScreen(),
          );
        } else {
          // Si no hay datos, el usuario no está logueado.
          return const LoginScreen();
        }
      },
    );
  }
}
