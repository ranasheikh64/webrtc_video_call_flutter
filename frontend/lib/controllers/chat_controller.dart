import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../api_config.dart';
import '../services/socket_service.dart';
import 'auth_controller.dart';

class MessageModel {
  final String senderId;
  final String text;
  final DateTime createdAt;

  MessageModel({required this.senderId, required this.text, required this.createdAt});

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      senderId: json['senderId'] is Map ? json['senderId']['_id'] : json['senderId'],
      text: json['text'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

class ChatController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();
  final SocketService _socketService = Get.find<SocketService>();
  
  var messages = <MessageModel>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    _socketService.on('receive-message', (data) {
      if (data['senderId'] != _authController.currentUser.value?.id) {
        messages.add(MessageModel(
          senderId: data['senderId'],
          text: data['text'],
          createdAt: DateTime.parse(data['createdAt'] ?? DateTime.now().toIso8601String()),
        ));
      }
    });
  }

  Future<void> loadMessages(String receiverId) async {
    try {
      isLoading.value = true;
      messages.clear();
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/messages/$receiverId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_authController.token.value}',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        messages.assignAll(data.map((m) => MessageModel.fromJson(m)).toList());
        print('DEBUG: Loaded ${messages.length} previous messages');
      } else {
        print('DEBUG: Failed to load messages: ${response.statusCode}');
      }
    } catch (e) {
      print('DEBUG: Error loading messages: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void sendMessage(String receiverId, String text) {
    if (text.trim().isEmpty) return;
    
    final newMessage = MessageModel(
      senderId: _authController.currentUser.value!.id,
      text: text,
      createdAt: DateTime.now(),
    );
    
    messages.add(newMessage);
    
    _socketService.emit('send-message', {
      'senderId': _authController.currentUser.value!.id,
      'receiverId': receiverId,
      'text': text,
    });
  }
}
