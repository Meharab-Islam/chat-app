import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../data/models/message_model.dart';
import '../../../../data/services/file_manager_service.dart';
import '../../../core/design_system/app_spacing.dart';

class FileMessageWidget extends StatefulWidget {
  final MessageModel message;
  final bool isMe;

  const FileMessageWidget({
    super.key,
    required this.message,
    required this.isMe,
  });

  @override
  State<FileMessageWidget> createState() => _FileMessageWidgetState();
}

class _FileMessageWidgetState extends State<FileMessageWidget> {
  final FileManagerService _fileService = FileManagerService();
  bool _isDownloading = false;
  double _progress = 0.0;
  File? _downloadedFile;

  @override
  void initState() {
    super.initState();
    _checkExistingFile();
  }

  Future<void> _checkExistingFile() async {
    final fileName = _getFileName();
    if (fileName.isNotEmpty) {
      final f = await _fileService.downloadFile(url: widget.message.mediaUrl ?? '', fileName: fileName);
      if (mounted) setState(() => _downloadedFile = f);
    }
  }

  String _getFileName() {
    if (widget.message.fileName?.isNotEmpty == true) return widget.message.fileName!;
    if (widget.message.mediaUrl != null) return widget.message.mediaUrl!.split('/').last;
    return 'file';
  }

  Future<void> _handleTap() async {
    if (_downloadedFile != null && await _downloadedFile!.exists()) {
      if (mounted) {
        await _fileService.openOrInstallFile(context, _downloadedFile!);
      }
      return;
    }

    if (widget.message.mediaUrl == null) return;

    setState(() {
      _isDownloading = true;
      _progress = 0.0;
    });

    final file = await _fileService.downloadFile(
      url: widget.message.mediaUrl!,
      fileName: _getFileName(),
      onProgress: (p) {
        if (mounted) setState(() => _progress = p);
      },
    );

    if (mounted) {
      setState(() {
        _isDownloading = false;
        _downloadedFile = file;
      });

      if (file != null) {
        await _fileService.openOrInstallFile(context, file);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.message.mediaType;
    final fileName = _getFileName();
    final fileSizeStr = _fileService.formatBytes(widget.message.fileSize ?? 0);
    final isDownloaded = _downloadedFile != null;
    final isApk = type == MessageMediaType.apk || fileName.toLowerCase().endsWith('.apk');

    Color iconBg = const Color(0xFF3B82F6);
    IconData icon = Icons.insert_drive_file_rounded;
    String tag = 'FILE';

    if (isApk) {
      iconBg = const Color(0xFF10B981);
      icon = Icons.android_rounded;
      tag = 'APK';
    } else if (type == MessageMediaType.pdf || fileName.toLowerCase().endsWith('.pdf')) {
      iconBg = const Color(0xFFEF4444);
      icon = Icons.picture_as_pdf_rounded;
      tag = 'PDF';
    } else if (type == MessageMediaType.zip || fileName.toLowerCase().endsWith('.zip')) {
      iconBg = const Color(0xFFF59E0B);
      icon = Icons.folder_zip_rounded;
      tag = 'ZIP';
    }

    final fg = widget.isMe ? Colors.white : Colors.black87;

    return Container(
      width: 250.w,
      padding: EdgeInsets.all(8.r),
      margin: EdgeInsets.only(bottom: 4.h),
      decoration: BoxDecoration(
        color: widget.isMe ? Colors.black12 : Colors.white24,
        borderRadius: AppSpacing.radiusMd,
      ),
      child: InkWell(
        onTap: _isDownloading ? null : _handleTap,
        borderRadius: AppSpacing.radiusMd,
        child: Row(
          children: [
            Container(
              width: 44.r,
              height: 44.r,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Center(
                child: Icon(icon, color: Colors.white, size: 24.r),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: fg,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
                        decoration: BoxDecoration(
                          color: iconBg.withAlpha(40),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            fontSize: 9.sp,
                            fontWeight: FontWeight.bold,
                            color: isApk ? Colors.greenAccent : iconBg,
                          ),
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        fileSizeStr,
                        style: TextStyle(fontSize: 11.sp, color: fg.withAlpha(180)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            if (_isDownloading)
              SizedBox(
                width: 26.r,
                height: 26.r,
                child: CircularProgressIndicator(
                  value: _progress > 0 ? _progress : null,
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(fg),
                ),
              )
            else if (isDownloaded)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: isApk ? const Color(0xFF10B981) : iconBg,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isApk ? Icons.install_mobile_rounded : Icons.open_in_new_rounded,
                      size: 13.r,
                      color: Colors.white,
                    ),
                    SizedBox(width: 3.w),
                    Text(
                      isApk ? 'INSTALL' : 'OPEN',
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: EdgeInsets.all(6.r),
                decoration: BoxDecoration(
                  color: fg.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_downward_rounded, size: 16.r, color: fg),
              ),
          ],
        ),
      ),
    );
  }
}
