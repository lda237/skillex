/**
 * Convertit une valeur d'opacité (0.0-1.0) en valeur alpha (0-255)
 * @param {number} opacity - Valeur d'opacité entre 0.0 et 1.0
 * @returns {number} Valeur alpha entre 0 et 255
 */
function convertOpacityToAlpha(opacity) {
  return Math.round(opacity * 255);
}

/**
 * Convertit une valeur alpha (0-255) en valeur d'opacité (0.0-1.0)
 * @param {number} alpha - Valeur alpha entre 0 et 255
 * @returns {number} Valeur d'opacité entre 0.0 et 1.0
 */
function convertAlphaToOpacity(alpha) {
  return alpha / 255;
}

/**
 * Génère le code de remplacement pour withValues
 * @param {string} opacityValue - Valeur d'opacité sous forme de chaîne
 * @returns {string} Code de remplacement avec withValues
 */
function generateWithValuesReplacement(opacityValue) {
  const opacity = parseFloat(opacityValue);
  const alpha = convertOpacityToAlpha(opacity);
  return `.withValues(alpha: ${alpha})`;
}

// Exemple d'utilisation :
// generateWithValuesReplacement("0.7") // Retourne ".withValues(alpha: 179)" 