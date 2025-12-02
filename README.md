# StudyMate

Aplicación Flutter para registrar y visualizar horas de estudio diarias.

## Características

- Pantalla de Datos del Estudiante (Nombre, Carrera, Asignatura y checkbox obligatorio).
- Pantalla de Registro de Sesión (horas > 0 y fecha, acumula total y cantidad de sesiones).
- Pantalla de Resumen (total de horas y promedio por sesión) con acciones para continuar o reiniciar.
- Navegación con `Navigator.push()` y `Navigator.pop()`.
- UI simple y centrada usando `Column` y `Card`.

## Cómo ejecutar

1. Requisitos: Flutter SDK instalado y emulador/dispositivo conectado.
2. Desde una terminal en la raíz del proyecto:

```powershell
cd studymate
flutter pub get
flutter run
```

## Estructura relevante

- `lib/main.dart`: Configura `MaterialApp` (sin banner de debug), tema y ruta inicial.
- `lib/screens/student_data_screen.dart`: Formulario inicial y validación. Navega a sesiones.
- `lib/screens/session_screen.dart`: Registro de sesiones, validación y acumulado.
- `lib/screens/summary_screen.dart`: Resumen con promedio y acciones.

## Autor

- Milenko Obilinovic — 04/11/2025
