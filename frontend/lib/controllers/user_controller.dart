import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../api_config.dart';
import '../models/user_model.dart';
import 'auth_controller.dart';

class UserController extends GetxController {
  final String baseUrl = '${ApiConfig.baseUrl}/api/users';
  final AuthController _authController = Get.find<AuthController>();
  
  var usersList = <UserModel>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchUsers();
  }

  Future<void> fetchUsers({String? name, String? passion}) async {
    try {
      isLoading.value = true;
      String url = baseUrl;
      if (name != null || passion != null) {
        url += '?';
        if (name != null) url += 'name=$name&';
        if (passion != null) url += 'passion=$passion';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${_authController.token.value}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        usersList.assignAll(data.map((u) => UserModel.fromJson(u)).toList());
      } else {
        Get.snackbar('Error', 'Failed to fetch users');
      }
    } catch (e) {
      Get.snackbar('Error', 'Something went wrong: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
