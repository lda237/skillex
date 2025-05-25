import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/playlist_provider.dart';
import '../../agents/ui/playlist_details.dart';

class PlaylistDetailsScreen extends StatefulWidget {
  final String playlistId;

  const PlaylistDetailsScreen({Key? key, required this.playlistId}) : super(key: key);

  @override
  PlaylistDetailsScreenState createState() => PlaylistDetailsScreenState();
}

class PlaylistDetailsScreenState extends State<PlaylistDetailsScreen> {

  @override
  void initState() {
    super.initState();
    // Charger la playlist et ses vidéos au démarrage de l'écran
    WidgetsBinding.instance.addPostFrameCallback((_) {
       Provider.of<PlaylistProvider>(context, listen: false).loadPlaylist(widget.playlistId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails de la Playlist'),
      ),
      body: Consumer<PlaylistProvider>(
        builder: (context, playlistProvider, child) {
          // Afficher un indicateur de chargement si la playlist est en cours de chargement ou si elle n'a pas encore été chargée
          if (playlistProvider.isLoading || playlistProvider.currentPlaylist == null) {
            return const Center(child: CircularProgressIndicator());
          }

          // Afficher un message d'erreur si quelque chose ne va pas
          if (playlistProvider.error != null) {
            return Center(
              child: Text('Erreur: ${playlistProvider.error}'),
            );
          }

          // Si la playlist est chargée, afficher les détails
          final playlist = playlistProvider.currentPlaylist!;
          final videos = playlistProvider.currentPlaylistVideos;

          return PlaylistDetails(
            playlist: playlist,
            videos: videos,
            // Vous pouvez ajouter ici des callbacks pour onVideoTap, onVideoRemove, onEdit, onDelete si nécessaire
            onVideoTap: (video) {
               // Naviguer vers le lecteur vidéo
               Navigator.pushNamed(context, '/video', arguments: video);
            },
            // showActions: true, // Afficher les boutons d'action si l'utilisateur a le droit de modifier la playlist
          );
        },
      ),
    );
  }
} 