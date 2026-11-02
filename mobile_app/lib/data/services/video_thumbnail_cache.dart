import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

class VideoThumbnailCache {
  VideoThumbnailCache._();

  static final Map<String, VideoPlayerController> _controllers = {};
  static final Map<String, double> _aspectRatios = {};
  static final Map<String, String> _localPaths = {};
  static final List<String> _lruList = [];
  static const int _maxControllers = 6;
  static final Map<String, Future<VideoPlayerController?>> _pendingInits = {};

  static void registerLocalPath(String url, String localPath) {
    if (url.isNotEmpty && localPath.isNotEmpty) {
      _localPaths[url] = localPath;
    }
  }

  static double? getCachedRatio(String url) => _aspectRatios[url];

  static bool isCached(String url) {
    final ctrl = _controllers[url];
    return ctrl != null && ctrl.value.isInitialized;
  }

  static VideoPlayerController? getInitialized(String url) {
    final ctrl = _controllers[url];
    if (ctrl != null && ctrl.value.isInitialized) {
      _touch(url);
      return ctrl;
    }
    return null;
  }

  static Future<VideoPlayerController?> getOrInit(
    String url, {
    ValueChanged<double>? onRatio,
  }) async {
    if (url.isEmpty) return null;

    final existing = getInitialized(url);
    if (existing != null) {
      if (existing.value.aspectRatio > 0) {
        onRatio?.call(existing.value.aspectRatio);
      }
      return existing;
    }

    if (_pendingInits.containsKey(url)) {
      final ctrl = await _pendingInits[url];
      if (ctrl != null && ctrl.value.aspectRatio > 0) {
        onRatio?.call(ctrl.value.aspectRatio);
      }
      return ctrl;
    }

    final future = _performInit(url, onRatio);
    _pendingInits[url] = future;
    try {
      return await future;
    } finally {
      _pendingInits.remove(url);
    }
  }

  static Future<VideoPlayerController?> _performInit(
    String url,
    ValueChanged<double>? onRatio,
  ) async {
    try {
      while (_controllers.length >= _maxControllers && _lruList.isNotEmpty) {
        final oldest = _lruList.removeAt(0);
        final ctrl = _controllers.remove(oldest);
        try {
          await ctrl?.dispose();
        } catch (_) {}
      }

      final localPath = _localPaths[url];
      final isLocal = (localPath != null && File(localPath).existsSync()) ||
          (!url.startsWith('http://') && !url.startsWith('https://') && File(url).existsSync());

      final filePath = isLocal ? (localPath ?? url) : null;
      final ctrl = filePath != null
          ? VideoPlayerController.file(File(filePath))
          : VideoPlayerController.networkUrl(Uri.parse(url));

      await ctrl.initialize();

      _controllers[url] = ctrl;
      _touch(url);

      final r = ctrl.value.aspectRatio;
      if (r > 0) {
        _aspectRatios[url] = r;
        onRatio?.call(r);
      }
      return ctrl;
    } catch (e) {
      debugPrint('[VideoThumbnailCache] Failed to init thumbnail for $url: $e');
      return null;
    }
  }

  static void _touch(String url) {
    _lruList.remove(url);
    _lruList.add(url);
  }

  static void disposeAll() {
    for (final ctrl in _controllers.values) {
      try {
        ctrl.dispose();
      } catch (_) {}
    }
    _controllers.clear();
    _lruList.clear();
  }
}

