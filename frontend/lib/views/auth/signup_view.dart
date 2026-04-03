import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../widgets/glass_container.dart';
import 'login_view.dart';

class SignupView extends StatelessWidget {
  final AuthController _authController = Get.put(AuthController());
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController passionController = TextEditingController();
  final TextEditingController interestsController = TextEditingController();

  SignupView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          // Background decorations (same as HomeView)
          Positioned(top: -100, right: -100, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.indigo.withOpacity(0.1)))),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Create Account', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Join our community and find your match', style: TextStyle(color: Colors.white.withOpacity(0.6))),
                    const SizedBox(height: 40),
                    
                    _buildTextField(label: 'Full Name', controller: nameController, icon: Icons.person_outline),
                    const SizedBox(height: 20),
                    _buildTextField(label: 'Email', controller: emailController, icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 20),
                    _buildTextField(label: 'Password', controller: passwordController, icon: Icons.lock_outline, isPassword: true),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(child: _buildTextField(label: 'Age', controller: ageController, icon: Icons.calendar_today_outlined, keyboardType: TextInputType.number)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildTextField(label: 'Passion', controller: passionController, icon: Icons.favorite_outline)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(label: 'Interests (comma separated)', controller: interestsController, icon: Icons.interests_outlined),
                    
                    const SizedBox(height: 40),
                    
                    Obx(() => SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _authController.isLoading.value ? null : () async {
                          if (_formKey.currentState!.validate()) {
                            bool success = await _authController.signup(
                              name: nameController.text,
                              email: emailController.text,
                              password: passwordController.text,
                              age: int.parse(ageController.text),
                              passion: passionController.text,
                              interests: interestsController.text.split(','),
                            );
                            if (success) Get.offAllNamed('/discover');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigoAccent,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _authController.isLoading.value 
                          ? const CircularProgressIndicator(color: Colors.white) 
                          : const Text('Sign Up', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    )),
                    
                    const SizedBox(height: 20),
                    Center(
                      child: TextButton(
                        onPressed: () => Get.to(() => LoginView()),
                        child: Text('Already have an account? Login', style: TextStyle(color: Colors.white.withOpacity(0.8))),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label, 
    required TextEditingController controller, 
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return GlassContainer(
      padding: EdgeInsets.zero,
      borderRadius: 16,
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
          prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.4)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        validator: (value) => value == null || value.isEmpty ? 'Please enter $label' : null,
      ),
    );
  }
}
