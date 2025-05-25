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

// Helper function to create a testable VideoPlayerScreen instance
Widget createTestableCommentSection({
  required MockAuthProvider authProvider,
  required MockCommentProvider commentProvider,
  required MockProgressProvider progressProvider, // Added
  required Video video, // VideoPlayerScreen takes Video as argument
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
      ChangeNotifierProvider<CommentProvider>.value(value: commentProvider),
      ChangeNotifierProvider<ProgressProvider>.value(value: progressProvider), // Added
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
  late MockProgressProvider mockProgressProvider; // Added
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
    mockProgressProvider = MockProgressProvider(); // Added

    mockVideo = Video(
      id: 'vid1',
      youtubeId: 'youtubeVid1',
      title: 'Test Video',
      description: 'A video for testing comments.',
      category: 'Testing',
      channelTitle: 'Tester', // Added based on Video model
      duration: '5:00', // Added based on Video model
      thumbnailUrl: 'http://example.com/thumb.jpg',
      publishedAt: DateTime.now(),
      viewCount: 100, // Added based on Video model
      likeCount: 10,  // Added based on Video model
      isFeatured: false, // Added based on Video model
      difficulty: 'Beginner', // Added based on Video model
      tags: ['test'], // Added based on Video model
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
    // Add other stubs for ProgressProvider if needed
  });

  // Helper to pump widget and settle
  Future<void> pumpCommentSection(WidgetTester tester) async {
    await tester.pumpWidget(createTestableCommentSection(
      authProvider: mockAuthProvider,
      commentProvider: mockCommentProvider,
      progressProvider: mockProgressProvider, // Added
      video: mockVideo,
    ));
    // pumpAndSettle can be long; use pump for more control if needed
    await tester.pumpAndSettle(const Duration(seconds: 1)); // Allow time for UI, including player init if any
  }

  group('Comment Section UI Tests', () {
    testWidgets('shows no input field when logged out', (WidgetTester tester) async {
      when(() => mockAuthProvider.user).thenReturn(null);
      await pumpCommentSection(tester);

      expect(find.byType(TextField), findsNothing);
      // The UI shows SizedBox.shrink() when user is null for the comment input part
    });

    testWidgets('shows comment input field when logged in', (WidgetTester tester) async {
      when(() => mockAuthProvider.user).thenReturn(mockUser);
      await pumpCommentSection(tester);
      
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

      await pumpCommentSection(tester);

      expect(find.text('User One'), findsOneWidget);
      expect(find.text('First comment!'), findsOneWidget);
      expect(find.text('User Two'), findsOneWidget);
      expect(find.text('Second comment!'), findsOneWidget);
      // Check for avatars (presence of CircleAvatar, though not specific image)
      expect(find.byType(CircleAvatar), findsNWidgets(comments.length));
    });

    testWidgets('shows empty message when no comments and not loading', (WidgetTester tester) async {
      when(() => mockCommentProvider.comments).thenReturn([]);
      when(() => mockCommentProvider.isLoading).thenReturn(false);
      when(() => mockAuthProvider.user).thenReturn(mockUser);

      await pumpCommentSection(tester);
      expect(find.text('Aucun commentaire pour le moment. Soyez le premier !'), findsOneWidget);
    });

    testWidgets('shows loading indicator when comments are loading and list is empty', (WidgetTester tester) async {
      when(() => mockCommentProvider.isLoading).thenReturn(true);
      when(() => mockCommentProvider.comments).thenReturn([]); 
      when(() => mockAuthProvider.user).thenReturn(mockUser);

      await pumpCommentSection(tester);
      
      // The specific check is `if (commentProvider.isLoading && commentProvider.comments.isEmpty)`
      // This should find the CircularProgressIndicator inside the Consumer<CommentProvider>
      final commentConsumerFinder = find.byWidgetPredicate((widget) => widget is Consumer<CommentProvider>);
      final progressIndicatorFinder = find.descendant(
        of: commentConsumerFinder,
        matching: find.byType(CircularProgressIndicator),
      );
      expect(progressIndicatorFinder, findsOneWidget);
    });

    testWidgets('allows typing and submitting a comment', (WidgetTester tester) async {
      when(() => mockAuthProvider.user).thenReturn(mockUser);
      await pumpCommentSection(tester);

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
          // Simulate the provider behavior upon successful comment:
          // It might re-fetch comments, which would update the list.
          // For this test, we primarily care about the call.
          // If it clears the text field, we can check that.
          return true; 
      });

      await tester.tap(sendButton);
      // Wait for the async addComment and subsequent UI updates (like clearing the field)
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

        await pumpCommentSection(tester);

        expect(find.widgetWithText(TextButton, 'Charger plus de commentaires'), findsOneWidget);
    });

    testWidgets('calls fetchMoreComments when load more button is tapped', (WidgetTester tester) async {
        when(() => mockCommentProvider.hasMoreComments).thenReturn(true);
        when(() => mockCommentProvider.isLoading).thenReturn(false);
        final comments = List.generate(5, (i) => Comment(id: 'c$i', videoId: 'vid1', userId: 'u$i', userName: 'User $i', text: 'Comment $i', timestamp: Timestamp.now()));
        when(() => mockCommentProvider.comments).thenReturn(comments);
        when(() => mockAuthProvider.user).thenReturn(mockUser);
        // Specific stub for fetchMoreComments
        when(() => mockCommentProvider.fetchMoreComments('vid1')).thenAnswer((_) async {});


        await pumpCommentSection(tester);
        final loadMoreButton = find.widgetWithText(TextButton, 'Charger plus de commentaires');
        await tester.tap(loadMoreButton);
        await tester.pumpAndSettle();

        verify(() => mockCommentProvider.fetchMoreComments('vid1')).called(1);
    });

    testWidgets('shows loading indicator at bottom when loading more comments', (WidgetTester tester) async {
      final initialComments = List.generate(5, (i) => Comment(id: 'c$i', videoId: 'vid1', userId: 'u$i', userName: 'User $i', text: 'Comment $i', timestamp: Timestamp.now()));
      when(() => mockCommentProvider.comments).thenReturn(initialComments);
      when(() => mockCommentProvider.hasMoreComments).thenReturn(true); // Important
      when(() => mockAuthProvider.user).thenReturn(mockUser);

      // Initial state: not loading more
      when(() => mockCommentProvider.isLoading).thenReturn(false);
      await pumpCommentSection(tester);

      // Ensure "Load more" is visible and no bottom indicator
      expect(find.widgetWithText(TextButton, 'Charger plus de commentaires'), findsOneWidget);
      expect(find.byWidgetPredicate(
          (widget) => widget is Padding && widget.child is Center && (widget.child as Center).child is CircularProgressIndicator
      ), findsNothing);


      // Trigger loading more: Tap the button
      // For testing the UI state *during* loading, we need to control isLoading state change
      when(() => mockCommentProvider.fetchMoreComments('vid1')).thenAnswer((_) async {
        // Simulate provider behavior: sets isLoading to true, then fetches
        when(() => mockCommentProvider.isLoading).thenReturn(true);
        // Manually trigger a pump to rebuild with new isLoading state
        await tester.pump(); 
        // Simulate network delay if necessary, then set isLoading to false and add new comments
      });
      
      await tester.tap(find.widgetWithText(TextButton, 'Charger plus de commentaires'));
      await tester.pump(); // First pump for isLoading state change if provider notifies immediately

      // Now check for the loading indicator at the bottom
      // `if (commentProvider.isLoading && commentProvider.comments.isNotEmpty)`
      final bottomIndicatorFinder = find.byWidgetPredicate(
          (widget) => widget is Padding && widget.child is Center && (widget.child as Center).child is CircularProgressIndicator
      );
      expect(bottomIndicatorFinder, findsOneWidget);
    });

  });
}
```
