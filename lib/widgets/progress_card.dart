import 'package:flutter/material.dart';
import '../models/video.dart';

class ProgressCard extends StatelessWidget {
  final Video video;

  const ProgressCard({
    super.key,
    required this.video,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            video.thumbnailUrl,
            width: 60,
            height: 45,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 60,
                height: 45,
                color: Colors.grey[300],
                child: const Icon(Icons.video_library),
              );
            },
          ),
        ),
        title: Text(
          video.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(video.category),
        trailing: const Icon(Icons.play_circle_outline),
        onTap: () {
          Navigator.pushNamed(
            context,
            '/video',
            arguments: video,
          );
        },
      ),
    );
  }
} 