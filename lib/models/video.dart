import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Video {
  final String id;
  final String title;
  final String description;
  final String thumbnailUrl;
  final String category;
  final int duration; // en secondes
  final int viewCount;
  final DateTime publishedAt;
  final String youtubeId;
  final String channelTitle;
  final List<String> tags;
  final String difficulty; // Débutant, Intermédiaire, Avancé
  final bool isPremium;

  Video({
    required this.id,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    required this.category,
    required this.duration,
    required this.viewCount,
    required this.publishedAt,
    required this.youtubeId,
    required this.channelTitle,
    this.tags = const [],
    this.difficulty = 'Débutant',
    this.isPremium = false,
  });

  // Convertir depuis JSON
  factory Video.fromJson(Map<String, dynamic> json) {
    return Video(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      thumbnailUrl: json['thumbnailUrl'] ?? '',
      category: json['category'] ?? 'Général',
      duration: json['duration'] ?? 0,
      viewCount: json['viewCount'] ?? 0,
      publishedAt: DateTime.tryParse(json['publishedAt'] ?? '') ?? DateTime.now(),
      youtubeId: json['youtubeId'] ?? '',
      channelTitle: json['channelTitle'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      difficulty: json['difficulty'] ?? 'Débutant',
      isPremium: json['isPremium'] ?? false,
    );
  }

  // Convertir vers JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'thumbnailUrl': thumbnailUrl,
      'category': category,
      'duration': duration,
      'viewCount': viewCount,
      'publishedAt': publishedAt.toIso8601String(),
      'youtubeId': youtubeId,
      'channelTitle': channelTitle,
      'tags': tags,
      'difficulty': difficulty,
      'isPremium': isPremium,
    };
  }

  // Convertir depuis YouTube API
  factory Video.fromYouTubeApi(Map<String, dynamic> json) {
    final snippet = json['snippet'] ?? {};
    final statistics = json['statistics'] ?? {};
    final contentDetails = json['contentDetails'] ?? {};
    
    return Video(
      id: json['id'] ?? '',
      title: snippet['title'] ?? '',
      description: snippet['description'] ?? '',
      thumbnailUrl: snippet['thumbnails']?['high']?['url'] ?? 
                    snippet['thumbnails']?['medium']?['url'] ?? 
                    snippet['thumbnails']?['default']?['url'] ?? '',
      category: _getCategoryFromYouTube(snippet['categoryId']),
      duration: _parseDuration(contentDetails['duration'] ?? 'PT0S'),
      viewCount: int.tryParse(statistics['viewCount'] ?? '0') ?? 0,
      publishedAt: DateTime.tryParse(snippet['publishedAt'] ?? '') ?? DateTime.now(),
      youtubeId: json['id'] ?? '',
      channelTitle: snippet['channelTitle'] ?? '',
      tags: List<String>.from(snippet['tags'] ?? []),
    );
  }

  // Convertir depuis Firestore
  factory Video.fromFirestore(Map<String, dynamic> data) {
    return Video(
      id: data['id'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      thumbnailUrl: data['thumbnailUrl'] ?? '',
      category: data['category'] ?? 'Général',
      duration: data['duration'] ?? 0,
      viewCount: data['viewCount'] ?? 0,
      publishedAt: (data['publishedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      youtubeId: data['youtubeId'] ?? '',
      channelTitle: data['channelTitle'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      difficulty: data['difficulty'] ?? 'Débutant',
      isPremium: data['isPremium'] ?? false,
    );
  }

  // Convertir vers Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'thumbnailUrl': thumbnailUrl,
      'category': category,
      'duration': duration,
      'viewCount': viewCount,
      'publishedAt': Timestamp.fromDate(publishedAt),
      'youtubeId': youtubeId,
      'channelTitle': channelTitle,
      'tags': tags,
      'difficulty': difficulty,
      'isPremium': isPremium,
    };
  }

  // Formater la durée en texte lisible
  String get formattedDuration {
    final hours = duration ~/ 3600;
    final minutes = (duration % 3600) ~/ 60;
    final seconds = duration % 60;

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    }
  }

  // Formater le nombre de vues
  String get formattedViewCount {
    if (viewCount >= 1000000) {
      return '${(viewCount / 1000000).toStringAsFixed(1)}M vues';
    } else if (viewCount >= 1000) {
      return '${(viewCount / 1000).toStringAsFixed(1)}K vues';
    } else {
      return '$viewCount vues';
    }
  }

  // Obtenir la couleur de difficulté
  Color get difficultyColor {
    switch (difficulty) {
      case 'Débutant':
        return Colors.green;
      case 'Intermédiaire':
        return Colors.orange;
      case 'Avancé':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Copier avec modifications
  Video copyWith({
    String? id,
    String? title,
    String? description,
    String? thumbnailUrl,
    String? category,
    int? duration,
    int? viewCount,
    DateTime? publishedAt,
    String? youtubeId,
    String? channelTitle,
    List<String>? tags,
    String? difficulty,
    bool? isPremium,
  }) {
    return Video(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      category: category ?? this.category,
      duration: duration ?? this.duration,
      viewCount: viewCount ?? this.viewCount,
      publishedAt: publishedAt ?? this.publishedAt,
      youtubeId: youtubeId ?? this.youtubeId,
      channelTitle: channelTitle ?? this.channelTitle,
      tags: tags ?? this.tags,
      difficulty: difficulty ?? this.difficulty,
      isPremium: isPremium ?? this.isPremium,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Video && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Video{id: $id, title: $title, category: $category}';
  }

  // Méthodes utilitaires privées
  static String _getCategoryFromYouTube(String? categoryId) {
    // Mapping des catégories YouTube vers nos catégories
    switch (categoryId) {
      case '27': return 'Éducation';
      case '28': return 'Science & Technologie';
      case '22': return 'Personnalité & Blog';
      case '24': return 'Divertissement';
      case '26': return 'Actualité & Politique';
      default: return 'Général';
    }
  }

  static int _parseDuration(String duration) {
    // Parse ISO 8601 duration (PT1H30M45S)
    final regex = RegExp(r'PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?');
    final match = regex.firstMatch(duration);
    
    if (match == null) return 0;
    
    final hours = int.tryParse(match.group(1) ?? '0') ?? 0;
    final minutes = int.tryParse(match.group(2) ?? '0') ?? 0;
    final seconds = int.tryParse(match.group(3) ?? '0') ?? 0;
    
    return hours * 3600 + minutes * 60 + seconds;
  }

  // Obtenir l'URL de la vidéo YouTube
  String get youtubeUrl => 'https://www.youtube.com/watch?v=$youtubeId';

  // Obtenir l'URL de la miniature en haute qualité
  String get highQualityThumbnailUrl => 'https://img.youtube.com/vi/$youtubeId/maxresdefault.jpg';

  // Obtenir l'URL de la miniature en qualité moyenne
  String get mediumQualityThumbnailUrl => 'https://img.youtube.com/vi/$youtubeId/hqdefault.jpg';

  // Vérifier si la vidéo est récente (moins de 7 jours)
  bool get isRecent => DateTime.now().difference(publishedAt).inDays <= 7;

  // Vérifier si la vidéo est populaire (plus de 100K vues)
  bool get isPopular => viewCount >= 100000;

  // Obtenir la durée formatée avec unité
  String get durationWithUnit {
    if (duration >= 3600) {
      return '${(duration / 3600).toStringAsFixed(1)} heures';
    } else if (duration >= 60) {
      return '${(duration / 60).toStringAsFixed(0)} minutes';
    } else {
      return '$duration secondes';
    }
  }

  // Obtenir la date formatée
  String get formattedPublishedDate {
    final now = DateTime.now();
    final difference = now.difference(publishedAt);

    if (difference.inDays == 0) {
      return "Aujourd'hui";
    } else if (difference.inDays == 1) {
      return "Hier";
    } else if (difference.inDays < 7) {
      return "Il y a ${difference.inDays} jours";
    } else if (difference.inDays < 30) {
      return "Il y a ${(difference.inDays / 7).floor()} semaines";
    } else if (difference.inDays < 365) {
      return "Il y a ${(difference.inDays / 30).floor()} mois";
    } else {
      return "Il y a ${(difference.inDays / 365).floor()} ans";
    }
  }

  // Valider les données de la vidéo
  bool get isValid {
    return id.isNotEmpty &&
           title.isNotEmpty &&
           youtubeId.isNotEmpty &&
           thumbnailUrl.isNotEmpty &&
           duration > 0;
  }

  // Obtenir le niveau de difficulté en nombre
  int get difficultyLevel {
    switch (difficulty) {
      case 'Débutant':
        return 1;
      case 'Intermédiaire':
        return 2;
      case 'Avancé':
        return 3;
      default:
        return 0;
    }
  }
}