import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../../data/models/message_model.dart';
import '../../../../data/repositories/chat_repository.dart';
import '../../../core/design_system/app_colors.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_button.dart';
import '../../auth/view_models/auth_view_model.dart';

class ForwardBottomSheet extends StatefulWidget {
  final MessageModel message;

  const ForwardBottomSheet({super.key, required this.message});

  static Future<void> show(BuildContext context, MessageModel message) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ForwardBottomSheet(message: message),
    );
  }

  @override
  State<ForwardBottomSheet> createState() => _ForwardBottomSheetState();
}

class _ForwardBottomSheetState extends State<ForwardBottomSheet> {
  final Set<String> _selectedConversationIds = {};
  bool _isForwarding = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final chatRepo = context.read<ChatRepository>();
    final conversations = chatRepo.conversations;
    final authVM = context.read<AuthViewModel>();
    final currentUser = authVM.currentUser;

    return Material(
      color: theme.scaffoldBackgroundColor,
      borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 520.h,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                'Forward Message',
                style: AppTypography.headingSmall(textPrimary),
              ),
              SizedBox(height: 4.h),
              Text(
                'Instantly share with contacts without re-downloading media.',
                style: AppTypography.caption(textSecondary),
              ),
              SizedBox(height: 12.h),
              Expanded(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: conversations.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                  ),
                  itemBuilder: (context, index) {
                    final item = conversations[index];
                    final isSelected = _selectedConversationIds.contains(item.id);

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: AppAvatar(
                        imageUrl: item.peerUser.avatarUrl,
                        name: item.peerUser.name,
                        size: 42.r,
                      ),
                      title: Text(
                        item.peerUser.name,
                        style: AppTypography.bodyMedium(textPrimary),
                      ),
                      trailing: Checkbox(
                        value: isSelected,
                        activeColor: theme.colorScheme.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.r)),
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _selectedConversationIds.add(item.id);
                            } else {
                              _selectedConversationIds.remove(item.id);
                            }
                          });
                        },
                      ),
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedConversationIds.remove(item.id);
                          } else {
                            _selectedConversationIds.add(item.id);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              SizedBox(height: 12.h),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: 'Forward (${_selectedConversationIds.length})',
                  isLoading: _isForwarding,
                  onPressed: _selectedConversationIds.isEmpty || currentUser == null
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final navigator = Navigator.of(context);
                          final count = _selectedConversationIds.length;

                          setState(() => _isForwarding = true);
                          await chatRepo.forwardMessage(
                            messageId: widget.message.id,
                            targetConversationIds:
                                _selectedConversationIds.toList(),
                          );

                          if (mounted) {
                            navigator.pop();
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('Forwarded to $count chat(s)'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
