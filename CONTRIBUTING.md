# Guide de Contribution - Skillex

Ce document décrit les bonnes pratiques de versionnement et de contribution au projet Skillex.

## Structure des Branches

- `master` : Branche principale stable
- `develop` : Branche de développement
- `feature/*` : Branches pour les nouvelles fonctionnalités
- `bugfix/*` : Branches pour les corrections de bugs
- `release/*` : Branches pour les versions

## Workflow de Développement

### 1. Développement d'une Nouvelle Fonctionnalité

```bash
# Créer une nouvelle branche feature
git checkout -b feature/nom-de-la-fonctionnalite

# Développer votre fonctionnalité
# ... votre code ...

# Une fois terminé
git add .
git commit -m "feat: description de la fonctionnalité"
git push origin feature/nom-de-la-fonctionnalite

# Créer une Pull Request sur GitHub pour merger dans develop
```

### 2. Correction d'un Bug

```bash
# Créer une branche bugfix
git checkout -b bugfix/description-du-bug

# Corriger le bug
# ... votre code ...

# Une fois terminé
git add .
git commit -m "fix: description de la correction"
git push origin bugfix/description-du-bug

# Créer une Pull Request sur GitHub pour merger dans develop
```

### 3. Préparation d'une Release

```bash
# Créer une branche release
git checkout -b release/v1.0.0

# Faire les derniers ajustements
# ... votre code ...

# Une fois prêt
git add .
git commit -m "chore: prepare release v1.0.0"
git push origin release/v1.0.0

# Créer une Pull Request sur GitHub pour merger dans master
```

## Conventions de Nommage

### Messages de Commit

Utilisez les préfixes suivants pour vos messages de commit :

- `feat:` : Nouvelle fonctionnalité
- `fix:` : Correction de bug
- `docs:` : Documentation
- `style:` : Changements de style
- `refactor:` : Refactoring
- `test:` : Tests
- `chore:` : Tâches de maintenance

### Branches

- `feature/nom-fonctionnalite`
- `bugfix/description-bug`
- `release/v1.0.0`

## Bonnes Pratiques

1. **Commits**
   - Faites des commits fréquents
   - Utilisez des messages descriptifs
   - Un commit = une modification logique

2. **Branches**
   - Gardez vos branches à jour avec `develop`
   - Utilisez `git pull origin develop` régulièrement
   - Supprimez les branches après merge

3. **Pull Requests**
   - Créez une PR pour chaque merge
   - Décrivez clairement les changements
   - Attendez la review avant de merger

4. **Code**
   - Suivez les conventions de code Flutter
   - Écrivez des tests unitaires
   - Documentez votre code

## Commandes Git Utiles

```bash
# Voir l'état des fichiers
git status

# Voir l'historique des commits
git log

# Mettre à jour sa branche
git pull origin develop

# Annuler des modifications
git checkout -- fichier

# Créer une nouvelle branche
git checkout -b nom-branche

# Changer de branche
git checkout nom-branche
```

## Processus de Review

1. Créez une Pull Request sur GitHub
2. Attendez la review d'au moins un autre développeur
3. Corrigez les commentaires si nécessaire
4. Une fois approuvé, mergez dans `develop`
5. Supprimez la branche après le merge

## Questions ?

Si vous avez des questions sur le processus de contribution, n'hésitez pas à :

- Ouvrir une issue sur GitHub
- Contacter l'équipe de développement
- Consulter la documentation Flutter
