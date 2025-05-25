import 'package:cloud_firestore/cloud_firestore.dart';

class Playlist {
  final String id;
  final String title;
  final String description;
  final List<String> videoIds;
  final String category;
  final String difficulty;
  final String creatorId;
  final DateTime createdAt;
  final bool isPublic;
  final String thumbnailUrl;
  final int totalDuration;
  final int videoCount;
  final Map<String, dynamic> metadata;

  Playlist({
    required this.id,
    required this.title,
    required this.description,
    required this.videoIds,
    required this.category,
    required this.difficulty,
    required this.creatorId,
    required this.createdAt,
    this.isPublic = true,
    this.thumbnailUrl = '',
    this.totalDuration = 0,
    this.videoCount = 0,
    this.metadata = const {},
  });

  // Convertir depuis Firestore
  factory Playlist.fromFirestore(Map<String, dynamic> data) {
    return Playlist(
      id: data['id'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      videoIds: List<String>.from(data['videoIds'] ?? []),
      category: data['category'] ?? 'Général',
      difficulty: data['difficulty'] ?? 'Débutant',
      creatorId: data['creatorId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isPublic: data['isPublic'] ?? true,
      thumbnailUrl: data['thumbnailUrl'] ?? '',
      totalDuration: data['totalDuration'] ?? 0,
      videoCount: data['videoCount'] ?? 0,
      metadata: data['metadata'] ?? {},
    );
  }

  // Convertir vers Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'videoIds': videoIds,
      'category': category,
      'difficulty': difficulty,
      'creatorId': creatorId,
      'createdAt': Timestamp.fromDate(createdAt),
      'isPublic': isPublic,
      'thumbnailUrl': thumbnailUrl,
      'totalDuration': totalDuration,
      'videoCount': videoCount,
      'metadata': metadata,
    };
  }

  // Copier avec modifications
  Playlist copyWith({
    String? id,
    String? title,
    String? description,
    List<String>? videoIds,
    String? category,
    String? difficulty,
    String? creatorId,
    DateTime? createdAt,
    bool? isPublic,
    String? thumbnailUrl,
    int? totalDuration,
    int? videoCount,
    Map<String, dynamic>? metadata,
  }) {
    return Playlist(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      videoIds: videoIds ?? this.videoIds,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      creatorId: creatorId ?? this.creatorId,
      createdAt: createdAt ?? this.createdAt,
      isPublic: isPublic ?? this.isPublic,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      totalDuration: totalDuration ?? this.totalDuration,
      videoCount: videoCount ?? this.videoCount,
      metadata: metadata ?? this.metadata,
    );
  }

  // Obtenir la durée formatée
  String get formattedDuration {
    final hours = totalDuration ~/ 3600;
    final minutes = (totalDuration % 3600) ~/ 60;

    if (hours > 0) {
      return '$hours h ${minutes.toString().padLeft(2, '0')} min';
    } else {
      return '$minutes min';
    }
  }

  // Vérifier si la playlist est vide
  bool get isEmpty => videoIds.isEmpty;

  // Vérifier si la playlist est complète
  bool get isComplete => videoCount > 0 && videoCount == videoIds.length;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Playlist && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Playlist{id: $id, title: $title, videoCount: $videoCount}';
  }
} 