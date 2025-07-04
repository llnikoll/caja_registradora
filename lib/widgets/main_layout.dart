import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/home_screen.dart';
import '../screens/reportes_screen.dart';
import '../screens/ventas_screen.dart';
import '../screens/configuracion_screen.dart';
import '../screens/ayuda_screen.dart';
import '../database/repositories/caja_repository.dart';
import '../database/repositories/transaccion_repository.dart';
import '../models/caja.dart';
import 'cierre_caja_dialog.dart';
import '../restart_widget.dart';
import '../providers/empresa_provider.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;
  final CajaRepository _cajaRepository = CajaRepository();
  final TransaccionRepository _transaccionRepository = TransaccionRepository();
  Caja? _cajaActual;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Siempre iniciar en modo loading para evitar pantalla negra tras reinicio
    setState(() {
      _isLoading = true;
    });
    _verificarEstadoCaja();
  }

  Future<void> _verificarEstadoCaja() async {
    setState(() => _isLoading = true);
    try {
      final caja = await _cajaRepository.getCajaAbierta();
      setState(() {
        _cajaActual = caja;
        _isLoading = false;
      });
      // Ya no mostrar automáticamente el diálogo de apertura
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al verificar el estado de la caja: $e'),
          ),
        );
      }
    }
  }

  Future<void> _mostrarDialogoAperturaCaja() async {
    final montoController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    // Formateo en tiempo real
    montoController.addListener(() {
      final text = montoController.text.replaceAll('.', '').replaceAll(',', '');
      if (text.isEmpty) return;
      final value = double.tryParse(text);
      if (value != null) {
        final formatted = value
            .toStringAsFixed(0)
            .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.');
        if (montoController.text != formatted) {
          montoController.value = montoController.value.copyWith(
            text: formatted,
            selection: TextSelection.collapsed(offset: formatted.length),
          );
        }
      }
    });

    final montoInicial = await showDialog<double?>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Apertura de Caja'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: montoController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Monto inicial en caja',
              prefixText: '₲',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingrese un monto';
              }
              final clean = value.replaceAll('.', '').replaceAll(',', '');
              if (double.tryParse(clean) == null) {
                return 'Ingrese un monto válido';
              }
              return null;
            },
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final clean = montoController.text
                    .replaceAll('.', '')
                    .replaceAll(',', '');
                Navigator.pop(context, double.parse(clean));
              }
            },
            child: const Text('ACEPTAR'),
          ),
        ],
      ),
    );

    if (montoInicial != null) {
      try {
        await _cajaRepository.abrirCaja(montoInicial);
        if (mounted) {
          await _verificarEstadoCaja();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error al abrir la caja: $e')));
        }
      }
    }
    // Si cancela, no hacer nada
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // List of screens to display in the body
  final List<Widget> _screens = [
    const HomeScreen(key: PageStorageKey('home')),
    const VentasScreen(key: PageStorageKey('ventas')),
    const ReportesScreen(key: PageStorageKey('reportes')),
    const ConfiguracionScreen(key: PageStorageKey('config')),
    const AyudaScreen(key: PageStorageKey('ayuda')),
  ];

  Widget _buildSinCajaAbierta() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.point_of_sale_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'No hay caja abierta',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Puedes explorar la app, pero para registrar ventas debes abrir una caja.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _mostrarDialogoAperturaCaja,
            icon: const Icon(Icons.add),
            label: const Text('Abrir Caja'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              textStyle: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return PopScope(
      canPop: _selectedIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _selectedIndex != 0) {
          setState(() {
            _selectedIndex = 0;
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            [
              'Inicio',
              'Ventas',
              'Reportes',
              'Configuración',
              'Ayuda',
            ][_selectedIndex],
          ),
          actions: _cajaActual != null && _selectedIndex == 0
              ? [
                  IconButton(
                    icon: const Icon(Icons.point_of_sale),
                    onPressed: _mostrarDialogoCierreCaja,
                    tooltip: 'Cerrar Caja',
                  ),
                ]
              : null,
        ),
        drawer: MediaQuery.of(context).size.width < 600
            ? _buildDrawer()
            : null, // Show drawer only on small screens
        body: Row(
          children: [
            // Persistent Drawer for large screens
            if (MediaQuery.of(context).size.width >=
                600) // Adjust breakpoint as needed
              SizedBox(
                width: 200, // Match the width we set in HomeScreen previously
                child: _buildDrawer(),
              ),
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: _cajaActual != null
                    ? _screens
                    : [
                        _buildSinCajaAbierta(),
                        ..._screens.sublist(
                          1,
                        ), // Mostrar otras pantallas normalmente
                      ],
              ), // Display the selected screen content
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _mostrarDialogoCierreCaja() async {
    if (!mounted) return;

    // Obtener el total de ventas del día
    double totalVentas = 0.0;
    try {
      final ahora = DateTime.now();
      final hoy = DateTime(ahora.year, ahora.month, ahora.day);
      final manana = hoy.add(const Duration(days: 1));

      final resumen = await _transaccionRepository.getResumenVentas(
        hoy,
        manana,
      );
      totalVentas = (resumen['totalGeneral'] as num).toDouble();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al calcular ventas: $e')));
      }
      return;
    }

    if (!mounted) return;

    // Mostrar el diálogo y manejar el resultado
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false, // Evitar que se cierre tocando fuera
      builder: (BuildContext dialogContext) {
        return CierreCajaDialog(
          montoInicial: _cajaActual?.montoInicial ?? 0,
          totalVentas: totalVentas,
          onCerrarCaja: (montoFinal, observaciones) {
            Navigator.of(
              dialogContext,
            ).pop({'montoFinal': montoFinal, 'observaciones': observaciones});
          },
        );
      },
    );

    if (result == null) return; // Usuario canceló

    try {
      // Cerrar la caja en la base de datos
      await _cajaRepository.cerrarCaja(
        result['montoFinal'] as double,
        observaciones: result['observaciones'] as String?,
      );

      // Reiniciar toda la app para forzar el estado inicial
      if (mounted) {
        RestartWidget.restartApp(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al cerrar la caja: $e')));
      }
    }
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          CompanyDrawerHeader(), // Use custom header
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Inicio'),
            selected: _selectedIndex == 0,
            onTap: () async {
              // Pequeño delay para asegurar reconstrucción limpia
              await Future.delayed(const Duration(milliseconds: 100));
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const MainLayout()),
                (route) => false,
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.point_of_sale),
            title: const Text('Ventas'),
            selected: _selectedIndex == 1,
            onTap: () => _onItemTapped(1),
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: const Text('Reportes'),
            selected: _selectedIndex == 2,
            onTap: () => _onItemTapped(2),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Configuración'),
            selected: _selectedIndex == 3,
            onTap: () => _onItemTapped(3),
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Ayuda'),
            selected: _selectedIndex == 4,
            onTap: () => _onItemTapped(4),
          ),
        ],
      ),
    );
  }
}

// Custom Drawer Header widget
class CompanyDrawerHeader extends StatelessWidget {
  const CompanyDrawerHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<EmpresaProvider>(
      builder: (context, empresa, _) => Container(
        height: 100, // Reduced height to decrease extra space
        decoration: BoxDecoration(color: empresa.iconColor),
        padding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 8.0, // Adjusted vertical padding
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start, // Explicitly set cross alignment
          mainAxisAlignment:
              MainAxisAlignment.end, // Align content to the bottom
          children: [
            CircleAvatar(
              radius: 20, // Keep radius
              backgroundColor: Colors.white,
              child: Icon(
                empresa.iconData,
                size: 26,
                color: empresa.iconColor,
              ), // Keep size
            ),
            const SizedBox(height: 4), // Keep spacing
            Text(
              'Caja Registradora',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15, // Keep font size
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 1), // Keep spacing
            const Text(
              'Versión 1.0.0',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 10,
              ), // Keep font size
            ),
          ],
        ),
      ),
    );
  }
}
