import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

class ApiService {
  static const String baseUrl = 'https://api.vakyapro.com/api';
  static const String _tokenKey = 'auth_token';

  // Helper to get headers
  Future<Map<String, String>> _getHeaders({bool isAuth = false}) async {
    final headers = {'Content-Type': 'application/json'};
    if (isAuth) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  // Handle generic API responses
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return json.decode(response.body);
    } else {
      String errorMessage = 'Unexpected error occurred';
      try {
        final errorData = json.decode(response.body);
        if (errorData['errors'] != null) {
          // Format validation errors
          final Map<String, dynamic> errors = errorData['errors'];
          errorMessage = errors.values.map((e) => (e as List).join(', ')).join('\n');
        } else if (errorData['message'] != null) {
          errorMessage = errorData['message'];
        }
      } catch (_) {
        errorMessage = 'Failed to process request: ${response.statusCode} - ${response.reasonPhrase}';
      }
      throw Exception(errorMessage);
    }
  }

  // --- 1. Authentication (Public) ---

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<bool> hasToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_tokenKey);
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/auth/login');
    final response = await http.post(
      url,
      headers: await _getHeaders(),
      body: json.encode({'email': email, 'password': password}),
    );
    final data = _handleResponse(response);
    await saveToken(data['access_token']);
    return data;
  }

  Future<Map<String, dynamic>> registerWithEmailOTP(String name, String email, String password) async {
    final url = Uri.parse('$baseUrl/auth/email/register');
    final response = await http.post(
      url,
      headers: await _getHeaders(),
      body: json.encode({
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': password,
      }),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> verifyEmailOTP(String email, String code) async {
    final url = Uri.parse('$baseUrl/auth/email/verify');
    final response = await http.post(
      url,
      headers: await _getHeaders(),
      body: json.encode({
        'email': email,
        'code': code,
      }),
    );
    final data = _handleResponse(response);
    await saveToken(data['access_token']);
    return data;
  }
  
  Future<Map<String, dynamic>> resendEmailOTP(String email) async {
    final url = Uri.parse('$baseUrl/auth/email/resend');
    final response = await http.post(
      url,
      headers: await _getHeaders(),
      body: json.encode({'email': email}),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> loginWithGoogle(String idToken) async {
    final url = Uri.parse('$baseUrl/auth/google');
    final response = await http.post(
      url,
      headers: await _getHeaders(),
      body: json.encode({'token': idToken}),
    );
    final data = _handleResponse(response);
    await saveToken(data['access_token']);
    return data;
  }

  Future<void> logout() async {
    try {
      final url = Uri.parse('$baseUrl/auth/logout');
      await http.post(url, headers: await _getHeaders(isAuth: true));
    } catch (e) {
      developer.log('Logout API failed, continuing with local cleanup', error: e);
    } finally {
      await removeToken();
    }
  }

  // --- 2. User Profile (Protected) ---

  Future<Map<String, dynamic>> getProfile() async {
    final url = Uri.parse('$baseUrl/auth/me');
    final response = await http.get(url, headers: await _getHeaders(isAuth: true));
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> updateProfile(String name, {String? avatar}) async {
    final url = Uri.parse('$baseUrl/profile');
    final Map<String, dynamic> body = {'name': name};
    if (avatar != null) body['avatar'] = avatar;

    final response = await http.put(
      url,
      headers: await _getHeaders(isAuth: true),
      body: json.encode(body),
    );
    return _handleResponse(response);
  }

  // --- 4. AI Features (Protected) ---

  Future<Map<String, dynamic>> generatePrompt(String prompt, {List<dynamic>? history, int questionCount = 0}) async {
    final url = Uri.parse('$baseUrl/prompts/generate');
    final response = await http.post(
      url,
      headers: await _getHeaders(isAuth: true),
      body: json.encode({
        'prompt': prompt,
        'history': history ?? [],
        'question_count': questionCount,
      }),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getPromptHistory() async {
    final url = Uri.parse('$baseUrl/prompts');
    final response = await http.get(url, headers: await _getHeaders(isAuth: true));
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> aiChat(List<Map<String, dynamic>> messages) async {
    final url = Uri.parse('$baseUrl/ai/chat');
    final response = await http.post(
      url,
      headers: await _getHeaders(isAuth: true),
      body: json.encode({'messages': messages}),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> generateImage(String prompt, {String size = '1024x1024'}) async {
    final url = Uri.parse('$baseUrl/ai/image');
    final response = await http.post(
      url,
      headers: await _getHeaders(isAuth: true),
      body: json.encode({'prompt': prompt, 'size': size}),
    );
    return _handleResponse(response);
  }

  // --- 5. Chat Sessions (Protected) ---

  Future<List<dynamic>> getChatSessions() async {
    final url = Uri.parse('$baseUrl/chat-sessions');
    final response = await http.get(url, headers: await _getHeaders(isAuth: true));
    final data = _handleResponse(response);
    return data['data'] ?? data;
  }

  Future<Map<String, dynamic>> createChatSession(String title, List<Map<String, dynamic>> messages) async {
    final url = Uri.parse('$baseUrl/chat-sessions');
    final response = await http.post(
      url,
      headers: await _getHeaders(isAuth: true),
      body: json.encode({'title': title, 'messages': messages}),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> updateChatSession(String sessionId, String title, List<Map<String, dynamic>> messages) async {
    final url = Uri.parse('$baseUrl/chat-sessions/$sessionId');
    final response = await http.put(
      url,
      headers: await _getHeaders(isAuth: true),
      body: json.encode({'title': title, 'messages': messages}),
    );
    return _handleResponse(response);
  }

  Future<void> deleteChatSession(String sessionId) async {
    final url = Uri.parse('$baseUrl/chat-sessions/$sessionId');
    final response = await http.delete(url, headers: await _getHeaders(isAuth: true));
    _handleResponse(response);
  }

  // --- 6. Plans & Data (Public) ---
  
  Future<List<dynamic>> getPlans() async {
    final url = Uri.parse('$baseUrl/plans');
    final response = await http.get(url, headers: await _getHeaders());
    final data = _handleResponse(response);
    return data['data'] ?? [];
  }
}
