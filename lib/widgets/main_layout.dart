import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/reportes_screen.dart';
import '../screens/ventas_screen.dart';
import '../screens/configuracion_screen.dart';
import '../screens/ayuda_screen.dart';
import '../database/repositories/caja_repository.dart';
import '../database/repositories/transaccion_repository.dart';
import '../models/caja.dart';
import 'cierre_caja_dialog.dart';

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

      if (caja == null) {
        _mostrarDialogoAperturaCaja();
      }
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
              if (double.tryParse(value) == null) {
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
                Navigator.pop(context, double.parse(montoController.text));
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
    } else if (mounted) {
      // Si el usuario canceló, volver a verificar el estado
      await _verificarEstadoCaja();
    }
  }

  // List of widgets to display in the body
  List<Widget> get _screens => [
    if (_cajaActual != null) const HomeScreen() else const Placeholder(),
    const VentasScreen(),
    const ReportesScreen(),
    const ConfiguracionScreen(),
    const AyudaScreen(),
  ];

  void _onItemTapped(int index) {
    // Si no hay caja abierta, solo permitir ir a Configuración y Ayuda
    if (_cajaActual == null && index != 3 && index != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe abrir una caja primero')),
      );
      return;
    }
    setState(() {
      _selectedIndex = index;
    });
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
          actions: _cajaActual != null
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
              child:
                  _screens[_selectedIndex], // Display the selected screen content
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

    // Verificar que el widget sigue montado antes de mostrar el diálogo
    if (!mounted) return;

    // Obtener el Navigator antes del showDialog
    final navigator = Navigator.of(context);
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => CierreCajaDialog(
        montoInicial: _cajaActual?.montoInicial ?? 0,
        totalVentas: totalVentas,
        onCerrarCaja: (montoFinal, observaciones) {
          navigator.pop({
            'montoFinal': montoFinal,
            'observaciones': observaciones,
          });
        },
      ),
    );

    if (result != null) {
      try {
        await _cajaRepository.cerrarCaja(
          result['montoFinal'] as double,
          observaciones: result['observaciones'] as String?,
        );
        if (mounted) {
          setState(() {
            _cajaActual = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Caja cerrada correctamente')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al cerrar la caja: $e')),
          );
        }
      }
    }
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Caja Registradora',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Versión 1.0.0',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Inicio'),
            selected: _selectedIndex == 0,
            onTap: () => _onItemTapped(0),
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
