import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'push_notification_service.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PushNotificationService _pushNotificationService =
      PushNotificationService();
  User? _user;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  User? get user => _user;
  Map<String, dynamic>? get userData => _userData;
  bool get isLoading => _isLoading;

  AuthService() {
    _auth.authStateChanges().listen((User? user) async {
      _user = user;
      if (user != null) {
        await _loadUserData(user.uid);
        unawaited(
          _pushNotificationService
              .initializeForUser(user.uid)
              .catchError((_) {}),
        );
      } else {
        _userData = null;
        await _pushNotificationService.dispose();
      }
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> _loadUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists) {
        _userData = doc.data() as Map<String, dynamic>;
      }
    } catch (e) {
      print('Errore caricamento dati utente: $e');
    }
  }

  Future<bool> register(
    String email,
    String password,
    String nome,
    String modelloMoto,
  ) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await result.user?.updateDisplayName(nome);
      await result.user?.reload();

      await _firestore.collection('users').doc(result.user!.uid).set({
        'nome': nome,
        'email': email,
        'modelloMoto': modelloMoto,
        'ruolo': 'user',
        'dataRegistrazione': FieldValue.serverTimestamp(),
      });

      await _loadUserData(result.user!.uid);
      return true;
    } on FirebaseAuthException catch (e) {
      print('Errore registrazione: ${e.message}');
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return true;
    } on FirebaseAuthException catch (e) {
      print('Errore login: ${e.message}');
      return false;
    }
  }

  // Metodo per inviare l'email di reset password
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'Nessun utente trovato con questa email.';
          break;
        case 'invalid-email':
          message = 'Indirizzo email non valido.';
          break;
        default:
          message = 'Errore durante l\'invio dell\'email di reset.';
      }
      throw Exception(message);
    }
  }

  Future<String> recoverUserEmailByName(String nome) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('nome', isEqualTo: nome)
          .limit(2)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception('Nessun utente trovato con questo nome.');
      }

      if (querySnapshot.docs.length > 1) {
        throw Exception(
          'Sono stati trovati più utenti con questo nome. Contatta l\'amministratore.',
        );
      }

      final data = querySnapshot.docs.first.data();
      final email = data['email'] as String?;
      if (email == null || email.isEmpty) {
        throw Exception('Email associata non disponibile.');
      }
      return email;
    } catch (e) {
      if (e is FirebaseAuthException) {
        throw Exception('Errore durante il recupero dell\'utente.');
      }
      rethrow;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  String getDisplayName() {
    return _user?.displayName ?? _userData?['nome'] ?? 'Utente';
  }

  String getModelloMoto() {
    return _userData?['modelloMoto'] ?? 'Non specificato';
  }

  String getRuolo() {
    return _userData?['ruolo'] ?? 'user';
  }

  bool isAdmin() {
    return getRuolo() == 'admin';
  }

  String getEmail() {
    return _user?.email ?? _userData?['email'] ?? '';
  }

  bool isLoggedIn() {
    return _user != null;
  }
}
