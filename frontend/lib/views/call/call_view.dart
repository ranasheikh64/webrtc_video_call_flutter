import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:frontend/controllers/signaling_controller.dart';
import 'package:frontend/views/widgets/glass_container.dart';
import 'package:get/get.dart';

class CallView extends StatelessWidget {
  final SignalingController _signalingController = Get.find<SignalingController>();

  CallView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          // Remote Video (Background)
          Positioned.fill(
            child: Container(
              color: Colors.black,
              child: Obx(() => _signalingController.callStatus.value == CallStatus.connected
                  ? RTCVideoView(
                      _signalingController.remoteRenderer,
                      key: ValueKey('remote_${_signalingController.remoteCameraVersion.value}'),
                      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    )
                  : const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: Colors.indigoAccent),
                          SizedBox(height: 24),
                          Text(
                            'ESTABLISHING CONNECTION...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    )),
            ),
          ),
          
          // Local Video (PIP)
          Positioned(
            right: 20,
            top: 60,
            width: 120,
            height: 180,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Obx(() => RTCVideoView(
                  _signalingController.localRenderer,
                  key: ValueKey('local_${_signalingController.localCameraVersion.value}'),
                  mirror: true,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                )),
              ),
            ),
          ),
          
          // Camera Restart Button (NEW: Floating)
          Positioned(
            right: 20,
            top: 250,
            child: GestureDetector(
              onTap: () => _signalingController.restartLocalCamera(),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.indigoAccent),
                ),
                child: const Icon(Icons.refresh_rounded, color: Colors.indigoAccent, size: 20),
              ),
            ),
          ),
          
          // Call Header (Timer)
          Positioned(
            top: 60,
            left: 20,
            child: GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              borderRadius: 16,
              child: Obx(() => Row(
                children: [
                  const Icon(Icons.timer_outlined, color: Colors.indigoAccent, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    _signalingController.callDuration.value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              )),
            ),
          ),
          
          // Call UI Controls
          Positioned(
            bottom: 40,
            left: 10,
            right: 10,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withOpacity(0.9),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildControlButton(
                    icon: Icons.switch_camera_rounded,
                    color: Colors.white.withOpacity(0.1),
                    onPressed: () => _signalingController.switchCamera(),
                    label: 'Flip',
                  ),
                  Obx(() => _buildControlButton(
                    icon: _signalingController.isMicMuted.value ? Icons.mic_off_rounded : Icons.mic_rounded,
                    color: _signalingController.isMicMuted.value ? Colors.redAccent.withOpacity(0.2) : Colors.white.withOpacity(0.1),
                    onPressed: () => _signalingController.toggleMic(),
                    label: 'Mute',
                    isActive: !_signalingController.isMicMuted.value,
                  )),
                  Obx(() => _buildControlButton(
                    icon: _signalingController.isSpeakerOn.value ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                    color: _signalingController.isSpeakerOn.value ? Colors.white.withOpacity(0.1) : Colors.redAccent.withOpacity(0.2),
                    onPressed: () => _signalingController.toggleSpeaker(),
                    label: 'Speaker',
                    isActive: _signalingController.isSpeakerOn.value,
                  )),
                  _buildHangupButton(),
                  Obx(() => _buildControlButton(
                    icon: _signalingController.isCameraOff.value ? Icons.videocam_off_rounded : Icons.videocam_rounded,
                    color: _signalingController.isCameraOff.value ? Colors.redAccent.withOpacity(0.2) : Colors.white.withOpacity(0.1),
                    onPressed: () => _signalingController.toggleCamera(),
                    label: 'Video',
                    isActive: !_signalingController.isCameraOff.value,
                  )),
                ],
              ),
            ),
          ),
          
          // Call Termination Overlay
          Obx(() => _signalingController.callStatus.value == CallStatus.ended
              ? Container(
                  color: Colors.black87,
                  child: const Center(
                    child: Text(
                      'CALL ENDED',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink()),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon, 
    required Color color, 
    required VoidCallback onPressed,
    required String label,
    bool isActive = true,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onPressed,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive ? Colors.white.withOpacity(0.2) : Colors.redAccent.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Icon(icon, color: isActive ? Colors.white : Colors.redAccent, size: 22),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildHangupButton() {
    return GestureDetector(
      onTap: () {
        _signalingController.hangUp();
        Get.back();
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: const BoxDecoration(
          color: Colors.redAccent,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.redAccent, blurRadius: 15, spreadRadius: 1),
          ],
        ),
        child: const Icon(Icons.call_end_rounded, color: Colors.white, size: 28),
      ),
    );
  }
}
