import 'package:flutter/material.dart';

class VentasScreen extends StatelessWidget {
  const VentasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.receipt_long, size: 80, color: Colors.blue),
            const SizedBox(height: 16),
            Text('Ventas', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            const Text(
              'Módulo de gestión de ventas',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Navegar a la pantalla de nueva venta
              },
              icon: const Icon(Icons.add),
              label: const Text('Nueva Venta'),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const VentasHistorialScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.history),
              label: const Text('Historial de Ventas'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[200],
                foregroundColor: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VentasHistorialScreen extends StatelessWidget {
  const VentasHistorialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historial de Ventas')),
      body: Center(child: Text('Aquí se mostrará el historial de ventas.')),
    );
  }
}
