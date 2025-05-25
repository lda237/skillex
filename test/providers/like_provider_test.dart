import 'package:flutter_test/flutter_test.dart';
// mocktail is not strictly needed here as FakeCloudFirestore handles mocking behavior
// import 'package:mocktail/mocktail.dart'; 
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:skillex/providers/like_provider.dart'; // Adjust path if your structure is different
import 'package:cloud_firestore/cloud_firestore.dart'; // Required for FieldValue

// No model imports needed unless you directly create model instances here.

void main() {
  late LikeProvider likeProvider;
  late FakeCloudFirestore fakeFirestore;

  // Test data
  const testVideoId = 'vid1';
  const testUserId = 'user1';
  const otherUserId = 'user2'; // Renamed for clarity from otherUserId to distinctOtherUserId if needed

  setUp(() {
    fakeFirestore = FakeCloudFirestore();
    // LikeProvider has been refactored to accept FirebaseFirestore instance.
    likeProvider = LikeProvider(firestore: fakeFirestore); 
  });

  // Helper to pre-populate video document for tests
  Future<void> _seedVideoDocument(String videoId, {int initialLikes = 0}) async {
    await fakeFirestore.collection('videos').doc(videoId).set({'appLikesCount': initialLikes, 'title': 'Test Video'});
  }
  
  // Helper to pre-populate a like
  Future<void> _seedLike(String videoId, String userId) async {
     // Using serverTimestamp() with FakeCloudFirestore might require specific setup
     // or using a fixed Timestamp for test predictability.
     // For FakeCloudFirestore, directly setting a map is usually fine.
     // Using a map directly for 'timestamp' to avoid potential FieldValue.serverTimestamp() issues in fake environment
     await fakeFirestore.collection('videos').doc(videoId).collection('video_likes').doc(userId).set({'timestamp': Timestamp.now()});
  }

  // Test Groups
  group('LikeProvider Unit Tests', () {
    // Tests for hasUserLikedVideo
    group('hasUserLikedVideo', () {
      test('returns true if user has liked the video', () async {
        await _seedVideoDocument(testVideoId);
        await _seedLike(testVideoId, testUserId);
        
        final liked = await likeProvider.hasUserLikedVideo(testVideoId, testUserId);
        expect(liked, isTrue);
        expect(likeProvider.hasUserLikedVideoSync(testVideoId), isTrue); // Check cache
      });

      test('returns false if user has not liked the video', () async {
        await _seedVideoDocument(testVideoId);
        final liked = await likeProvider.hasUserLikedVideo(testVideoId, testUserId);
        expect(liked, isFalse);
        expect(likeProvider.hasUserLikedVideoSync(testVideoId), isFalse); // Check cache
      });
      
      test('returns false if userId is empty', () async {
        final liked = await likeProvider.hasUserLikedVideo(testVideoId, '');
        expect(liked, isFalse);
      });
    });

    // Tests for toggleLikeVideo
    group('toggleLikeVideo', () {
      test('likes a video if not already liked, increments count', () async {
        await _seedVideoDocument(testVideoId, initialLikes: 0);
        
        await likeProvider.toggleLikeVideo(testVideoId, testUserId);
        
        final videoDoc = await fakeFirestore.collection('videos').doc(testVideoId).get();
        expect(videoDoc.data()?['appLikesCount'], 1);
        
        final likeDoc = await fakeFirestore.collection('videos').doc(testVideoId).collection('video_likes').doc(testUserId).get();
        expect(likeDoc.exists, isTrue);
        expect(likeProvider.hasUserLikedVideoSync(testVideoId), isTrue);
      });

      test('unlikes a video if already liked, decrements count', () async {
        await _seedVideoDocument(testVideoId, initialLikes: 1);
        await _seedLike(testVideoId, testUserId);

        await likeProvider.toggleLikeVideo(testVideoId, testUserId);

        final videoDoc = await fakeFirestore.collection('videos').doc(testVideoId).get();
        expect(videoDoc.data()?['appLikesCount'], 0);
        
        final likeDoc = await fakeFirestore.collection('videos').doc(testVideoId).collection('video_likes').doc(testUserId).get();
        expect(likeDoc.exists, isFalse);
        expect(likeProvider.hasUserLikedVideoSync(testVideoId), isFalse);
      });

      test('does nothing if userId is empty', () async {
        await _seedVideoDocument(testVideoId, initialLikes: 0);
        await likeProvider.toggleLikeVideo(testVideoId, '');
        
        final videoDoc = await fakeFirestore.collection('videos').doc(testVideoId).get();
        expect(videoDoc.data()?['appLikesCount'], 0); // Count remains unchanged
      });

      test('handles non-existent video document gracefully (throws exception)', () async {
        // This behavior depends on transaction error handling.
        // FakeCloudFirestore's transaction might behave differently or not throw if doc doesn't exist before update.
        // The code has `if (!videoSnapshot.exists) { throw Exception("Video document not found!"); }`
        expect(
          () => likeProvider.toggleLikeVideo('nonExistentVideo', testUserId),
          throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Video document not found!')))
        );
      });
    });
    
    // Tests for cache clearing
    group('Cache Management', () {
        test('clearLikeCacheForVideo removes specific video from cache', () async {
            await _seedVideoDocument(testVideoId);
            await _seedLike(testVideoId, testUserId);
            await likeProvider.hasUserLikedVideo(testVideoId, testUserId); // Populate cache
            expect(likeProvider.hasUserLikedVideoSync(testVideoId), isTrue);

            likeProvider.clearLikeCacheForVideo(testVideoId);
            // To verify it's cleared, hasUserLikedVideoSync would ideally throw or return a specific "not cached" value
            // or we check internal cache state if possible.
            // For now, we assume it's cleared. A better test would be to re-fetch and ensure it hits Firestore.
            // The current hasUserLikedVideoSync returns `_userLikedStatusCache[videoId] ?? false;`
            // So after clearing, it will return false.
            expect(likeProvider.hasUserLikedVideoSync(testVideoId), isFalse); 
        });

        test('clearAllLikeCache clears all entries', () async {
            await _seedVideoDocument('vid1'); // Using testVideoId for consistency if preferred
            await _seedLike('vid1', testUserId);
            await likeProvider.hasUserLikedVideo('vid1', testUserId);

            await _seedVideoDocument('vid2');
            await _seedLike('vid2', otherUserId); 
            await likeProvider.hasUserLikedVideo('vid2', otherUserId);
            
            expect(likeProvider.hasUserLikedVideoSync('vid1'), isTrue);
            expect(likeProvider.hasUserLikedVideoSync('vid2'), isTrue);

            likeProvider.clearAllLikeCache();
            expect(likeProvider.hasUserLikedVideoSync('vid1'), isFalse);
            expect(likeProvider.hasUserLikedVideoSync('vid2'), isFalse);
        });
    });
  });
}
