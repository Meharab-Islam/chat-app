import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ChatAttachmentSheet {
  static void show({
    required BuildContext context,
    required VoidCallback onPickMedia,
    required VoidCallback onPickAudio,
    required VoidCallback onSendFiles,
  }) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: Colors.blueAccent,
              ),
              title: const Text('Photos & Videos (Gallery)'),
              subtitle: const Text('Select multiple photos & videos'),
              onTap: () {
                Navigator.pop(ctx);
                onPickMedia();
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.audiotrack_outlined,
                color: Colors.amber,
              ),
              title: const Text('Audio & Music'),
              subtitle: const Text('Select songs or audio recordings'),
              onTap: () {
                Navigator.pop(ctx);
                onPickAudio();
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.insert_drive_file_outlined,
                color: Colors.teal,
              ),
              title: const Text('Document & Files (PDF, APK, ZIP)'),
              subtitle: const Text('Send any file or archive'),
              onTap: () {
                Navigator.pop(ctx);
                onSendFiles();
              },
            ),
          ],
        ),
      ),
    );
  }
}
