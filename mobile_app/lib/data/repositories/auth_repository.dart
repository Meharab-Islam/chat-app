import 'dart:io';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

class AuthRepository {
  final AuthService authService;
  final StorageService storageService;

  AuthRepository({
    required this.authService,
    required this.storageService,
  }) {
    final savedUser = storageService.getSavedUser();
    final hasToken = storageService.hasValidToken();
    // Strictly require a saved user with valid auth token. Reject any fake/demo session.
    if (savedUser != null &&
        hasToken &&
        !savedUser.id.startsWith('usr_meharab')) {
      final token = storageService.getAccessToken();
      authService.restoreUser(savedUser, accessToken: token);
    } else {
      authService.restoreUser(null);
      storageService.clearUser();
    }
  }

  UserModel? get currentUser => authService.currentUser;
  bool get isAuthenticated => authService.isAuthenticated;

  Future<UserModel?> signInWithGoogle() async {
    final user = await authService.signInWithGoogle();
    if (user != null) {
      await storageService.saveUser(user);
    }
    return user;
  }

  Future<void> updateUser(UserModel user) async {
    authService.restoreUser(user);
    await storageService.saveUser(user);
  }

  Future<UserModel> updateProfile({
    String? name,
    String? bio,
    String? status,
    String? avatarUrl,
  }) async {
    final updated = await authService.updateProfile(
      name: name,
      bio: bio,
      status: status,
      avatarUrl: avatarUrl,
    );
    await storageService.saveUser(updated);
    return updated;
  }

  Future<UserModel> updateAvatar(File imageFile) async {
    final updated = await authService.updateAvatar(imageFile);
    await storageService.saveUser(updated);
    return updated;
  }

  Future<void> signOut() async {
    await authService.signOut();
    await storageService.clearUser();
  }
}
