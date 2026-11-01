import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'api_client.dart';

class SocketService {
  static const String defaultSocketUrl = ApiClient.realDeviceHost;
  io.Socket? _socket;
  bool _isConnected = false;
  String? _lastToken;
  String? _currentChatId;

  final Map<String, List<Function(dynamic)>> _listeners = {};

  bool get isConnected => _isConnected;
  io.Socket? get socket => _socket;

  void connect({required String accessToken, String? socketUrl}) {
    _lastToken = accessToken;
    if (_socket != null && _isConnected) return;

    disconnect();

    final url = socketUrl ?? ApiClient.baseHost;
    debugPrint('🔌 [SocketService] Connecting to $url with token: ${accessToken.substring(0, accessToken.length > 15 ? 15 : accessToken.length)}...');

    try {
      _socket = io.io(
        url,
        io.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionAttempts(99999)
            .setReconnectionDelay(1000)
            .setAuth({'token': accessToken})
            .setExtraHeaders({'authorization': 'Bearer $accessToken'})
            .build(),
      );

      _socket?.onConnect((_) {
        _isConnected = true;
        debugPrint('✅ [SocketService] Connected to backend: $url (socketId: ${_socket?.id})');
        _attachAllListeners();
        if (_currentChatId != null) {
          _socket?.emit('chat:join', _currentChatId);
        }
      });

      _socket?.onDisconnect((reason) {
        _isConnected = false;
        debugPrint('⚠️ [SocketService] Disconnected: $reason');
      });

      _socket?.onConnectError((err) {
        _isConnected = false;
        debugPrint('❌ [SocketService] Connect error: $err');
      });

      _attachAllListeners();
    } catch (e) {
      debugPrint('❌ [SocketService] Init error: $e');
    }
  }

  VoidCallback _on(String event, Function(dynamic) callback) {
    final list = _listeners.putIfAbsent(event, () {
      _bindSocketEvent(event);
      return [];
    });
    list.add(callback);
    return () => off(event, callback);
  }

  void _bindSocketEvent(String event) {
    if (_socket == null) return;
    _socket?.off(event);
    _socket?.on(event, (data) => _dispatchEvent(event, data));
  }

  void _dispatchEvent(String event, dynamic data) {
    debugPrint('📩 [SocketService] Event received: $event');
    final callbacks = List<Function(dynamic)>.from(_listeners[event] ?? []);
    for (final cb in callbacks) {
      try {
        cb(data);
      } catch (e, st) {
        debugPrint('Error in socket listener for $event: $e\n$st');
      }
    }
  }

  void off(String event, [Function(dynamic)? callback]) {
    if (callback != null) {
      _listeners[event]?.remove(callback);
      if (_listeners[event]?.isEmpty ?? true) {
        _listeners.remove(event);
        _socket?.off(event);
      }
    } else {
      _listeners.remove(event);
      _socket?.off(event);
    }
  }

  void _attachAllListeners() {
    if (_socket == null) return;
    for (final event in _listeners.keys) {
      _bindSocketEvent(event);
    }
  }

  void joinChat(String chatId) {
    if (_currentChatId == chatId && _isConnected) return;
    _currentChatId = chatId;
    if (_socket != null && _isConnected) {
      _socket?.emit('chat:join', chatId);
      debugPrint('👥 [SocketService] Joined chat: $chatId');
    }
  }

  void leaveChat(String chatId) {
    if (_currentChatId == chatId) _currentChatId = null;
    if (_socket != null && _isConnected) {
      _socket?.emit('chat:leave', chatId);
      debugPrint('👋 [SocketService] Left chat: $chatId');
    }
  }

  void emitTyping(String chatId, bool isTyping) {
    if (_socket != null && _isConnected) {
      final event = isTyping ? 'typing:start' : 'typing:stop';
      _socket?.emit(event, {'chatId': chatId});
    }
  }

  void emitMessageRead(String chatId, String lastReadMessageId) {
    if (_socket != null && _isConnected) {
      _socket?.emit('message:read', {
        'chatId': chatId,
        'lastReadMessageId': lastReadMessageId,
      });
    }
  }

  void emitMessageDelivered(String messageId, String chatId) {
    if (_socket != null && _isConnected) {
      _socket?.emit('message:delivered', {
        'messageId': messageId,
        'chatId': chatId,
      });
    }
  }

  VoidCallback onNewMessage(Function(dynamic data) callback) => _on('message:new', callback);
  VoidCallback onMessageDelivered(Function(dynamic data) callback) => _on('message:delivered', callback);
  VoidCallback onMessageRead(Function(dynamic data) callback) => _on('message:read', callback);
  VoidCallback onMessageUnsent(Function(dynamic data) callback) => _on('message:unsent', callback);
  VoidCallback onMessageReaction(Function(dynamic data) callback) => _on('message:reaction', callback);
  VoidCallback onUserOnline(Function(dynamic data) callback) => _on('presence:user_online', callback);
  VoidCallback onUserOffline(Function(dynamic data) callback) => _on('presence:user_offline', callback);
  VoidCallback onTypingStart(Function(dynamic data) callback) => _on('typing:start', callback);
  VoidCallback onTypingStop(Function(dynamic data) callback) => _on('typing:stop', callback);

  void reconnect() {
    if (_lastToken != null && _lastToken!.isNotEmpty) {
      connect(accessToken: _lastToken!);
    }
  }

  void disconnect() {
    try {
      _socket?.disconnect();
      _socket?.dispose();
    } catch (_) {}
    _socket = null;
    _isConnected = false;
  }
}
