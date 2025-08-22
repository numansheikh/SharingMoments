import 'dart:convert';
import 'dart:html' as html;
import 'dart:io';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

class AuthService {
  static String? _clientId;
  static String? _clientSecret;
  
  static const List<String> _scopes = [
    'https://www.googleapis.com/auth/drive.file',
    'https://www.googleapis.com/auth/drive.metadata.readonly',
  ];

  static const String _redirectUri = 'http://localhost:8080/auth/callback';

  // Load credentials from file
  static Future<void> _loadCredentials() async {
    if (_clientId != null && _clientSecret != null) return;
    
    try {
      final file = File('cred.txt');
      if (await file.exists()) {
        final contents = await file.readAsString();
        final lines = contents.split('\n');
        
        for (final line in lines) {
          if (line.startsWith('GOOGLE_CLIENT_ID=')) {
            _clientId = line.substring('GOOGLE_CLIENT_ID='.length).trim();
          } else if (line.startsWith('GOOGLE_CLIENT_SECRET=')) {
            _clientSecret = line.substring('GOOGLE_CLIENT_SECRET='.length).trim();
          }
        }
      }
    } catch (e) {
      print('Error loading credentials: $e');
    }
    
    // Fallback to placeholder values if file not found
    _clientId ??= 'YOUR_GOOGLE_CLIENT_ID_HERE';
    _clientSecret ??= 'YOUR_GOOGLE_CLIENT_SECRET_HERE';
  }

  // Get client ID (loads credentials if needed)
  static Future<String> get _getClientId async {
    await _loadCredentials();
    return _clientId!;
  }

  // Get client secret (loads credentials if needed)
  static Future<String> get _getClientSecret async {
    await _loadCredentials();
    return _clientSecret!;
  }

  // Check if user is already authenticated
  static bool isAuthenticated() {
    final token = html.window.localStorage['access_token'];
    final expiry = html.window.localStorage['token_expiry'];
    
    if (token == null || expiry == null) return false;
    
    final expiryTime = DateTime.parse(expiry).toUtc();
    return DateTime.now().toUtc().isBefore(expiryTime);
  }

  // Get stored access token
  static String? getStoredToken() {
    if (!isAuthenticated()) return null;
    return html.window.localStorage['access_token'];
  }

  // Get stored token expiry
  static DateTime? getStoredTokenExpiry() {
    final expiry = html.window.localStorage['token_expiry'];
    if (expiry == null) return null;
    return DateTime.parse(expiry).toUtc();
  }

  // Store access token
  static void storeToken(String accessToken, DateTime expiry) {
    html.window.localStorage['access_token'] = accessToken;
    html.window.localStorage['token_expiry'] = expiry.toIso8601String();
  }

  // Clear stored token
  static void clearToken() {
    html.window.localStorage.remove('access_token');
    html.window.localStorage.remove('token_expiry');
  }

  // Start OAuth flow
  static Future<void> startAuthFlow() async {
    final authUrl = await _buildAuthUrl();
    // Open in same window for better callback handling
    html.window.location.href = authUrl;
  }

  // Build authorization URL
  static Future<String> _buildAuthUrl() async {
    final clientId = await _getClientId;
    final params = {
      'client_id': clientId,
      'redirect_uri': _redirectUri,
      'scope': _scopes.join(' '),
      'response_type': 'code',
      'access_type': 'offline',
      'prompt': 'consent',
    };

    final queryString = params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return 'https://accounts.google.com/o/oauth2/v2/auth?$queryString';
  }

  // Handle OAuth callback
  static Future<String?> handleCallback(String code) async {
    try {
      final clientId = await _getClientId;
      final clientSecret = await _getClientSecret;
      
      final tokenResponse = await http.post(
        Uri.parse('https://oauth2.googleapis.com/token'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'client_id': clientId,
          'client_secret': clientSecret,
          'code': code,
          'grant_type': 'authorization_code',
          'redirect_uri': _redirectUri,
        },
      );

      if (tokenResponse.statusCode == 200) {
        final tokenData = json.decode(tokenResponse.body);
        print('Token response: $tokenData'); // Debug
        
        // Store refresh token if provided
        if (tokenData['refresh_token'] != null) {
          html.window.localStorage['refresh_token'] = tokenData['refresh_token'];
        }
        
        final accessToken = tokenData['access_token'];
        final expiresIn = tokenData['expires_in'] as int;
        final expiry = DateTime.now().toUtc().add(Duration(seconds: expiresIn));
        
        storeToken(accessToken, expiry);
        return accessToken;
      } else {
        print('Token request failed: ${tokenResponse.statusCode} - ${tokenResponse.body}');
        return null;
      }
    } catch (e) {
      print('Error during token exchange: $e');
      return null;
    }
  }

  // Refresh access token
  static Future<String?> refreshToken() async {
    final refreshToken = html.window.localStorage['refresh_token'];
    if (refreshToken == null) return null;

    try {
      final clientId = await _getClientId;
      final clientSecret = await _getClientSecret;
      
      final tokenResponse = await http.post(
        Uri.parse('https://oauth2.googleapis.com/token'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'client_id': clientId,
          'client_secret': clientSecret,
          'refresh_token': refreshToken,
          'grant_type': 'refresh_token',
        },
      );

      if (tokenResponse.statusCode == 200) {
        final tokenData = json.decode(tokenResponse.body);
        final accessToken = tokenData['access_token'];
        final expiresIn = tokenData['expires_in'] as int;
        final expiry = DateTime.now().toUtc().add(Duration(seconds: expiresIn));
        
        storeToken(accessToken, expiry);
        return accessToken;
      } else {
        print('Token refresh failed: ${tokenResponse.statusCode} - ${tokenResponse.body}');
        return null;
      }
    } catch (e) {
      print('Error during token refresh: $e');
      return null;
    }
  }

  // Sign out
  static void signOut() {
    clearToken();
    html.window.localStorage.remove('refresh_token');
  }
}
