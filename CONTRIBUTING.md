# Guide de Contribution pour Skillex

Merci de vouloir contribuer à l'amélioration de Skillex !

Ce document a pour but de définir un ensemble de règles et de bonnes pratiques pour assurer la cohérence, la qualité et la maintenabilité du code source.

## Principes Généraux

1.  **Consistance avant tout :** Avant d'écrire du code, prenez le temps de parcourir les fichiers existants pour comprendre les conventions et l'architecture en place.
2.  **Petites contributions :** Privilégiez les modifications petites et ciblées. Une Pull Request (PR) doit idéalement adresser un seul besoin (une seule correction de bug ou l'ajout d'une seule fonctionnalité).
3.  **Le code doit fonctionner :** Assurez-vous que l'application se compile et s'exécute sans erreur après vos modifications.

## Style de Code

-   **Langage :** Le code est écrit en Dart. Les commentaires et le texte visible par l'utilisateur sont en français.
-   **Formatage :** Le code doit être formaté avec l'outil standard de Dart (`dart format`).
-   **Conventions de nommage :**
    -   Classes, Enums, Mixins : `UpperCamelCase` (ex: `PlaylistProvider`).
    -   Variables, méthodes, fonctions : `lowerCamelCase` (ex: `loadUserProgress`).
    -   Fichiers : `snake_case` (ex: `playlist_provider.dart`).
-   **Linting :** Respectez les règles définies dans le fichier `analysis_options.yaml`.

## Architecture du Projet

L'application suit une architecture claire qui sépare les responsabilités. Il est impératif de la respecter.

-   `lib/models/` : Contient les objets de données (ex: `Playlist`, `Video`). Ils doivent être immuables (utiliser `copyWith` pour les modifications) et contenir la logique de sérialisation (`fromFirestore`, `toFirestore`).
-   `lib/services/` : Contient toute la logique de communication avec des sources externes (API YouTube, base de données Firestore). **Les services ne doivent jamais être appelés directement depuis l'interface utilisateur (UI).**
-   `lib/providers/` : Sert de pont entre les services et l'UI. Les providers appellent les services pour récupérer/modifier les données, gèrent l'état de la logique métier (chargement, erreurs) et notifient l'UI des changements via `notifyListeners()`.
-   `lib/screens/` & `lib/widgets/` : Contiennent l'UI. Les widgets doivent être aussi "simples" que possible. Leur rôle est d'afficher l'état fourni par les providers et de remonter les interactions de l'utilisateur en appelant les méthodes des providers.

## Gestion de l'État

-   **Provider est roi :** La gestion d'état doit se faire exclusivement avec le package `provider`.
-   **Lecture de l'état :** Pour écouter les changements et reconstruire un widget, utilisez `context.watch<MonProvider>()` ou le widget `Consumer`.
-   **Appel de méthodes :** Pour appeler une fonction d'un provider sans écouter les changements (dans un `onPressed` par exemple), utilisez `context.read<MonProvider>()`.

## Processus pour Ajouter une Nouvelle Fonctionnalité

Pour ajouter une nouvelle fonctionnalité, suivez ces étapes dans l'ordre :

1.  **Modèle :** Si nécessaire, créez ou mettez à jour le modèle de données dans `lib/models/`.
2.  **Service :** Ajoutez la logique de récupération ou de modification des données dans le service approprié dans `lib/services/`.
3.  **Provider :** Créez ou mettez à jour un provider dans `lib/providers/` pour gérer l'état de la nouvelle fonctionnalité. C'est ici que vous appellerez votre service.
4.  **UI :** Construisez l'interface utilisateur dans un nouveau fichier dans `lib/screens/` et/ou `lib/widgets/`. Connectez l'UI au provider pour afficher les données et remonter les actions.
5.  **Route :** Ajoutez la nouvelle route dans le fichier `lib/main.dart`.

### Règle d'Or pour les Widgets

**Autonomie des Méthodes de "Build" Privées**

Les méthodes privées dont le but est de construire une partie de l'interface (commençant par `_build...`) ne doivent pas recevoir de paramètres comme `ThemeData` ou `Size`. Elles doivent plutôt prendre le `BuildContext` en paramètre et obtenir elles-mêmes les dépendances dont elles ont besoin (ex: `Theme.of(context)`, `MediaQuery.of(context)`). Cela rend les méthodes plus autonomes et le code plus lisible.

*   **Mauvais exemple :** `Widget _buildTitle(ThemeData theme) { ... }`
*   **Bon exemple :** `Widget _buildTitle(BuildContext context) { final theme = Theme.of(context); ... }`

### Règle d'Or pour les Widgets

**Autonomie des Méthodes de "Build" Privées**

Les méthodes privées dont le but est de construire une partie de l'interface (commençant par `_build...`) ne doivent pas recevoir de paramètres comme `ThemeData` ou `Size`. Elles doivent plutôt prendre le `BuildContext` en paramètre et obtenir elles-mêmes les dépendances dont elles ont besoin (ex: `Theme.of(context)`, `MediaQuery.of(context)`). Cela rend les méthodes plus autonomes et le code plus lisible.

*   **Mauvais exemple :** `Widget _buildTitle(ThemeData theme) { ... }`
*   **Bon exemple :** `Widget _buildTitle(BuildContext context) { final theme = Theme.of(context); ... }`

### Règle d'Or pour les Widgets

**Autonomie des Méthodes de "Build" Privées**

Les méthodes privées dont le but est de construire une partie de l'interface (commençant par `_build...`) ne doivent pas recevoir de paramètres comme `ThemeData` ou `Size`. Elles doivent plutôt prendre le `BuildContext` en paramètre et obtenir elles-mêmes les dépendances dont elles ont besoin (ex: `Theme.of(context)`, `MediaQuery.of(context)`). Cela rend les méthodes plus autonomes et le code plus lisible.

*   **Mauvais exemple :** `Widget _buildTitle(ThemeData theme) { ... }`
*   **Bon exemple :** `Widget _buildTitle(BuildContext context) { final theme = Theme.of(context); ... }`

### Règle d'Or pour les Widgets

**Autonomie des Méthodes de "Build" Privées**

Les méthodes privées dont le but est de construire une partie de l'interface (commençant par `_build...`) ne doivent pas recevoir de paramètres comme `ThemeData` ou `Size`. Elles doivent plutôt prendre le `BuildContext` en paramètre et obtenir elles-mêmes les dépendances dont elles ont besoin (ex: `Theme.of(context)`, `MediaQuery.of(context)`). Cela rend les méthodes plus autonomes et le code plus lisible.

*   **Mauvais exemple :** `Widget _buildTitle(ThemeData theme) { ... }`
*   **Bon exemple :** `Widget _buildTitle(BuildContext context) { final theme = Theme.of(context); ... }`

### Règle d'Or pour les Widgets

**Autonomie des Méthodes de "Build" Privées**

Les méthodes privées dont le but est de construire une partie de l'interface (commençant par `_build...`) ne doivent pas recevoir de paramètres comme `ThemeData` ou `Size`. Elles doivent plutôt prendre le `BuildContext` en paramètre et obtenir elles-mêmes les dépendances dont elles ont besoin (ex: `Theme.of(context)`, `MediaQuery.of(context)`). Cela rend les méthodes plus autonomes et le code plus lisible.

*   **Mauvais exemple :** `Widget _buildTitle(ThemeData theme) { ... }`
*   **Bon exemple :** `Widget _buildTitle(BuildContext context) { final theme = Theme.of(context); ... }`

### Règle d'Or pour les Widgets

**Autonomie des Méthodes de "Build" Privées**

Les méthodes privées dont le but est de construire une partie de l'interface (commençant par `_build...`) ne doivent pas recevoir de paramètres comme `ThemeData` ou `Size`. Elles doivent plutôt prendre le `BuildContext` en paramètre et obtenir elles-mêmes les dépendances dont elles ont besoin (ex: `Theme.of(context)`, `MediaQuery.of(context)`). Cela rend les méthodes plus autonomes et le code plus lisible.

*   **Mauvais exemple :** `Widget _buildTitle(ThemeData theme) { ... }`
*   **Bon exemple :** `Widget _buildTitle(BuildContext context) { final theme = Theme.of(context); ... }`

### Règle d'Or pour les Widgets

**Autonomie des Méthodes de "Build" Privées**

Les méthodes privées dont le but est de construire une partie de l'interface (commençant par `_build...`) ne doivent pas recevoir de paramètres comme `ThemeData` ou `Size`. Elles doivent plutôt prendre le `BuildContext` en paramètre et obtenir elles-mêmes les dépendances dont elles ont besoin (ex: `Theme.of(context)`, `MediaQuery.of(context)`). Cela rend les méthodes plus autonomes et le code plus lisible.

*   **Mauvais exemple :** `Widget _buildTitle(ThemeData theme) { ... }`
*   **Bon exemple :** `Widget _buildTitle(BuildContext context) { final theme = Theme.of(context); ... }`

### Règle d'Or pour les Widgets

**Autonomie des Méthodes de "Build" Privées**

Les méthodes privées dont le but est de construire une partie de l'interface (commençant par `_build...`) ne doivent pas recevoir de paramètres comme `ThemeData` ou `Size`. Elles doivent plutôt prendre le `BuildContext` en paramètre et obtenir elles-mêmes les dépendances dont elles ont besoin (ex: `Theme.of(context)`, `MediaQuery.of(context)`). Cela rend les méthodes plus autonomes et le code plus lisible.

*   **Mauvais exemple :** `Widget _buildTitle(ThemeData theme) { ... }`
*   **Bon exemple :** `Widget _buildTitle(BuildContext context) { final theme = Theme.of(context); ... }`

## Messages de Commit

Utilisez la norme [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/). Le message doit être clair, concis et en anglais de préférence (pour respecter les standards internationaux).

**Format :** `<type>(<scope>): <sujet>`

-   **Types principaux :**
    -   `feat` : Pour l'ajout d'une nouvelle fonctionnalité.
    -   `fix` : Pour la correction d'un bug.
    -   `refactor` : Pour des changements qui n'ajoutent ni fonctionnalité ni ne corrigent de bug.
    -   `docs` : Pour des changements dans la documentation.
    -   `style` : Pour des changements de style (formatage, etc.).
    -   `chore` : Pour des tâches de maintenance (mise à jour de dépendances, etc.).

**Exemples :**

-   `feat(auth): Add Google Sign-In functionality`
-   `fix(profile): Correct user avatar display bug`
-   `docs(readme): Update setup instructions`