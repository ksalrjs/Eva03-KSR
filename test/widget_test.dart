// Prueba básica de widgets en Flutter.
//
// Para interactuar con un widget en las pruebas, usa WidgetTester del paquete
// flutter_test. Por ejemplo, puedes simular toques y desplazamientos (scroll),
// encontrar widgets hijos en el árbol, leer textos y verificar propiedades.

import 'package:flutter_test/flutter_test.dart';

import 'package:studymate/main.dart';

void main() {
  testWidgets('Carga la app y muestra la pantalla de Datos', (WidgetTester tester) async {
    // Construye la app y dispara un frame inicial.
    await tester.pumpWidget(const StudyMateApp());

    // Verifica que se vea el título de la pantalla inicial.
    expect(find.text('Datos del Estudiante'), findsOneWidget);

    // Verifica que exista el botón Continuar.
    expect(find.text('Continuar'), findsOneWidget);
  });
}
