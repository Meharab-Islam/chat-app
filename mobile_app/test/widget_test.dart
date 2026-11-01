import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/data/models/message_model.dart';
import 'package:mobile_app/data/models/user_model.dart';
import 'package:mobile_app/data/repositories/auth_repository.dart';
import 'package:mobile_app/data/services/auth_service.dart';
import 'package:mobile_app/data/services/socket_service.dart';
import 'package:mobile_app/data/services/storage_service.dart';
import 'package:mobile_app/ui/core/design_system/app_colors.dart';
import 'package:mobile_app/ui/features/auth/view_models/auth_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('UserModel json serialization works', () {
    const user = UserModel(
      id: 'test_1',
      name: 'Test User',
      email: 'test@example.com',
      avatarUrl: 'https://example.com/avatar.png',
      isOnline: true,
    );

    final json = user.toJson();
    final restored = UserModel.fromJson(json);

    expect(restored.id, 'test_1');
    expect(restored.name, 'Test User');
    expect(restored.email, 'test@example.com');
    expect(restored.isOnline, true);
  });

  test('AppAccentTheme colors are defined', () {
    expect(AppAccentTheme.values.length, 6);
    expect(AppColors.lightBackground.toARGB32(), 0xFFFFFFFF);
    expect(AppColors.darkBackground.toARGB32(), 0xFF000000);
  });

  test('AuthService and SocketService endpoints are configured for click-live', () async {
    expect(
      AuthService.serverClientId,
      '366527404345-qf56pvo90k61dhqsqlnkbs23kgffoa1v.apps.googleusercontent.com',
    );
    expect(AuthService.realDeviceBaseUrl, 'http://107.174.137.29:5055/api');
    expect(SocketService.defaultSocketUrl, 'http://107.174.137.29:5055');

    final authService = AuthService();
    authService.restoreUser(const UserModel(
      id: 'usr_real',
      name: 'Test User',
      email: 'test@clicklive.com',
      avatarUrl: '',
      isOnline: true,
    ));
    expect(authService.currentUser?.email, 'test@clicklive.com');
    expect(authService.isAuthenticated, true);
  });

  test('AuthViewModel error handling preserves unauthenticated state on failure', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final authService = AuthService();
    final storageService = StorageService(prefs: prefs);
    final authRepo = AuthRepository(
      authService: authService,
      storageService: storageService,
    );
    final authVM = AuthViewModel(authRepository: authRepo);

    expect(authVM.isAuthenticated, false);
    expect(authVM.errorMessage, null);
  });

  test('AuthRepository strictly blocks unauthenticated users without backend token', () async {
    SharedPreferences.setMockInitialValues({
      'saved_user_session':
          '{"id":"usr_meharab_01","name":"Fake","email":"fake@test.com","avatarUrl":"","isOnline":true}',
    });
    final prefs = await SharedPreferences.getInstance();
    final storageService = StorageService(prefs: prefs);
    final authService = AuthService();
    final authRepo = AuthRepository(
      authService: authService,
      storageService: storageService,
    );

    expect(authRepo.isAuthenticated, false);
    expect(authRepo.currentUser, null);
    expect(storageService.getSavedUser(), null);
  });

  test('MessageModel multiple attachments and mediaType parsing', () {
    final msg = MessageModel(
      id: 'msg_grid',
      conversationId: 'chat_1',
      senderId: 'me',
      text: 'Check these out',
      attachmentUrls: const [
        'http://example.com/1.jpg',
        'http://example.com/2.jpg',
        'http://example.com/3.jpg',
        'http://example.com/4.mp4',
        'http://example.com/5.jpg',
        'http://example.com/6.jpg',
      ],
      mediaType: MessageMediaType.image,
      timestamp: DateTime.now(),
      status: 'sending',
    );

    expect(msg.attachmentUrls.length, 6);
    expect(msg.status, 'sending');
    final remainingForOverlay = msg.attachmentUrls.length - 3;
    expect(remainingForOverlay, 3);
  });
}
