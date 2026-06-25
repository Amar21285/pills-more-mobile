import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    final userStr = prefs.getString('auth_user');
    if (userStr != null) {
      _user = jsonDecode(userStr);
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

  Future<void> logout() async {
    _token = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_user');
    notifyListeners();
  }
}
