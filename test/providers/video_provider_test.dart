import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:skillex/models/video.dart'; // Adjust import path if necessary
import 'package:skillex/providers/video_provider.dart'; // Adjust import path
import 'package:skillex/services/youtube_service.dart'; // Adjust import path

// Mock YoutubeService
class MockYoutubeService extends Mock implements YoutubeService {}

void main() {
  late VideoProvider videoProvider;
  late MockYoutubeService mockYoutubeService;

  setUp(() {
    mockYoutubeService = MockYoutubeService();
    // It seems VideoProvider instantiates YoutubeService directly.
    // This is a challenge for testing. For now, we can't directly inject the mock.
    // The tests written will have to acknowledge this limitation or
    // VideoProvider will need to be refactored for dependency injection.
    // For now, let's proceed and see how far we can get, or if the
    // worker can suggest a simple refactor for VideoProvider.
    // A common pattern is to pass the service in the constructor.
    videoProvider = VideoProvider(youtubeService: mockYoutubeService);
  });

  group('VideoProvider Tests', () {
    // Test cases will be added here
    test('Initial values are correct', () {
      expect(videoProvider.videos, isEmpty);
      expect(videoProvider.categories, ['Tous']);
      expect(videoProvider.selectedCategory, 'Tous');
      expect(videoProvider.searchQuery, '');
      expect(videoProvider.isLoading, false);
      expect(videoProvider.error, null);
    });

    final mockVideos = [
      Video(id: '1', youtubeId: 'y1', title: 'Flutter Intro', description: 'Learn Flutter', category: 'Flutter', viewCount: 1000, publishedAt: DateTime(2023, 1, 1)),
      Video(id: '2', youtubeId: 'y2', title: 'Dart Basics', description: 'Learn Dart', category: 'Dart', viewCount: 500, publishedAt: DateTime(2023, 1, 15)),
      Video(id: '3', youtubeId: 'y3', title: 'Advanced Flutter', description: 'Deep dive into Flutter', category: 'Flutter', viewCount: 1500, publishedAt: DateTime(2023, 2, 1)),
    ];

    final mockVideo = Video(id: '1', youtubeId: 'y1', title: 'Flutter Intro', description: 'Learn Flutter', category: 'Flutter', viewCount: 1000, publishedAt: DateTime(2023, 1, 1));


    group('loadVideos', () {
      test('loads videos successfully and updates state', () async {
        // Arrange
        when(() => mockYoutubeService.fetchVideos()).thenAnswer((_) async => mockVideos);

        // Act
        await videoProvider.loadVideos();

        // Assert
        expect(videoProvider.videos.length, 3);
        expect(videoProvider.videos, containsAll(mockVideos));
        expect(videoProvider.categories, ['Tous', 'Dart', 'Flutter']); // Sorted
        expect(videoProvider.isLoading, false);
        expect(videoProvider.error, null);
        verify(() => mockYoutubeService.fetchVideos()).called(1);
      });

      test('handles error during video loading', () async {
        // Arrange
        when(() => mockYoutubeService.fetchVideos()).thenThrow(Exception('Failed to load'));

        // Act
        await videoProvider.loadVideos();

        // Assert
        expect(videoProvider.videos, isEmpty);
        expect(videoProvider.isLoading, false);
        expect(videoProvider.error, startsWith('Erreur lors du chargement des vidéos: Exception: Failed to load'));
        verify(() => mockYoutubeService.fetchVideos()).called(1);
      });

      test('sets loading state correctly', () {
        // Arrange
        when(() => mockYoutubeService.fetchVideos()).thenAnswer((_) async {
          // Check loading state while future is not completed
          expect(videoProvider.isLoading, true);
          return mockVideos;
        });

        // Act
        final future = videoProvider.loadVideos();
        expect(videoProvider.isLoading, true); // Check immediately after call
        
        // Assert (completion)
        expect(future, completes);
      });
    });

    group('searchVideos', () {
      setUp(() async {
        when(() => mockYoutubeService.fetchVideos()).thenAnswer((_) async => mockVideos);
        await videoProvider.loadVideos(); // Load initial data
      });

      test('filters videos by search query (title)', () {
        videoProvider.searchVideos('intro');
        expect(videoProvider.videos.length, 1);
        expect(videoProvider.videos.first.title, 'Flutter Intro');
      });

      test('filters videos by search query (description)', () {
        videoProvider.searchVideos('learn dart');
        expect(videoProvider.videos.length, 1);
        expect(videoProvider.videos.first.title, 'Dart Basics');
      });
      
      test('search is case-insensitive', () {
        videoProvider.searchVideos('FLUTTER');
        expect(videoProvider.videos.length, 2);
      });

      test('clears search query and shows all videos', () {
        videoProvider.searchVideos('intro'); // Apply a search
        videoProvider.searchVideos('');     // Clear search
        expect(videoProvider.videos.length, 3);
      });
    });

    group('filterByCategory', () {
      setUp(() async {
        when(() => mockYoutubeService.fetchVideos()).thenAnswer((_) async => mockVideos);
        await videoProvider.loadVideos();
      });

      test('filters videos by category "Flutter"', () {
        videoProvider.filterByCategory('Flutter');
        expect(videoProvider.videos.length, 2);
        expect(videoProvider.videos.every((v) => v.category == 'Flutter'), isTrue);
        expect(videoProvider.selectedCategory, 'Flutter');
      });

      test('filters videos by category "Dart"', () {
        videoProvider.filterByCategory('Dart');
        expect(videoProvider.videos.length, 1);
        expect(videoProvider.videos.first.category, 'Dart');
        expect(videoProvider.selectedCategory, 'Dart');
      });

      test('shows all videos when category is "Tous"', () {
        videoProvider.filterByCategory('Flutter'); // Apply a filter
        videoProvider.filterByCategory('Tous');    // Select "Tous"
        expect(videoProvider.videos.length, 3);
        expect(videoProvider.selectedCategory, 'Tous');
      });
    });
    
    group('getVideoById', () {
      setUp(() async {
        when(() => mockYoutubeService.fetchVideos()).thenAnswer((_) async => mockVideos);
        await videoProvider.loadVideos();
      });

      test('returns correct video for existing ID', () {
        final video = videoProvider.getVideoById('1');
        expect(video, isNotNull);
        expect(video!.title, 'Flutter Intro');
      });

      test('returns null for non-existing ID', () {
        final video = videoProvider.getVideoById('non_existent_id');
        expect(video, isNull);
      });
    });

    group('getRecommendedVideos', () {
      setUp(() async {
        when(() => mockYoutubeService.fetchVideos()).thenAnswer((_) async => mockVideos);
        await videoProvider.loadVideos();
      });

      test('returns videos of the same category, excluding current video', () {
        final recommendations = videoProvider.getRecommendedVideos('1', limit: 1); // Video '1' is Flutter
        expect(recommendations.length, 1);
        expect(recommendations.first.id, '3'); // 'Advanced Flutter'
        expect(recommendations.first.category, 'Flutter');
      });

      test('returns empty list if no other videos in category', () {
        final recommendations = videoProvider.getRecommendedVideos('2'); // Video '2' is Dart (only one)
        expect(recommendations, isEmpty);
      });
       
      test('returns empty list if currentVideoId is not found', () {
        final recommendations = videoProvider.getRecommendedVideos('invalid_id');
        expect(recommendations, isEmpty);
      });
    });

    group('getPopularVideos', () {
      setUp(() async {
        when(() => mockYoutubeService.fetchVideos()).thenAnswer((_) async => mockVideos);
        await videoProvider.loadVideos();
      });

      test('returns videos sorted by viewCount descending', () {
        final popular = videoProvider.getPopularVideos(limit: 2);
        expect(popular.length, 2);
        expect(popular[0].id, '3'); // Advanced Flutter (1500 views)
        expect(popular[1].id, '1'); // Flutter Intro (1000 views)
      });
    });

    group('getRecentVideos', () {
      setUp(() async {
        when(() => mockYoutubeService.fetchVideos()).thenAnswer((_) async => mockVideos);
        await videoProvider.loadVideos();
      });

      test('returns videos sorted by publishedAt descending', () {
        final recent = videoProvider.getRecentVideos(limit: 2);
        expect(recent.length, 2);
        expect(recent[0].id, '3'); // Advanced Flutter (Feb 1)
        expect(recent[1].id, '2'); // Dart Basics (Jan 15)
      });
    });
    
    group('clearFilters', () {
      setUp(() async {
        when(() => mockYoutubeService.fetchVideos()).thenAnswer((_) async => mockVideos);
        await videoProvider.loadVideos();
        // Apply some filters
        videoProvider.searchVideos('intro');
        videoProvider.filterByCategory('Flutter');
      });

      test('resets search query and selected category, shows all videos', () {
        // Pre-check that filters are applied
        expect(videoProvider.videos.length, 1); // 'Flutter Intro'
        expect(videoProvider.selectedCategory, 'Flutter');
        expect(videoProvider.searchQuery, 'intro');

        // Act
        videoProvider.clearFilters();

        // Assert
        expect(videoProvider.videos.length, 3); // All videos
        expect(videoProvider.selectedCategory, 'Tous');
        expect(videoProvider.searchQuery, '');
      });
    });
    
    group('refresh', () {
      test('calls loadVideos and updates data', () async {
        // Arrange
        final refreshedVideos = [
          Video(id: '4', youtubeId: 'y4', title: 'New Video', description: 'Latest content', category: 'Flutter', viewCount: 200, publishedAt: DateTime(2023, 3, 1)),
        ];
        when(() => mockYoutubeService.fetchVideos()).thenAnswer((_) async => mockVideos);
        await videoProvider.loadVideos(); // Initial load

        // Ensure initial state
        expect(videoProvider.videos.length, 3);

        // Setup for refresh
        when(() => mockYoutubeService.fetchVideos()).thenAnswer((_) async => refreshedVideos);
        
        // Act
        await videoProvider.refresh();

        // Assert
        expect(videoProvider.videos.length, 1);
        expect(videoProvider.videos.first.id, '4');
        expect(videoProvider.isLoading, false);
        expect(videoProvider.error, null);
        // loadVideos is called once initially, then once for refresh
        verify(() => mockYoutubeService.fetchVideos()).called(2); 
      });
    });
  });
}
