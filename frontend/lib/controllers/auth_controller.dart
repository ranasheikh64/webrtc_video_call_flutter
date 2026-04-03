import 'dart:convert';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import '../api_config.dart';
import '../models/user_model.dart';
import '../services/socket_service.dart';

class AuthController extends GetxController {
  final String baseUrl = '${ApiConfig.baseUrl}/api/auth';
  final _storage = GetStorage();
  
  var isLoading = false.obs;
  var token = ''.obs;
  var currentUser = Rxn<UserModel>();

  @override
  void onInit() {
    super.onInit();
    _loadSession(); // NEW: Load session on startup
    
    // Re-join socket if user is already logged in
    ever(currentUser, (user) {
      if (user != null) {
        try {
          Get.find<SocketService>().socket.emit('join-user', user.id);
        } catch (e) {
          print('SocketService not yet initialized: $e');
        }
      }
    });
  }

  void _loadSession() {
    final savedToken = _storage.read('token');
    final savedUser = _storage.read('user');
    
    if (savedToken != null && savedUser != null) {
      token.value = savedToken;
      currentUser.value = UserModel.fromJson(jsonDecode(savedUser));
      print('DEBUG: Session restored for ${currentUser.value?.name}');
    }
  }

  Future<void> _saveSession(String userToken, UserModel user) async {
    token.value = userToken;
    currentUser.value = user;
    await _storage.write('token', userToken);
    await _storage.write('user', jsonEncode(user.toJson()));
  }

  Future<bool> signup({
    required String name,
    required String email,
    required String password,
    required int age,
    required String passion,
    required List<String> interests,
  }) async {
    try {
      isLoading.value = true;
      final response = await http.post(
        Uri.parse('$baseUrl/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'age': age,
          'passion': passion,
          'interests': interests,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        await _saveSession(data['token'], UserModel.fromJson(data['user']));
        return true;
      } else {
        final error = jsonDecode(response.body);
        Get.snackbar('Signup Failed', error['message'] ?? 'Unknown error');
        return false;
      }
    } catch (e) {
      Get.snackbar('Error', 'Something went wrong: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      isLoading.value = true;
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _saveSession(data['token'], UserModel.fromJson(data['user']));
        return true;
      } else {
        final error = jsonDecode(response.body);
        Get.snackbar('Login Failed', error['message'] ?? 'Invalid credentials');
        return false;
      }
    } catch (e) {
      Get.snackbar('Error', 'Something went wrong: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  void logout() {
    token.value = '';
    currentUser.value = null;
    _storage.remove('token');
    _storage.remove('user');
    Get.offAllNamed('/login');
  }
}
