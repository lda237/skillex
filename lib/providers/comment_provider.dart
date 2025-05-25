import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/comment.dart'; // Adjust path if needed

class CommentProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Comment> _comments = [];
  bool _isLoading = false;
  String? _error;
  DocumentSnapshot? _lastDocument; // For pagination
  bool _hasMoreComments = true;

  // Getters
  List<Comment> get comments => _comments;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMoreComments => _hasMoreComments;

  // Fetch comments for a video
  Future<void> fetchComments(String videoId, {int limit = 10}) async {
    if (_isLoading) return;
    _setLoading(true);
    _setError(null);
    _lastDocument = null; // Reset for a fresh fetch/refresh
    _comments.clear(); // Clear previous comments for a new video or refresh
    _hasMoreComments = true;

    try {
      Query query = _firestore
          .collection('videos')
          .doc(videoId)
          .collection('comments')
          .orderBy('timestamp', descending: true) // Show newest first
          .limit(limit);

      final snapshot = await query.get();
      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
        _comments = snapshot.docs.map((doc) => Comment.fromFirestore(doc)).toList();
      } else {
        _lastDocument = null;
        _hasMoreComments = false;
      }
    } catch (e) {
      _setError('Erreur lors du chargement des commentaires: ${e.toString()}');
      _hasMoreComments = false;
    } finally {
      _setLoading(false);
    }
  }

  // Fetch more comments for pagination
  Future<void> fetchMoreComments(String videoId, {int limit = 10}) async {
    if (_isLoading || !_hasMoreComments || _lastDocument == null) return;
    _setLoading(true, notify: true); // Notify for incremental loading state

    try {
      Query query = _firestore
          .collection('videos')
          .doc(videoId)
          .collection('comments')
          .orderBy('timestamp', descending: true)
          .startAfterDocument(_lastDocument!)
          .limit(limit);

      final snapshot = await query.get();
      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
        _comments.addAll(snapshot.docs.map((doc) => Comment.fromFirestore(doc)).toList());
      } else {
        _lastDocument = null; // No more documents
        _hasMoreComments = false;
      }
    } catch (e) {
      _setError('Erreur lors du chargement de plus de commentaires: ${e.toString()}');
       // Optionally keep _hasMoreComments as true to allow retry, or set to false
    } finally {
      _setLoading(false); // This will notify listeners due to setLoading
    }
  }

  // Add a new comment
  Future<bool> addComment({
    required String videoId,
    required String text,
    required String userId,
    required String userName,
    String? userProfilePicUrl,
  }) async {
    if (text.trim().isEmpty) {
      _setError('Le commentaire ne peut pas être vide.');
      return false;
    }
    _setLoading(true); // Consider a specific loading state for adding comment
    _setError(null);

    try {
      final newCommentData = {
        'videoId': videoId,
        'userId': userId,
        'userName': userName,
        'userProfilePicUrl': userProfilePicUrl,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(), // Use server timestamp
        'likesCount': 0,
        'isEdited': false,
      };

      // Add to the video's subcollection
      DocumentReference docRef = await _firestore
          .collection('videos')
          .doc(videoId)
          .collection('comments')
          .add(newCommentData);
      
      // Optionally add to a global comments collection if needed for other queries,
      // but typically subcollections are fine.

      // To reflect the change immediately, we can create a temporary Comment object
      // or re-fetch. For simplicity, let's prepend the new comment (optimistic update)
      // or trigger a re-fetch. Re-fetching might be simpler to ensure data consistency.
      // For now, let's just clear and reload the first page of comments.
      // A more advanced approach would be to insert it locally.
      await fetchComments(videoId); // Refresh comments after adding
      
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Erreur lors de l'ajout du commentaire: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  void _setLoading(bool loading, {bool notify = true}) {
    _isLoading = loading;
    if (notify) notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    // Optionally notifyListeners here if error display is immediate
    // For now, error is typically checked after an operation
  }

  // Consider adding methods for deleting and editing comments in the future.
}
