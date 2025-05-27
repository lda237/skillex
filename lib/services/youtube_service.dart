import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/video.dart';
import '../config/api_config.dart';

class YoutubeService {
  static const String _baseUrl = 'https://www.googleapis.com/youtube/v3';
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late SharedPreferences _prefs;
  static const String _cacheKey = 'cached_videos';
  static const Duration _cacheDuration = Duration(hours: 1);

  YoutubeService() {
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Vérifier la configuration
  void _checkConfiguration() {
    if (!ApiConfig.isConfigured) {
      throw Exception('Les clés API ne sont pas configurées correctement');
    }
  }

  // Récupérer les vidéos avec cache
  Future<List<Video>> fetchVideos() async {
    try {
      _checkConfiguration();
      
      // Vérifier le cache
      final cachedVideos = await _getCachedVideos();
      if (cachedVideos != null) {
        return cachedVideos;
      }

      // Si pas de cache, récupérer depuis Firestore
      final querySnapshot = await _firestore
          .collection('videos')
          .orderBy('publishedAt', descending: true)
          .get();

      if (querySnapshot.docs.isEmpty) {
        // Si aucune vidéo en base, essayer de récupérer depuis YouTube
        final videos = await _fetchFromYouTubeAndStore();
        await _cacheVideos(videos);
        return videos;
      }

      final videos = querySnapshot.docs
          .map((doc) => Video.fromFirestore(doc.data()))
          .toList();
      
      await _cacheVideos(videos);
      return videos;
    } catch (e) {
      debugPrint('Erreur lors de la récupération des vidéos: $e');
      // En cas d'erreur, essayer de récupérer depuis le cache
      final cachedVideos = await _getCachedVideos();
      if (cachedVideos != null) {
        return cachedVideos;
      }
      // Si pas de cache, retourner les vidéos mock
      return _getMockVideos();
    }
  }

  // Gestion du cache
  Future<List<Video>?> _getCachedVideos() async {
    try {
      final cachedData = _prefs.getString(_cacheKey);
      if (cachedData == null) return null;

      final Map<String, dynamic> cache = json.decode(cachedData);
      final timestamp = DateTime.parse(cache['timestamp']);
      
      if (DateTime.now().difference(timestamp) > _cacheDuration) {
        await _prefs.remove(_cacheKey);
        return null;
      }

      final List<dynamic> videosJson = cache['videos'];
      return videosJson.map((json) => Video.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Erreur lors de la récupération du cache: $e');
      return null;
    }
  }

  Future<void> _cacheVideos(List<Video> videos) async {
    try {
      final cache = {
        'timestamp': DateTime.now().toIso8601String(),
        'videos': videos.map((v) => v.toJson()).toList(),
      };
      await _prefs.setString(_cacheKey, json.encode(cache));
    } catch (e) {
      debugPrint('Erreur lors de la mise en cache: $e');
    }
  }

  // Récupérer depuis YouTube API avec retry
  Future<List<Video>> _fetchFromYouTubeAndStore() async {
    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        final channelId = ApiConfig.youtubeChannelId;
        final url = '$_baseUrl/search?part=snippet&channelId=$channelId&maxResults=50&type=video&key=${ApiConfig.youtubeApiKey}';
        
        final response = await http.get(Uri.parse(url));
        if (response.statusCode != 200) {
          throw Exception('Erreur API YouTube: ${response.statusCode}');
        }

        final data = json.decode(response.body);
        final items = data['items'] as List;
        
        final videos = <Video>[];
        for (final item in items) {
          final videoId = item['id']['videoId'];
          final video = await _fetchVideoDetails(videoId);
          if (video != null) {
            videos.add(video);
            await _storeVideoInFirestore(video);
          }
        }

        return videos;
      } catch (e) {
        retryCount++;
        if (retryCount == maxRetries) {
          debugPrint('Échec après $maxRetries tentatives: $e');
          return _getMockVideos();
        }
        await Future.delayed(Duration(seconds: retryCount * 2));
      }
    }
    return _getMockVideos();
  }

  // Récupérer les détails d'une vidéo YouTube
  Future<Video?> _fetchVideoDetails(String videoId) async {
    try {
      final url = '$_baseUrl/videos?part=snippet,contentDetails,statistics&id=$videoId&key=${ApiConfig.youtubeApiKey}';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List;
        
        if (items.isNotEmpty) {
          return Video.fromYouTubeApi(items.first);
        }
      }
      return null;
    } catch (e) {
      debugPrint('Erreur lors de la récupération de la vidéo $videoId: $e');
      return null;
    }
  }

  // Stocker une vidéo en Firestore
  Future<void> _storeVideoInFirestore(Video video) async {
    try {
      await _firestore
          .collection('videos')
          .doc(video.id)
          .set(video.toFirestore());
    } catch (e) {
      debugPrint('Erreur lors du stockage de la vidéo: $e');
    }
  }

  // Ajouter une nouvelle vidéo manuellement
  Future<void> addVideo({
    required String youtubeId,
    required String title,
    required String description,
    required String category,
    required String difficulty,
    bool isPremium = false,
    List<String> tags = const [],
  }) async {
    try {
      // Essayer de récupérer les détails depuis YouTube
      Video? video = await _fetchVideoDetails(youtubeId);
      
      if (video == null) {
        // Créer manuellement si l'API YouTube n'est pas disponible
        video = Video(
          id: youtubeId,
          title: title,
          description: description,
          thumbnailUrl: 'https://img.youtube.com/vi/$youtubeId/maxresdefault.jpg',
          category: category,
          duration: 0, // À mettre à jour manuellement
          viewCount: 0,
          publishedAt: DateTime.now(),
          youtubeId: youtubeId,
          channelTitle: 'Skillex',
          tags: tags,
          difficulty: difficulty,
          isPremium: isPremium,
        );
      } else {
        // Mettre à jour avec les informations personnalisées
        video = video.copyWith(
          category: category,
          difficulty: difficulty,
          isPremium: isPremium,
          tags: tags.isNotEmpty ? tags : video.tags,
        );
      }

      await _storeVideoInFirestore(video);
    } catch (e) {
      throw Exception('Erreur lors de l\'ajout de la vidéo: $e');
    }
  }

  // Rechercher des vidéos
  Future<List<Video>> searchVideos(String query) async {
    try {
      final querySnapshot = await _firestore
          .collection('videos')
          .where('tags', arrayContains: query.toLowerCase())
          .get();

      final results = querySnapshot.docs
          .map((doc) => Video.fromFirestore(doc.data()))
          .toList();

      // Si pas de résultats avec les tags, rechercher dans le titre
      if (results.isEmpty) {
        final allVideos = await fetchVideos();
        return allVideos.where((video) =>
            video.title.toLowerCase().contains(query.toLowerCase()) ||
            video.description.toLowerCase().contains(query.toLowerCase()) ||
            video.category.toLowerCase().contains(query.toLowerCase())
        ).toList();
      }

      return results;
    } catch (e) {
      throw Exception('Erreur lors de la recherche: $e');
    }
  }

  // Récupérer les vidéos par catégorie
  Future<List<Video>> getVideosByCategory(String category) async {
    try {
      final querySnapshot = await _firestore
          .collection('videos')
          .where('category', isEqualTo: category)
          .orderBy('publishedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Video.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération par catégorie: $e');
    }
  }

  // Récupérer les catégories disponibles
  Future<List<String>> getCategories() async {
    try {
      final querySnapshot = await _firestore.collection('videos').get();
      final categories = <String>{};
      
      for (final doc in querySnapshot.docs) {
        final video = Video.fromFirestore(doc.data());
        categories.add(video.category);
      }
      
      return categories.toList()..sort();
    } catch (e) {
      return ['Programmation', 'Design', 'Marketing', 'Business'];
    }
  }

  // Mettre à jour le nombre de vues
  Future<void> incrementViewCount(String videoId) async {
    try {
      final docRef = _firestore.collection('videos').doc(videoId);
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (snapshot.exists) {
          final currentViews = snapshot.data()?['viewCount'] ?? 0;
          transaction.update(docRef, {'viewCount': currentViews + 1});
        }
      });
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour des vues: $e');
    }
  }

  // Obtenir l'URL de la thumbnail sécurisée
  String getSecureThumbnailUrl(String youtubeId) {
    return 'https://img.youtube.com/vi/$youtubeId/maxresdefault.jpg';
  }

  // Valider si une vidéo YouTube existe
  Future<bool> validateYouTubeVideo(String youtubeId) async {
    try {
      final url = '$_baseUrl/videos?part=id&id=$youtubeId&key=${ApiConfig.youtubeApiKey}';
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List;
        return items.isNotEmpty;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Données d'exemple pour le développement
  List<Video> _getMockVideos() {
    return [
      Video(
        id: '1',
        title: 'Introduction à Flutter',
        description: 'Apprenez les bases de Flutter pour créer des applications mobiles.',
        thumbnailUrl: 'https://img.youtube.com/vi/1gDhl4leEzA/maxresdefault.jpg',
        category: 'Programmation',
        duration: 1800, // 30 minutes
        viewCount: 15420,
        publishedAt: DateTime.now().subtract(const Duration(days: 7)),
        youtubeId: '1gDhl4leEzA',
        channelTitle: 'Skillex',
        tags: ['flutter', 'mobile', 'développement'],
        difficulty: 'Débutant',
      ),
      Video(
        id: '2',
        title: 'Design UI/UX Moderne',
        description: 'Créez des interfaces utilisateur modernes et intuitives.',
        thumbnailUrl: 'https://img.youtube.com/vi/c9Wg6Cb_YlU/maxresdefault.jpg',
        category: 'Design',
        duration: 2400, // 40 minutes
        viewCount: 8730,
        publishedAt: DateTime.now().subtract(const Duration(days: 3)),
        youtubeId: 'c9Wg6Cb_YlU',
        channelTitle: 'Skillex',
        tags: ['design', 'ui', 'ux'],
        difficulty: 'Intermédiaire',
      ),
      Video(
        id: '3',
        title: 'Marketing Digital Avancé',
        description: 'Stratégies avancées de marketing digital pour votre business.',
        thumbnailUrl: 'https://img.youtube.com/vi/fRh_vgS2dFE/maxresdefault.jpg',
        category: 'Marketing',
        duration: 3600, // 1 heure
        viewCount: 12350,
        publishedAt: DateTime.now().subtract(const Duration(days: 1)),
        youtubeId: 'fRh_vgS2dFE',
        channelTitle: 'Skillex',
        tags: ['marketing', 'digital', 'stratégie'],
        difficulty: 'Avancé',
        isPremium: true,
      ),
    ];
  }

  // Méthode pour récupérer les vidéos populaires
  Future<List<Video>> getPopularVideos() async {
    try {
      final url = '$_baseUrl/videos?part=snippet,contentDetails,statistics&chart=mostPopular&maxResults=10&key=${ApiConfig.youtubeApiKey}';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List;
        
        return items.map((item) => Video.fromYouTubeApi(item)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Erreur lors de la récupération des vidéos populaires: $e');
      return [];
    }
  }

  // Méthode pour récupérer les vidéos d'une playlist
  Future<List<Video>> getPlaylistVideos(String playlistId) async {
    try {
      final url = '$_baseUrl/playlistItems?part=snippet&playlistId=$playlistId&maxResults=50&key=${ApiConfig.youtubeApiKey}';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List;
        
        final videos = <Video>[];
        for (final item in items) {
          final videoId = item['snippet']['resourceId']['videoId'];
          final video = await _fetchVideoDetails(videoId);
          if (video != null) {
            videos.add(video);
          }
        }
        return videos;
      }
      return [];
    } catch (e) {
      debugPrint('Erreur lors de la récupération des vidéos de la playlist: $e');
      return [];
    }
  }

  // Méthode pour rechercher des vidéos sur YouTube
  Future<List<Video>> searchYouTubeVideos(String query) async {
    try {
      final url = '$_baseUrl/search?part=snippet&q=$query&type=video&maxResults=10&key=${ApiConfig.youtubeApiKey}';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List;
        
        final videos = <Video>[];
        for (final item in items) {
          final videoId = item['id']['videoId'];
          final video = await _fetchVideoDetails(videoId);
          if (video != null) {
            videos.add(video);
          }
        }
        return videos;
      }
      return [];
    } catch (e) {
      debugPrint('Erreur lors de la recherche YouTube: $e');
      return [];
    }
  }

  // Récupérer les détails d'une vidéo YouTube et la sauvegarder dans Firestore
  Future<void> fetchVideoDetailsAndSave(String videoId, {String? customDescription}) async {
    try {
      final video = await _fetchVideoDetails(videoId);
      if (video != null) {
        // Créer un document dans Firestore avec les détails de la vidéo
        final videoDocRef = _firestore.collection('videos').doc(video.id);

        // Vous pourriez vouloir ajouter la description personnalisée ici si elle est fournie
        final videoData = video.toFirestore();
        if (customDescription != null && customDescription.isNotEmpty) {
           videoData['description'] = customDescription; // Écrase la description de l'API ou ajoute-la
        }

        await videoDocRef.set(videoData, SetOptions(merge: true)); // Utiliser merge pour ne pas écraser les champs existants si le doc existe
        debugPrint('Vidéo ID: $videoId sauvegardée dans Firestore.');
      } else {
        throw Exception('Impossible de récupérer les détails de la vidéo YouTube: $videoId');
      }
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde de la vidéo dans Firestore: $e');
      rethrow; // Renvoyer l'erreur pour qu'elle soit gérée par l'écran d'administration
    }
  }
}