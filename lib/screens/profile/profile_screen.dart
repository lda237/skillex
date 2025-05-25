import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Added import
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/progress_provider.dart';
import '../../widgets/progress_card.dart';
import '../../widgets/achievement_badge.dart';
import '../../models/video.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/theme_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  // Constantes
  static const int _tabCount = 3;
  static const double _profilePadding = 24.0;
  static const double _avatarRadius = 50.0;
  static const double _tabViewHeight = 400.0;
  static const double _statCardPadding = 16.0;
  static const double _listPadding = 16.0;

  @override
  void initState() {
    super.initState();
    _initializeTabController();
    _loadUserProgress();
  }

  void _initializeTabController() {
    _tabController = TabController(length: _tabCount, vsync: this);
  }

  void _loadUserProgress() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ProgressProvider>().loadUserProgress();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Consumer2<AuthProvider, ProgressProvider>(
        builder: (context, authProvider, progressProvider, child) {
          final user = authProvider.user;
          
          if (user == null) {
            return _buildNotLoggedInState();
          }

          return _buildProfileContent(user, progressProvider);
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        'Mon Profil',
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: 20,
          color: Colors.white,
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.primary,
      elevation: 2,
      iconTheme: const IconThemeData(color: Colors.white), // For back button and other icons if any
      actions: [_buildPopupMenu()],
    );
  }

  Widget _buildPopupMenu() {
    final authProvider = Provider.of<AuthProvider>(context);
    final isAdmin = authProvider.user?.email == 'narcissekodo@gmail.com';

    return PopupMenuButton<String>(
      onSelected: _handleMenuSelection,
      itemBuilder: (context) => [
        if (isAdmin)
          _buildPopupMenuItem('addContent', Icons.add_box_outlined, 'Ajouter Contenu'),
        _buildPopupMenuItem('settings', Icons.settings, 'Paramètres'),
        _buildPopupMenuItem('logout', Icons.logout, 'Déconnexion', isDestructive: true),
      ],
      tooltip: 'Options',
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem(
    String value, 
    IconData icon, 
    String text, 
    {bool isDestructive = false}
  ) {
    final color = isDestructive ? Colors.red : null;
    
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: color)),
        ],
      ),
    );
  }

  void _handleMenuSelection(String value) {
    switch (value) {
      case 'addContent':
        Navigator.pushNamed(context, '/adminAddContent');
        break;
      case 'settings':
        _showSettingsDialog();
        break;
      case 'logout':
        _showLogoutDialog();
        break;
    }
  }

  Widget _buildNotLoggedInState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Utilisateur non connecté',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent(dynamic user, ProgressProvider progressProvider) {
    return RefreshIndicator(
      onRefresh: () => _refreshProfile(progressProvider),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            _buildProfileHeader(user, progressProvider),
            _buildTabSection(progressProvider),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshProfile(ProgressProvider progressProvider) async {
    await progressProvider.loadUserProgress();
  }

  Widget _buildProfileHeader(dynamic user, ProgressProvider progressProvider) {
    return Container(
      padding: const EdgeInsets.all(_profilePadding),
      child: Column(
        children: [
          _buildProfileAvatar(user),
          const SizedBox(height: 16),
          _buildUserInfo(user),
          const SizedBox(height: 24),
          _buildStatsRow(progressProvider),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(dynamic user) {
    return Stack(
      children: [
        GestureDetector(
          onTap: _handleProfilePhotoChange,
          child: Hero(
            tag: 'profile_avatar',
            child: CircleAvatar(
              radius: _avatarRadius,
              backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
              child: user.photoURL == null ? _buildAvatarFallback(user) : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarFallback(dynamic user) {
    return Text(
      _getInitials(user.displayName),
      style: const TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  String _getInitials(String? displayName) {
    if (displayName == null || displayName.isEmpty) return 'U';
    
    final names = displayName.trim().split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    }
    return displayName[0].toUpperCase();
  }

  void _handleProfilePhotoChange() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uploading photo...'), duration: Duration(seconds: 5)),
      );

      try {
        final user = context.read<AuthProvider>().user;
        if (user == null) return;

        final file = File(pickedFile.path);
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_pictures')
            .child(user.uid)
            .child('profile.jpg');

        final uploadTask = storageRef.putFile(file);
        final snapshot = await uploadTask.whenComplete(() => {});

        final downloadUrl = await snapshot.ref.getDownloadURL();

        await user.updatePhotoURL(downloadUrl);

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'profileImageUrl': downloadUrl});

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photo de profil mise à jour !')),
          );
        }

      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur lors de la mise à jour de la photo: ${e.toString()}')),
          );
        }
      }
    }
  }

  Widget _buildUserInfo(dynamic user) {
    return Column(
      children: [
        Text(
          user.displayName ?? 'Utilisateur',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          user.email ?? '',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStatsRow(ProgressProvider progressProvider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: _buildStatCard(
            'Formations\nTerminées',
            progressProvider.completedVideos.toString(),
            Icons.check_circle,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Temps\nTotal',
            _formatWatchTime(progressProvider.totalWatchTime),
            Icons.access_time,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Badges\nObtenus',
            progressProvider.achievements.length.toString(),
            Icons.military_tech,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  String _formatWatchTime(int totalMinutes) {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(_statCardPadding),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(51)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSection(ProgressProvider progressProvider) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildTabBar(),
          SizedBox(
            height: _tabViewHeight,
            child: _buildTabBarView(progressProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      tabs: const [
        Tab(text: 'Progression', icon: Icon(Icons.trending_up, size: 18)),
        Tab(text: 'Badges', icon: Icon(Icons.military_tech, size: 18)),
        Tab(text: 'Historique', icon: Icon(Icons.history, size: 18)),
      ],
      labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      unselectedLabelStyle: const TextStyle(fontSize: 12),
    );
  }

  Widget _buildTabBarView(ProgressProvider progressProvider) {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildProgressTab(progressProvider),
        _buildAchievementsTab(progressProvider),
        _buildHistoryTab(progressProvider),
      ],
    );
  }

  Widget _buildProgressTab(ProgressProvider progressProvider) {
    return ListView(
      padding: const EdgeInsets.all(_listPadding),
      children: [
        _buildOverallProgressCard(progressProvider),
        const SizedBox(height: 16),
        _buildInProgressSection(progressProvider),
      ],
    );
  }

  Widget _buildOverallProgressCard(ProgressProvider progressProvider) {
    final progress = progressProvider.overallProgress;
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Progression Globale',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress / 100,
                backgroundColor: Colors.grey[300],
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${progress.toInt()}% complété',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInProgressSection(ProgressProvider progressProvider) {
    final inProgressVideos = progressProvider.inProgressVideos;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.play_circle, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            const Text(
              'Formations en cours',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (inProgressVideos.isEmpty)
          _buildEmptyState('Aucune formation en cours', Icons.play_circle_outline)
        else
          ...inProgressVideos.map((video) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ProgressCard(video: video),
          )),
      ],
    );
  }

  Widget _buildAchievementsTab(ProgressProvider progressProvider) {
    final achievements = progressProvider.achievements;
    
    if (achievements.isEmpty) {
      return _buildEmptyState('Aucun badge obtenu', Icons.military_tech);
    }

    return GridView.builder(
      padding: const EdgeInsets.all(_listPadding),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        final achievement = achievements[index];
        return AchievementBadge(achievement: achievement);
      },
    );
  }

  Widget _buildHistoryTab(ProgressProvider progressProvider) {
    final watchHistory = progressProvider.watchHistory;
    
    if (watchHistory.isEmpty) {
      return _buildEmptyState('Aucun historique', Icons.history);
    }

    return ListView.separated(
      padding: const EdgeInsets.all(_listPadding),
      itemCount: watchHistory.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final historyItem = watchHistory[index];
        return _buildHistoryItem(historyItem);
      },
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> historyItem) {
    return Card(
      child: ListTile(
        leading: _buildHistoryThumbnail(historyItem['thumbnail']),
        title: Text(
          historyItem['title'],
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(_formatWatchDate(historyItem['watchedAt'])),
        trailing: _buildProgressBadge(historyItem['progress']),
        onTap: () => _navigateToVideo(historyItem),
      ),
    );
  }

  Widget _buildHistoryThumbnail(String? thumbnailUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        thumbnailUrl ?? '',
        width: 60,
        height: 45,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: 60,
          height: 45,
          color: Colors.grey[300],
          child: const Icon(Icons.video_library),
        ),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 60,
            height: 45,
            color: Colors.grey[300],
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatWatchDate(DateTime watchedAt) {
    return 'Regardé le ${watchedAt.day.toString().padLeft(2, '0')}/'
           '${watchedAt.month.toString().padLeft(2, '0')}/'
           '${watchedAt.year}';
  }

  Widget _buildProgressBadge(double progress) {
    final isCompleted = progress >= 100;
    final color = isCompleted ? Colors.green : Colors.orange;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Text(
        '${progress.toInt()}%',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  void _navigateToVideo(Map<String, dynamic> historyItem) {
    Navigator.pushNamed(
      context,
      '/video',
      arguments: Video(
        id: historyItem['videoId'],
        title: historyItem['title'],
        description: '',
        thumbnailUrl: historyItem['thumbnail'],
        category: '',
        viewCount: 0,
        publishedAt: DateTime.now(),
        channelTitle: '',
        duration: 0,
        youtubeId: historyItem['videoId'],
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => _buildSettingsDialog(),
    );
  }

  Widget _buildSettingsDialog() {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.settings),
          SizedBox(width: 8),
          Text('Paramètres'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSettingItem(
            Icons.dark_mode,
            'Mode sombre',
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                 return Switch(
                   value: themeProvider.isDarkMode(context),
                   onChanged: (value) {
                      themeProvider.setThemeMode(
                         value ? ThemeMode.dark : ThemeMode.light
                      );
                   },
                 );
              },
            )
          ),
          _buildSettingItem(
            Icons.notifications,
            'Notifications',
            Switch(
              value: true,
              onChanged: (value) {},
            ),
          ),
          _buildSettingItem(
             Icons.smartphone,
             'Thème système',
             Consumer<ThemeProvider>(
                builder: (context, themeProvider, child) {
                   return Switch(
                      value: themeProvider.themeMode == ThemeMode.system,
                      onChanged: (value) {
                         if (value) {
                           themeProvider.setThemeMode(ThemeMode.system);
                         } else {
                            themeProvider.setThemeMode(ThemeMode.light);
                         }
                      },
                   );
                },
             ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fermer'),
        ),
      ],
    );
  }

  Widget _buildSettingItem(IconData icon, String title, Widget trailing) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: trailing,
      contentPadding: EdgeInsets.zero,
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => _buildLogoutDialog(),
    );
  }

  Widget _buildLogoutDialog() {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.logout, color: Colors.red),
          SizedBox(width: 8),
          Text('Déconnexion'),
        ],
      ),
      content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _handleLogout,
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Déconnexion'),
        ),
      ],
    );
  }

  void _handleLogout() {
    Navigator.of(context).pop();
    context.read<AuthProvider>().signOut();
    
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/welcome',
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}