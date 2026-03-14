import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

class ApiService {
  static const String baseUrl = 'https://api.vakyapro.com/api';
  static const String _tokenKey = 'auth_token';

  // Helper to get headers
  Future<Map<String, String>> _getHeaders({bool isAuth = false}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
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
      if (response.body.isEmpty) return {}; // Return empty map instead of null
      try {
        return json.decode(response.body);
      } catch (e) {
        return {}; // Fallback for non-json success bodies
      }
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

  Future<void> saveToken(String? token) async {
    if (token == null || token.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<bool> hasToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    return token != null && token.isNotEmpty;
  }

  Future<Map<String, dynamic>> register(String name, String email, String password) async {
    final url = Uri.parse('$baseUrl/auth/register');
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
    final data = _handleResponse(response);
    if (data is Map && data['access_token'] != null) {
      await saveToken(data['access_token'].toString());
    }
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/auth/login');
    final response = await http.post(
      url,
      headers: await _getHeaders(),
      body: json.encode({'email': email, 'password': password}),
    );
    final data = _handleResponse(response);
    if (data is Map && data['access_token'] != null) {
      await saveToken(data['access_token'].toString());
    }
    return data is Map ? Map<String, dynamic>.from(data) : {};
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
    final data = _handleResponse(response);
    return data is Map ? Map<String, dynamic>.from(data) : {};
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
    if (data is Map && data['access_token'] != null) {
      await saveToken(data['access_token'].toString());
    }
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }
  
  Future<Map<String, dynamic>> resendEmailOTP(String email) async {
    final url = Uri.parse('$baseUrl/auth/email/resend');
    final response = await http.post(
      url,
      headers: await _getHeaders(),
      body: json.encode({'email': email}),
    );
    final data = _handleResponse(response);
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  Future<Map<String, dynamic>> loginWithGoogle(String idToken) async {
    final url = Uri.parse('$baseUrl/auth/google');
    final response = await http.post(
      url,
      headers: await _getHeaders(),
      body: json.encode({'token': idToken}),
    );
    final data = _handleResponse(response);
    if (data is Map && data['access_token'] != null) {
      await saveToken(data['access_token'].toString());
    }
    return data is Map ? Map<String, dynamic>.from(data) : {};
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
    final data = _handleResponse(response);
    return data is Map ? Map<String, dynamic>.from(data) : {};
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
    final data = _handleResponse(response);
    return data is Map ? Map<String, dynamic>.from(data) : {};
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
    final data = _handleResponse(response);
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  Future<Map<String, dynamic>> getPromptHistory() async {
    final url = Uri.parse('$baseUrl/prompts');
    final response = await http.get(url, headers: await _getHeaders(isAuth: true));
    final data = _handleResponse(response);
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  Future<Map<String, dynamic>> aiChat(List<Map<String, dynamic>> messages) async {
    final url = Uri.parse('$baseUrl/ai/chat');
    final response = await http.post(
      url,
      headers: await _getHeaders(isAuth: true),
      body: json.encode({'messages': messages, 'stream': false}),
    );
    final data = _handleResponse(response);
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  /// AI Chat with Streaming (SSE)
  Stream<String> aiChatStream(List<Map<String, dynamic>> messages) async* {
    final url = Uri.parse('$baseUrl/ai/chat/stream');
    final client = http.Client();
    try {
      final request = http.Request('POST', url);
      request.headers.addAll(await _getHeaders(isAuth: true));
      request.headers['Accept'] = 'text/event-stream';
      request.headers['Cache-Control'] = 'no-cache';
      request.body = json.encode({'messages': messages});

      final response = await client.send(request);
      developer.log('Stream response status: ${response.statusCode}', name: 'ApiService');

      if (response.statusCode != 200) {
        final body = await response.stream.bytesToString();
        developer.log('Streaming failed with body: $body', name: 'ApiService');
        throw Exception('Streaming failed: ${response.statusCode} - $body');
      }

      // Process SSE stream
      await for (final line in response.stream.transform(utf8.decoder).transform(const LineSplitter())) {
        if (line.trim().isEmpty) continue;
        developer.log('Stream line: $line', name: 'ApiService');
        if (line.startsWith('data: ') && line.length >= 6) {
          final data = line.substring(6).trim();
          if (data == '[DONE]') {
            developer.log('Stream finished [DONE]', name: 'ApiService');
            break;
          }
          try {
            final decoded = json.decode(data);
            final content = decoded['content'] ?? 
                           (decoded['choices']?[0]?['delta']?['content'] ?? '');
            if (content.isNotEmpty) {
              yield content.toString();
            }
          } catch (e) {
            // If it's not JSON, it might be raw text
            developer.log('Stream decode error or raw text: $e', name: 'ApiService');
            yield data;
          }
        }
      }
    } catch (e) {
      developer.log('Stream error: $e', error: e, name: 'ApiService');
      rethrow;
    } finally {
      client.close();
    }
  }

  Future<Map<String, dynamic>> generateImage(String prompt, {String size = '1024x1024'}) async {
    final url = Uri.parse('$baseUrl/ai/image');
    final response = await http.post(
      url,
      headers: await _getHeaders(isAuth: true),
      body: json.encode({'prompt': prompt, 'size': size}),
    );
    final data = _handleResponse(response);
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  // --- 5. Chat Sessions (Protected) ---

  Future<List<dynamic>> getChatSessions() async {
    final url = Uri.parse('$baseUrl/chat-sessions');
    final response = await http.get(url, headers: await _getHeaders(isAuth: true));
    final data = _handleResponse(response);
    if (data is Map) return data['data'] ?? [];
    return data is List ? data : [];
  }

  Future<Map<String, dynamic>> createChatSession(String title, List<Map<String, dynamic>> messages) async {
    final url = Uri.parse('$baseUrl/chat-sessions');
    final response = await http.post(
      url,
      headers: await _getHeaders(isAuth: true),
      body: json.encode({'title': title, 'messages': messages}),
    );
    final data = _handleResponse(response);
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  Future<Map<String, dynamic>> getChatSession(String sessionId) async {
    final url = Uri.parse('$baseUrl/chat-sessions/$sessionId');
    final response = await http.get(url, headers: await _getHeaders(isAuth: true));
    final data = _handleResponse(response);
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  Future<Map<String, dynamic>> updateChatSession(String sessionId, String title, List<Map<String, dynamic>> messages) async {
    final url = Uri.parse('$baseUrl/chat-sessions/$sessionId');
    final response = await http.put(
      url,
      headers: await _getHeaders(isAuth: true),
      body: json.encode({'title': title, 'messages': messages}),
    );
    final data = _handleResponse(response);
    return data is Map ? Map<String, dynamic>.from(data) : {};
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
    if (data is Map) return data['data'] ?? [];
    return data is List ? data : [];
  }

  /// Fetch multiple app settings (e.g., prefix='onboarding_')
  Future<Map<String, String>> getAppSettings({String? prefix, List<String>? keys}) async {
    var uri = Uri.parse('$baseUrl/app-settings');
    final Map<String, dynamic> queryParams = {};
    if (prefix != null) queryParams['prefix'] = prefix;
    if (keys != null && keys.isNotEmpty) queryParams['keys[]'] = keys;
    
    if (queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }

    try {
      final response = await http.get(uri, headers: await _getHeaders());
      final data = _handleResponse(response);
      final List<dynamic> items = data is Map ? (data['data'] ?? []) : [];
      
      final Map<String, String> settings = {};
      for (var item in items) {
        if (item is Map<String, dynamic>) {
          final key = item['setting_key']?.toString();
          final val = item['setting_value']?.toString();
          if (key != null && val != null) {
            settings[key] = val;
          }
        }
      }
      return settings;
    } catch (e) {
      developer.log('Failed to fetch app settings', error: e);
      return {};
    }
  }

  /// Fetch a single app setting by key
  Future<String?> getAppSetting(String key) async {
    try {
      final url = Uri.parse('$baseUrl/app-settings/$key');
      final response = await http.get(url, headers: await _getHeaders());
      final data = _handleResponse(response);
      if (data is Map) return data['data']?['setting_value']?.toString();
      return null;
    } catch (e) {
      developer.log('Failed to fetch single app setting: $key', error: e);
      return null;
    }
  }
}
