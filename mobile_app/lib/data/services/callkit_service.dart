import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import '../models/call_model.dart';

class CallkitService {
  StreamSubscription? _eventSubscription;
  Function(IncomingCallData)? onAccept;
  Function(IncomingCallData)? onDecline;

  void initialize({
    Function(IncomingCallData)? onCallAccepted,
    Function(IncomingCallData)? onCallDeclined,
  }) {
    onAccept = onCallAccepted;
    onDecline = onCallDeclined;

    _eventSubscription?.cancel();
    _eventSubscription = FlutterCallkitIncoming.onEvent.listen((event) {
      if (event == null) return;
      debugPrint('📞 [CallkitService] Event: ${event.eventName}');

      if (event is CallEventActionCallAccept) {
        final p = event.callKitParams;
        final extra = p.extra ?? {};
        final callData = IncomingCallData(
          callId: p.id,
          chatId: extra['chatId'] as String? ?? p.id,
          callerId: extra['callerId'] as String? ?? '',
          callerName: p.nameCaller ?? 'Caller',
          callerAvatar: p.avatar,
          callType: (extra['callType'] as String?) ?? (p.type == 1 ? 'video' : 'audio'),
          isGroup: extra['isGroup'] as bool? ?? false,
          chatName: p.handle ?? 'Call',
        );
        onAccept?.call(callData);
      } else if (event is CallEventActionCallDecline) {
        final p = event.callKitParams;
        final extra = p.extra ?? {};
        final callData = IncomingCallData(
          callId: p.id,
          chatId: extra['chatId'] as String? ?? p.id,
          callerId: extra['callerId'] as String? ?? '',
          callerName: p.nameCaller ?? 'Caller',
          callerAvatar: p.avatar,
          callType: (extra['callType'] as String?) ?? (p.type == 1 ? 'video' : 'audio'),
          isGroup: extra['isGroup'] as bool? ?? false,
          chatName: p.handle ?? 'Call',
        );
        onDecline?.call(callData);
      }
    });
  }

  Future<void> showIncomingCall(IncomingCallData call) async {
    final isVideo = call.callType == 'video';

    final params = CallKitParams(
      id: call.callId,
      nameCaller: call.callerName,
      appName: 'Chat App',
      avatar: call.callerAvatar,
      handle: call.chatName,
      type: isVideo ? 1 : 0,
      duration: 35000,
      extra: <String, dynamic>{
        'chatId': call.chatId,
        'callerId': call.callerId,
        'callType': call.callType,
        'isGroup': call.isGroup,
      },
      android: const AndroidParams(
        isCustomNotification: true,
        isShowLogo: false,
        ringtonePath: 'system_ringtone_default',
        backgroundColor: '#0955fa',
        actionColor: '#4CAF50',
        textColor: '#ffffff',
        incomingCallNotificationChannelName: 'Incoming Calls',
        missedCallNotificationChannelName: 'Missed Calls',
      ),
      ios: const IOSParams(
        iconName: 'CallKitLogo',
        handleType: 'generic',
        supportsVideo: true,
        maximumCallGroups: 2,
        maximumCallsPerCallGroup: 1,
        audioSessionMode: 'default',
        audioSessionActive: true,
        audioSessionPreferredSampleRate: 44100.0,
        audioSessionPreferredIOBufferDuration: 0.005,
        supportsDTMF: true,
        supportsHolding: true,
        supportsGrouping: false,
        supportsUngrouping: false,
        ringtonePath: 'system_ringtone_default',
      ),
    );

    try {
      await FlutterCallkitIncoming.showCallkitIncoming(params);
    } catch (e) {
      debugPrint('Failed to show CallKit incoming: $e');
    }
  }

  Future<void> endCall(String callId) async {
    try {
      await FlutterCallkitIncoming.endCall(callId);
    } catch (e) {
      debugPrint('Failed to end CallKit: $e');
    }
  }

  Future<void> endAllCalls() async {
    try {
      await FlutterCallkitIncoming.endAllCalls();
    } catch (e) {
      debugPrint('Failed to end all CallKit calls: $e');
    }
  }

  void dispose() {
    _eventSubscription?.cancel();
    _eventSubscription = null;
  }
}
