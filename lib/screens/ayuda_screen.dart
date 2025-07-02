import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AyudaScreen extends StatefulWidget {
  const AyudaScreen({super.key});

  @override
  State<AyudaScreen> createState() => _AyudaScreenState();
}

class _AyudaScreenState extends State<AyudaScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('No se pudo abrir $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Necesario para AutomaticKeepAliveClientMixin
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 24),
            const Icon(
              Icons.help_outline,
              size: 80,
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            Text(
              'Centro de Ayuda',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 32),
            _buildHelpCard(
              context,
              'Preguntas Frecuentes',
              Icons.question_answer,
              'Encuentra respuestas a las preguntas más comunes',
              onTap: () {
                // Navegar a preguntas frecuentes
              },
            ),
            const SizedBox(height: 16),
            _buildHelpCard(
              context,
              'Tutoriales',
              Icons.play_circle_fill,
              'Aprende a usar la aplicación con nuestros tutoriales',
              onTap: () {
                // Navegar a tutoriales
              },
            ),
            const SizedBox(height: 16),
            _buildHelpCard(
              context,
              'Soporte Técnico',
              Icons.support_agent,
              'Contáctanos para recibir asistencia personalizada',
              onTap: () {
                _launchURL('mailto:soporte@cajaregistradora.com');
              },
            ),
            const SizedBox(height: 32),
            Text(
              'Versión 1.0.0',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '© 2025 Caja Registradora App',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpCard(
    BuildContext context,
    String title,
    IconData icon,
    String subtitle, {
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Colors.blue, size: 32),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 8.0,
        ),
      ),
    );
  }
}
