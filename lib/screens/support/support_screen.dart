import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/debug_logger.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  String _logs = 'Chargement des logs...';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    try {
      final logs = await DebugLogger.instance.getLogs();
      setState(() {
        _logs = logs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _logs = 'Erreur lors du chargement des logs: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _launchUrl(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible d\'ouvrir $url')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Support'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Center(
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    height: 100,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Support Skillex',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Contact
            _buildSection(
              title: 'Contactez-nous',
              content: Column(
                children: [
                  _buildContactItem(
                    icon: Icons.email,
                    title: 'Email de support',
                    subtitle: 'dev@mediasystem.cm',
                    onTap: () => _launchUrl('mailto:dev@mediasystem.cm'),
                  ),
                  _buildContactItem(
                    icon: Icons.language,
                    title: 'Site web',
                    subtitle: 'mediasystem.cm',
                    onTap: () => _launchUrl('https://mediasystem.cm'),
                  ),
                  _buildContactItem(
                    icon: Icons.phone,
                    title: 'Téléphone',
                    subtitle: '+237 XXX XXX XXX',
                    onTap: () => _launchUrl('tel:+237XXXXXXXXX'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Horaires de support
            _buildSection(
              title: 'Horaires de support',
              content: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Lundi - Vendredi: 8h00 - 18h00'),
                  Text('Samedi: 9h00 - 13h00'),
                  Text('Dimanche: Fermé'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // FAQ
            _buildSection(
              title: 'Questions fréquentes',
              content: Column(
                children: [
                  _buildFAQItem(
                    question: 'Comment réinitialiser mon mot de passe ?',
                    answer: 'Vous pouvez réinitialiser votre mot de passe en cliquant sur "Mot de passe oublié" sur l\'écran de connexion.',
                  ),
                  _buildFAQItem(
                    question: 'Comment contacter le support ?',
                    answer: 'Vous pouvez nous contacter par email à dev@mediasystem.cm ou via le formulaire de contact sur notre site web.',
                  ),
                  _buildFAQItem(
                    question: 'Comment signaler un bug ?',
                    answer: 'Utilisez la fonction "Signaler un problème" dans les paramètres de l\'application.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Logs système
            _buildSection(
              title: 'Logs système',
              content: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SelectableText(
                          _logs,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required Widget content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        content,
      ],
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }

  Widget _buildFAQItem({
    required String question,
    required String answer,
  }) {
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(answer),
        ),
      ],
    );
  }
} 