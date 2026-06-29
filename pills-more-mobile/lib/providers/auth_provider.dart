import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  String? _token;
  Map<String, dynamic>? _user;
  bool _isLoading = false;

  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  bool get isAuthenticated => _token != null;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _loadStoredSession();
  }

  Future<void> _loadStoredSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('auth_token');
      final userStr = prefs.getString('auth_user');
      if (userStr != null) {
        _user = jsonDecode(userStr);
      }
    } catch (e) {
      print('[AUTH SESSION ERROR] Failed to load stored session: $e');
      // Clear corrupted cache to prevent repeated crashes
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
      } catch (_) {}
    }
    notifyListeners();
  }

  Future<String?> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    final response = await ApiService.login(email, password);
    _isLoading = false;

    if (response['statusCode'] == 200) {
      final body = response['body'];
      _token = body['token'];
      _user = body['user'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', _token!);
      await prefs.setString('auth_user', jsonEncode(_user));
      
      notifyListeners();
      return null; // Success
    } else {
      notifyListeners();
      return response['body']['error'] ?? 'Login failed. Please try again.';
    }
  }

  Future<String?> register(String name, String email, String password, String phone) async {
    _isLoading = true;
    notifyListeners();

    final response = await ApiService.register(name, email, password, phone);
    _isLoading = false;

    if (response['statusCode'] == 201 || response['statusCode'] == 200) {
      notifyListeners();
      return null; // Success
    } else {
      notifyListeners();
      return response['body']['error'] ?? 'Registration failed.';
    }
  }

  Future<String?> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        // Pass clientId only on Web to prevent startup assertion crash.
        // On Android/iOS, it is read from the Google Services config files automatically.
        clientId: kIsWeb ? 'your-google-client-id-here.apps.googleusercontent.com' : null,
        scopes: ['email'],
      );
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return 'Sign in cancelled by user';
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        _isLoading = false;
        notifyListeners();
        return 'Failed to get ID Token from Google';
      }

      final response = await ApiService.loginWithGoogle(idToken);
      _isLoading = false;

      if (response['statusCode'] == 200) {
        final body = response['body'];
        _token = body['token'];
        _user = body['user'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _token!);
        await prefs.setString('auth_user', jsonEncode(_user));
        
        notifyListeners();
        return null; // Success
      } else {
        notifyListeners();
        return response['body']['error'] ?? 'Google login failed';
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return 'Google sign-in error: ${e.toString()}';
    }
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_user');
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      // Ignore signout error if not signed in with Google
    }
    notifyListeners();
  }
}
