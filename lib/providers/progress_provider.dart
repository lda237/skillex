import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_progress.dart';
import '../models/video.dart';
import '../models/video_progress.dart';

class ProgressProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  UserProgress? _userProgress;
  final Map<String, VideoProgress> _videoProgresses = {};
  bool _isLoading = false;
  String? _error;

  // Getters
  UserProgress? get userProgress => _userProgress;
  Map<String, VideoProgress> get videoProgresses => _videoProgresses;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // UserProgress getters
  int get completedVideos => _userProgress?.completedVideos.length ?? 0;
  int get totalWatchTime => _userProgress?.totalWatchTime ?? 0;
  List<String> get achievements => _userProgress?.badges ?? [];
  List<String> get favoriteVideoIds => _userProgress?.favoriteVideoIds ?? [];

  bool isFavorite(String videoId) => favoriteVideoIds.contains(videoId);

  double get overallProgress => _userProgress != null && _videoProgresses.isNotEmpty
      ? (_userProgress!.completedVideos.length / _videoProgresses.length * 100)
      : 0;
      
  List<Video> get inProgressVideos => _videoProgresses.values
      .where((progress) => progress.isCompleted == false)
      .map((progress) => Video(
            id: progress.videoId,
            title: '',
            description: '',
            thumbnailUrl: '',
            category: '',
            viewCount: 0,
            publishedAt: DateTime.now(),
            channelTitle: '',
            duration: 0,
            youtubeId: progress.videoId,
          ))
      .toList();
      
  List<Map<String, dynamic>> get watchHistory => _videoProgresses.values
      .map((progress) => {
            'videoId': progress.videoId,
            'title': '',
            'thumbnail': '',
            'progress': (progress.watchTime / progress.totalDuration * 100),
            'watchedAt': progress.lastWatched,
          })
      .toList();

  // Initialiser les données de progression
  Future<void> loadUserProgress() async {
    final user = _auth.currentUser;
    if (user == null) return;

    _setLoading(true);
    _setError(null);

    try {
      await _loadUserProgress();
      await _loadVideoProgresses();
    } catch (e) {
      _setError('Erreur lors du chargement de la progression: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Charger la progression globale de l'utilisateur
  Future<void> _loadUserProgress() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final doc = await _firestore
        .collection('user_progress')
        .doc(user.uid)
        .get();

    if (doc.exists) {
      _userProgress = UserProgress.fromFirestore(doc.data()!);
    } else {
      // Créer une nouvelle progression utilisateur
      _userProgress = UserProgress(
        userId: user.uid,
        totalWatchTime: 0,
        videosWatched: 0,
        completedVideos: [],
        favoriteVideoIds: [], // Initialiser la liste des favoris
        badges: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _saveUserProgress();
    }
  }

  // Charger les progressions de toutes les vidéos
  Future<void> _loadVideoProgresses() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final querySnapshot = await _firestore
        .collection('video_progress')
        .where('userId', isEqualTo: user.uid)
        .get();

    _videoProgresses.clear();
    for (final doc in querySnapshot.docs) {
      final progress = VideoProgress.fromFirestore(doc.data());
      _videoProgresses[progress.videoId] = progress;
    }
  }

  // --- FAVORITES LOGIC ---

  Future<void> addFavorite(String videoId) async {
    final user = _auth.currentUser;
    if (user == null || _userProgress == null) return;

    try {
      // Mettre à jour l'état local
      _userProgress!.favoriteVideoIds.add(videoId);
      notifyListeners();

      // Mettre à jour Firestore
      await _firestore.collection('user_progress').doc(user.uid).update({
        'favoriteVideoIds': FieldValue.arrayUnion([videoId])
      });
    } catch (e) {
      _setError('Erreur lors de l\'ajout aux favoris: ${e.toString()}');
      // Annuler le changement local en cas d'erreur
      _userProgress!.favoriteVideoIds.remove(videoId);
      notifyListeners();
    }
  }

  Future<void> removeFavorite(String videoId) async {
    final user = _auth.currentUser;
    if (user == null || _userProgress == null) return;

    try {
      // Mettre à jour l'état local
      _userProgress!.favoriteVideoIds.remove(videoId);
      notifyListeners();

      // Mettre à jour Firestore
      await _firestore.collection('user_progress').doc(user.uid).update({
        'favoriteVideoIds': FieldValue.arrayRemove([videoId])
      });
    } catch (e) {
      _setError('Erreur lors de la suppression des favoris: ${e.toString()}');
      // Annuler le changement local en cas d'erreur
      _userProgress!.favoriteVideoIds.add(videoId);
      notifyListeners();
    }
  }

  // --- VIDEO PROGRESS LOGIC ---

  VideoProgress? getVideoProgress(String videoId) {
    return _videoProgresses[videoId];
  }

  Future<void> updateVideoProgress({
    required String videoId,
    required int currentTime,
    required int totalDuration,
    bool? isCompleted,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final progress = _videoProgresses[videoId] ?? VideoProgress(
        userId: user.uid,
        videoId: videoId,
        watchTime: 0,
        totalDuration: totalDuration,
        isCompleted: false,
        lastWatched: DateTime.now(),
        createdAt: DateTime.now(),
      );

      progress.watchTime = currentTime;
      progress.totalDuration = totalDuration;
      progress.lastWatched = DateTime.now();
      
      if (isCompleted != null) {
        progress.isCompleted = isCompleted;
      } else {
        final progressPercentage = (currentTime / totalDuration) * 100;
        progress.isCompleted = progressPercentage >= 90;
      }

      await _firestore
          .collection('video_progress')
          .doc('${user.uid}_$videoId')
          .set(progress.toFirestore());

      _videoProgresses[videoId] = progress;

      await _updateUserProgressStats();
      
      notifyListeners();
    } catch (e) {
      _setError('Erreur lors de la mise à jour: ${e.toString()}');
    }
  }

  Future<void> markVideoAsCompleted(String videoId, int totalDuration) async {
    await updateVideoProgress(
      videoId: videoId,
      currentTime: totalDuration,
      totalDuration: totalDuration,
      isCompleted: true,
    );
  }

  Future<void> _updateUserProgressStats() async {
    if (_userProgress == null) return;

    final completedVideos = _videoProgresses.values
        .where((progress) => progress.isCompleted)
        .toList();

    final totalWatchTime = _videoProgresses.values
        .fold<int>(0, (total, progress) => total + progress.watchTime);

    _userProgress = _userProgress!.copyWith(
      totalWatchTime: totalWatchTime,
      videosWatched: _videoProgresses.length,
      completedVideos: completedVideos.map((p) => p.videoId).toList(),
      updatedAt: DateTime.now(),
    );

    await _checkAndAwardBadges();
    await _saveUserProgress();
  }

  Future<void> _checkAndAwardBadges() async {
    if (_userProgress == null) return;

    final newBadges = <String>[];
    final currentBadges = _userProgress!.badges;

    if (_userProgress!.videosWatched >= 1 && !currentBadges.contains('first_video')) {
      newBadges.add('first_video');
    }
    if (_userProgress!.videosWatched >= 10 && !currentBadges.contains('video_explorer')) {
      newBadges.add('video_explorer');
    }
    if (_userProgress!.videosWatched >= 50 && !currentBadges.contains('video_master')) {
      newBadges.add('video_master');
    }
    if (_userProgress!.totalWatchTime >= 18000 && !currentBadges.contains('time_keeper')) {
      newBadges.add('time_keeper');
    }
    if (_userProgress!.totalWatchTime >= 72000 && !currentBadges.contains('dedicated_learner')) {
      newBadges.add('dedicated_learner');
    }

    if (newBadges.isNotEmpty) {
      _userProgress = _userProgress!.copyWith(
        badges: [...currentBadges, ...newBadges],
      );
    }
  }

  Map<String, dynamic> getProgressStats() {
    if (_userProgress == null) return {};

    final completedCount = _userProgress!.completedVideos.length;
    final totalCount = _videoProgresses.length;
    final completionRate = totalCount > 0 ? (completedCount / totalCount) * 100 : 0.0;

    return {
      'totalWatchTime': _userProgress!.totalWatchTime,
      'videosWatched': _userProgress!.videosWatched,
      'completedVideos': completedCount,
      'completionRate': completionRate,
      'badges': _userProgress!.badges.length,
    };
  }

  String getFormattedWatchTime() {
    if (_userProgress == null) return '0min';
    
    final hours = _userProgress!.totalWatchTime ~/ 3600;
    final minutes = (_userProgress!.totalWatchTime % 3600) ~/ 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}min';
    } else {
      return '${minutes}min';
    }
  }

  Future<void> _saveUserProgress() async {
    if (_userProgress == null) return;

    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('user_progress')
        .doc(user.uid)
        .set(_userProgress!.toFirestore());
  }

  List<String> getRecentlyWatchedVideos({int limit = 10}) {
    final recentVideos = _videoProgresses.values.toList();
    recentVideos.sort((a, b) => b.lastWatched.compareTo(a.lastWatched));
    return recentVideos.take(limit).map((p) => p.videoId).toList();
  }

  double getVideoProgressPercentage(String videoId) {
    final progress = _videoProgresses[videoId];
    if (progress == null || progress.totalDuration == 0) return 0.0;
    
    return (progress.watchTime / progress.totalDuration) * 100;
  }

  Future<void> resetVideoProgress(String videoId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('video_progress')
          .doc('${user.uid}_$videoId')
          .delete();

      _videoProgresses.remove(videoId);
      await _updateUserProgressStats();
      
      notifyListeners();
    } catch (e) {
      _setError('Erreur lors de la réinitialisation: ${e.toString()}');
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void clearProgress() {
    _userProgress = null;
    _videoProgresses.clear();
    _setError(null);
    notifyListeners();
  }
}
