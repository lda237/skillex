import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
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
        title: const Text('À propos'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo et version
            Center(
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    height: 120,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Skillex',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_packageInfo != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Version ${_packageInfo!.version}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Description
            const Text(
              'À propos de Skillex',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Skillex est une plateforme de formation vidéo conçue pour offrir une expérience d\'apprentissage interactive et engageante. Notre mission est de rendre l\'éducation accessible à tous grâce à des contenus vidéo de qualité.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),

            // Développeur
            const Text(
              'Développé par',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _launchUrl('https://mediasystem.cm'),
              child: const Text(
                'MediaSystem',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Technologies utilisées
            const Text(
              'Technologies utilisées',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Flutter pour le développement multiplateforme\n'
              '• Firebase pour l\'authentification et la base de données\n'
              '• YouTube Player pour la lecture vidéo\n'
              '• Provider pour la gestion d\'état\n'
              '• Material Design pour l\'interface utilisateur',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),

            // Fonctionnalités
            const Text(
              'Fonctionnalités principales',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Authentification sécurisée\n'
              '• Catalogue de vidéos de formation\n'
              '• Lecteur vidéo intégré\n'
              '• Système de paiement\n'
              '• Interface responsive\n'
              '• Mode hors ligne',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),

            // Support
            const Text(
              'Support',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _launchUrl('mailto:dev@mediasystem.cm'),
              child: const Text(
                'dev@mediasystem.cm',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Mentions légales
            const Text(
              'Mentions légales',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '© 2024 MediaSystem. Tous droits réservés.\n'
              'Skillex est une marque déposée de MediaSystem.',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
} 