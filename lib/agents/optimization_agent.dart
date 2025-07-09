import 'package:flutter/material.dart';

/// Agent d'optimisation pour améliorer les performances de l'application
class OptimizationAgent {
  /// Widget optimisé pour le chargement d'images
  static Widget optimizedImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                : null,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return const Icon(Icons.error);
      },
    );
  }

  /// Widget optimisé pour les listes
  static Widget optimizedListView({
    required List<Widget> children,
    ScrollController? controller,
  }) {
    return ListView.builder(
      controller: controller,
      itemCount: children.length,
      itemBuilder: (context, index) {
        return children[index];
      },
    );
  }

  /// Méthode pour optimiser la taille des images
  static String getOptimizedImageUrl(String originalUrl, {int width = 300}) {
    // Ajouter des paramètres d'optimisation selon votre service d'images
    return '$originalUrl?w=$width&q=80';
  }

  /// Widget optimisé pour le cache des données
  static Widget cachedNetworkImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    return Image.network(
      getOptimizedImageUrl(imageUrl),
      width: width,
      height: height,
      fit: fit,
      cacheWidth: (width ?? 300).toInt(),
      cacheHeight: (height ?? 300).toInt(),
    );
  }
}