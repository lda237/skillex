import 'package:flutter/foundation.dart';
import '../models/playlist.dart';
import '../models/video.dart';
import '../services/playlist_service.dart';

class PlaylistProvider with ChangeNotifier {
  final PlaylistService _playlistService = PlaylistService();
  List<Playlist> _playlists = [];
  Playlist? _currentPlaylist;
  List<Video> _currentPlaylistVideos = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Playlist> get playlists => _playlists;
  Playlist? get currentPlaylist => _currentPlaylist;
  List<Video> get currentPlaylistVideos => _currentPlaylistVideos;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Charger les playlists d'un utilisateur
  Future<void> loadUserPlaylists(String userId) async {
    _setLoading(true);
    try {
      _playlists = await _playlistService.getUserPlaylists(userId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Charger les playlists publiques
  Future<void> loadPublicPlaylists() async {
    _setLoading(true);
    try {
      _playlists = await _playlistService.getPublicPlaylists();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Créer une nouvelle playlist
  Future<void> createPlaylist({
    required String title,
    required String description,
    required String category,
    required String difficulty,
    required String creatorId,
    bool isPublic = true,
  }) async {
    _setLoading(true);
    try {
      final playlist = await _playlistService.createPlaylist(
        title: title,
        description: description,
        category: category,
        difficulty: difficulty,
        creatorId: creatorId,
        isPublic: isPublic,
      );
      _playlists.insert(0, playlist);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Charger une playlist spécifique
  Future<void> loadPlaylist(String playlistId) async {
    _setLoading(true);
    try {
      _currentPlaylist = await _playlistService.getPlaylist(playlistId);
      if (_currentPlaylist != null) {
        _currentPlaylistVideos = await _playlistService.getPlaylistVideos(playlistId);
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Mettre à jour une playlist
  Future<void> updatePlaylist(Playlist playlist) async {
    _setLoading(true);
    try {
      await _playlistService.updatePlaylist(playlist);
      final index = _playlists.indexWhere((p) => p.id == playlist.id);
      if (index != -1) {
        _playlists[index] = playlist;
      }
      if (_currentPlaylist?.id == playlist.id) {
        _currentPlaylist = playlist;
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Supprimer une playlist
  Future<void> deletePlaylist(String playlistId) async {
    _setLoading(true);
    try {
      await _playlistService.deletePlaylist(playlistId);
      _playlists.removeWhere((p) => p.id == playlistId);
      if (_currentPlaylist?.id == playlistId) {
        _currentPlaylist = null;
        _currentPlaylistVideos = [];
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Ajouter une vidéo à une playlist
  Future<void> addVideoToPlaylist(String playlistId, String videoId) async {
    _setLoading(true);
    try {
      await _playlistService.addVideoToPlaylist(playlistId, videoId);
      await loadPlaylist(playlistId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Retirer une vidéo d'une playlist
  Future<void> removeVideoFromPlaylist(String playlistId, String videoId) async {
    _setLoading(true);
    try {
      await _playlistService.removeVideoFromPlaylist(playlistId, videoId);
      await loadPlaylist(playlistId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Rechercher des playlists
  Future<void> searchPlaylists(String query) async {
    _setLoading(true);
    try {
      _playlists = await _playlistService.searchPlaylists(query);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Récupérer les playlists par catégorie
  Future<void> getPlaylistsByCategory(String category) async {
    _setLoading(true);
    try {
      _playlists = await _playlistService.getPlaylistsByCategory(category);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Récupérer les playlists par niveau de difficulté
  Future<void> getPlaylistsByDifficulty(String difficulty) async {
    _setLoading(true);
    try {
      _playlists = await _playlistService.getPlaylistsByDifficulty(difficulty);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Réinitialiser l'état
  void reset() {
    _playlists = [];
    _currentPlaylist = null;
    _currentPlaylistVideos = [];
    _error = null;
    notifyListeners();
  }

  // Mettre à jour l'état de chargement
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
} 