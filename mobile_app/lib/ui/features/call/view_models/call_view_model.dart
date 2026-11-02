import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../data/models/call_model.dart';
import '../../../../data/services/call_service.dart';
import '../../../../data/services/chat_api_service.dart';
import '../../../../data/services/socket_service.dart';
import '../views/call_screen.dart';

class CallViewModel extends ChangeNotifier {
  final CallService callService;
  final ChatApiService chatApiService;
  final SocketService socketService;

  IncomingCallData? _incomingCall;
  bool _isInCall = false;
  bool _isConnecting = false;
  bool _isMuted = false;
  bool _isCameraOff = false;
  bool _isSpeakerOn = true;
  int _callDuration = 0;
  Timer? _durationTimer;

  String _chatName = '';
  bool _isGroup = false;
  String? _currentCallId;
  String? _currentChatId;

  CallViewModel({
    required this.callService,
    required this.chatApiService,
    required this.socketService,
  }) {
    _initSocketEvents();
  }

  IncomingCallData? get incomingCall => _incomingCall;
  bool get isInCall => _isInCall;
  bool get isConnecting => _isConnecting;
  bool get isMuted => _isMuted;
  bool get isCameraOff => _isCameraOff;
  bool get isSpeakerOn => _isSpeakerOn;
  int get callDuration => _callDuration;
  String get chatName => _chatName;
  bool get isGroup => _isGroup;

  void _initSocketEvents() {
    socketService.on('call:incoming', (data) {
      if (data is Map<String, dynamic>) {
        if (_isInCall) {
          socketService.emit('call:reject', {
            'callId': data['callId'],
            'chatId': data['chatId'],
            'reason': 'busy',
          });
          return;
        }
        _incomingCall = IncomingCallData.fromJson(data);
        HapticFeedback.vibrate();
        notifyListeners();
      }
    });

    socketService.on('call:ended', (_) => endCall());
    socketService.on('call:rejected', (_) {});
  }

  Future<void> startCall(
    BuildContext context, {
    required String chatId,
    required String callType,
    required String chatName,
    required bool isGroup,
  }) async {
    _currentCallId = 'call_${DateTime.now().millisecondsSinceEpoch}';
    _currentChatId = chatId;
    _chatName = chatName;
    _isGroup = isGroup;
    _isCameraOff = callType == 'audio';
    _isMuted = false;
    _isInCall = true;
    _isConnecting = true;
    _callDuration = 0;
    notifyListeners();

    socketService.emit('call:initiate', {
      'callId': _currentCallId,
      'chatId': chatId,
      'callType': callType,
    });

    if (context.mounted) {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const CallScreen()));
    }

    try {
      final tokenData = await chatApiService.getCallToken(
        chatId,
        callType: callType,
      );
      if (tokenData == null) {
        throw Exception('Failed to get token');
      }

      await callService.connect(
        url: tokenData['url'] as String? ?? 'wss://sp-live-77aj0nb6.livekit.cloud',
        token: tokenData['token'] as String,
        isVideo: callType == 'video',
        onRoomUpdated: () => notifyListeners(),
      );

      _isConnecting = false;
      _startTimer();
      notifyListeners();
    } catch (e) {
      debugPrint('Error starting call: $e');
      endCall();
    }
  }

  Future<void> acceptCall(BuildContext context) async {
    if (_incomingCall == null) return;
    final call = _incomingCall!;
    _incomingCall = null;
    _currentCallId = call.callId;
    _currentChatId = call.chatId;
    _chatName = call.chatName;
    _isGroup = call.isGroup;
    _isCameraOff = call.callType == 'audio';
    _isMuted = false;
    _isInCall = true;
    _isConnecting = true;
    _callDuration = 0;
    notifyListeners();

    socketService.emit('call:accept', {
      'callId': call.callId,
      'chatId': call.chatId,
    });

    if (context.mounted) {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const CallScreen()));
    }

    try {
      final tokenData = await chatApiService.getCallToken(
        call.chatId,
        callType: call.callType,
      );
      if (tokenData == null) throw Exception('No token');

      await callService.connect(
        url: tokenData['url'] as String? ?? 'wss://sp-live-77aj0nb6.livekit.cloud',
        token: tokenData['token'] as String,
        isVideo: call.callType == 'video',
        onRoomUpdated: () => notifyListeners(),
      );

      _isConnecting = false;
      _startTimer();
      notifyListeners();
    } catch (e) {
      debugPrint('Error accepting call: $e');
      endCall();
    }
  }

  void rejectCall() {
    if (_incomingCall != null) {
      socketService.emit('call:reject', {
        'callId': _incomingCall!.callId,
        'chatId': _incomingCall!.chatId,
        'reason': 'declined',
      });
      _incomingCall = null;
      notifyListeners();
    }
  }

  Future<void> endCall([BuildContext? context]) async {
    _durationTimer?.cancel();
    _durationTimer = null;

    if (_currentCallId != null && _currentChatId != null) {
      socketService.emit('call:end', {
        'callId': _currentCallId,
        'chatId': _currentChatId,
      });
    }

    await callService.disconnect();
    _isInCall = false;
    _isConnecting = false;
    _incomingCall = null;
    _currentCallId = null;
    _currentChatId = null;
    notifyListeners();

    if (context != null && context.mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void toggleMute() async {
    _isMuted = !_isMuted;
    await callService.setMicrophoneEnabled(!_isMuted);
    notifyListeners();
  }

  void toggleCamera() async {
    _isCameraOff = !_isCameraOff;
    await callService.setCameraEnabled(!_isCameraOff);
    notifyListeners();
  }

  void flipCamera() async {
    await callService.flipCamera();
  }

  void toggleSpeaker() async {
    _isSpeakerOn = !_isSpeakerOn;
    await callService.setSpeakerphoneOn(_isSpeakerOn);
    notifyListeners();
  }

  void _startTimer() {
    _durationTimer?.cancel();
    _callDuration = 0;
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _callDuration++;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    super.dispose();
  }
}
