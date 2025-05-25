import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // For consistent text styling if needed

class PlaylistDetailsSkeletonWidget extends StatelessWidget {
  const PlaylistDetailsSkeletonWidget({Key? key}) : super(key: key);

  Widget _buildPlaceholder({double? width, required double height, double borderRadius = 4.0}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }

  Widget _buildVideoItemSkeleton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPlaceholder(width: 100, height: 60, borderRadius: 8), // Thumbnail
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                _buildPlaceholder(height: 16), // Title line 1
                const SizedBox(height: 6),
                _buildPlaceholder(width: MediaQuery.of(context).size.width * 0.4, height: 14), // Title line 2 or channel
                const SizedBox(height: 6),
                _buildPlaceholder(width: MediaQuery.of(context).size.width * 0.2, height: 12), // Duration or other info
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView( // To mimic the structure of a details screen
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Playlist Header Skeleton
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPlaceholder(height: 28, width: MediaQuery.of(context).size.width * 0.7), // Playlist Title
                const SizedBox(height: 10),
                _buildPlaceholder(height: 18, width: MediaQuery.of(context).size.width * 0.4), // Creator or count
                const SizedBox(height: 16),
                _buildPlaceholder(height: 40, width: MediaQuery.of(context).size.width * 0.5), // e.g. Play All / Shuffle buttons row
                const SizedBox(height: 10),
                _buildPlaceholder(height: 16), // Description line 1
                const SizedBox(height: 6),
                _buildPlaceholder(height: 16), // Description line 2
                const SizedBox(height: 6),
                _buildPlaceholder(height: 16, width: MediaQuery.of(context).size.width * 0.8), // Description line 3
              ],
            ),
          ),
          const Divider(height: 1),
          // List of Video Item Skeletons
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 5, // Show a few skeleton items
            itemBuilder: (context, index) => _buildVideoItemSkeleton(context),
          ),
        ],
      ),
    );
  }
}
