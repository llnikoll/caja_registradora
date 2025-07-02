import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'database/database_helper.dart';
import 'providers/cart_provider.dart';
import 'widgets/main_layout.dart'; // Import the new MainLayout

void main() async {
  // Asegurarse de que Flutter esté inicializado
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar la base de datos
  final dbHelper = DatabaseHelper();
  await dbHelper.database; // Esto creará la base de datos si no existe

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => CartProvider()),
        // Aquí podrías agregar más providers si es necesario
      ],
      child: const CajaRegistradoraApp(),
    ),
  );
}

class CajaRegistradoraApp extends StatelessWidget {
  const CajaRegistradoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Caja Registradora',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      // Use MainLayout as the home widget
      home: const MainLayout(),
      // Remove initialRoute and routes as navigation is handled in MainLayout
      // initialRoute: '/',
      // routes: {
      //   '/': (context) => const HomeScreen(),
      //   '/reportes': (context) => const ReportesScreen(),
      // },
    );
  }
}
