import 'package:cloud_firestore/cloud_firestore.dart';

class VideoProgress {
  final String userId;
  final String videoId;
  int watchTime;
  int totalDuration;
  bool isCompleted;
  DateTime lastWatched;
  final DateTime createdAt;

  VideoProgress({
    required this.userId,
    required this.videoId,
    required this.watchTime,
    required this.totalDuration,
    required this.isCompleted,
    required this.lastWatched,
    required this.createdAt,
  });

  factory VideoProgress.fromFirestore(Map<String, dynamic> data) {
    return VideoProgress(
      userId: data['userId'] ?? '',
      videoId: data['videoId'] ?? '',
      watchTime: data['watchTime'] ?? 0,
      totalDuration: data['totalDuration'] ?? 0,
      isCompleted: data['isCompleted'] ?? false,
      lastWatched: (data['lastWatched'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'videoId': videoId,
      'watchTime': watchTime,
      'totalDuration': totalDuration,
      'isCompleted': isCompleted,
      'lastWatched': Timestamp.fromDate(lastWatched),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
} 