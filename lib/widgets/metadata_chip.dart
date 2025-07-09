import 'package:flutter/material.dart';

/// Un widget de "chip" standardisé pour afficher des métadonnées (ex: durée, catégorie).
class MetadataChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const MetadataChip({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        // Utilise la couleur secondaire avec une faible opacité pour un look subtil
        color: theme.colorScheme.secondary.withAlpha(26),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium!.color!.withAlpha(200),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
