import 'package:flutter/foundation.dart';
import '../../../../data/services/call_service.dart';

mixin CallControlsMixin on ChangeNotifier {
  CallService get callService;

  bool isMuted = false;
  bool isCameraOff = false;
  bool isSpeakerOn = true;

  void toggleMute() async {
    isMuted = !isMuted;
    await callService.setMicrophoneEnabled(!isMuted);
    notifyListeners();
  }

  void toggleCamera() async {
    isCameraOff = !isCameraOff;
    await callService.setCameraEnabled(!isCameraOff);
    notifyListeners();
  }

  void flipCamera() => callService.flipCamera();

  void toggleSpeaker() async {
    isSpeakerOn = !isSpeakerOn;
    await callService.setSpeakerphoneOn(isSpeakerOn);
    notifyListeners();
  }

  void resetControls({bool audioOnly = false}) {
    isMuted = false;
    isCameraOff = audioOnly;
    isSpeakerOn = true;
  }
}
