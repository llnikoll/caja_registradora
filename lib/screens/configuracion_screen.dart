import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/empresa_provider.dart';
import '../providers/quick_amounts_provider.dart';
import '../providers/theme_provider.dart';

class ConfiguracionScreen extends StatefulWidget {
  const ConfiguracionScreen({super.key});

  @override
  State<ConfiguracionScreen> createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen>
    with AutomaticKeepAliveClientMixin {
  final _quickAmount1Controller = TextEditingController();
  final _quickAmount2Controller = TextEditingController();
  final _quickAmount3Controller = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with values from QuickAmountsProvider
    final quickProvider = Provider.of<QuickAmountsProvider>(
      context,
      listen: false,
    );
    _quickAmount1Controller.text = quickProvider.amounts[0].toString();
    _quickAmount2Controller.text = quickProvider.amounts[1].toString();
    _quickAmount3Controller.text = quickProvider.amounts[2].toString();
  }

  @override
  void dispose() {
    _quickAmount1Controller.dispose();
    _quickAmount2Controller.dispose();
    _quickAmount3Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Necesario para AutomaticKeepAliveClientMixin
    final quickProvider = Provider.of<QuickAmountsProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
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
                  leading: const Icon(Icons.flash_on),
                  title: const Text('Montos rápidos del teclado'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _quickAmount1Controller,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Monto 1',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _quickAmount2Controller,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Monto 2',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _quickAmount3Controller,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Monto 3',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.save),
                          label: const Text('Guardar'),
                          onPressed: () async {
                            final scaffoldMessenger = ScaffoldMessenger.of(context); // Capture before async gap
                            // Use the provider to set amounts
                            await quickProvider.setAmounts([
                              int.tryParse(_quickAmount1Controller.text) ??
                                  15000,
                              int.tryParse(_quickAmount2Controller.text) ??
                                  18000,
                              int.tryParse(_quickAmount3Controller.text) ??
                                  20000,
                            ]);
                            // No need for mounted check here for scaffoldMessenger as it was obtained before the async gap
                            scaffoldMessenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Montos rápidos guardados'),
                                ),
                              );
                          },
                        ),
                      ),
                    ],
                  ),
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
                  value: themeProvider.isDarkMode,
                  onChanged: (bool value) {
                    themeProvider.setDarkMode(value);
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
