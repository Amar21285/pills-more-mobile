import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Set the base URL of your live VPS server
  static const String baseUrl = 'https://pillsnmore.in/api';

  static Map<String, String> getHeaders(String? token) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // --- AUTHENTICATION ---
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: getHeaders(null),
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );
      return {
        'statusCode': response.statusCode,
        'body': jsonDecode(response.body),
      };
    } catch (e) {
      return {
        'statusCode': 500,
        'body': {'error': 'Failed to connect to server: ${e.toString()}'},
      };
    }
  }

  static Future<Map<String, dynamic>> register(String name, String email, String password, String phone) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: getHeaders(null),
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'phone': phone,
        }),
      );
      return {
        'statusCode': response.statusCode,
        'body': jsonDecode(response.body),
      };
    } catch (e) {
      return {
        'statusCode': 500,
        'body': {'error': 'Failed to connect to server: ${e.toString()}'},
      };
    }
  }

  static Future<Map<String, dynamic>> loginWithGoogle(String idToken) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/google'),
        headers: getHeaders(null),
        body: jsonEncode({
          'idToken': idToken,
        }),
      );
      return {
        'statusCode': response.statusCode,
        'body': jsonDecode(response.body),
      };
    } catch (e) {
      return {
        'statusCode': 500,
        'body': {'error': 'Failed to connect to server: ${e.toString()}'},
      };
    }
  }

  // --- PRODUCTS ---
  static Future<List<dynamic>> fetchProducts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products'),
        headers: getHeaders(null),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // --- ORDERS ---
  static Future<Map<String, dynamic>> createOrder(Map<String, dynamic> orderData, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/orders'),
        headers: getHeaders(token),
        body: jsonEncode(orderData),
      );
      return {
        'statusCode': response.statusCode,
        'body': jsonDecode(response.body),
      };
    } catch (e) {
      return {
        'statusCode': 500,
        'body': {'error': 'Failed to connect to server: ${e.toString()}'},
      };
    }
  }

  static Future<List<dynamic>> fetchMyOrders(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/orders/my-orders'),
        headers: getHeaders(token),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // --- SETTINGS ---
  static Future<Map<String, dynamic>?> fetchSettings() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/settings'),
        headers: getHeaders(null),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // --- ADDRESSES ---
  static Future<List<dynamic>> fetchAddresses(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/addresses'),
        headers: getHeaders(token),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> createAddress(Map<String, dynamic> addressData, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/addresses'),
        headers: getHeaders(token),
        body: jsonEncode(addressData),
      );
      return {
        'statusCode': response.statusCode,
        'body': jsonDecode(response.body),
      };
    } catch (e) {
      return {
        'statusCode': 500,
        'body': {'error': 'Failed to connect to server: ${e.toString()}'},
      };
    }
  }
}

