import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String id; // Document ID
  final String videoId;
  final String userId;
  final String userName; // Denormalized for easier display
  final String? userProfilePicUrl; // Denormalized
  final String text;
  final Timestamp timestamp;
  final int likesCount;
  final bool isEdited;
  // final int repliesCount; // Future: for threaded comments

  Comment({
    required this.id,
    required this.videoId,
    required this.userId,
    required this.userName,
    this.userProfilePicUrl,
    required this.text,
    required this.timestamp,
    this.likesCount = 0,
    this.isEdited = false,
    // this.repliesCount = 0,
  });

  factory Comment.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Comment(
      id: doc.id,
      videoId: data['videoId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Anonymous',
      userProfilePicUrl: data['userProfilePicUrl'],
      text: data['text'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
      likesCount: data['likesCount'] ?? 0,
      isEdited: data['isEdited'] ?? false,
      // repliesCount: data['repliesCount'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'videoId': videoId,
      'userId': userId,
      'userName': userName,
      'userProfilePicUrl': userProfilePicUrl,
      'text': text,
      'timestamp': timestamp, // Or FieldValue.serverTimestamp() for new comments
      'likesCount': likesCount,
      'isEdited': isEdited,
      // 'repliesCount': repliesCount,
    };
  }
}
