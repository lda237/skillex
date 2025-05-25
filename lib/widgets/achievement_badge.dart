import 'package:flutter/material.dart';

class AchievementBadge extends StatelessWidget {
  final String achievement;

  const AchievementBadge({
    super.key,
    required this.achievement,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getIconForAchievement(achievement),
            size: 48,
            color: _getColorForAchievement(achievement),
          ),
          const SizedBox(height: 8),
          Text(
            _getTitleForAchievement(achievement),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _getDescriptionForAchievement(achievement),
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

  IconData _getIconForAchievement(String achievement) {
    switch (achievement) {
      case 'first_video':
        return Icons.play_circle;
      case 'video_explorer':
        return Icons.explore;
      case 'video_master':
        return Icons.star;
      default:
        return Icons.emoji_events;
    }
  }

  Color _getColorForAchievement(String achievement) {
    switch (achievement) {
      case 'first_video':
        return Colors.blue;
      case 'video_explorer':
        return Colors.green;
      case 'video_master':
        return Colors.orange;
      default:
        return Colors.purple;
    }
  }

  String _getTitleForAchievement(String achievement) {
    switch (achievement) {
      case 'first_video':
        return 'Première vidéo';
      case 'video_explorer':
        return 'Explorateur';
      case 'video_master':
        return 'Maître';
      default:
        return 'Badge';
    }
  }

  String _getDescriptionForAchievement(String achievement) {
    switch (achievement) {
      case 'first_video':
        return 'Regardé votre première vidéo';
      case 'video_explorer':
        return 'Regardé 10 vidéos';
      case 'video_master':
        return 'Regardé 50 vidéos';
      default:
        return 'Badge obtenu';
    }
  }
} 