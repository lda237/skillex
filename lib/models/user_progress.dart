import 'package:cloud_firestore/cloud_firestore.dart';

class UserProgress {
  final String userId;
  final int totalWatchTime;
  final int videosWatched;
  final List<String> completedVideos;
  final List<String> favoriteVideoIds;
  final List<String> badges;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProgress({
    required this.userId,
    required this.totalWatchTime,
    required this.videosWatched,
    required this.completedVideos,
    required this.favoriteVideoIds,
    required this.badges,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProgress.fromFirestore(Map<String, dynamic> data) {
    return UserProgress(
      userId: data['userId'] ?? '',
      totalWatchTime: data['totalWatchTime'] ?? 0,
      videosWatched: data['videosWatched'] ?? 0,
      completedVideos: List<String>.from(data['completedVideos'] ?? []),
      favoriteVideoIds: List<String>.from(data['favoriteVideoIds'] ?? []),
      badges: List<String>.from(data['badges'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'totalWatchTime': totalWatchTime,
      'videosWatched': videosWatched,
      'completedVideos': completedVideos,
      'favoriteVideoIds': favoriteVideoIds,
      'badges': badges,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  UserProgress copyWith({
    String? userId,
    int? totalWatchTime,
    int? videosWatched,
    List<String>? completedVideos,
    List<String>? favoriteVideoIds,
    List<String>? badges,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProgress(
      userId: userId ?? this.userId,
      totalWatchTime: totalWatchTime ?? this.totalWatchTime,
      videosWatched: videosWatched ?? this.videosWatched,
      completedVideos: completedVideos ?? this.completedVideos,
      favoriteVideoIds: favoriteVideoIds ?? this.favoriteVideoIds,
      badges: badges ?? this.badges,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}