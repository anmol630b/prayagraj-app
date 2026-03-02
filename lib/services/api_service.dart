import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';

const String baseUrl = 'https://web-production-d08a8.up.railway.app/api';

String _token = '';
String _username = '';
String _email = '';

class ApiService {
  static void setToken(String token) => _token = token;
  static String get username => _username;
  static String get email => _email;

  static Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/token/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    final data = jsonDecode(response.body);
    if (data.containsKey('access')) {
      _token = data['access'];
      _username = username;
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
    final response = await http.get(Uri.parse(url), headers: {'Authorization': 'Bearer $_token'});
    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> getCategories() async {
    final response = await http.get(Uri.parse('$baseUrl/categories/'), headers: {'Authorization': 'Bearer $_token'});
    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> getCart() async {
    final response = await http.get(Uri.parse('$baseUrl/cart/'), headers: {'Authorization': 'Bearer $_token'});
    return jsonDecode(response.body);
  }

  static Future<bool> addToCart(int productId, int quantity) async {
    final response = await http.post(
      Uri.parse('$baseUrl/cart/'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $_token'},
      body: jsonEncode({'product': productId, 'quantity': quantity}),
    );
    return response.statusCode == 201;
  }

  static Future<bool> placeOrder(String address) async {
    String? fcmToken = await FirebaseMessaging.instance.getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/orders/'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $_token'},
      body: jsonEncode({'address': address, 'fcm_token': fcmToken}),
    );
    return response.statusCode == 201;
  }

  static Future<List<dynamic>> getOrders() async {
    final response = await http.get(Uri.parse('$baseUrl/orders/'), headers: {'Authorization': 'Bearer $_token'});
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> trackOrder(int orderId) async {
    final response = await http.get(Uri.parse('$baseUrl/orders/$orderId/tracking/'), headers: {'Authorization': 'Bearer $_token'});
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> createPayment(int amount) async {
    final response = await http.post(
      Uri.parse('$baseUrl/payment/create/'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $_token'},
      body: jsonEncode({'amount': amount}),
    );
    return jsonDecode(response.body);
  }

  static Future<bool> verifyPayment(String paymentId, String orderId, String signature) async {
    final response = await http.post(
      Uri.parse('$baseUrl/payment/verify/'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $_token'},
      body: jsonEncode({'razorpay_payment_id': paymentId, 'razorpay_order_id': orderId, 'razorpay_signature': signature}),
    );
    return jsonDecode(response.body)['status'] == 'success';
  }

  static Future<Map<String, dynamic>> getAgentStatus() async {
    final response = await http.get(Uri.parse('$baseUrl/agent/status/'), headers: {'Authorization': 'Bearer $_token'});
    return jsonDecode(response.body);
  }
}