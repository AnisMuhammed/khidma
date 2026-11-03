import 'package:flutter/material.dart';
import '../../core/localization/app_language_manager.dart';
import '../../core/localization/app_strings.dart';
import '../../core/utils/app_image_helper.dart';
import '../../data/user_session.dart';
import '../../models/chat_model.dart';
import '../../models/order_model.dart';
import '../../models/provider_model.dart';
import '../../services/chat_service.dart';

class ChatView extends StatefulWidget {
  const ChatView({super.key});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _initialized = false;
  late String _chatId;
  late String _peerId;
  late String _peerName;
  late String _peerRole; // 'client' or 'provider'
  String? _peerImage;
  String? _orderId;

  late String _currentUserId;
  late String _currentUserName;
  late String _currentUserRole;
  String? _currentUserImage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _resolveChatParameters();
      _initialized = true;
      _markAsRead();
    }
  }

  void _resolveChatParameters() {
    _currentUserRole = UserSession.currentUserRole;

    if (_currentUserRole == 'provider') {
      _currentUserId = UserSession.currentProvider.id.isNotEmpty
          ? UserSession.currentProvider.id
          : 'provider_guest';
      _currentUserName = UserSession.currentProvider.name.isNotEmpty
          ? UserSession.currentProvider.name
          : 'مزود الخدمة';
      _currentUserImage = UserSession.currentProvider.profileImagePath;
    } else {
      _currentUserId = UserSession.currentUser.id.isNotEmpty
          ? UserSession.currentUser.id
          : 'client_guest';
      _currentUserName = UserSession.currentUser.name.isNotEmpty
          ? UserSession.currentUser.name
          : 'العميل';
      _currentUserImage = UserSession.currentUser.profileImagePath;
    }

    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is ChatConversation) {
      _chatId = args.id;
      _orderId = args.orderId;
      if (_currentUserRole == 'provider') {
        _peerId = args.clientId;
        _peerName = args.clientName.isNotEmpty ? args.clientName : 'العميل';
        _peerImage = args.clientImage;
        _peerRole = 'client';
      } else {
        _peerId = args.providerId;
        _peerName =
            args.providerName.isNotEmpty ? args.providerName : 'مزود الخدمة';
        _peerImage = args.providerImage;
        _peerRole = 'provider';
      }
    } else if (args is OrderModel) {
      _orderId = args.id;
      if (_currentUserRole == 'provider') {
        _peerId = args.clientId.isNotEmpty ? args.clientId : 'client_guest';
        _peerName = args.clientName.isNotEmpty ? args.clientName : 'العميل';
        _peerRole = 'client';
      } else {
        _peerId =
            args.providerId.isNotEmpty ? args.providerId : 'provider_guest';
        _peerName =
            args.providerName.isNotEmpty ? args.providerName : 'مزود الخدمة';
        _peerRole = 'provider';
      }
      _chatId = ChatService.buildChatId(
        orderId: args.id,
        clientId: args.clientId,
        providerId: args.providerId,
      );
    } else if (args is ProviderModel) {
      _peerId = args.id;
      _peerName = args.name;
      _peerImage = args.profileImagePath;
      _peerRole = 'provider';
      _chatId = ChatService.buildChatId(
        clientId: _currentUserId,
        providerId: _peerId,
      );
    } else if (args is Map<String, dynamic>) {
      _peerId = (args['peerId'] ?? args['receiverId'] ?? '').toString();
      _peerName =
          (args['peerName'] ?? args['receiverName'] ?? 'المستخدم').toString();
      _peerRole = (args['peerRole'] ??
              (_currentUserRole == 'provider' ? 'client' : 'provider'))
          .toString();
      _peerImage = args['peerImage']?.toString();
      _orderId = args['orderId']?.toString();

      final explicitChatId = args['chatId']?.toString();
      if (explicitChatId != null && explicitChatId.isNotEmpty) {
        _chatId = explicitChatId;
      } else {
        _chatId = ChatService.buildChatId(
          orderId: _orderId,
          clientId: _currentUserRole == 'client' ? _currentUserId : _peerId,
          providerId:
              _currentUserRole == 'provider' ? _currentUserId : _peerId,
        );
      }
    } else {
      // افتراضي
      if (_currentUserRole == 'provider') {
        _peerId = 'client_guest';
        _peerName = AppStrings.t('العميل', 'Client');
        _peerRole = 'client';
      } else {
        _peerId = UserSession.currentProvider.id.isNotEmpty
            ? UserSession.currentProvider.id
            : 'provider_guest';
        _peerName = UserSession.currentProvider.name.isNotEmpty
            ? UserSession.currentProvider.name
            : AppStrings.t('مزود الخدمة', 'Service Provider');
        _peerImage = UserSession.currentProvider.profileImagePath;
        _peerRole = 'provider';
      }
      _chatId = ChatService.buildChatId(
        clientId: _currentUserRole == 'client' ? _currentUserId : _peerId,
        providerId:
            _currentUserRole == 'provider' ? _currentUserId : _peerId,
      );
    }
  }

  void _markAsRead() {
    if (_chatId.isNotEmpty && _currentUserId.isNotEmpty) {
      ChatService.markMessagesAsRead(
        chatId: _chatId,
        currentUserId: _currentUserId,
        currentUserRole: _currentUserRole,
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    await ChatService.sendMessage(
      chatId: _chatId,
      senderId: _currentUserId,
      senderName: _currentUserName,
      senderRole: _currentUserRole,
      receiverId: _peerId,
      receiverName: _peerName,
      text: text,
      orderId: _orderId,
      clientImage:
          _currentUserRole == 'client' ? _currentUserImage : _peerImage,
      providerImage:
          _currentUserRole == 'provider' ? _currentUserImage : _peerImage,
    );

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(DateTime dt) {
    final isAr = AppLanguageManager.isArabic;
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period =
        isAr ? (dt.hour >= 12 ? 'م' : 'ص') : (dt.hour >= 12 ? 'PM' : 'AM');
    return '$hour:$minute $period';
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final imageProvider = AppImageHelper.getImageProvider(_peerImage);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: colors.primary.withValues(alpha: 0.15),
              backgroundImage: imageProvider,
              child: imageProvider == null
                  ? Icon(
                      _peerRole == 'provider'
                          ? Icons.handyman_rounded
                          : Icons.person_rounded,
                      color: colors.primary,
                      size: 22,
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _peerName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _orderId != null
                            ? '${AppStrings.t('طلب رقم', 'Order #')}: $_orderId'
                            : AppStrings.t('متصل الآن', 'Online now'),
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // شريط إشعار سياق الطلب إن وجد
          if (_orderId != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: colors.primary.withValues(alpha: 0.08),
              child: Row(
                children: [
                  Icon(
                    Icons.receipt_long_rounded,
                    size: 16,
                    color: colors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppStrings.t(
                        'محادثة مباشرة بخصوص الطلب: $_orderId',
                        'Direct chat regarding order: $_orderId',
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // قائمة الرسائل اللحظية من Firestore
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: ChatService.getMessagesStream(_chatId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 64,
                            color: colors.primary.withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            AppStrings.t(
                              'لا توجد رسائل سابقة',
                              'No previous messages',
                            ),
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppStrings.t(
                              'ابدأ المحادثة الآن للاتفاق على التفاصيل وموعد التنفيذ 💬',
                              'Start the chat now to agree on details and schedule 💬',
                            ),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // التمرير لأسفل عند وصول رسائل جديدة
                _scrollToBottom();

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final bool isMe = message.senderId == _currentUserId ||
                        (message.senderRole == _currentUserRole &&
                            message.senderId.isNotEmpty &&
                            message.senderId == _currentUserId);

                    return Align(
                      alignment: isMe
                          ? AlignmentDirectional.centerEnd
                          : AlignmentDirectional.centerStart,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.78,
                        ),
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isMe
                              ? colors.primary
                              : Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade200,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(18),
                            topRight: const Radius.circular(18),
                            bottomLeft: isMe
                                ? const Radius.circular(18)
                                : const Radius.circular(4),
                            bottomRight: isMe
                                ? const Radius.circular(4)
                                : const Radius.circular(18),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: isMe
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            Text(
                              message.text,
                              style: TextStyle(
                                color: isMe
                                    ? Colors.white
                                    : Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white
                                        : Colors.black87,
                                fontSize: 15,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _formatTime(message.timestamp),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isMe
                                        ? Colors.white.withValues(alpha: 0.75)
                                        : Colors.grey.shade600,
                                  ),
                                ),
                                if (isMe) ...[
                                  const SizedBox(width: 4),
                                  Icon(
                                    message.isRead
                                        ? Icons.done_all_rounded
                                        : Icons.done_rounded,
                                    size: 13,
                                    color: message.isRead
                                        ? Colors.lightBlueAccent
                                        : Colors.white.withValues(alpha: 0.75),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // شريط كتابة وإرسال الرسالة
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border(
                  top: BorderSide(
                    color: colors.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      _messageController.text = AppStrings.t(
                        '📍 هذا موقع تنفيذ الخدمة المتفق عليه.',
                        '📍 This is the agreed service location.',
                      );
                    },
                    icon: Icon(
                      Icons.location_on_outlined,
                      color: colors.primary,
                    ),
                    tooltip: AppStrings.t('إرسال الموقع', 'Share location'),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      textAlign: AppLanguageManager.isArabic
                          ? TextAlign.right
                          : TextAlign.left,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: AppStrings.t(
                          'اكتب رسالتك...',
                          'Type your message...',
                        ),
                        isDense: true,
                        filled: true,
                        fillColor: colors.surfaceContainerHighest
                            .withValues(alpha: 0.45),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 11,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: colors.primary,
                    child: IconButton(
                      onPressed: _sendMessage,
                      icon: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      tooltip: AppStrings.t('إرسال', 'Send'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
