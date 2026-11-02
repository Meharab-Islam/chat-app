import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../../../data/models/user_model.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/chat_repository.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository authRepository;
  final ChatRepository? chatRepository;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isInitialized = false;

  AuthViewModel({required this.authRepository, this.chatRepository});

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserModel? get currentUser => authRepository.currentUser;
  bool get isAuthenticated => authRepository.isAuthenticated;
  bool get isInitialized => _isInitialized;

  void completeInitialization() {
    if (!_isInitialized) {
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final user = await authRepository.signInWithGoogle();
      _setLoading(false);
      if (user == null) {
        _errorMessage = 'Google Sign-In was cancelled.';
        notifyListeners();
        return false;
      }
      chatRepository?.updateCurrentUser(user.id);
      return true;
    } catch (e) {
      final err = e.toString();
      if (err.contains('channel-error') ||
          err.contains('MissingPluginException')) {
        _errorMessage = 'Native plugin channel error. Please stop and rebuild the app using "flutter run".';
      } else if (err.contains('network_error') ||
          err.contains('SocketException') ||
          err.contains('Failed to connect')) {
        _errorMessage = 'Cannot reach backend server. Make sure your server is running on port 5055.';
      } else {
        _errorMessage = err.replaceAll('Exception: ', '');
      }
      _setLoading(false);
      return false;
    }
  }

  Future<void> updateProfileImage(String newPathOrUrl) async {
    final current = currentUser;
    if (current == null) return;
    try {
      if (newPathOrUrl.startsWith('http://') ||
          newPathOrUrl.startsWith('https://')) {
        await authRepository.updateProfile(avatarUrl: newPathOrUrl);
      } else {
        final file = File(newPathOrUrl);
        if (await file.exists()) {
          await authRepository.updateAvatar(file);
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating avatar: $e');
      final updated = current.copyWith(avatarUrl: newPathOrUrl);
      await authRepository.updateUser(updated);
      notifyListeners();
    }
  }

  Future<bool> updateProfileInfo({
    String? name,
    String? bio,
    String? status,
    String? avatarUrl,
  }) async {
    _setLoading(true);
    try {
      await authRepository.updateProfile(
        name: name,
        bio: bio,
        status: status,
        avatarUrl: avatarUrl,
      );
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  Future<void> signOut() async {
    await authRepository.signOut();
    chatRepository?.clearStore();
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
