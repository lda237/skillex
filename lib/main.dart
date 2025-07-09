import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

import 'providers/auth_provider.dart';
import 'providers/video_provider.dart';
import 'providers/progress_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/video/video_player_screen.dart';
import 'screens/admin_add_content_screen.dart';
import 'screens/playlist/playlist_details_screen.dart';
import 'screens/about/about_screen.dart';
import 'screens/admin/admin_management_screen.dart';
import 'screens/support/support_screen.dart';
import 'screens/favorites/favorites_screen.dart';
import 'utils/app_theme.dart';
import 'services/youtube_service.dart';
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => VideoProvider()),
        ChangeNotifierProvider(create: (_) => ProgressProvider()),
        Provider(create: (_) => YoutubeService()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Skillex',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            initialRoute: '/',
            routes: {
              '/': (context) => const SplashScreen(),
              '/welcome': (context) => const WelcomeScreen(),
              '/login': (context) => const LoginScreen(),
              '/signup': (context) => const SignupScreen(),
              '/home': (context) => const HomeScreen(),
              '/profile': (context) => const ProfileScreen(),
              '/video': (context) => const VideoPlayerScreen(),
              '/adminAddContent': (context) => const AdminAddContentScreen(),
              '/adminManagement': (context) => const AdminManagementScreen(),
              '/playlistDetails': (context) {
                final Object? args = ModalRoute.of(context)!.settings.arguments;
                if (args is String) {
                  return PlaylistDetailsScreen(playlistId: args);
                }
                // Retourne un écran d'erreur si l'argument est invalide
                return const Scaffold(
                  body: Center(child: Text('Erreur: Argument de page invalide')),
                );
              },
              '/about': (context) => const AboutScreen(),
              '/support': (context) => const SupportScreen(),
              '/favorites': (context) => const FavoritesScreen(),
            },
          );
        },
      ),
    );
  }
}