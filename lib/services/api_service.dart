import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String baseUrl = 'https://web-production-d08a8.up.railway.app/api';

String _token = '';
String _username = '';
String _email = '';

class ApiService {
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
    }
    return data;
  }

  static Future<Map<String, dynamic>> register(String username, String password, String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password, 'email': email}),
    );
    if (response.statusCode == 201) {
      _username = username;
      _email = email;
    }
    return jsonDecode(response.body);
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

  // ✅ FIX 2: placeOrder mein payment details bhi bhejo — Django verify karega
  static Future<bool> placeOrder(
    String address, {
    required String paymentId,
    required String razorpayOrderId,
    required String signature,
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
        'razorpay_payment_id': paymentId,       // ✅ payment verify hoga
        'razorpay_order_id': razorpayOrderId,
        'razorpay_signature': signature,
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
}