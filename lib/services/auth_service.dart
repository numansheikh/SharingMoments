import 'dart:convert';
import 'dart:html' as html;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

class AuthService   // TODO: Replace these with your actual Google OAuth credentials
  // Get them from: https://console.cloud.google.com/apis/credentials
  static const String _clientId = 'YOUR_GOOGLE_CLIENT_ID_HERE';
  static const String _clientSecret = 'YOUR_GOOGLE_CLIENT_SECRET_HERE';
  static const List<String> _scopes = [
    'https://www.googleapis.com/auth/drive.file',
    'https://www.googleapis.com/auth/drive.metadata.readonly',
  ];

  static const String _redirectUri = 'http://localhost:8080/auth/callback';

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
  static void startAuthFlow() {
    final authUrl = _buildAuthUrl();
    // Open in same window for better callback handling
    html.window.location.href = authUrl;
  }

  // Build authorization URL
  static String _buildAuthUrl() {
    final params = {
      'client_id': _clientId,
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
      final tokenResponse = await http.post(
        Uri.parse('https://oauth2.googleapis.com/token'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'client_id': _clientId,
          'client_secret': _clientSecret,
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
      final tokenResponse = await http.post(
        Uri.parse('https://oauth2.googleapis.com/token'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'client_id': _clientId,
          'client_secret': _clientSecret,
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
