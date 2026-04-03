import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/chat_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/signaling_controller.dart';
import '../../models/user_model.dart';
import '../widgets/glass_container.dart';
import '../call/call_view.dart';

class ChatView extends StatelessWidget {
  final UserModel targetUser;
  final ChatController _chatController = Get.put(ChatController());
  final AuthController _authController = Get.find<AuthController>();
  final SignalingController _signalingController = Get.find<SignalingController>();
  final TextEditingController _messageController = TextEditingController();

  ChatView({super.key, required this.targetUser}) {
    _chatController.loadMessages(targetUser.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(backgroundColor: Colors.indigoAccent.withOpacity(0.2), child: const Icon(Icons.person, color: Colors.white)),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(targetUser.name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                Text(targetUser.status, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone_outlined, color: Colors.indigoAccent),
            onPressed: () {
              // Placeholder for Audio Call
              Get.snackbar('Audio Call', 'Initiating audio call with ${targetUser.name}');
            },
          ),
          IconButton(
            icon: const Icon(Icons.videocam_outlined, color: Colors.indigoAccent),
            onPressed: () {
              _signalingController.makeCall(targetUser.id);
              Get.to(() => CallView());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              if (_chatController.isLoading.value && _chatController.messages.isEmpty) {
                return const Center(child: CircularProgressIndicator(color: Colors.indigoAccent));
              }
              return ListView.builder(
                padding: const EdgeInsets.all(20),
                reverse: true,
                itemCount: _chatController.messages.length,
                itemBuilder: (context, index) {
                  final msg = _chatController.messages[_chatController.messages.length - 1 - index];
                  final isMe = msg.senderId == _authController.currentUser.value!.id;
                  return _buildMessageBubble(msg, isMe);
                },
              );
            }),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel msg, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isMe ? Colors.indigoAccent : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMe ? 20 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 20),
          ),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(msg.text, style: const TextStyle(color: Colors.white, fontSize: 15)),
            const SizedBox(height: 4),
            Text(
              '${msg.createdAt.hour}:${msg.createdAt.minute.toString().padLeft(2, '0')}', 
              style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: GlassContainer(
              padding: EdgeInsets.zero,
              borderRadius: 24,
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              _chatController.sendMessage(targetUser.id, _messageController.text);
              _messageController.clear();
            },
            child: Container(
              width: 54,
              height: 54,
              decoration: const BoxDecoration(color: Colors.indigoAccent, shape: BoxShape.circle),
              child: const Icon(Icons.send_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
