import 'package:flutter/material.dart';
import '../../models/playlist.dart';
import '../../models/video.dart';
import '../../widgets/metadata_chip.dart';
import 'video_card.dart';

class PlaylistDetails extends StatelessWidget {
  final Playlist playlist;
  final List<Video> videos;
  final bool isLoading;
  final String? error;
  final Function(Video)? onVideoTap;
  final Function(Video)? onVideoRemove;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showActions;

  const PlaylistDetails({
    Key? key,
    required this.playlist,
    required this.videos,
    this.isLoading = false,
    this.error,
    this.onVideoTap,
    this.onVideoRemove,
    this.onEdit,
    this.onDelete,
    this.showActions = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withAlpha(26),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 120,
                      height: 80,
                      color: theme.colorScheme.secondary.withAlpha(26),
                      child: playlist.thumbnailUrl.isNotEmpty
                          ? Image.network(
                              playlist.thumbnailUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildPlaceholder(theme),
                            )
                          : _buildPlaceholder(theme),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Informations
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          playlist.title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          playlist.description,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Métadonnées
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  MetadataChip(
                    icon: Icons.video_library,
                    label: '${playlist.videoCount} vidéos',
                  ),
                  MetadataChip(
                    icon: Icons.timer,
                    label: playlist.formattedDuration,
                  ),
                  MetadataChip(
                    icon: Icons.category,
                    label: playlist.category,
                  ),
                  MetadataChip(
                    icon: Icons.speed,
                    label: playlist.difficulty,
                  ),
                  MetadataChip(
                    icon: playlist.isPublic ? Icons.public : Icons.lock,
                    label: playlist.isPublic ? 'Publique' : 'Privée',
                  ),
                ],
              ),
              if (showActions) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onEdit != null)
                      TextButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit),
                        label: const Text('Modifier'),
                      ),
                    if (onDelete != null) ...[
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete),
                        label: const Text('Supprimer'),
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Liste des vidéos
        Expanded(
          child: _buildVideoList(context),
        ),
      ],
    );
  }

  Widget _buildVideoList(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              error!,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.red,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (videos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.video_library,
              size: 48,
              color: Theme.of(context).colorScheme.primary.withAlpha(128),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune vidéo dans cette playlist',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withAlpha(153),
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        final video = videos[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: VideoCard(
            video: video,
            onTap: onVideoTap != null ? () => onVideoTap!(video) : null,
            onRemove: onVideoRemove != null
                ? () => onVideoRemove!(video)
                : null,
            showRemoveButton: showActions,
          ),
        );
      },
    );
  }

  Widget _buildPlaceholder(ThemeData theme) {
    return Center(
      child: Icon(
        Icons.playlist_play,
        size: 32,
        color: theme.colorScheme.primary,
      ),
    );
  }
}