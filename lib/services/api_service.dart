import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

final navigatorKey = GlobalKey<NavigatorState>();

const String baseUrl = 'https://web-production-d08a8.up.railway.app/api';

String _token = '';
String _username = '';
String _email = '';

class ApiService {

  static void _handle401() {
    clearSession();
    navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);
  }

  static dynamic _parseResponse(http.Response response) {
    if (response.statusCode == 401) {
      _handle401();
      return {};
    }
    return jsonDecode(response.body);
  }

  static void setToken(String token) => _token = token;
  static String get username => _username;
  static String get email => _email;

  static Future<void> saveSession(String token, String username, String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('username', username);
    await prefs.setString('email', email);
    _token = token;
    _username = username;
    _email = email;
  }

  static Future<bool> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    if (token.isNotEmpty) {
      _token = token;
      _username = prefs.getString('username') ?? '';
      _email = prefs.getString('email') ?? '';
      return true;
    }
    return false;
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _token = '';
    _username = '';
    _email = '';
  }

  // ✅ FIX 1: Login mein email bhi save hota hai ab
  static Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/token/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    final data = jsonDecode(response.body);
    if (data.containsKey('access')) {
      final email = data['email'] ?? '';       // ✅ email ab save hoti hai
      final uname = data['username'] ?? username;
      await saveSession(data['access'], uname, email);
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      String? fcmToken = await messaging.getToken();
      if (fcmToken != null) await saveFCMToken(fcmToken);
    }
    return data;
  }

  static Future<Map<String, dynamic>> register(String username, String password, String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password, 'email': email}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return {'message': 'success', ...data};
    }
    return data;
  }

  static Future<List<dynamic>> getProducts({
    String? search, int? categoryId,
    double? minPrice, double? maxPrice, String? sort,
  }) async {
    String url = '$baseUrl/products/?';
    if (search != null) url += 'search=$search&';
    if (categoryId != null) url += 'category=$categoryId&';
    if (minPrice != null) url += 'min_price=$minPrice&';
    if (maxPrice != null) url += 'max_price=$maxPrice&';
    if (sort != null) url += 'sort=$sort&';
    final response = await http.get(Uri.parse(url),
        headers: {'Authorization': 'Bearer $_token'});
    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> getCategories() async {
    final response = await http.get(Uri.parse('$baseUrl/categories/'),
        headers: {'Authorization': 'Bearer $_token'});
    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> getCart() async {
    final response = await http.get(Uri.parse('$baseUrl/cart/'),
        headers: {'Authorization': 'Bearer $_token'});
    return jsonDecode(response.body);
  }

  static Future<bool> addToCart(int productId, int quantity) async {
    final response = await http.post(
      Uri.parse('$baseUrl/cart/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token'
      },
      body: jsonEncode({'product': productId, 'quantity': quantity}),
    );
    return response.statusCode == 201;
  }

  static Future<bool> updateCartQuantity(int cartItemId, int quantity) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/cart/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token'
      },
      body: jsonEncode({'cart_id': cartItemId, 'quantity': quantity}),
    );
    return response.statusCode == 200;
  }

  static Future<bool> removeFromCart(int cartItemId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/cart/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token'
      },
      body: jsonEncode({'cart_id': cartItemId}),
    );
    return response.statusCode == 200;
  }

  static Future<bool> placeOrder({
    required String address,
    String paymentMethod = 'cod',
  }) async {
    String? fcmToken = await FirebaseMessaging.instance.getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/orders/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token'
      },
      body: jsonEncode({
        'address': address,
        'fcm_token': fcmToken,
        'payment_method': paymentMethod,
      }),
    );
    return response.statusCode == 201;
  }

  static Future<List<dynamic>> getOrders() async {
    final response = await http.get(Uri.parse('$baseUrl/orders/'),
        headers: {'Authorization': 'Bearer $_token'});
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> trackOrder(int orderId) async {
    final response = await http.get(
        Uri.parse('$baseUrl/orders/$orderId/tracking/'),
        headers: {'Authorization': 'Bearer $_token'});
    return jsonDecode(response.body);
  }

  static Future<bool> cancelOrder(int orderId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/orders/$orderId/cancel/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token'
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> changePassword(
      String oldPass, String newPass) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/change-password/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({'old_password': oldPass, 'new_password': newPass}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'error': 'Network error'};
    }
  }

  static Future<Map<String, dynamic>> createPayment(int amount) async {
    final response = await http.post(
      Uri.parse('$baseUrl/payment/create/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token'
      },
      body: jsonEncode({'amount': amount}),
    );
    return jsonDecode(response.body);
  }

  static Future<bool> verifyPayment(
      String paymentId, String orderId, String signature) async {
    final response = await http.post(
      Uri.parse('$baseUrl/payment/verify/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token'
      },
      body: jsonEncode({
        'razorpay_payment_id': paymentId,
        'razorpay_order_id': orderId,
        'razorpay_signature': signature
      }),
    );
    return jsonDecode(response.body)['status'] == 'success';
  }

  static Future<Map<String, dynamic>> getAgentStatus() async {
    final response = await http.get(Uri.parse('$baseUrl/agent/status/'),
        headers: {'Authorization': 'Bearer $_token'});
    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> getChatMessages() async {
    final response = await http.get(
      Uri.parse('$baseUrl/chat/'),
      headers: {'Authorization': 'Bearer $_token'},
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> sendChatMessage(String message) async {
    final response = await http.post(
      Uri.parse('$baseUrl/chat/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
      body: jsonEncode({'message': message}),
    );
    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> getSavedAddresses() async {
    final response = await http.get(
      Uri.parse('$baseUrl/addresses/'),
      headers: {'Authorization': 'Bearer $_token'},
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> addSavedAddress(String label, String address, bool isDefault) async {
    final response = await http.post(
      Uri.parse('$baseUrl/addresses/'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $_token'},
      body: jsonEncode({'label': label, 'address': address, 'is_default': isDefault}),
    );
    return jsonDecode(response.body);
  }

  static Future<void> deleteSavedAddress(int id) async {
    await http.delete(
      Uri.parse('$baseUrl/addresses/$id/'),
      headers: {'Authorization': 'Bearer $_token'},
    );
  }

  static Future<Map<String, dynamic>> getProductRatings(int productId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/products/$productId/ratings/'),
      headers: {'Authorization': 'Bearer $_token'},
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> addRating(int productId, int orderId, int stars, String review) async {
    final response = await http.post(
      Uri.parse('$baseUrl/products/$productId/ratings/'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $_token'},
      body: jsonEncode({'order_id': orderId, 'stars': stars, 'review': review}),
    );
    return jsonDecode(response.body);
  }

  static Future<void> saveFCMToken(String token) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/fcm-token/'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $_token'},
        body: jsonEncode({'token': token}),
      );
    } catch (e) {}
  }

  static Future<List<dynamic>> getWishlist() async {
    final response = await http.get(
      Uri.parse('$baseUrl/wishlist/'),
      headers: {'Authorization': 'Bearer $_token'},
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> toggleWishlist(int productId, bool wishlisted) async {
    if (wishlisted) {
      await http.delete(
        Uri.parse('$baseUrl/wishlist/$productId/'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      return {'wishlisted': false};
    } else {
      final response = await http.post(
        Uri.parse('$baseUrl/wishlist/$productId/'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      return jsonDecode(response.body);
    }
  }

  static Future<dynamic> getOrderTracking(int orderId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/orders/$orderId/tracking/'),
      headers: {'Authorization': 'Bearer $_token'},
    );
    return jsonDecode(response.body);
  }

  static Future<void> updateProfile({String? phone, String? email, String? avatarUrl}) async {
    await http.post(
      Uri.parse('$baseUrl/profile/'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $_token'},
      body: jsonEncode({
        if (phone != null) 'phone': phone,
        if (email != null) 'email': email,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
      }),
    );
  }

  static Future<Map<String, dynamic>> getProfile() async {
    final response = await http.get(
      Uri.parse('$baseUrl/profile/'),
      headers: {'Authorization': 'Bearer $_token'},
    );
    return jsonDecode(response.body);
  }
}