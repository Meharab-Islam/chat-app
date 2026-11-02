import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class VoiceRecordingService {
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  String? _currentPath;

  bool get isRecording => _isRecording;

  Future<bool> startRecording() async {
    try {
      if (await _recorder.hasPermission()) {
        final dir = await getTemporaryDirectory();
        _currentPath =
            '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _recorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: _currentPath!,
        );
        _isRecording = true;
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<File?> stopRecording() async {
    try {
      final path = await _recorder.stop();
      _isRecording = false;
      if (path != null) {
        final file = File(path);
        if (await file.exists() && await file.length() > 0) {
          return file;
        }
      }
    } catch (_) {}
    _isRecording = false;
    return null;
  }

  Future<void> cancelRecording() async {
    try {
      await _recorder.stop();
      if (_currentPath != null) {
        final f = File(_currentPath!);
        if (await f.exists()) await f.delete();
      }
    } catch (_) {}
    _isRecording = false;
  }

  void dispose() {
    _recorder.dispose();
  }
}
