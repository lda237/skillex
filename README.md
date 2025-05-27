# Skillex - Plateforme d'Apprentissage en Ligne

Skillex est une application mobile de formation en ligne qui permet aux utilisateurs d'apprendre de nouvelles compétences à travers des vidéos de qualité.

## 🚀 Fonctionnalités Implémentées

### Authentification

- ✅ Connexion avec email/mot de passe
- ✅ Connexion avec Google
- ✅ Inscription de nouveaux utilisateurs
- ✅ Récupération de mot de passe
- ✅ Gestion des sessions utilisateur

### Interface Utilisateur

- ✅ Écran de démarrage animé
- ✅ Écran d'accueil avec animations
- ✅ Thème clair/sombre
- ✅ Interface responsive
- ✅ Navigation fluide entre les écrans

### Gestion des Vidéos

- ✅ Intégration YouTube API
- ✅ Lecture de vidéos
- ✅ Catégorisation des vidéos
- ✅ Recherche de vidéos
- ✅ Filtrage par catégories
- ✅ Affichage des miniatures

### Profil Utilisateur

- ✅ Affichage des informations utilisateur
- ✅ Historique de visionnage
- ✅ Suivi de progression
- ✅ Badges et réalisations

### Gestion des playlists

- 🔄 Création et édition de playlists
- 🔄 Organisation des vidéos par playlist
- 🔄 Partage de playlists
- 🔄 Filtrage par catégorie et difficulté
- 🔄 Suivi de progression par playlist

## 🛠️ Fonctionnalités en Cours de Développement

### Contenu

- 🔄 Système de playlists
- 🔄 Recommandations personnalisées
- 🔄 Contenu premium
- 🔄 Système de notes et commentaires

### Social

- 🔄 Partage de vidéos
- 🔄 Système de likes
- 🔄 Commentaires sur les vidéos
- 🔄 Suivi d'autres utilisateurs

### Progression

- 🔄 Certificats de complétion
- 🔄 Système de points d'expérience
- 🔄 Niveaux d'apprentissage
- 🔄 Quiz et exercices

## 📋 Fonctionnalités à Venir

### Premium

- ⏳ Abonnement premium
- ⏳ Contenu exclusif
- ⏳ Téléchargement de vidéos
- ⏳ Accès hors ligne

### Apprentissage

- ⏳ Système de mentorat
- ⏳ Sessions en direct
- ⏳ Exercices pratiques
- ⏳ Projets guidés

### Communauté

- ⏳ Forums de discussion
- ⏳ Groupes d'étude
- ⏳ Événements virtuels
- ⏳ Collaboration en temps réel

## 🛠️ Technologies Utilisées

- **Frontend**: Flutter
- **Backend**: Firebase
- **Base de données**: Firestore
- **Authentification**: Firebase Auth
- **Stockage**: Firebase Storage
- **API Vidéo**: YouTube Data API

## 📱 Configuration Requise

- Android 6.0 (API level 23) ou supérieur
- iOS 11.0 ou supérieur
- Connexion Internet
- Compte Google (pour certaines fonctionnalités)

## 🔧 Installation

1. Clonez le repository

```bash
git clone https://github.com/lda237/skillex.git
```

1. Installez les dépendances

```bash
flutter pub get
```

1. Configurez Firebase

- Créez un projet Firebase
- Ajoutez votre fichier `google-services.json`
- Configurez les règles Firestore

1. Configurez YouTube API

- Ajoutez la clé API dans les variables d'environnement

1. Lancez l'application

```bash
flutter run
```

## Configuration des variables d'environnement

1. Copiez le fichier `.env.example` vers `.env` :

```bash
cp .env.example .env
```

1. Remplissez les variables dans le fichier `.env` avec vos clés API :

- `YOUTUBE_API_KEY` : Votre clé API YouTube
- `YOUTUBE_CHANNEL_ID` : L'ID de votre chaîne YouTube
- `FIREBASE_API_KEY` : Votre clé API Firebase
- `FIREBASE_AUTH_DOMAIN` : Votre domaine d'authentification Firebase
- `FIREBASE_PROJECT_ID` : L'ID de votre projet Firebase
- `FIREBASE_STORAGE_BUCKET` : Votre bucket de stockage Firebase
- `FIREBASE_MESSAGING_SENDER_ID` : Votre ID d'expéditeur Firebase
- `FIREBASE_APP_ID` : Votre ID d'application Firebase

1. Pour le développement, vous pouvez utiliser les variables d'environnement de Flutter :

```bash
flutter run --dart-define=YOUTUBE_API_KEY=your_key --dart-define=FIREBASE_API_KEY=your_key
```

## Sécurité

- Ne jamais commiter le fichier `.env` dans le dépôt Git
- Utiliser des clés API différentes pour le développement et la production
- Mettre en place une rotation régulière des clés API
- Limiter les quotas d'API pour éviter les abus
