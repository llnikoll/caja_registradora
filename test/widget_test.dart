import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:caja_registradora/main.dart';

void main() {
  testWidgets('La aplicación se inicia correctamente', (WidgetTester tester) async {
    // Construye nuestra aplicación y dispara un frame.
    await tester.pumpWidget(
      const CajaRegistradoraApp(),
    );

    // Verifica que la pantalla de inicio se muestra correctamente
    expect(find.text('Caja Registradora'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byType(ElevatedButton), findsWidgets);
  });

  testWidgets('Agregar un producto al carrito', (WidgetTester tester) async {
    // Construye nuestra aplicación
    await tester.pumpWidget(
      const CajaRegistradoraApp(),
    );

    // Ingresa el nombre del producto
    await tester.enterText(find.byType(TextField).first, 'Producto de prueba');
    
    // Ingresa el precio del producto
    await tester.tap(find.text('1'));
    await tester.tap(find.text('0'));
    await tester.tap(find.text('0'));
    await tester.pump();
    
    // Presiona el botón para agregar
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    
    // Verifica que el producto se haya agregado al carrito
    expect(find.text('Producto de prueba'), findsOneWidget);
    expect(find.text('\$100.00'), findsOneWidget);
  });
}
