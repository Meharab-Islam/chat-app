import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../../data/models/message_model.dart';
import '../../../../data/services/media_service.dart';
import '../../../core/widgets/app_cached_image.dart';
import '../../forward/views/forward_bottom_sheet.dart';

class ImageViewerView extends StatefulWidget {
  final MessageModel message;

  const ImageViewerView({super.key, required this.message});

  @override
  State<ImageViewerView> createState() => _ImageViewerViewState();
}

class _ImageViewerViewState extends State<ImageViewerView> {
  bool _isSaving = false;

  Future<void> _downloadImage() async {
    if (widget.message.mediaUrl == null || _isSaving) return;
    setState(() => _isSaving = true);

    final mediaService = context.read<MediaService>();
    final success = await mediaService.saveImageToGallery(widget.message.mediaUrl!);

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Image saved to gallery!' : 'Failed to save image to gallery.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.forward_rounded),
            tooltip: 'Forward',
            onPressed: () => ForwardBottomSheet.show(context, widget.message),
          ),
          IconButton(
            icon: _isSaving
                ? SizedBox(
                    width: 18.r,
                    height: 18.r,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.download_rounded),
            tooltip: 'Download to Gallery',
            onPressed: _downloadImage,
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 4.0,
          child: AppCachedImage(
            imageUrl: widget.message.mediaUrl ?? '',
            fit: BoxFit.contain,
            borderRadius: BorderRadius.zero,
          ),
        ),
      ),
    );
  }
}

