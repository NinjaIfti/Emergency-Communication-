import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../utils/constants.dart';
import '../widgets/message_bubble.dart';
import '../models/message_model.dart';
import '../providers/message_provider.dart';
import '../providers/peer_provider.dart';

class ChatScreen extends StatefulWidget {
  final String peerName;
  final String peerId;

  const ChatScreen({
    super.key,
    required this.peerName,
    required this.peerId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _userId;

  @override
  void initState() {
    super.initState();
    // Load conversation when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final messageProvider = Provider.of<MessageProvider>(context, listen: false);
      _userId = messageProvider.myDeviceId;
      messageProvider.loadConversation(_userId!, widget.peerId);
      
      // Load all messages to get real-time updates
      messageProvider.loadMessages();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    if (_userId == null) return;

    final messageProvider = Provider.of<MessageProvider>(context, listen: false);
    
    // Create new message
    final message = Message(
      id: const Uuid().v4(),
      content: _messageController.text.trim(),
      senderId: _userId!,
      recipientId: widget.peerId,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      messageType: MessageType.TEXT,
      isDelivered: false,
    );

    // Send via provider
    messageProvider.sendMessage(message);

    _messageController.clear();

    // Auto scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<PeerProvider>(
          builder: (context, peerProvider, child) {
            final peer = peerProvider.getPeerById(widget.peerId);
            final isConnected = peer?.isConnected ?? false;
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.peerName),
                Text(
                  isConnected ? 'Online' : 'Offline',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            );
          },
        ),
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              // Show peer info
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages List with Provider (real-time updates)
          Expanded(
            child: Consumer<MessageProvider>(
              builder: (context, messageProvider, child) {
                // Auto-refresh messages periodically for real-time updates
                if (messageProvider.messages.isEmpty && !messageProvider.isLoading) {
                  // Reload if empty
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    final userId = _userId ?? messageProvider.myDeviceId;
                    messageProvider.loadConversation(userId, widget.peerId);
                  });
                }

                if (messageProvider.isLoading && messageProvider.messages.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (messageProvider.messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 80,
                          color: AppColors.grey,
                        ),
                        const SizedBox(height: AppSizes.paddingMedium),
                        Text(
                          'No messages yet',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.grey,
                          ),
                        ),
                        const SizedBox(height: AppSizes.paddingSmall),
                        Text(
                          'Send a message to start chatting',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  );
                }

                // Filter messages for this conversation
                final userId = _userId ?? messageProvider.myDeviceId;
                final conversationMessages = messageProvider.messages.where((m) =>
                  (m.senderId == userId && m.recipientId == widget.peerId) ||
                  (m.senderId == widget.peerId && m.recipientId == userId)
                ).toList();

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(AppSizes.paddingMedium),
                  itemCount: conversationMessages.length,
                  itemBuilder: (context, index) {
                    final message = conversationMessages[index];
                    final userId = _userId ?? messageProvider.myDeviceId;
                    final isSent = message.senderId == userId;
                    return MessageBubble(
                      message: message,
                      isSent: isSent,
                    );
                  },
                );
              },
            ),
          ),

          // Message Input
          Container(
            padding: const EdgeInsets.all(AppSizes.paddingMedium),
            decoration: BoxDecoration(
              color: AppColors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        filled: true,
                        fillColor: AppColors.lightGrey,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.paddingMedium,
                          vertical: AppSizes.paddingSmall,
                        ),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: AppSizes.paddingSmall),
                  CircleAvatar(
                    backgroundColor: AppColors.secondary,
                    child: IconButton(
                      icon: const Icon(Icons.send),
                      color: AppColors.white,
                      onPressed: _sendMessage,
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


