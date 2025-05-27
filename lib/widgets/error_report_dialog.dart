import 'package:flutter/material.dart';
import '../utils/error_reporter.dart';

class ErrorReportDialog extends StatelessWidget {
  final String errorMessage;
  final Object? error;
  final StackTrace? stackTrace;
  final String? additionalInfo;

  const ErrorReportDialog({
    super.key,
    required this.errorMessage,
    this.error,
    this.stackTrace,
    this.additionalInfo,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rapport d\'erreur'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Une erreur s\'est produite. Voulez-vous envoyer un rapport d\'erreur à notre équipe de support ?',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'Le rapport inclura :',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildInfoItem('Message d\'erreur', errorMessage),
            if (error != null) _buildInfoItem('Détails', error.toString()),
            if (stackTrace != null) _buildInfoItem('Stack trace', stackTrace.toString()),
            if (additionalInfo != null) _buildInfoItem('Informations supplémentaires', additionalInfo!),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () async {
            try {
              await ErrorReporter.instance.sendErrorReport(
                errorMessage: errorMessage,
                error: error,
                stackTrace: stackTrace,
                additionalInfo: additionalInfo,
              );
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Rapport d\'erreur envoyé avec succès'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erreur lors de l\'envoi du rapport: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          child: const Text('Envoyer le rapport'),
        ),
      ],
    );
  }

  Widget _buildInfoItem(String title, String content) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              content,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
} 