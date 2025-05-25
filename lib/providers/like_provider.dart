import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LikeProvider with ChangeNotifier {
  // final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Old way
  final FirebaseFirestore _firestore; // New way

  // Constructor for dependency injection
  LikeProvider({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  // Map to cache whether a user has liked a video to reduce Firestore reads.
  // Key: videoId, Value: bool (true if liked, false if not)
  // This could be further optimized by including userId in the key if provider is app-scoped.
  // For now, let's assume it's simple and might be re-fetched or cleared on user change.
  Map<String, bool> _userLikedStatusCache = {}; 

  bool hasUserLikedVideoSync(String videoId) {
    return _userLikedStatusCache[videoId] ?? false;
  }

  Future<bool> hasUserLikedVideo(String videoId, String userId) async {
    if (userId.isEmpty) return false; // Cannot determine like status for empty userId

    // Check cache first
    if (_userLikedStatusCache.containsKey(videoId)) {
      return _userLikedStatusCache[videoId]!;
    }

    try {
      final likeDocRef = _firestore
          .collection('videos')
          .doc(videoId)
          .collection('video_likes')
          .doc(userId);

      final docSnapshot = await likeDocRef.get();
      final liked = docSnapshot.exists;
      _userLikedStatusCache[videoId] = liked;
      notifyListeners(); // Notify if state changes from unknown to known
      return liked;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking if user liked video: $e');
      }
      // Assume not liked in case of error, or rethrow if critical
      return false;
    }
  }

  Future<void> toggleLikeVideo(String videoId, String userId) async {
    if (userId.isEmpty) {
      if (kDebugMode) {
        print('User ID is empty, cannot toggle like.');
      }
      return; 
    }

    final videoDocRef = _firestore.collection('videos').doc(videoId);
    final likeDocRef = videoDocRef.collection('video_likes').doc(userId);

    try {
      await _firestore.runTransaction((transaction) async {
        final videoSnapshot = await transaction.get(videoDocRef);
        final likeSnapshot = await transaction.get(likeDocRef);

        if (!videoSnapshot.exists) {
          throw Exception("Video document not found!");
        }

        int currentAppLikesCount = (videoSnapshot.data()?['appLikesCount'] ?? 0).toInt();

        if (likeSnapshot.exists) {
          // User has liked it, so unlike
          transaction.delete(likeDocRef);
          transaction.update(videoDocRef, {'appLikesCount': currentAppLikesCount - 1});
          _userLikedStatusCache[videoId] = false;
        } else {
          // User has not liked it, so like
          transaction.set(likeDocRef, {'timestamp': FieldValue.serverTimestamp()});
          transaction.update(videoDocRef, {'appLikesCount': currentAppLikesCount + 1});
          _userLikedStatusCache[videoId] = true;
        }
      });
      notifyListeners(); // Notify UI to rebuild (e.g., like button state, count)
    } catch (e) {
      if (kDebugMode) {
        print('Error toggling like status: $e');
      }
      // Optionally, rethrow or set an error state in the provider
    }
  }
  
  // Call this when user logs out or video context changes significantly
  void clearLikeCacheForVideo(String videoId) {
    _userLikedStatusCache.remove(videoId);
    notifyListeners();
  }

  void clearAllLikeCache() {
    _userLikedStatusCache.clear();
    notifyListeners();
  }
}
