import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart' hide navigator;
import 'package:permission_handler/permission_handler.dart';
import '../services/socket_service.dart';
import '../views/call/call_view.dart';
import 'auth_controller.dart';

enum CallStatus { idle, ringing, calling, connected, ended }

class SignalingController extends GetxController {
  final SocketService _socketService = Get.find<SocketService>();
  final AuthController _authController = Get.find<AuthController>();
  
  // WebRTC variables
  RTCPeerConnection? _peerConnection;
  RTCVideoRenderer localRenderer = RTCVideoRenderer();
  RTCVideoRenderer remoteRenderer = RTCVideoRenderer();
  MediaStream? _localStream;
  
  // State Observables
  var selfId = ''.obs;
  var targetId = ''.obs;
  var socketStatus = 'Disconnected'.obs;
  var callStatus = CallStatus.idle.obs;
  var isMicMuted = false.obs;
  var isCameraOff = false.obs;
  var isSpeakerOn = true.obs;
  var callDuration = '00:00'.obs;
  
  // Camera refresh markers
  var localCameraVersion = 0.obs;
  var remoteCameraVersion = 0.obs;
  
  // Remote user info
  var callerId = ''.obs;
  dynamic _pendingOffer;
  
  // Timer for call duration
  Timer? _timer;
  int _secondsElapsed = 0;

  // ICE candidate queue and state
  final List<RTCIceCandidate> _remoteCandidatesQueue = [];
  bool _isRemoteDescriptionSet = false;

  @override
  void onInit() {
    super.onInit();
    
    // Robust Identity Sync
    if (_authController.currentUser.value != null) {
      selfId.value = _authController.currentUser.value!.id;
    }
    
    // Watch for identity changes
    ever(_authController.currentUser, (user) {
      if (user != null && selfId.value != user.id) {
        print('DEBUG: Syncing selfId to ${user.id}');
        selfId.value = user.id;
      }
    });

    _startFullInit();
  }

  Future<void> _startFullInit() async {
    try {
      await _initRenderers();
      await _requestPermissions();
      await Future.delayed(const Duration(milliseconds: 1000));
      await _initLocalStream();
      _setupSocketListeners();
    } catch (e) {
      print('DEBUG: Initialization error: $e');
    }
  }

  @override
  void onClose() {
    _stopTimer();
    localRenderer.dispose();
    remoteRenderer.dispose();
    _peerConnection?.dispose();
    super.onClose();
  }

  Future<void> _initRenderers() async {
    await localRenderer.initialize();
    await remoteRenderer.initialize();
  }

  Future<void> _requestPermissions() async {
    try {
      if (GetPlatform.isAndroid || GetPlatform.isIOS) {
        Map<Permission, PermissionStatus> statuses = await [
          Permission.camera,
          Permission.microphone,
        ].request();
        
        if (statuses[Permission.camera]!.isDenied || statuses[Permission.microphone]!.isDenied) {
          Get.snackbar(
            'Permissions Required', 
            'Camera and Microphone access are needed for video calls.',
            backgroundColor: Colors.redAccent.withOpacity(0.8),
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      }
    } catch (e) {
      print('DEBUG: Permission request error: $e');
    }
  }

  Future<void> _initLocalStream() async {
    try {
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': {
          'facingMode': 'user',
          'width': {'ideal': 640},
          'height': {'ideal': 480},
          'frameRate': {'ideal': 15, 'max': 20},
        },
      });
      localRenderer.srcObject = _localStream;
      localCameraVersion.value++;
      print('DEBUG: Local camera started at 640x480');
    } catch (e) {
      print('DEBUG: Error initializing local stream: $e');
      try {
        _localStream = await navigator.mediaDevices.getUserMedia({
          'audio': true,
          'video': {
            'facingMode': 'user',
            'width': {'ideal': 320},
            'height': {'ideal': 240},
            'frameRate': {'ideal': 10, 'max': 15},
          },
        });
        localRenderer.srcObject = _localStream;
        localCameraVersion.value++; 
      } catch (e2) {
        print('DEBUG: Fallback resolution also failed: $e2');
      }
    }
  }

  Future<void> restartLocalCamera() async {
    print('DEBUG: Manually restarting camera...');
    if (_localStream != null) {
      _localStream!.getTracks().forEach((track) => track.stop());
    }
    localRenderer.srcObject = null;
    await Future.delayed(const Duration(milliseconds: 500));
    await _initLocalStream();
  }

  void _setupSocketListeners() {
    _socketService.on('incoming-call', (data) {
      print('DEBUG: [EVENT] incoming-call from ${data['callerId']}');
      callerId.value = data['callerId'];
      _pendingOffer = data['offer'];
      callStatus.value = CallStatus.ringing;
      _showIncomingCallDialog(data['callerId']);
    });

    _socketService.on('call-accepted', (data) async {
      print('DEBUG: [EVENT] call-accepted by ${data['responderId']}');
      var answer = data['answer'];
      if (_peerConnection != null) {
        String sdp = _optimizeSDP(answer['sdp']);
        await _peerConnection!.setRemoteDescription(
          RTCSessionDescription(sdp, answer['type']),
        );
        _isRemoteDescriptionSet = true;
        print('DEBUG: Remote description (answer) set successfully');
        await _processRemoteCandidates();
        _startCallSession();
      }
    });

    _socketService.on('ice-candidate', (data) async {
      var candidateMap = data['candidate'];
      String candidateStr = candidateMap['candidate'] ?? '';
      String type = candidateStr.contains('typ host') ? 'HOST' : (candidateStr.contains('typ srflx') ? 'SRFLX' : 'OTHER');
      
      print('DEBUG: [EVENT] ice-candidate RECEIVED ($type) from ${data['senderId']}');
      
      RTCIceCandidate candidate = RTCIceCandidate(
        candidateMap['candidate'],
        candidateMap['sdpMid'],
        candidateMap['sdpMLineIndex'],
      );
      
      if (_peerConnection != null && _isRemoteDescriptionSet) {
        try {
          await _peerConnection?.addCandidate(candidate);
          print('DEBUG: ICE Candidate added to PeerConnection');
        } catch (e) {
          print('DEBUG: [ICE] Error adding candidate: $e');
        }
      } else {
        _remoteCandidatesQueue.add(candidate);
        print('DEBUG: ICE Candidate queued (remote description not set yet)');
      }
    });

    _socketService.on('hangup', (_) {
      print('DEBUG: [EVENT] hangup received');
      _finishCall();
    });
  }

  void _showIncomingCallDialog(String callerName) {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Incoming Call', style: TextStyle(color: Colors.white)),
        content: Text('$callerName is calling you...', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () {
              rejectCall();
              Get.back();
            },
            child: const Text('Reject', style: TextStyle(color: Colors.redAccent)),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              acceptCall();
              Get.to(() => CallView());
            },
            child: const Text('Accept'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  void join(String userId) {
    selfId.value = userId;
    _socketService.emit('join-user', userId);
  }

  // --- WebRTC Logic ---

  Future<void> makeCall(String targetUserId) async {
    if (selfId.value.isEmpty) {
      print('DEBUG: makeCall failed: selfId is empty');
      Get.snackbar('Error', 'Identity not synced. Please wait a moment.');
      return;
    }
    
    print('DEBUG: Initiating call to $targetUserId');
    targetId.value = targetUserId;
    callStatus.value = CallStatus.calling;
    
    await _createPeerConnection();
    
    RTCSessionDescription offer = await _peerConnection!.createOffer();
    String optimizedSdp = _optimizeSDP(offer.sdp!);
    
    await _peerConnection!.setLocalDescription(RTCSessionDescription(optimizedSdp, offer.type!));

    print('DEBUG: [SOCKET] Emit call-user (offer)');
    _socketService.emit('call-user', {
      'targetId': targetUserId,
      'callerId': selfId.value,
      'offer': {
        'type': offer.type,
        'sdp': optimizedSdp,
      },
    });
  }

  Future<void> acceptCall() async {
    print('DEBUG: Accepting call from ${callerId.value}');
    callStatus.value = CallStatus.connected;
    
    await _createPeerConnection();
    
    String optimizedOfferSdp = _optimizeSDP(_pendingOffer['sdp']);
    await _peerConnection!.setRemoteDescription(
      RTCSessionDescription(optimizedOfferSdp, _pendingOffer['type']),
    );
    _isRemoteDescriptionSet = true;
    print('DEBUG: Remote description (offer) set successfully');
    await _processRemoteCandidates();

    RTCSessionDescription answer = await _peerConnection!.createAnswer();
    String optimizedAnswerSdp = _optimizeSDP(answer.sdp!);
    
    await _peerConnection!.setLocalDescription(RTCSessionDescription(optimizedAnswerSdp, answer.type!));

    print('DEBUG: [SOCKET] Emit accept-call (answer)');
    _socketService.emit('accept-call', {
      'targetId': callerId.value,
      'responderId': selfId.value,
      'answer': {
        'type': answer.type,
        'sdp': optimizedAnswerSdp,
      },
    });
    
    _startCallSession();
  }

  void rejectCall() {
    print('DEBUG: Rejecting call');
    _socketService.emit('hangup', {
      'targetId': callerId.value,
      'senderId': selfId.value,
    });
    _finishCall();
  }

  void hangUp() {
    print('DEBUG: Hanging up');
    _socketService.emit('hangup', {
      'targetId': callStatus.value == CallStatus.ringing ? callerId.value : targetId.value,
      'senderId': selfId.value,
    });
    _finishCall();
  }

  Future<void> _createPeerConnection() async {
    print('DEBUG: Creating PeerConnection...');
    Map<String, dynamic> configuration = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        {'urls': 'stun:stun1.l.google.com:19302'},
        {'urls': 'stun:stun2.l.google.com:19302'},
        {'urls': 'stun:stun3.l.google.com:19302'},
        {'urls': 'stun:stun4.l.google.com:19302'},
        {'urls': 'stun:global.stun.twilio.com:3478'},
      ],
      'sdpSemantics': 'unified-plan',
      'bundlePolicy': 'max-bundle',
      'rtcpMuxPolicy': 'require',
    };

    _peerConnection = await createPeerConnection(configuration);

    _localStream?.getTracks().forEach((track) {
      print('DEBUG: Adding local track: ${track.kind}');
      _peerConnection!.addTrack(track, _localStream!);
    });

    _peerConnection!.onIceCandidate = (RTCIceCandidate? candidate) {
      if (candidate != null) {
        String candidateStr = candidate.candidate ?? '';
        String type = candidateStr.contains('typ host') ? 'HOST' : (candidateStr.contains('typ srflx') ? 'SRFLX' : 'OTHER');
        print('DEBUG: onIceCandidate GENERATED ($type)');
        
        _socketService.emit('ice-candidate', {
          'targetId': (callStatus.value == CallStatus.ringing || (callStatus.value == CallStatus.connected && callerId.value.isNotEmpty)) ? callerId.value : targetId.value,
          'candidate': candidate.toMap(),
          'senderId': selfId.value,
        });
      }
    };

    _peerConnection!.onTrack = (RTCTrackEvent event) {
      print('DEBUG: onTrack event: ${event.track.kind}');
      if (event.streams.isNotEmpty) {
        remoteRenderer.srcObject = event.streams[0];
        remoteCameraVersion.value++;
      }
    };

    _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
      print('DEBUG: [STATE] Connection: $state');
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        callStatus.value = CallStatus.connected;
      }
    };
    
    _peerConnection!.onIceConnectionState = (RTCIceConnectionState state) {
      print('DEBUG: [ICE] Connection state: $state');
      // Fix: Only restart if we had a connection and lost it, or if it timed out in checking
      if (state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
         print('DEBUG: [ICE] Restarting gathering...');
         _peerConnection?.restartIce();
      }
    };

    _peerConnection!.onIceGatheringState = (RTCIceGatheringState state) {
      print('DEBUG: [ICE] Gathering state: $state');
    };
  }

  // Fixed Optimized SDP Helper
  String _optimizeSDP(String sdp) {
    List<String> lines = sdp.split('\r\n');
    List<String> newLines = [];
    
    int videoIndex = -1;
    for (int i = 0; i < lines.length; i++) {
        String line = lines[i];
        if (line.startsWith('m=video')) videoIndex = i;
        newLines.add(line);
        
        if (videoIndex != -1 && i == videoIndex) {
            newLines.add('b=AS:500'); 
            newLines.add('a=framerate:20');
        }
    }

    if (videoIndex != -1) {
        String videoLine = newLines[videoIndex];
        List<String> parts = videoLine.split(' ');
        if (parts.length > 3) {
            String vp8Id = '';
            for (String line in lines) {
                if (line.contains('a=rtpmap:') && line.contains('VP8/90000')) {
                    var match = RegExp(r'a=rtpmap:(\d+)').firstMatch(line);
                    if (match != null) {
                        vp8Id = match.group(1)!;
                    }
                    break;
                }
            }
            if (vp8Id.isNotEmpty) {
                List<String> payloadIds = parts.sublist(3);
                payloadIds.remove(vp8Id);
                payloadIds.insert(0, vp8Id);
                newLines[videoIndex] = '${parts[0]} ${parts[1]} ${parts[2]} ${payloadIds.join(' ')}';
                print('DEBUG: [SDP] Forced VP8 as preferred codec ($vp8Id)');
            }
        }
    }
    
    return newLines.join('\r\n');
  }

  Future<void> _processRemoteCandidates() async {
    print('DEBUG: Processing ${_remoteCandidatesQueue.length} queued remote candidates');
    for (var candidate in _remoteCandidatesQueue) {
      try {
        await _peerConnection?.addCandidate(candidate);
      } catch (e) {
        print('DEBUG: [ICE] Error adding remote candidate: $e');
      }
    }
    _remoteCandidatesQueue.clear();
  }

  void _startCallSession() {
    print('DEBUG: Starting call session timer');
    callStatus.value = CallStatus.connected;
    _startTimer();
  }

  void _finishCall() {
    print('DEBUG: Finishing call and disposing resources');
    _stopTimer();
    callStatus.value = CallStatus.ended;
    remoteRenderer.srcObject = null;
    _isRemoteDescriptionSet = false;
    _remoteCandidatesQueue.clear();
    _peerConnection?.close();
    _peerConnection = null;
    
    Future.delayed(const Duration(seconds: 2), () {
      callStatus.value = CallStatus.idle;
    });
  }

  // --- UI Controls ---

  void toggleMic() {
    isMicMuted.value = !isMicMuted.value;
    _localStream?.getAudioTracks().forEach((track) {
      track.enabled = !isMicMuted.value;
    });
  }

  void toggleCamera() {
    isCameraOff.value = !isCameraOff.value;
    _localStream?.getVideoTracks().forEach((track) {
      track.enabled = !isCameraOff.value;
    });
  }

  void switchCamera() {
    if (_localStream != null && _localStream!.getVideoTracks().isNotEmpty) {
      Helper.switchCamera(_localStream!.getVideoTracks()[0]);
    }
  }

  void toggleSpeaker() {
    isSpeakerOn.value = !isSpeakerOn.value;
    Helper.setSpeakerphoneOn(isSpeakerOn.value);
  }

  // --- Timer Logic ---

  void _startTimer() {
    _secondsElapsed = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _secondsElapsed++;
      int minutes = _secondsElapsed ~/ 60;
      int seconds = _secondsElapsed % 60;
      callDuration.value = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _secondsElapsed = 0;
    callDuration.value = '00:00';
  }
}
