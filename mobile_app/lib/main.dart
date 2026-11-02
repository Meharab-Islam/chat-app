import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/chat_repository.dart';
import 'data/services/api_client.dart';
import 'data/services/auth_service.dart';
import 'data/services/call_service.dart';
import 'data/services/callkit_service.dart';
import 'data/services/chat_api_service.dart';
import 'data/services/fcm_service.dart';
import 'data/services/media_service.dart';
import 'data/services/notification_service.dart';
import 'data/services/storage_service.dart';
import 'ui/core/design_system/app_theme.dart';
import 'ui/core/design_system/theme_provider.dart';
import 'ui/core/navigation/app_navigator.dart';
import 'ui/features/auth/view_models/auth_view_model.dart';
import 'ui/features/auth/views/login_view.dart';
import 'ui/features/call/view_models/call_view_model.dart';
import 'ui/features/call/views/incoming_call_sheet.dart';
import 'ui/features/chat_list/view_models/chat_list_view_model.dart';
import 'ui/features/chat_list/views/chat_list_view.dart';
import 'ui/features/settings/view_models/settings_view_model.dart';
import 'ui/features/splash/views/splash_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (_) {}

  await NotificationService.instance.initialize();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final prefs = await SharedPreferences.getInstance();
  final storageService = StorageService(prefs: prefs);
  final authService = AuthService();
  final mediaService = MediaService();
  final apiClient = ApiClient();
  final socketService = authService.socketService;
  final callService = CallService();
  final callkitService = CallkitService();
  final chatApiService = ChatApiService(apiClient: apiClient);

  // Initialize FCM device token registration and handlers
  FcmService(apiClient: apiClient).initialize();

  final authRepo = AuthRepository(
    authService: authService,
    storageService: storageService,
  );

  final initialUserId = authRepo.currentUser?.id ?? '';
  final chatRepo = ChatRepository(
    apiClient: apiClient,
    socketService: socketService,
    mediaService: mediaService,
    storageService: storageService,
    currentUserId: initialUserId,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(prefs: prefs)),
        Provider<MediaService>.value(value: mediaService),
        Provider<StorageService>.value(value: storageService),
        Provider<AuthRepository>.value(value: authRepo),
        Provider<ChatRepository>.value(value: chatRepo),
        ChangeNotifierProvider(
          create: (_) =>
              AuthViewModel(authRepository: authRepo, chatRepository: chatRepo),
        ),
        ChangeNotifierProvider(
          create: (_) => ChatListViewModel(chatRepository: chatRepo),
        ),
        ChangeNotifierProvider(
          create: (_) => CallViewModel(
            callService: callService,
            chatApiService: chatApiService,
            socketService: socketService,
            callkitService: callkitService,
          ),
        ),
        ChangeNotifierProxyProvider2<
          StorageService,
          ThemeProvider,
          SettingsViewModel
        >(
          create: (ctx) => SettingsViewModel(
            storageService: storageService,
            themeProvider: ctx.read<ThemeProvider>(),
          ),
          update: (_, storage, theme, prev) =>
              prev ??
              SettingsViewModel(storageService: storage, themeProvider: theme),
        ),
      ],
      child: const MinimalChatApp(),
    ),
  );
}

class MinimalChatApp extends StatelessWidget {
  const MinimalChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return ScreenUtilInit(
      designSize: const Size(393, 852),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          navigatorKey: AppNavigator.navigatorKey,
          title: 'Minimal Chat',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.createLightTheme(
            accentColor: themeProvider.accentColor,
          ),
          darkTheme: AppTheme.createDarkTheme(
            accentColor: themeProvider.accentColor,
          ),
          themeMode: themeProvider.themeMode,
          builder: (context, routerChild) {
            final incoming = context.watch<CallViewModel>().incomingCall;
            return Stack(
              children: [
                ?routerChild,
                if (incoming != null) IncomingCallOverlay(call: incoming),
              ],
            );
          },
          home: Consumer<AuthViewModel>(
            builder: (context, authVM, _) {
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                switchInCurve: Curves.easeInOut,
                switchOutCurve: Curves.easeInOut,
                child: !authVM.isInitialized
                    ? SplashView(
                        key: const ValueKey('splash_view'),
                        onComplete: authVM.completeInitialization,
                      )
                    : (authVM.isAuthenticated
                          ? const ChatListView(key: ValueKey('chat_list_view'))
                          : const LoginView(key: ValueKey('login_view'))),
              );
            },
          ),
        );
      },
    );
  }
}
