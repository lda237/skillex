import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/youtube_service.dart';
import '../utils/app_theme.dart';

class AdminAddContentScreen extends StatefulWidget {
  const AdminAddContentScreen({super.key});

  @override
  AdminAddContentScreenState createState() => AdminAddContentScreenState();
}

class AdminAddContentScreenState extends State<AdminAddContentScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _linkController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isAddingContent = false;
  String? _addContentError;
  String? _successMessage;

  @override
  void dispose() {
    _linkController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (mounted) {
      final theme = Theme.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? theme.colorScheme.error : AppTheme.successColor,
          duration: Duration(seconds: isError ? 3 : 2),
        ),
      );
    }
  }

  String? _extractVideoId(String youtubeLink) {
    try {
      final uri = Uri.tryParse(youtubeLink.trim());
      if (uri == null) return null;

      String? videoId;

      if (uri.host.contains('youtube.com') || uri.host.contains('www.youtube.com')) {
        if (uri.pathSegments.contains('watch') && uri.queryParameters.containsKey('v')) {
          videoId = uri.queryParameters['v'];
        } else if (uri.pathSegments.contains('embed') && uri.pathSegments.length > 1) {
          final embedIndex = uri.pathSegments.indexOf('embed');
          if (embedIndex + 1 < uri.pathSegments.length) {
            videoId = uri.pathSegments[embedIndex + 1];
          }
        }
      } else if (uri.host.contains('youtu.be')) {
        if (uri.pathSegments.isNotEmpty) {
          videoId = uri.pathSegments.first;
        }
      } else if (uri.host.contains('m.youtube.com')) {
        if (uri.queryParameters.containsKey('v')) {
          videoId = uri.queryParameters['v'];
        }
      }

      if (videoId != null && videoId.contains('&')) {
        videoId = videoId.split('&').first;
      }

      return videoId?.isNotEmpty == true ? videoId : null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _addVideoContent() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isAddingContent = true;
      _addContentError = null;
      _successMessage = null;
    });

    try {
      final youtubeLink = _linkController.text.trim();
      final description = _descriptionController.text.trim();

      final videoId = _extractVideoId(youtubeLink);
      if (videoId == null || videoId.isEmpty) {
        throw Exception('Lien YouTube invalide. Veuillez vérifier le format du lien.');
      }

      final youtubeService = Provider.of<YoutubeService>(context, listen: false);
      await youtubeService.fetchVideoDetailsAndSave(videoId, customDescription: description);

      setState(() {
        _successMessage = 'Vidéo ajoutée avec succès !';
      });
      
      _showSnackBar('Vidéo ajoutée avec succès !', isError: false);
      _clearForm();

    } catch (e) {
      setState(() {
        _addContentError = 'Erreur lors de l\'ajout: ${e.toString()}';
      });
      _showSnackBar(_addContentError!, isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isAddingContent = false;
        });
      }
    }
  }

  void _clearForm() {
    _linkController.clear();
    _descriptionController.clear();
    setState(() {
      _addContentError = null;
      _successMessage = null;
    });
  }

  Widget _buildUnauthorizedScreen() {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accès refusé'),
        backgroundColor: theme.colorScheme.error,
        foregroundColor: theme.colorScheme.onError,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.block, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            const Text(
              'Accès non autorisé',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Vous n\'avez pas les permissions nécessaires\npour accéder à cette page.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentForm(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administration - Contenu'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Réinitialiser le formulaire',
            onPressed: _clearForm,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.video_library, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Ajouter une nouvelle formation',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Ajoutez du contenu de formation en collant un lien YouTube valide',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _linkController,
                decoration: InputDecoration(
                  labelText: 'Lien YouTube *',
                  hintText: 'https://www.youtube.com/watch?v=...',
                  prefixIcon: const Icon(Icons.link),
                  border: const OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: theme.colorScheme.primary),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le lien YouTube est requis';
                  }
                  if (!value.contains('youtube.com/') && !value.contains('youtu.be/')) {
                    return 'Veuillez entrer un lien YouTube valide';
                  }
                  return null;
                },
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description personnalisée *',
                  hintText: 'Décrivez brièvement le contenu de cette formation...',
                  prefixIcon: const Icon(Icons.description),
                  border: const OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: theme.colorScheme.primary),
                  ),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Une description est requise';
                  }
                  if (value.trim().length < 10) {
                    return 'La description doit contenir au moins 10 caractères';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isAddingContent ? null : _addVideoContent,
                icon: _isAddingContent
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.add_circle),
                label: Text(_isAddingContent ? 'Ajout en cours...' : 'Ajouter la Vidéo'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              if (_addContentError != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error, color: theme.colorScheme.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _addContentError!,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (_successMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.successColor.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: AppTheme.successColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _successMessage!,
                          style: const TextStyle(color: AppTheme.successColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (!authProvider.isAdmin) {
          return _buildUnauthorizedScreen();
        }
        return _buildContentForm(context);
      },
    );
  }
}