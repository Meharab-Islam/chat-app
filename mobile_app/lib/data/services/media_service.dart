import 'dart:io';
import 'package:dio/dio.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';

class MediaService {
  final Dio _dio = Dio();

  Future<bool> requestGalleryPermission() async {
    try {
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        return await Gal.requestAccess();
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String?> downloadToTempFile(String url, String extension) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final fileName = 'media_${DateTime.now().millisecondsSinceEpoch}.$extension';
      final savePath = '${tempDir.path}/$fileName';

      await _dio.download(
        url,
        savePath,
        options: Options(responseType: ResponseType.bytes),
      );

      final file = File(savePath);
      if (await file.exists()) {
        return savePath;
      }
    } catch (_) {}
    return null;
  }

  Future<bool> saveImageToGallery(String imageUrl) async {
    try {
      final hasPermission = await requestGalleryPermission();
      if (!hasPermission) return false;

      final localPath = await downloadToTempFile(imageUrl, 'jpg');
      if (localPath != null) {
        await Gal.putImage(localPath);
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> saveVideoToGallery(String videoUrl) async {
    try {
      final hasPermission = await requestGalleryPermission();
      if (!hasPermission) return false;

      final localPath = await downloadToTempFile(videoUrl, 'mp4');
      if (localPath != null) {
        await Gal.putVideo(localPath);
        return true;
      }
    } catch (_) {}
    return false;
  }
}

