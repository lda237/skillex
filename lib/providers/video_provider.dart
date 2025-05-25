import 'package:flutter/foundation.dart';
import '../models/video.dart';
import '../services/youtube_service.dart';

class VideoProvider with ChangeNotifier {
  late final YoutubeService _youtubeService;

  VideoProvider({YoutubeService? youtubeService})
      : _youtubeService = youtubeService ?? YoutubeService();
  
  List<Video> _videos = [];
  List<Video> _filteredVideos = [];
  List<String> _categories = [];
  String _selectedCategory = 'Tous';
  String _searchQuery = '';
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Video> get videos => _filteredVideos;
  List<String> get categories => ['Tous', ..._categories];
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Charger toutes les vidéos
  Future<void> loadVideos() async {
    _setLoading(true);
    _setError(null);

    try {
      _videos = await _youtubeService.fetchVideos();
      _extractCategories();
      _applyFilters();
    } catch (e) {
      _setError('Erreur lors du chargement des vidéos: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Rechercher des vidéos
  void searchVideos(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilters();
    notifyListeners();
  }

  // Filtrer par catégorie
  void filterByCategory(String category) {
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }

  // Obtenir une vidéo par ID
  Video? getVideoById(String id) {
    try {
      return _videos.firstWhere((video) => video.id == id);
    } catch (e) {
      return null;
    }
  }

  // Obtenir les vidéos recommandées
  List<Video> getRecommendedVideos(String currentVideoId, {int limit = 5}) {
    final currentVideo = getVideoById(currentVideoId);
    if (currentVideo == null) return [];

    return _videos
        .where((video) => 
            video.id != currentVideoId && 
            video.category == currentVideo.category)
        .take(limit)
        .toList();
  }

  // Obtenir les vidéos populaires
  List<Video> getPopularVideos({int limit = 10}) {
    final sortedVideos = List<Video>.from(_videos);
    sortedVideos.sort((a, b) => b.viewCount.compareTo(a.viewCount));
    return sortedVideos.take(limit).toList();
  }

  // Obtenir les vidéos récentes
  List<Video> getRecentVideos({int limit = 10}) {
    final sortedVideos = List<Video>.from(_videos);
    sortedVideos.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    return sortedVideos.take(limit).toList();
  }

  // Méthodes privées
  void _extractCategories() {
    final categorySet = <String>{};
    for (final video in _videos) {
      categorySet.add(video.category);
    }
    _categories = categorySet.toList()..sort();
  }

  void _applyFilters() {
    _filteredVideos = _videos.where((video) {
      final matchesCategory = _selectedCategory == 'Tous' || 
                            video.category == _selectedCategory;
      
      final matchesSearch = _searchQuery.isEmpty ||
                          video.title.toLowerCase().contains(_searchQuery) ||
                          video.description.toLowerCase().contains(_searchQuery) ||
                          video.category.toLowerCase().contains(_searchQuery);

      return matchesCategory && matchesSearch;
    }).toList();

    // Trier par popularité par défaut
    _filteredVideos.sort((a, b) => b.viewCount.compareTo(a.viewCount));
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  // Rafraîchir les données
  Future<void> refresh() async {
    await loadVideos();
  }

  // Nettoyer les filtres
  void clearFilters() {
    _selectedCategory = 'Tous';
    _searchQuery = '';
    _applyFilters();
    notifyListeners();
  }
}