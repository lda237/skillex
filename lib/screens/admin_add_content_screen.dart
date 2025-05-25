import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/youtube_service.dart';

class AdminAddContentScreen extends StatefulWidget {
  const AdminAddContentScreen({super.key});

  @override
  AdminAddContentScreenState createState() => AdminAddContentScreenState();
}

class AdminAddContentScreenState extends State<AdminAddContentScreen> {
  final String _adminEmail = 'narcissenkodo@gmail.com';
  final String _adminPin = '1234';

  bool _isAuthorizedUser = false;
  bool _isPinVerified = false;
  String _pinInput = '';
  final TextEditingController _pinController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _linkController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isAddingContent = false;
  String? _addContentError;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _checkUserAuthorization();
  }

  void _checkUserAuthorization() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user?.email == _adminEmail) {
      setState(() {
        _isAuthorizedUser = true;
      });
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    _linkController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _verifyPin() {
    if (_pinInput == _adminPin) {
      setState(() {
        _isPinVerified = true;
        _pinController.clear();
      });
      _showSnackBar('Accès autorisé !', isError: false);
    } else {
      _showSnackBar('Code PIN incorrect', isError: true);
      setState(() {
        _pinInput = '';
      });
      _pinController.clear();
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red[600] : Colors.green[600],
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

      // Gestion des différents formats YouTube
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

      // Nettoyer l'ID vidéo (supprimer les paramètres supplémentaires)
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accès refusé'),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.block, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Accès non autorisé',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Vous n\'avez pas les permissions nécessaires\npour accéder à cette page.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPinVerificationScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vérification sécurisée'),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.security, size: 64, color: Colors.orange),
              const SizedBox(height: 24),
              Text(
                'Code PIN requis',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Entrez votre code PIN pour continuer',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              Container(
                width: 200,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: TextField(
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 4,
                  obscureText: true,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    counterText: "",
                    hintText: "••••",
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                  onChanged: (value) {
                    _pinInput = value;
                    if (value.length == 4) {
                      _verifyPin();
                    }
                  },
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 200,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (_pinController.text.length == 4) {
                      _pinInput = _pinController.text;
                      _verifyPin();
                    } else {
                      _showSnackBar('Veuillez entrer 4 chiffres', isError: true);
                    }
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Vérifier'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentForm() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administration - Contenu'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
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
              // En-tête
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.video_library, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Ajouter une nouvelle formation',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.blue[700],
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

              // Champ lien YouTube
              TextFormField(
                controller: _linkController,
                decoration: InputDecoration(
                  labelText: 'Lien YouTube *',
                  hintText: 'https://www.youtube.com/watch?v=...',
                  prefixIcon: const Icon(Icons.link),
                  border: const OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue[700]!),
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

              // Champ description
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description personnalisée *',
                  hintText: 'Décrivez brièvement le contenu de cette formation...',
                  prefixIcon: const Icon(Icons.description),
                  border: const OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue[700]!),
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

              // Bouton d'ajout
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
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),

              // Messages d'erreur ou de succès
              if (_addContentError != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error, color: Colors.red[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _addContentError!,
                          style: TextStyle(color: Colors.red[700]),
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
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _successMessage!,
                          style: TextStyle(color: Colors.green[700]),
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
    if (!_isAuthorizedUser) {
      return _buildUnauthorizedScreen();
    }

    if (!_isPinVerified) {
      return _buildPinVerificationScreen();
    }

    return _buildContentForm();
  }
}