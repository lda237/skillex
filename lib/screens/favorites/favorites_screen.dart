import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/progress_provider.dart';
import '../../providers/video_provider.dart';
import '../../widgets/video_card.dart';


class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Favoris'),
      ),
      body: Consumer2<ProgressProvider, VideoProvider>(
        builder: (context, progressProvider, videoProvider, child) {
          // Récupérer la liste complète des vidéos
          final allVideos = videoProvider.videos;
          // Filtrer pour ne garder que les vidéos favorites
          final favoriteVideos = allVideos
              .where((video) => progressProvider.isFavorite(video.id))
              .toList();

          if (favoriteVideos.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: favoriteVideos.length,
            itemBuilder: (context, index) {
              final video = favoriteVideos[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: VideoCard(
                  video: video,
                  onTap: () {
                    Navigator.pushNamed(context, '/video', arguments: video);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_border,
            size: 80,
            color: theme.primaryColor.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 24),
          Text(
            'Aucune vidéo en favori',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Appuyez sur l\'icône de marque-page sur une vidéo pour l\'ajouter ici.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
