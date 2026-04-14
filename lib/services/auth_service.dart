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
