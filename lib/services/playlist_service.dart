import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/playlist.dart';
import '../models/video.dart';

class PlaylistService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'playlists';

  // Créer une nouvelle playlist
  Future<Playlist> createPlaylist({
    required String title,
    required String description,
    required String category,
    required String difficulty,
    required String creatorId,
    bool isPublic = true,
  }) async {
    final docRef = _firestore.collection(_collection).doc();
    final playlist = Playlist(
      id: docRef.id,
      title: title,
      description: description,
      videoIds: [],
      category: category,
      difficulty: difficulty,
      creatorId: creatorId,
      createdAt: DateTime.now(),
      isPublic: isPublic,
    );

    await docRef.set(playlist.toFirestore());
    return playlist;
  }

  // Récupérer une playlist par son ID
  Future<Playlist?> getPlaylist(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (!doc.exists) return null;
    return Playlist.fromFirestore(doc.data()!);
  }

  // Récupérer toutes les playlists d'un utilisateur
  Future<List<Playlist>> getUserPlaylists(String userId) async {
    final querySnapshot = await _firestore
        .collection(_collection)
        .where('creatorId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) => Playlist.fromFirestore(doc.data()))
        .toList();
  }

  // Récupérer les playlists publiques
  Future<List<Playlist>> getPublicPlaylists() async {
    final querySnapshot = await _firestore
        .collection(_collection)
        .where('isPublic', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) => Playlist.fromFirestore(doc.data()))
        .toList();
  }

  // Mettre à jour une playlist
  Future<void> updatePlaylist(Playlist playlist) async {
    await _firestore
        .collection(_collection)
        .doc(playlist.id)
        .update(playlist.toFirestore());
  }

  // Supprimer une playlist
  Future<void> deletePlaylist(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }

  // Ajouter une vidéo à une playlist
  Future<void> addVideoToPlaylist(String playlistId, String videoId) async {
    final playlist = await getPlaylist(playlistId);
    if (playlist == null) throw Exception('Playlist non trouvée');

    final updatedVideoIds = List<String>.from(playlist.videoIds)..add(videoId);
    final updatedPlaylist = playlist.copyWith(
      videoIds: updatedVideoIds,
      videoCount: updatedVideoIds.length,
    );

    await updatePlaylist(updatedPlaylist);
  }

  // Retirer une vidéo d'une playlist
  Future<void> removeVideoFromPlaylist(String playlistId, String videoId) async {
    final playlist = await getPlaylist(playlistId);
    if (playlist == null) throw Exception('Playlist non trouvée');

    final updatedVideoIds = List<String>.from(playlist.videoIds)
      ..remove(videoId);
    final updatedPlaylist = playlist.copyWith(
      videoIds: updatedVideoIds,
      videoCount: updatedVideoIds.length,
    );

    await updatePlaylist(updatedPlaylist);
  }

  // Récupérer les vidéos d'une playlist
  Future<List<Video>> getPlaylistVideos(String playlistId) async {
    final playlist = await getPlaylist(playlistId);
    if (playlist == null) throw Exception('Playlist non trouvée');

    final videos = <Video>[];
    for (final videoId in playlist.videoIds) {
      final videoDoc = await _firestore.collection('videos').doc(videoId).get();
      if (videoDoc.exists) {
        videos.add(Video.fromFirestore(videoDoc.data()!));
      }
    }

    return videos;
  }

  // Rechercher des playlists
  Future<List<Playlist>> searchPlaylists(String query) async {
    final querySnapshot = await _firestore
        .collection(_collection)
        .where('isPublic', isEqualTo: true)
        .get();

    return querySnapshot.docs
        .map((doc) => Playlist.fromFirestore(doc.data()))
        .where((playlist) =>
            playlist.title.toLowerCase().contains(query.toLowerCase()) ||
            playlist.description.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  // Récupérer les playlists par catégorie
  Future<List<Playlist>> getPlaylistsByCategory(String category) async {
    final querySnapshot = await _firestore
        .collection(_collection)
        .where('category', isEqualTo: category)
        .where('isPublic', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) => Playlist.fromFirestore(doc.data()))
        .toList();
  }

  // Récupérer les playlists par niveau de difficulté
  Future<List<Playlist>> getPlaylistsByDifficulty(String difficulty) async {
    final querySnapshot = await _firestore
        .collection(_collection)
        .where('difficulty', isEqualTo: difficulty)
        .where('isPublic', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) => Playlist.fromFirestore(doc.data()))
        .toList();
  }
} 