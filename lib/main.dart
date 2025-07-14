import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'database/database_helper.dart';
import 'providers/cart_provider.dart';
import 'providers/empresa_provider.dart'; // Import the EmpresaProvider
import 'providers/quick_amounts_provider.dart';
import 'providers/theme_provider.dart'; // Import ThemeProvider
import 'providers/calculator_provider.dart'; // Import CalculatorProvider
import 'providers/sales_history_provider.dart'; // Import SalesHistoryProvider
import 'providers/reportes_provider.dart'; // Import ReportesProvider
import 'widgets/main_layout.dart'; // Import the new MainLayout
import 'restart_widget.dart';

void main() async {
  // Asegurarse de que Flutter esté inicializado
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar la base de datos
  final dbHelper = DatabaseHelper();
  await dbHelper.database; // Esto creará la base de datos si no existe

  runApp(
    RestartWidget(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => CartProvider()),
          ChangeNotifierProvider(
            create: (context) => EmpresaProvider(),
          ), // Add EmpresaProvider
          ChangeNotifierProvider(create: (context) => QuickAmountsProvider()),
          ChangeNotifierProvider(
            create: (context) => ThemeProvider(),
          ), // Add ThemeProvider
          ChangeNotifierProvider(create: (context) => CalculatorProvider()), // Add CalculatorProvider
          ChangeNotifierProvider(create: (context) => SalesHistoryProvider()), // Add SalesHistoryProvider
          ChangeNotifierProvider(create: (context) => ReportesProvider()), // Add ReportesProvider
          // Aquí podrías agregar más providers si es necesario
        ],
        child: const CajaRegistradoraApp(),
      ),
    ),
  );
}

class CajaRegistradoraApp extends StatelessWidget {
  const CajaRegistradoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
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
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
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
