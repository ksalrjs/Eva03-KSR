import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
// Para el DatePicker en español
import 'package:flutter_localizations/flutter_localizations.dart'; 
// Si estás usando `firebase_options.dart` (generado por Firebase CLI), descomenta la siguiente línea:
// import 'firebase_options.dart'; 

// Importaciones de Archivos de la Aplicación
import 'screens/splash_screen.dart'; 
import 'services/auth_service.dart'; 
import 'services/study_log_service.dart';

void main() async {
  // Asegura que los bindings de Flutter estén inicializados para llamar a métodos nativos
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Inicialización de Firebase (Punto Crítico)
  await Firebase.initializeApp(
    // Si tienes configurado el CLI de Firebase, usa la siguiente línea:
    // options: DefaultFirebaseOptions.currentPlatform, 
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 2. Configuración del MultiProvider
    return MultiProvider(
      providers: [
        // Proveedor de Autenticación (maneja el estado de login)
        ChangeNotifierProvider(create: (_) => AuthService()),
        
        // Proveedor de Registros de Estudio (maneja la lógica CRUD con Firestore)
        ChangeNotifierProvider(create: (_) => StudyLogService()), 
      ],
      child: MaterialApp(
        title: 'Eva03 | Registro de Estudio',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.indigo,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          // Definir la fuente de iconos de material 3
          useMaterial3: true, 
        ),
        
        // 3. Configuración de Localización (para el formato de fecha en español)
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en', 'US'), // English
          Locale('es', 'ES'), // Spanish (Importante para el DatePicker)
        ],
        
        // La aplicación comienza en el SplashScreen para verificar la sesión.
        home: const SplashScreen(),
      ),
    );
  }
}