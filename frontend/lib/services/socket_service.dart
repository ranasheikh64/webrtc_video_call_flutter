import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../api_config.dart';
import '../controllers/auth_controller.dart';

class SocketService extends GetxService {
  late IO.Socket socket;
  final AuthController _authController = Get.find<AuthController>();

  Future<SocketService> init() async {
    _initSocket();
    return this;
  }

  void _initSocket() {
    socket = IO.io(ApiConfig.baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.onConnect((_) {
      print('Socket connected: ${socket.id}');
      _joinUser();
    });

    socket.onDisconnect((_) {
      print('Socket disconnected');
    });

    socket.onConnectError((err) {
      print('Socket connect error: $err');
    });

    socket.connect();
  }

  void _joinUser() {
    if (_authController.currentUser.value != null) {
      print('Joining user: ${_authController.currentUser.value!.id}');
      socket.emit('join-user', _authController.currentUser.value!.id);
    }
  }

  // Helper method for other controllers to subscribe to events
  void on(String event, Function(dynamic) handler) {
    socket.on(event, handler);
  }

  // Helper method for other controllers to emit events
  void emit(String event, dynamic data) {
    socket.emit(event, data);
  }
}
