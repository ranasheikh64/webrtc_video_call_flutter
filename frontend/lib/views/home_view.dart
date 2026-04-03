import 'package:flutter/material.dart';
import 'package:frontend/views/call/call_view.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import '../controllers/signaling_controller.dart';
import 'widgets/glass_container.dart';

class HomeView extends StatelessWidget {
  final SignalingController _signalingController = Get.put(
    SignalingController(),
  );
  final TextEditingController _selfIdController = TextEditingController();
  final TextEditingController _targetIdController = TextEditingController();

  HomeView({super.key});

  Future<void> _handlePermissions() async {
    await [Permission.camera, Permission.microphone].request();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          // Background Gradient Circles
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.indigo.withOpacity(0.2),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.purple.withOpacity(0.2),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 40.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 48),

                  // Identity Card
                  _buildCard(
                    title: 'Your Presence',
                    icon: Icons.person_outline,
                    child: Column(
                      children: [
                        _buildTextField(
                          controller: _selfIdController,
                          label: 'Set Your Unique ID',
                          icon: Icons.fingerprint,
                        ),
                        const SizedBox(height: 16),
                        _buildPrimaryButton(
                          onPressed: () {
                            if (_selfIdController.text.isNotEmpty) {
                              _signalingController.join(_selfIdController.text);
                              Get.snackbar(
                                'Identity Set',
                                'You are now online as ${_selfIdController.text}',
                                backgroundColor: Colors.indigo.withOpacity(0.8),
                                colorText: Colors.white,
                                snackPosition: SnackPosition.BOTTOM,
                              );
                            }
                          },
                          text: 'Go Online',
                          icon: Icons.wifi,
                          color: Colors.indigoAccent,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Connect Card
                  _buildCard(
                    title: 'Make a Connection',
                    icon: Icons.add_call,
                    child: Column(
                      children: [
                        _buildTextField(
                          controller: _targetIdController,
                          label: 'Target User ID',
                          icon: Icons.alternate_email,
                        ),
                        const SizedBox(height: 16),
                        _buildPrimaryButton(
                          onPressed: () async {
                            if (_targetIdController.text.isNotEmpty) {
                              await _handlePermissions();
                              _signalingController.makeCall(
                                _targetIdController.text,
                              );
                              Get.to(() => CallView());
                            }
                          },
                          text: 'Initiate Call',
                          icon: Icons.videocam_rounded,
                          color: const Color(0xFF10B981),
                        ),
                      ],
                    ),
                  ),

                  // Watch for incoming calls
                  Obx(() {
                    if (_signalingController.callStatus.value ==
                        CallStatus.ringing) {
                      Future.delayed(Duration.zero, () {
                        _showIncomingCallDialog();
                      });
                    }
                    return const SizedBox.shrink();
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'G-RTC SDK',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
              ),
            ),
            Obx(
              () => Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          _signalingController.socketStatus.value == 'Connected'
                          ? Colors.green
                          : Colors.redAccent,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _signalingController.socketStatus.value,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        _buildAvatar(),
      ],
    );
  }

  Widget _buildAvatar() {
    return GlassContainer(
      padding: const EdgeInsets.all(8),
      borderRadius: 12,
      child: const Icon(Icons.settings_outlined, color: Colors.white),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white.withOpacity(0.8), size: 20),
            const SizedBox(width: 8),
            Text(
              title.toUpperCase(),
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GlassContainer(
          borderRadius: 24,
          padding: const EdgeInsets.all(20),
          child: child,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
        prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.4)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.indigoAccent, width: 2),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required VoidCallback onPressed,
    required String text,
    required IconData icon,
    required Color color,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        label: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  void _showIncomingCallDialog() {
    Get.bottomSheet(
      GlassContainer(
        borderRadius: 32,
        padding: const EdgeInsets.all(32),
        color: const Color(0xFF1E293B).withOpacity(0.95),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.auto_awesome,
              color: Colors.indigoAccent,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'Incoming Call Request',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Connection request from ${_signalingController.callerId.value}',
              style: TextStyle(color: Colors.white.withOpacity(0.6)),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _signalingController.rejectCall();
                      Get.back();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.1),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'REJECT',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await _handlePermissions();
                      _signalingController.acceptCall();
                      Get.back();
                      Get.to(() => CallView());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'ACCEPT',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      isDismissible: false,
      enableDrag: false,
    );
  }
}
