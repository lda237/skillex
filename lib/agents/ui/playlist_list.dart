import 'package:flutter/material.dart';
import '../../models/playlist.dart';
import 'playlist_card.dart';

class PlaylistList extends StatelessWidget {
  final String title;
  final List<Playlist> playlists;
  final bool isLoading;
  final String? error;
  final Function(Playlist)? onPlaylistTap;
  final Function(Playlist)? onPlaylistEdit;
  final Function(Playlist)? onPlaylistDelete;
  final bool showActions;
  final ScrollController? scrollController;

  const PlaylistList({
    Key? key,
    required this.title,
    required this.playlists,
    this.isLoading = false,
    this.error,
    this.onPlaylistTap,
    this.onPlaylistEdit,
    this.onPlaylistDelete,
    this.showActions = false,
    this.scrollController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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

    if (playlists.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.playlist_play,
              size: 48,
              color: Theme.of(context).colorScheme.primary.withAlpha(26),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune playlist disponible',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).textTheme.bodyMedium!.color!.withAlpha(153),
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: playlists.length,
      itemBuilder: (context, index) {
        final playlist = playlists[index];
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          child: PlaylistCard(
            playlist: playlist,
            onTap: onPlaylistTap != null
                ? () => onPlaylistTap!(playlist)
                : null,
            onEdit: onPlaylistEdit != null
                ? () => onPlaylistEdit!(playlist)
                : null,
            onDelete: onPlaylistDelete != null
                ? () => onPlaylistDelete!(playlist)
                : null,
            showActions: showActions,
          ),
        );
      },
    );
  }
}

// Widget pour afficher une grille de playlists
class PlaylistGrid extends StatelessWidget {
  final List<Playlist> playlists;
  final bool isLoading;
  final String? error;
  final Function(Playlist)? onPlaylistTap;
  final Function(Playlist)? onPlaylistEdit;
  final Function(Playlist)? onPlaylistDelete;
  final bool showActions;
  final ScrollController? scrollController;

  const PlaylistGrid({
    Key? key,
    required this.playlists,
    this.isLoading = false,
    this.error,
    this.onPlaylistTap,
    this.onPlaylistEdit,
    this.onPlaylistDelete,
    this.showActions = false,
    this.scrollController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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

    if (playlists.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.playlist_play,
              size: 48,
              color: Theme.of(context).colorScheme.primary.withAlpha(26),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune playlist disponible',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).textTheme.bodyMedium!.color!.withAlpha(153),
                  ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: playlists.length,
      itemBuilder: (context, index) {
        final playlist = playlists[index];
        return PlaylistCard(
          playlist: playlist,
          onTap: onPlaylistTap != null
              ? () => onPlaylistTap!(playlist)
              : null,
          onEdit: onPlaylistEdit != null
              ? () => onPlaylistEdit!(playlist)
              : null,
          onDelete: onPlaylistDelete != null
              ? () => onPlaylistDelete!(playlist)
              : null,
          showActions: showActions,
        );
      },
    );
  }
} 