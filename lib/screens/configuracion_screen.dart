import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/empresa_provider.dart';

class ConfiguracionScreen extends StatefulWidget {
  const ConfiguracionScreen({super.key});

  @override
  State<ConfiguracionScreen> createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Necesario para AutomaticKeepAliveClientMixin
    final empresa = Provider.of<EmpresaProvider>(context);
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const SizedBox(height: 16),
          Center(
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white,
              child: Icon(empresa.iconData, size: 50, color: empresa.iconColor),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.edit),
              label: const Text('Cambiar icono de empresa'),
              onPressed: () async {
                await showDialog(
                  context: context,
                  builder: (context) => _IconoEmpresaDialog(),
                );
              },
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

class _IconoEmpresaDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final empresa = Provider.of<EmpresaProvider>(context, listen: false);
    return AlertDialog(
      title: const Text('Seleccionar icono y color'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Icono'),
            Wrap(
              spacing: 12,
              children: [
                for (var iconData in empresa.listaIconos)
                  IconButton(
                    icon: Icon(iconData, size: 32),
                    onPressed: () {
                      empresa.cambiarIcono(iconData);
                      Navigator.of(context).pop();
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Color'),
            Wrap(
              spacing: 12,
              children: [
                for (var color in empresa.listaColores)
                  GestureDetector(
                    onTap: () {
                      empresa.cambiarColor(color);
                      Navigator.of(context).pop();
                    },
                    child: CircleAvatar(
                      backgroundColor: color,
                      radius: 16,
                      child: empresa.iconColor == color
                          ? const Icon(Icons.check, color: Colors.white)
                          : null,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}
