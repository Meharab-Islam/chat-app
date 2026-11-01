import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'api_client.dart';
import 'socket_service.dart';

class AuthService {
  static const String serverClientId =
      '366527404345-qf56pvo90k61dhqsqlnkbs23kgffoa1v.apps.googleusercontent.com';
  static const String iOSClientId =
      '366527404345-io77q4ek23teumbg96bdh8iumsudp8c2.apps.googleusercontent.com';

  static const String serverBaseUrl = 'http://107.174.137.29:5055/api';
  static const String realDeviceBaseUrl = serverBaseUrl;
  static const String emulatorBaseUrl = serverBaseUrl;
  static const String localhostBaseUrl = serverBaseUrl;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: !kIsWeb && (Platform.isIOS || Platform.isMacOS)
        ? iOSClientId
        : null,
    serverClientId: serverClientId,
    scopes: ['email', 'profile'],
  );

  final SocketService socketService = SocketService();
  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  static String get resolvedBaseUrl {
    if (!kIsWeb && Platform.isAndroid) {
      // In Android emulator 10.0.2.2 points to host machine localhost
      // In real device 192.168.0.116 is used
      return realDeviceBaseUrl;
    }
    return realDeviceBaseUrl;
  }

  Future<UserModel?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('User cancelled Google Sign-in');
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      debugPrint('Google Sign-In successful: ${googleUser.email}');
      if (idToken != null) {
        debugPrint(
          'Google ID Token obtained: ${idToken.substring(0, idToken.length > 25 ? 25 : idToken.length)}...',
        );
      }

      // Node.js Backend Verification with idToken
      if (idToken == null) {
        throw Exception('Google Auth did not return an idToken.');
      }

      final backendUser = await _verifyWithBackend(idToken);
      if (backendUser == null) {
        throw Exception(
          'Backend verification failed. Ensure server is running at $resolvedBaseUrl.',
        );
      }

      _currentUser = backendUser;
      return _currentUser;
    } catch (error) {
      debugPrint('Google Sign-In caught error: $error');
      // Do not silently fallback to demo mode. Propagate error to view model.
      rethrow;
    }
  }

  Future<UserModel?> _verifyWithBackend(String idToken) async {
    final urlsToTry = [
      resolvedBaseUrl,
      emulatorBaseUrl,
      localhostBaseUrl,
    ];

    for (final base in urlsToTry) {
      try {
        final response = await http
            .post(
              Uri.parse('$base/auth/google'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'idToken': idToken}),
            )
            .timeout(const Duration(seconds: 10));

        final responseData = jsonDecode(response.body);
        if (response.statusCode == 200 && responseData['success'] == true) {
          final data = responseData['data'];
          final String backendAccessToken = data['tokens']['accessToken'];
          final String backendRefreshToken = data['tokens']['refreshToken'];
          final Map<String, dynamic> userMap = data['user'];

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('accessToken', backendAccessToken);
          await prefs.setString('refreshToken', backendRefreshToken);
          await prefs.setString('userId', userMap['id'] ?? '');
          await prefs.setString('userName', userMap['name'] ?? '');

          // Connect real-time socket
          final socketHost = base.replaceAll('/api', '');
          socketService.connect(
            accessToken: backendAccessToken,
            socketUrl: socketHost,
          );

          debugPrint('Backend login verified! User: ${userMap['name']}');
          return UserModel(
            id: userMap['id'] ?? 'usr_google',
            name: userMap['name'] ?? 'Google User',
            email: userMap['email'] ?? '',
            avatarUrl: userMap['avatarUrl'] ?? '',
            isOnline: true,
          );
        } else {
          debugPrint('Backend response error [${response.statusCode}] from $base: ${response.body}');
        }
      } catch (err) {
        debugPrint('Connection attempt failed to $base: $err');
      }
    }
    return null;
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      socketService.disconnect();

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('accessToken');
      await prefs.remove('refreshToken');
      await prefs.remove('userId');
      await prefs.remove('userName');
    } catch (_) {}
    _currentUser = null;
  }

  void restoreUser(UserModel? user, {String? accessToken}) {
    _currentUser = user;
    if (user != null && accessToken != null && accessToken.isNotEmpty) {
      final socketHost = resolvedBaseUrl.replaceAll('/api', '');
      socketService.connect(
        accessToken: accessToken,
        socketUrl: socketHost,
      );
    }
  }

  Future<UserModel> updateProfile({
    String? name,
    String? bio,
    String? status,
    String? avatarUrl,
  }) async {
    final body = <String, dynamic>{};
    if (name != null && name.isNotEmpty) body['name'] = name;
    if (bio != null) body['bio'] = bio;
    if (status != null) body['status'] = status;
    if (avatarUrl != null) body['avatarUrl'] = avatarUrl;

    final data = await ApiClient().put('/users/profile', body);
    if (data is Map<String, dynamic>) {
      _currentUser = _currentUser?.copyWith(
        name: data['name'] as String?,
        avatarUrl: data['avatarUrl'] as String?,
        status: data['status'] as String?,
        bio: data['bio'] as String?,
      );
    }
    return _currentUser!;
  }

  Future<UserModel> updateAvatar(File imageFile) async {
    final data = await ApiClient().postMultipart(
      endpoint: '/users/avatar',
      fields: {},
      files: [imageFile],
      fileFieldName: 'avatar',
    );
    if (data is Map<String, dynamic>) {
      final rawUrl = data['avatarUrl'] as String? ?? '';
      _currentUser = _currentUser?.copyWith(avatarUrl: ApiClient.resolveUrl(rawUrl));
    }
    return _currentUser!;
  }
}
