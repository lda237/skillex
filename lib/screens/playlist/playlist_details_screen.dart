import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Added import
import 'package:provider/provider.dart';
import '../../providers/playlist_provider.dart';
import '../../agents/ui/playlist_details.dart';
import '../../widgets/common_error_widget.dart';
import '../../widgets/playlist_details_skeleton_widget.dart'; // Added import

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
    final playlistProvider = Provider.of<PlaylistProvider>(context, listen: true); // Listen to provider for title updates

    return Scaffold(
      appBar: AppBar(
        title: Text(
          playlistProvider.currentPlaylist?.title ?? 'Détails de la Playlist',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Consumer<PlaylistProvider>( // Keep consumer for body, or use the one above if it doesn't cause issues
        builder: (context, playlistProviderForBody, child) { // Renamed to avoid conflict if needed
          // Use playlistProviderForBody for the body's logic
          if ((playlistProviderForBody.isLoading && playlistProviderForBody.currentPlaylist == null) ||
              (playlistProviderForBody.isLoading && playlistProviderForBody.currentPlaylist != null && playlistProviderForBody.currentPlaylistVideos.isEmpty)) {
            return const PlaylistDetailsSkeletonWidget();
          }

          // Afficher un message d'erreur si quelque chose ne va pas
          if (playlistProviderForBody.error != null && playlistProviderForBody.currentPlaylist == null) {
            return CommonErrorWidget(
              errorMessage: playlistProviderForBody.error!,
              onRetry: () {
                // Use the initial provider instance or re-fetch with listen:false
                Provider.of<PlaylistProvider>(context, listen: false).loadPlaylist(widget.playlistId);
              },
            );
          }

          // Si la playlist est chargée, afficher les détails
          final playlist = playlistProviderForBody.currentPlaylist!;
          final videos = playlistProviderForBody.currentPlaylistVideos;

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