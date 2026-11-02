import '../models/chat_conversation_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';

class MockChatData {
  MockChatData._();

  static final List<UserModel> sampleUsers = [
    const UserModel(
      id: 'usr_sarah',
      name: 'Sarah Connor',
      email: 'sarah.connor@gmail.com',
      avatarUrl:
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
      isOnline: true,
    ),
    const UserModel(
      id: 'usr_alex',
      name: 'Alex Rivera',
      email: 'alex.rivera@gmail.com',
      avatarUrl:
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
      isOnline: false,
    ),
    const UserModel(
      id: 'usr_priya',
      name: 'Priya Sharma',
      email: 'priya.sharma@gmail.com',
      avatarUrl:
          'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=150',
      isOnline: true,
    ),
    const UserModel(
      id: 'usr_david',
      name: 'David Kim',
      email: 'david.kim@gmail.com',
      avatarUrl:
          'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
      isOnline: false,
    ),
  ];

  static List<MessageModel> initialSarahMessages(String myId) => [
    MessageModel(
      id: 'msg_1',
      conversationId: 'conv_sarah',
      senderId: 'usr_sarah',
      text: 'Hey! Did you check out the new design system guidelines?',
      timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
    ),
    MessageModel(
      id: 'msg_2',
      conversationId: 'conv_sarah',
      senderId: myId,
      text: 'Yes! Super clean, pure white and pitch black OLED support.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 38)),
    ),
    MessageModel(
      id: 'msg_3',
      conversationId: 'conv_sarah',
      senderId: 'usr_sarah',
      text: 'Look at this photo from today\'s photoshoot!',
      mediaUrl:
          'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=800',
      mediaType: MessageMediaType.image,
      timestamp: DateTime.now().subtract(const Duration(minutes: 25)),
    ),
    MessageModel(
      id: 'msg_4',
      conversationId: 'conv_sarah',
      senderId: 'usr_sarah',
      text: 'Here is the short clip of the river scene:',
      mediaUrl: 'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
      mediaType: MessageMediaType.video,
      durationSeconds: 30,
      timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
    ),
  ];

  static List<ChatConversationModel> initialConversations(String myId) {
    return [
      ChatConversationModel(
        id: 'conv_sarah',
        peerUser: sampleUsers[0],
        lastMessage: MessageModel(
          id: 'msg_4',
          conversationId: 'conv_sarah',
          senderId: 'usr_sarah',
          text: 'Here is the short clip of the river scene:',
          mediaType: MessageMediaType.video,
          timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
        ),
        unreadCount: 1,
        updatedAt: DateTime.now().subtract(const Duration(minutes: 10)),
      ),
      ChatConversationModel(
        id: 'conv_alex',
        peerUser: sampleUsers[1],
        lastMessage: MessageModel(
          id: 'msg_alex_1',
          conversationId: 'conv_alex',
          senderId: 'usr_alex',
          text: 'Can you forward me that mountain photo?',
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        unreadCount: 0,
        updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      ChatConversationModel(
        id: 'conv_priya',
        peerUser: sampleUsers[2],
        lastMessage: MessageModel(
          id: 'msg_priya_1',
          conversationId: 'conv_priya',
          senderId: 'usr_priya',
          text: 'Awesome, everything looks silky smooth!',
          timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        ),
        unreadCount: 0,
        updatedAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      ChatConversationModel(
        id: 'conv_david',
        peerUser: sampleUsers[3],
        lastMessage: MessageModel(
          id: 'msg_david_1',
          conversationId: 'conv_david',
          senderId: 'usr_david',
          text: 'Let us catch up tomorrow morning.',
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
        ),
        unreadCount: 0,
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }
}
