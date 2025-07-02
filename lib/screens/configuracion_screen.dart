import 'package:flutter/material.dart';

class ConfiguracionScreen extends StatelessWidget {
  const ConfiguracionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const SizedBox(height: 16),
          const Center(
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blue,
              child: Icon(
                Icons.settings,
                size: 50,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.store),
                  title: const Text('Datos del Negocio'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Navegar a configuración de negocio
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.receipt),
                  title: const Text('Configuración de Facturación'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Navegar a configuración de facturación
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.payment),
                  title: const Text('Métodos de Pago'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Navegar a configuración de métodos de pago
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Modo Oscuro'),
                  secondary: const Icon(Icons.dark_mode),
                  value: false,
                  onChanged: (bool value) {
                    // Implementar cambio de tema
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.language),
                  title: const Text('Idioma'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Español',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: () {
                    // Navegar a selección de idioma
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
