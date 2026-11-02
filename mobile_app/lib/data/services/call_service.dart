import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart';

class CallService {
  Room? _room;
  EventsListener<RoomEvent>? _listener;
  CameraPosition _cameraPosition = CameraPosition.front;

  Room? get room => _room;
  LocalParticipant? get localParticipant => _room?.localParticipant;
  List<RemoteParticipant> get remoteParticipants =>
      _room?.remoteParticipants.values.toList() ?? [];

  Future<Room> connect({
    required String url,
    required String token,
    bool isVideo = true,
    Function()? onRoomUpdated,
  }) async {
    await disconnect();

    final roomOptions = RoomOptions(
      adaptiveStream: true,
      dynacast: true,
      defaultCameraCaptureOptions: const CameraCaptureOptions(
        maxFrameRate: 30,
        cameraPosition: CameraPosition.front,
        params: VideoParametersPresets.h540_169,
      ),
    );

    _room = Room(roomOptions: roomOptions);
    _listener = _room!.createListener();

    _listener!
      ..on<RoomDisconnectedEvent>((_) {
        onRoomUpdated?.call();
      })
      ..on<ParticipantConnectedEvent>((_) {
        onRoomUpdated?.call();
      })
      ..on<ParticipantDisconnectedEvent>((_) {
        onRoomUpdated?.call();
      })
      ..on<TrackSubscribedEvent>((_) {
        onRoomUpdated?.call();
      })
      ..on<TrackUnsubscribedEvent>((_) {
        onRoomUpdated?.call();
      })
      ..on<TrackMutedEvent>((_) {
        onRoomUpdated?.call();
      })
      ..on<TrackUnmutedEvent>((_) {
        onRoomUpdated?.call();
      })
      ..on<ActiveSpeakersChangedEvent>((_) {
        onRoomUpdated?.call();
      });

    await _room!.connect(url, token);

    // Enable microphone
    await _room!.localParticipant?.setMicrophoneEnabled(true);

    // Enable camera if video call
    if (isVideo) {
      await _room!.localParticipant?.setCameraEnabled(true);
    } else {
      await _room!.localParticipant?.setCameraEnabled(false);
    }

    _cameraPosition = CameraPosition.front;
    return _room!;
  }

  Future<void> setMicrophoneEnabled(bool enabled) async {
    await _room?.localParticipant?.setMicrophoneEnabled(enabled);
  }

  Future<void> setCameraEnabled(bool enabled) async {
    await _room?.localParticipant?.setCameraEnabled(enabled);
  }

  Future<void> flipCamera() async {
    final track =
        _room?.localParticipant?.videoTrackPublications.firstOrNull?.track;
    if (track is LocalVideoTrack) {
      _cameraPosition = _cameraPosition == CameraPosition.front
          ? CameraPosition.back
          : CameraPosition.front;
      await track.setCameraPosition(_cameraPosition);
    }
  }

  Future<void> setSpeakerphoneOn(bool enabled) async {
    try {
      await AudioManager.instance.setSpeakerOutputPreferred(enabled);
    } catch (e) {
      debugPrint('Failed to set speakerphone: $e');
    }
  }

  Future<void> disconnect() async {
    try {
      await _listener?.dispose();
      _listener = null;
      await _room?.disconnect();
      await _room?.dispose();
    } catch (e) {
      debugPrint('Error disconnecting room: $e');
    } finally {
      _room = null;
    }
  }
}
