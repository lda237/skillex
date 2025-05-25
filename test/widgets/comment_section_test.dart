import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:skillex/models/comment.dart';
import 'package:skillex/models/video.dart'; // Needed for VideoPlayerScreen arguments
// import 'package:skillex/models/user.dart'; // Not strictly needed if MockUser is used directly
import 'package:skillex/providers/auth_provider.dart';
import 'package:skillex/providers/comment_provider.dart';
import 'package:skillex/providers/progress_provider.dart'; // Added for completeness
import 'package:skillex/screens/video/video_player_screen.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart'; // For Timestamp
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart'; // For MockUser

// Mocks
class MockCommentProvider extends Mock implements CommentProvider {}
class MockAuthProvider extends Mock implements AuthProvider {}
class MockProgressProvider extends Mock implements ProgressProvider {} // Added for completeness
class MockLikeProvider extends Mock implements LikeProvider {} // Added MockLikeProvider

// Helper function to create a testable VideoPlayerScreen instance
// Renaming for clarity as it's now more general
Widget createTestableVideoPlayerScreen({
  required MockAuthProvider authProvider,
  required MockCommentProvider commentProvider,
  required MockProgressProvider progressProvider,
  required MockLikeProvider likeProvider, // Added LikeProvider
  required Video video, 
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
      ChangeNotifierProvider<CommentProvider>.value(value: commentProvider),
      ChangeNotifierProvider<ProgressProvider>.value(value: progressProvider),
      ChangeNotifierProvider<LikeProvider>.value(value: likeProvider), // Added LikeProvider
    ],
    child: MaterialApp(
      home: VideoPlayerScreen(),
      // Mock the route arguments that VideoPlayerScreen expects
      onGenerateRoute: (settings) {
        // This setup ensures that when VideoPlayerScreen calls ModalRoute.of(context)!.settings.arguments
        // in its initState or didChangeDependencies, it receives the mockVideo.
        // The home property initializes the first route. If VideoPlayerScreen is home,
        // its arguments can be passed directly if MaterialApp supported it, but it doesn't.
        // Thus, onGenerateRoute is a robust way to handle named routes or initial route arguments.
        // For the `home` widget, arguments are typically passed to its constructor directly.
        // However, VideoPlayerScreen is designed to get args via ModalRoute.
        // So, we ensure the route that *leads* to VideoPlayerScreen provides the args.
        // If VideoPlayerScreen is the very first widget, one might need to wrap it
        // in a Navigator and push it with arguments, or ensure the `home` itself
        // is a builder that provides context with arguments.
        // The current setup with `home: VideoPlayerScreen()` and `onGenerateRoute`
        // for the default route (triggered by `home`) is a common pattern.
        if (settings.name == null || settings.name == '/') { 
          return MaterialPageRoute(builder: (_) => VideoPlayerScreen(), settings: RouteSettings(arguments: video));
        }
        return null;
      },
    ),
  );
}

void main() {
  late MockAuthProvider mockAuthProvider;
  late MockCommentProvider mockCommentProvider;
  late MockProgressProvider mockProgressProvider;
  late MockLikeProvider mockLikeProvider; // Added LikeProvider
  late Video mockVideo;
  late MockUser mockUser; // From firebase_auth_mocks

  setUpAll(() {
    // Required for mocktail if using any() for certain types like DocumentReference
    // For simple types like String, int, bool, it's usually not needed.
    // registerFallbackValue(FakeFirebaseFirestore()); // Example if needed
  });

  setUp(() {
    mockAuthProvider = MockAuthProvider();
    mockCommentProvider = MockCommentProvider();
    mockProgressProvider = MockProgressProvider();
    mockLikeProvider = MockLikeProvider(); // Initialize MockLikeProvider

    mockVideo = Video(
      id: 'vid1',
      youtubeId: 'youtubeVid1',
      title: 'Test Video',
      description: 'A video for testing comments.',
      category: 'Testing',
      channelTitle: 'Tester', 
      // duration: '5:00', // Assuming duration is int in seconds as per model
      duration: 300, // Example: 5 minutes in seconds
      thumbnailUrl: 'http://example.com/thumb.jpg',
      publishedAt: DateTime.now(),
      viewCount: 100, 
      appLikesCount: 0, // Initialize appLikesCount, likeCount was a typo
      isFeatured: false, 
      difficulty: 'Beginner', 
      tags: ['test'], 
    );

    mockUser = MockUser(
      uid: 'testUserId',
      email: 'test@example.com',
      displayName: 'Test User',
      photoURL: 'http://example.com/avatar.jpg',
    );

    // Default stubs for AuthProvider
    when(() => mockAuthProvider.user).thenReturn(null); // Default to logged out

    // Default stubs for CommentProvider
    when(() => mockCommentProvider.comments).thenReturn([]);
    when(() => mockCommentProvider.isLoading).thenReturn(false);
    when(() => mockCommentProvider.error).thenReturn(null);
    when(() => mockCommentProvider.hasMoreComments).thenReturn(false);
    when(() => mockCommentProvider.fetchComments(any())).thenAnswer((_) async {});
    when(() => mockCommentProvider.fetchMoreComments(any())).thenAnswer((_) async {});
    when(() => mockCommentProvider.addComment(
      videoId: any(named: 'videoId'),
      text: any(named: 'text'),
      userId: any(named: 'userId'),
      userName: any(named: 'userName'),
      userProfilePicUrl: any(named: 'userProfilePicUrl'),
    )).thenAnswer((_) async => true);

    // Default stubs for ProgressProvider (added for completeness)
    // These might need to be more specific if VideoPlayerScreen interacts heavily during init
    when(() => mockProgressProvider.updateVideoProgress(
        videoId: any(named: 'videoId'),
        currentTime: any(named: 'currentTime'),
        totalDuration: any(named: 'totalDuration')))
    .thenAnswer((_) async {});
    when(() => mockProgressProvider.markVideoAsCompleted(any(), any())).thenAnswer((_) async {});
    
    // Default stubs for LikeProvider
    when(() => mockLikeProvider.hasUserLikedVideo(any(), any())).thenAnswer((_) async => false);
    when(() => mockLikeProvider.hasUserLikedVideoSync(any())).thenReturn(false);
    when(() => mockLikeProvider.toggleLikeVideo(any(), any())).thenAnswer((_) async {});
    when(() => mockLikeProvider.clearLikeCacheForVideo(any())).thenAnswer((_) {});
    when(() => mockLikeProvider.clearAllLikeCache()).thenAnswer((_) {}); // Added for completeness
  });

  // Helper to pump widget and settle, renamed for clarity
  Future<void> pumpVideoPlayerScreen(WidgetTester tester) async {
    await tester.pumpWidget(createTestableVideoPlayerScreen(
      authProvider: mockAuthProvider,
      commentProvider: mockCommentProvider,
      progressProvider: mockProgressProvider,
      likeProvider: mockLikeProvider, // Added LikeProvider
      video: mockVideo,
    ));
    // pumpAndSettle can be long; use pump for more control if needed
    // VideoPlayerScreen's initState calls _fetchInitialLikeStatus, which is async.
    // It also calls commentProvider.fetchComments.
    // We need to ensure these async operations complete.
    await tester.pumpAndSettle(); 
  }

  group('Comment Section UI Tests', () {
    testWidgets('shows no input field when logged out', (WidgetTester tester) async {
      when(() => mockAuthProvider.user).thenReturn(null);
      await pumpVideoPlayerScreen(tester); // Using new helper name

      expect(find.byType(TextField), findsNothing);
      // The UI shows SizedBox.shrink() when user is null for the comment input part
    });

    testWidgets('shows comment input field when logged in', (WidgetTester tester) async {
      when(() => mockAuthProvider.user).thenReturn(mockUser);
      await pumpVideoPlayerScreen(tester); // Using new helper name
      
      expect(find.widgetWithText(TextField, 'Ajouter un commentaire...'), findsOneWidget);
      expect(find.widgetWithIcon(IconButton, Icons.send), findsOneWidget);
    });

    testWidgets('displays a list of comments', (WidgetTester tester) async {
      final comments = [
        Comment(id: 'c1', videoId: 'vid1', userId: 'u1', userName: 'User One', text: 'First comment!', timestamp: Timestamp.now(), userProfilePicUrl: 'http://example.com/pic1.jpg'),
        Comment(id: 'c2', videoId: 'vid1', userId: 'u2', userName: 'User Two', text: 'Second comment!', timestamp: Timestamp.now(), userProfilePicUrl: 'http://example.com/pic2.jpg'),
      ];
      when(() => mockCommentProvider.comments).thenReturn(comments);
      when(() => mockAuthProvider.user).thenReturn(mockUser);

      await pumpVideoPlayerScreen(tester); // Using new helper name

      expect(find.text('User One'), findsOneWidget);
      expect(find.text('First comment!'), findsOneWidget);
      expect(find.text('User Two'), findsOneWidget);
      expect(find.text('Second comment!'), findsOneWidget);
      // Check for avatars (presence of CircleAvatar, though not specific image)
      // The like button also has a CircleAvatar if user has no photoURL, adjust count if needed.
      // For now, let's assume profile avatars are distinct enough or test more specifically.
      // The video player screen itself might have user avatars for comments.
      // The like button itself doesn't have an avatar.
      expect(find.byType(CircleAvatar), findsNWidgets(comments.length));
    });

    testWidgets('shows empty message when no comments and not loading', (WidgetTester tester) async {
      when(() => mockCommentProvider.comments).thenReturn([]);
      when(() => mockCommentProvider.isLoading).thenReturn(false);
      when(() => mockAuthProvider.user).thenReturn(mockUser);

      await pumpVideoPlayerScreen(tester); // Using new helper name
      expect(find.text('Aucun commentaire pour le moment. Soyez le premier !'), findsOneWidget);
    });

    testWidgets('shows loading indicator when comments are loading and list is empty', (WidgetTester tester) async {
      when(() => mockCommentProvider.isLoading).thenReturn(true);
      when(() => mockCommentProvider.comments).thenReturn([]); 
      when(() => mockAuthProvider.user).thenReturn(mockUser);

      await pumpVideoPlayerScreen(tester); // Using new helper name
      
      // The specific check is `if (commentProvider.isLoading && commentProvider.comments.isEmpty)`
      // This should find the CircularProgressIndicator inside the Consumer<CommentProvider>
      // There might be other CircularProgressIndicators (e.g. for like button).
      // Be specific if this fails. For now, assuming one main content loader.
      final commentSectionLoader = find.descendant(
        of: find.byType(Consumer<CommentProvider>), // Scope to comment section's consumer
        matching: find.byType(CircularProgressIndicator),
      );
      expect(commentSectionLoader, findsOneWidget);
    });

    testWidgets('allows typing and submitting a comment', (WidgetTester tester) async {
      when(() => mockAuthProvider.user).thenReturn(mockUser);
      await pumpVideoPlayerScreen(tester); // Using new helper name

      final commentTextField = find.widgetWithText(TextField, 'Ajouter un commentaire...');
      expect(commentTextField, findsOneWidget);
      await tester.enterText(commentTextField, 'This is a test comment');
      await tester.pump(); 

      final sendButton = find.widgetWithIcon(IconButton, Icons.send);
      expect(sendButton, findsOneWidget);
      
      // Stub the addComment call
      when(() => mockCommentProvider.addComment(
          videoId: 'vid1',
          text: 'This is a test comment',
          userId: 'testUserId',
          userName: 'Test User',
          userProfilePicUrl: 'http://example.com/avatar.jpg'
      )).thenAnswer((_) async {
          return true; 
      });

      await tester.tap(sendButton);
      await tester.pumpAndSettle(); 

      verify(() => mockCommentProvider.addComment(
          videoId: 'vid1',
          text: 'This is a test comment',
          userId: 'testUserId',
          userName: 'Test User',
          userProfilePicUrl: 'http://example.com/avatar.jpg'
      )).called(1);
      
      expect(find.text('This is a test comment'), findsNothing); 
    });

    testWidgets('shows load more button when hasMoreComments is true and not loading', (WidgetTester tester) async {
        when(() => mockCommentProvider.hasMoreComments).thenReturn(true);
        when(() => mockCommentProvider.isLoading).thenReturn(false); 
        final comments = List.generate(5, (i) => Comment(id: 'c$i', videoId: 'vid1', userId: 'u$i', userName: 'User $i', text: 'Comment $i', timestamp: Timestamp.now()));
        when(() => mockCommentProvider.comments).thenReturn(comments);
        when(() => mockAuthProvider.user).thenReturn(mockUser);

        await pumpVideoPlayerScreen(tester); // Using new helper name

        expect(find.widgetWithText(TextButton, 'Charger plus de commentaires'), findsOneWidget);
    });

    testWidgets('calls fetchMoreComments when load more button is tapped', (WidgetTester tester) async {
        when(() => mockCommentProvider.hasMoreComments).thenReturn(true);
        when(() => mockCommentProvider.isLoading).thenReturn(false);
        final comments = List.generate(5, (i) => Comment(id: 'c$i', videoId: 'vid1', userId: 'u$i', userName: 'User $i', text: 'Comment $i', timestamp: Timestamp.now()));
        when(() => mockCommentProvider.comments).thenReturn(comments);
        when(() => mockAuthProvider.user).thenReturn(mockUser);
        when(() => mockCommentProvider.fetchMoreComments('vid1')).thenAnswer((_) async {});


        await pumpVideoPlayerScreen(tester); // Using new helper name
        final loadMoreButton = find.widgetWithText(TextButton, 'Charger plus de commentaires');
        await tester.tap(loadMoreButton);
        await tester.pumpAndSettle();

        verify(() => mockCommentProvider.fetchMoreComments('vid1')).called(1);
    });

    testWidgets('shows loading indicator at bottom when loading more comments', (WidgetTester tester) async {
      final initialComments = List.generate(5, (i) => Comment(id: 'c$i', videoId: 'vid1', userId: 'u$i', userName: 'User $i', text: 'Comment $i', timestamp: Timestamp.now()));
      when(() => mockCommentProvider.comments).thenReturn(initialComments);
      when(() => mockCommentProvider.hasMoreComments).thenReturn(true); 
      when(() => mockAuthProvider.user).thenReturn(mockUser);

      when(() => mockCommentProvider.isLoading).thenReturn(false);
      await pumpVideoPlayerScreen(tester); // Using new helper name

      expect(find.widgetWithText(TextButton, 'Charger plus de commentaires'), findsOneWidget);
      expect(find.byWidgetPredicate(
          (widget) => widget is Padding && widget.child is Center && (widget.child as Center).child is CircularProgressIndicator
      ), findsNothing);

      when(() => mockCommentProvider.fetchMoreComments('vid1')).thenAnswer((_) async {
        when(() => mockCommentProvider.isLoading).thenReturn(true);
        await tester.pump(); 
      });
      
      await tester.tap(find.widgetWithText(TextButton, 'Charger plus de commentaires'));
      await tester.pump(); 

      final bottomIndicatorFinder = find.descendant( // More specific to comment section
        of: find.byType(Consumer<CommentProvider>),
        matching: find.byWidgetPredicate(
          (widget) => widget is Padding && widget.child is Center && (widget.child as Center).child is CircularProgressIndicator
        )
      );
      expect(bottomIndicatorFinder, findsOneWidget);
    });
  });

  group('Like Button UI Tests', () {
    // Helper to pump widget, ensuring VideoPlayerScreen receives the mockVideo
      Future<void> pumpVideoPlayerScreenForLikeTests(WidgetTester tester) async { // Renamed to avoid conflict if original pumpCommentSection is still used
      await tester.pumpWidget(createTestableVideoPlayerScreen( 
        authProvider: mockAuthProvider,
        commentProvider: mockCommentProvider, 
        likeProvider: mockLikeProvider, 
        progressProvider: mockProgressProvider, // Ensure all providers are passed
        video: mockVideo, 
      ));
      await tester.pumpAndSettle(); 
    }

    testWidgets('displays like button and initial like count', (WidgetTester tester) async {
      when(() => mockAuthProvider.user).thenReturn(mockUser); 
      when(() => mockLikeProvider.hasUserLikedVideo(mockVideo.id, mockUser.uid)).thenAnswer((_) async => false);
      when(() => mockLikeProvider.hasUserLikedVideoSync(mockVideo.id)).thenReturn(false);
      
      mockVideo = mockVideo.copyWith(appLikesCount: 10);

      await pumpVideoPlayerScreenForLikeTests(tester);

      expect(find.byIcon(Icons.thumb_up_alt_outlined), findsOneWidget);
      expect(find.text('10 J\'aime'), findsOneWidget);
    });

    testWidgets('displays filled like icon if video is liked', (WidgetTester tester) async {
      when(() => mockAuthProvider.user).thenReturn(mockUser);
      when(() => mockLikeProvider.hasUserLikedVideo(mockVideo.id, mockUser.uid)).thenAnswer((_) async => true);
      when(() => mockLikeProvider.hasUserLikedVideoSync(mockVideo.id)).thenReturn(true);
      mockVideo = mockVideo.copyWith(appLikesCount: 11);

      await pumpVideoPlayerScreenForLikeTests(tester);
      
      expect(find.byIcon(Icons.thumb_up_alt), findsOneWidget);
      expect(find.text('11 J\'aime'), findsOneWidget);
    });

    testWidgets('calls toggleLikeVideo on tap and updates UI optimistically', (WidgetTester tester) async {
      when(() => mockAuthProvider.user).thenReturn(mockUser);
      when(() => mockLikeProvider.hasUserLikedVideo(mockVideo.id, mockUser.uid)).thenAnswer((_) async => false);
      when(() => mockLikeProvider.hasUserLikedVideoSync(mockVideo.id)).thenReturn(false);
      when(() => mockLikeProvider.toggleLikeVideo(mockVideo.id, mockUser.uid)).thenAnswer((_) async {});
      
      mockVideo = mockVideo.copyWith(appLikesCount: 5);
      await pumpVideoPlayerScreenForLikeTests(tester);

      expect(find.byIcon(Icons.thumb_up_alt_outlined), findsOneWidget);
      
      await tester.tap(find.byIcon(Icons.thumb_up_alt_outlined));
      await tester.pump(); 

      expect(find.byIcon(Icons.thumb_up_alt), findsOneWidget); 
      
      verify(() => mockLikeProvider.toggleLikeVideo(mockVideo.id, mockUser.uid)).called(1);
      
      await tester.pumpAndSettle(); 
    });

    testWidgets('Like button is disabled if user is not logged in', (WidgetTester tester) async {
      when(() => mockAuthProvider.user).thenReturn(null); 
      
      mockVideo = mockVideo.copyWith(appLikesCount: 7);
      await pumpVideoPlayerScreenForLikeTests(tester);

      // Find the IconButton specifically. The icon itself might still be found.
      final Finder iconButtonFinder = find.widgetWithIcon(IconButton, Icons.thumb_up_alt_outlined);
      expect(iconButtonFinder, findsOneWidget);
      final IconButton likeButton = tester.widget<IconButton>(iconButtonFinder);
      expect(likeButton.onPressed, isNull); 
      expect(find.text('7 J\'aime'), findsOneWidget); 
    });
    
    testWidgets('Like button shows loading indicator while fetching initial status', (WidgetTester tester) async {
      when(() => mockAuthProvider.user).thenReturn(mockUser);
      when(() => mockLikeProvider.hasUserLikedVideo(mockVideo.id, mockUser.uid))
          .thenAnswer((_) async {
            await Future.delayed(const Duration(milliseconds: 100)); 
            return true; 
          });
      when(() => mockLikeProvider.hasUserLikedVideoSync(mockVideo.id)).thenReturn(false);

      await tester.pumpWidget(createTestableVideoPlayerScreen(
        authProvider: mockAuthProvider,
        commentProvider: mockCommentProvider,
        likeProvider: mockLikeProvider,
        progressProvider: mockProgressProvider,
        video: mockVideo,
      ));
      
      await tester.pump(); 
      // The IconButton itself contains the CircularProgressIndicator as its child when _isLoadingLikeStatus is true.
      final Finder circularProgressFinder = find.descendant(
        of: find.byType(IconButton), // Scope it to be inside an IconButton
        matching: find.byType(CircularProgressIndicator),
      );
      expect(circularProgressFinder, findsOneWidget);

      await tester.pumpAndSettle(); 
      expect(find.byIcon(Icons.thumb_up_alt), findsOneWidget); 
    });
  });
}
```
