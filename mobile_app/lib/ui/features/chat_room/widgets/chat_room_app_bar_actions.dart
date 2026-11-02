import 'package:flutter/material.dart';

import '../../../../data/models/user_model.dart';
import '../../call/view_models/call_view_model.dart';
import '../view_models/chat_room_view_model.dart';
import 'group_info_bottom_sheet.dart';

import 'package:provider/provider.dart';

class ChatRoomAppBarActions extends StatelessWidget {
  final String conversationId;
  final UserModel peerUser;
  final bool isGroup;
  final int memberCount;
  final ChatRoomViewModel vm;

  const ChatRoomAppBarActions({
    super.key,
    required this.conversationId,
    required this.peerUser,
    required this.isGroup,
    required this.memberCount,
    required this.vm,
  });

  @override
  Widget build(BuildContext context) {
    if (vm.isSearching) {
      return IconButton(
        icon: const Icon(Icons.close),
        tooltip: 'Close Search',
        onPressed: () => vm.toggleSearch(false),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.call_rounded),
          tooltip: 'Audio Call',
          onPressed: () => context.read<CallViewModel>().startCall(
            context,
            chatId: conversationId,
            callType: 'audio',
            chatName: peerUser.name,
            isGroup: isGroup,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.videocam_rounded),
          tooltip: 'Video Call',
          onPressed: () => context.read<CallViewModel>().startCall(
            context,
            chatId: conversationId,
            callType: 'video',
            chatName: peerUser.name,
            isGroup: isGroup,
          ),
        ),
        if (isGroup)
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            tooltip: 'Group Settings',
            onPressed: () => GroupInfoBottomSheet.show(
              context,
              conversationId: conversationId,
              groupName: peerUser.name,
              groupAvatar: peerUser.avatarUrl,
              memberCount: memberCount,
            ),
          ),
        IconButton(
          icon: const Icon(Icons.search_rounded),
          tooltip: 'Search in Conversation',
          onPressed: () => vm.toggleSearch(true),
        ),
      ],
    );
  }
}
