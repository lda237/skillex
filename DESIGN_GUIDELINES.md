# Guide de Design de Skillex

Ce document définit les standards et les conventions de design pour l'application Skillex. L'objectif est d'assurer une expérience utilisateur (UX) cohérente et une interface (UI) de haute qualité.

## 1. Palette de Couleurs

La palette est basée sur un jeu de couleurs primaires, neutres et sémantiques.

### Couleurs Primaires
-   **Primary (`primaryColor`):** `#2563EB` - Utilisée pour les actions principales, les boutons, les liens et les éléments actifs.
-   **Secondary (`secondaryColor`):** `#3B82F6` - Utilisée comme une couleur d'accentuation pour les dégradés et les éléments secondaires.
-   **Accent (`accentColor`):** `#06B6D4` - Utilisée pour des points d'attention spécifiques ou des indicateurs.

### Couleurs Neutres
-   **Background (`backgroundColor`):** `#F8FAFC` - Couleur de fond principale de l'application en mode clair.
-   **Surface (`surfaceColor`):** `#FFFFFF` - Couleur de fond pour les éléments en premier plan comme les cartes (Cards).
-   **Texte Principal:** `#334155` - Couleur pour la majorité du texte.
-   **Texte Secondaire:** `#64748B` - Couleur pour les descriptions, les sous-titres et les textes moins importants.

### Couleurs Sémantiques
-   **Erreur (`errorColor`):** `#EF4444` - Pour les messages d'erreur, les champs invalides et les actions destructrices.
-   **Succès (`successColor`):** `#10B981` - Pour les messages de confirmation et les indicateurs de succès.
-   **Avertissement (`warningColor`):** `#F59E0B` - Pour les avertissements et les informations importantes.

### Couleurs du Mode Sombre
-   **Primary (Dark):** `#1E40AF`
-   **Background (Dark):** `#0F172A`
-   **Surface (Dark):** `#1E293B`
-   **Texte (Dark):** `#E2E8F0`

## 2. Typographie

La police de caractères principale de l'application est **Inter**, importée via `google_fonts`.

### Hiérarchie
-   `displayLarge` (32pt, Bold): Titres d'écran très importants.
-   `displayMedium` (28pt, Bold): Titres d'écran principaux (ex: "Bon retour !").
-   `headlineLarge` (24pt, Semi-Bold): Titres de section majeurs.
-   `headlineMedium` (20pt, Semi-Bold): Titres de section (ex: "À propos de Skillex").
-   `titleLarge` (18pt, Semi-Bold): Titres de cartes ou d'éléments importants.
-   `bodyLarge` (16pt, Normal): Corps de texte principal.
-   `bodyMedium` (14pt, Normal): Texte secondaire, descriptions.

## 3. Espacement et Mise en Page

Un système d'espacement cohérent est utilisé pour garantir une mise en page harmonieuse.

-   **Unité de base :** `8.0`
-   **Marges et Paddings courants :**
    -   Padding d'écran : `24.0` (horizontal)
    -   Padding de contenu (dans les cartes) : `16.0`
    -   Espacement entre les éléments : `16.0`
    -   Espacement entre les sections : `24.0` ou `32.0`

## 4. Composants de l'UI

### Boutons
-   **`ElevatedButton` (Bouton plein) :** Pour l'action la plus importante d'un écran (ex: "Se connecter", "Créer un compte"). Utilise `primaryColor`.
-   **`OutlinedButton` (Bouton contour) :** Pour les actions secondaires (ex: "Continuer avec Google").
-   **`TextButton` (Bouton texte) :** Pour les actions moins importantes (ex: "Mot de passe oublié ?").

### Cartes (Cards)
-   Les cartes doivent avoir un `borderRadius` de `16.0`.
-   L'élévation (`elevation`) doit être subtile (`0` à `2`).
-   La couleur de fond doit être `Theme.of(context).colorScheme.surface`.

### Champs de Texte (Text Fields)
-   Utiliser le widget `CustomTextField` pour la cohérence.
-   Le `borderRadius` des bordures est de `12.0`.
-   La bordure focus utilise `primaryColor`.

## 5. Iconographie

-   Utiliser la bibliothèque **Material Icons** fournie par Flutter.
-   Les icônes doivent être sémantiques et leur signification claire pour l'utilisateur.
-   Tailles standards : `18px` (dans les tabs), `20px` (dans les champs de texte), `24px` (taille par défaut).
