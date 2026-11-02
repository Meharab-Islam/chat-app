import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class FileManagerService {
  final Dio _dio = Dio();

  String formatBytes(int bytes, [int decimals = 1]) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    int i = (bytes.toString().length - 1) ~/ 3;
    if (i >= suffixes.length) i = suffixes.length - 1;
    double size = bytes / (1 << (i * 10));
    return '${size.toStringAsFixed(decimals)} ${suffixes[i]}';
  }

  Future<File?> downloadFile({
    required String url,
    required String fileName,
    ValueChanged<double>? onProgress,
  }) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final savePath = '${dir.path}/$fileName';
      final file = File(savePath);

      if (await file.exists() && await file.length() > 0) {
        onProgress?.call(1.0);
        return file;
      }

      await _dio.download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            onProgress?.call(received / total);
          }
        },
      );

      return File(savePath);
    } catch (e) {
      debugPrint('Error downloading file: $e');
      return null;
    }
  }

  Future<void> openOrInstallFile(BuildContext context, File file) async {
    final path = file.path.toLowerCase();

    if (path.endsWith('.apk') && Platform.isAndroid) {
      await _handleApkInstall(context, file);
      return;
    }

    try {
      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.message.isNotEmpty
                  ? result.message
                  : 'Could not open file',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error opening file: $e');
    }
  }

  Future<void> _handleApkInstall(BuildContext context, File apkFile) async {
    try {
      final status = await Permission.requestInstallPackages.status;
      if (!status.isGranted) {
        final req = await Permission.requestInstallPackages.request();
        if (!req.isGranted) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Permission denied: Enable "Install unknown apps" in Settings to install APKs.',
                ),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return;
        }
      }

      final result = await OpenFilex.open(
        apkFile.path,
        type: 'application/vnd.android.package-archive',
      );

      if (result.type != ResultType.done && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Install prompt failed: ${result.message}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error installing APK: $e');
    }
  }
}
