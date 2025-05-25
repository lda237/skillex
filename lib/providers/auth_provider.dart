import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? '320421822385-rums8f0lmp368l0hr09i7e6mn5ldhore.apps.googleusercontent.com' : null,
  );
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;
  bool _isAuthenticated = false;
  bool _isAdmin = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _isAuthenticated;
  bool get isAdmin => _isAdmin;

  AuthProvider() {
    _initializeAuth();
  }

  void _initializeAuth() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      _isAuthenticated = user != null;
      _isInitialized = true;
      
      // Vérifier le rôle admin
      if (user != null) {
        _checkAdminStatus(user);
      } else {
        _isAdmin = false;
      }
      
      notifyListeners();
    });
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Inscription avec email/mot de passe - Améliorée
  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      // Validation côté client avant Firebase
      if (!isEmailValid(email)) {
        _setError('Adresse email invalide');
        return false;
      }

      if (!isPasswordValid(password)) {
        _setError('Le mot de passe doit contenir au moins 6 caractères');
        return false;
      }

      if (!isNameValid(name)) {
        _setError('Le nom doit contenir au moins 2 caractères');
        return false;
      }

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Mettre à jour le profil avec retry en cas d'échec
        await _updateUserProfile(credential.user!, name);
        
        // Créer le document utilisateur dans Firestore
        await _createUserDocument(credential.user!, name);
        
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      return false;
    } catch (e) {
      _setError('Une erreur inattendue s\'est produite');
      debugPrint('SignUp Error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Mise à jour du profil avec retry
  Future<void> _updateUserProfile(User user, String name) async {
    int retries = 3;
    while (retries > 0) {
      try {
        await user.updateDisplayName(name);
        await user.reload();
        break;
      } catch (e) {
        retries--;
        if (retries == 0) {
          debugPrint('Failed to update user profile after 3 attempts: $e');
        } else {
          await Future.delayed(Duration(seconds: 1));
        }
      }
    }
  }

  // Connexion avec email/mot de passe - Améliorée
  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      // Validation côté client
      if (!isEmailValid(email)) {
        _setError('Adresse email invalide');
        return false;
      }

      if (password.isEmpty) {
        _setError('Le mot de passe est requis');
        return false;
      }

      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      return false;
    } catch (e) {
      _setError('Une erreur inattendue s\'est produite');
      debugPrint('SignIn Error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Connexion avec Google - Améliorée
  Future<bool> signInWithGoogle() async {
    try {
      _setLoading(true);
      _setError(null);

      // Vérifier la disponibilité de Google Sign-In
      if (!await _googleSignIn.isSignedIn()) {
        // S'assurer qu'aucune session précédente n'existe
        await _googleSignIn.signOut();
      }

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // L'utilisateur a annulé la connexion
        return false;
      }

      final GoogleSignInAuthentication googleAuth = 
          await googleUser.authentication;

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        _setError('Impossible d\'obtenir les informations d\'authentification Google');
        return false;
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      
      if (userCredential.user != null) {
        // Créer ou mettre à jour le document utilisateur
        await _createUserDocument(
          userCredential.user!, 
          userCredential.user!.displayName ?? 'Utilisateur',
        );
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      return false;
    } catch (e) {
      _setError('Erreur lors de la connexion avec Google');
      debugPrint('Google SignIn Error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Réinitialisation du mot de passe - Améliorée
  Future<bool> resetPassword(String email) async {
    try {
      _setLoading(true);
      _setError(null);

      if (!isEmailValid(email)) {
        _setError('Adresse email invalide');
        return false;
      }

      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      return false;
    } catch (e) {
      _setError('Une erreur inattendue s\'est produite');
      debugPrint('Reset Password Error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Déconnexion - Améliorée
  Future<void> signOut() async {
    try {
      _setLoading(true);
      
      // Déconnexion simultanée de Firebase et Google
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);

      _user = null;
      _isAuthenticated = false;
      _isAdmin = false;
      _errorMessage = null;
      
    } catch (e) {
      _setError('Erreur lors de la déconnexion');
      debugPrint('SignOut Error: $e');
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  // Créer le document utilisateur dans Firestore - Améliorée
  Future<void> _createUserDocument(User user, String name) async {
    try {
      final userDocRef = _firestore.collection('users').doc(user.uid);
      final userDoc = await userDocRef.get();
      
      if (!userDoc.exists) {
        await userDocRef.set({
          'uid': user.uid,
          'name': name.trim(),
          'email': user.email,
          'profileImageUrl': user.photoURL,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'lastLoginAt': FieldValue.serverTimestamp(),
          'progress': {
            'totalVideosWatched': 0,
            'totalWatchTime': 0,
            'completedCourses': <String>[],
            'currentStreak': 0,
            'longestStreak': 0,
            'badges': <String>[],
            'lastActivityDate': FieldValue.serverTimestamp(),
          },
          'preferences': {
            'notifications': true,
            'theme': 'system',
            'language': 'fr',
          },
        });
      } else {
        // Mettre à jour la dernière connexion
        await userDocRef.update({
          'lastLoginAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Erreur lors de la création/mise à jour du document utilisateur: $e');
      // Ne pas bloquer l'authentification si Firestore échoue
    }
  }

  // Gestion des erreurs d'authentification - Améliorée
  void _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        _setError('Aucun utilisateur trouvé avec cet email');
        break;
      case 'wrong-password':
        _setError('Mot de passe incorrect');
        break;
      case 'email-already-in-use':
        _setError('Cet email est déjà utilisé');
        break;
      case 'invalid-email':
        _setError('Email invalide');
        break;
      case 'weak-password':
        _setError('Le mot de passe est trop faible');
        break;
      case 'user-disabled':
        _setError('Ce compte a été désactivé');
        break;
      case 'too-many-requests':
        _setError('Trop de tentatives. Veuillez réessayer plus tard');
        break;
      case 'session-expired':
        _handleSessionExpired();
        break;
      default:
        _setError('Une erreur d\'authentification est survenue');
    }
    debugPrint('Auth Error [${e.code}]: ${e.message}');
  }

  // Validation de l'email - Améliorée
  static bool isEmailValid(String email) {
    if (email.trim().isEmpty) return false;
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email.trim());
  }

  // Validation du mot de passe - Améliorée
  static bool isPasswordValid(String password) {
    return password.length >= 6;
  }

  // Validation du nom - Améliorée
  static bool isNameValid(String name) {
    return name.trim().length >= 2 && name.trim().length <= 50;
  }

  // Vérification du statut d'authentification - Simplifiée
  Future<void> checkAuthStatus() async {
    if (!_isInitialized) {
      // Attendre l'initialisation
      while (!_isInitialized) {
        await Future.delayed(Duration(milliseconds: 100));
      }
    }
  }

  // Actualiser les données utilisateur
  Future<void> refreshUser() async {
    try {
      if (_auth.currentUser != null) {
        await _auth.currentUser!.reload();
        _user = _auth.currentUser;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error refreshing user: $e');
    }
  }

  // Obtenir les données utilisateur depuis Firestore
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      if (_user != null) {
        final doc = await _firestore.collection('users').doc(_user!.uid).get();
        return doc.data();
      }
    } catch (e) {
      debugPrint('Error getting user data: $e');
    }
    return null;
  }

  Future<void> _checkAdminStatus(User user) async {
    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      _isAdmin = userDoc.exists && (userDoc.data()?['isAdmin'] ?? false);
      notifyListeners();
    } catch (e) {
      debugPrint('Error checking admin status: $e');
      _isAdmin = false;
    }
  }

  void _handleSessionExpired() {
    signOut();
    _setError('Votre session a expiré. Veuillez vous reconnecter.');
  }
}