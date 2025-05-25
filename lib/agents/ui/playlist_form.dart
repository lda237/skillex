import 'package:flutter/material.dart';
import '../../models/playlist.dart';

class PlaylistForm extends StatefulWidget {
  final Playlist? playlist;
  final Function({
    required String title,
    required String description,
    required String category,
    required String difficulty,
    required bool isPublic,
  }) onSubmit;
  final VoidCallback? onCancel;

  const PlaylistForm({
    super.key,
    this.playlist,
    required this.onSubmit,
    this.onCancel,
  });

  @override
  State<PlaylistForm> createState() => _PlaylistFormState();
}

class _PlaylistFormState extends State<PlaylistForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late String _selectedCategory;
  late String _selectedDifficulty;
  late bool _isPublic;

  final List<String> _categories = [
    'Développement Web',
    'Développement Mobile',
    'Data Science',
    'Intelligence Artificielle',
    'DevOps',
    'Cybersécurité',
    'Général',
  ];

  final List<String> _difficulties = [
    'Débutant',
    'Intermédiaire',
    'Avancé',
    'Expert',
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.playlist?.title);
    _descriptionController =
        TextEditingController(text: widget.playlist?.description);
    _selectedCategory = widget.playlist?.category ?? _categories.first;
    _selectedDifficulty = widget.playlist?.difficulty ?? _difficulties.first;
    _isPublic = widget.playlist?.isPublic ?? true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      widget.onSubmit(
        title: _titleController.text,
        description: _descriptionController.text,
        category: _selectedCategory,
        difficulty: _selectedDifficulty,
        isPublic: _isPublic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Titre
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Titre',
              hintText: 'Entrez le titre de la playlist',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Le titre est requis';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Description
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'Entrez la description de la playlist',
            ),
            maxLines: 3,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'La description est requise';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Catégorie
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: const InputDecoration(
              labelText: 'Catégorie',
            ),
            items: _categories.map((category) {
              return DropdownMenuItem(
                value: category,
                child: Text(category),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedCategory = value;
                });
              }
            },
          ),
          const SizedBox(height: 16),

          // Niveau de difficulté
          DropdownButtonFormField<String>(
            value: _selectedDifficulty,
            decoration: const InputDecoration(
              labelText: 'Niveau de difficulté',
            ),
            items: _difficulties.map((difficulty) {
              return DropdownMenuItem(
                value: difficulty,
                child: Text(difficulty),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedDifficulty = value;
                });
              }
            },
          ),
          const SizedBox(height: 16),

          // Visibilité
          SwitchListTile(
            title: const Text('Playlist publique'),
            subtitle: Text(
              _isPublic
                  ? 'Visible par tous les utilisateurs'
                  : 'Visible uniquement par vous',
              style: theme.textTheme.bodySmall,
            ),
            value: _isPublic,
            onChanged: (value) {
              setState(() {
                _isPublic = value;
              });
            },
          ),
          const SizedBox(height: 24),

          // Boutons d'action
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (widget.onCancel != null)
                TextButton(
                  onPressed: widget.onCancel,
                  child: const Text('Annuler'),
                ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _handleSubmit,
                child: Text(
                  widget.playlist == null ? 'Créer' : 'Mettre à jour',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 