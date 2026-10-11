// lib/Presentations/call/call_screen.dart

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../../services/agora_service.dart';
import '../../services/one_Signal_Service.dart';

class CallScreen extends StatefulWidget {
  final String channelName;
  final String otherUserName;
  final String otherUserId;
  final int uid;
  final bool isVideoCall;

  const CallScreen({
    super.key,
    required this.channelName,
    required this.otherUserName,
    required this.otherUserId,
    required this.uid,
    this.isVideoCall = false,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  RtcEngine? _engine;
  bool _isMuted = false;
  bool _isSpeakerOn = true;
  bool _isCameraOn = true;
  bool _isConnected = false;
  bool _isRemoteUserJoined = false;
  bool _remoteAudioMuted = false;
  bool _remoteVideoMuted = false;
  int? _remoteUid;
  Timer? _timer;
  int _seconds = 0;

  @override
  void initState() {
    super.initState();
    _initializeCall();
  }

  // ============================================================
  // ✅ INITIALIZE CALL - FIXED
  // ============================================================
  Future<void> _initializeCall() async {
    try {
      // ✅ Initialize engine with correct parameters
      final engine = await AgoraService.initializeEngine(
        onJoinChannel: () {
          if (!mounted) return;
          setState(() {
            _isConnected = true;
            _startTimer();
          });
          debugPrint("🔊 Call connected");
        },
        onUserJoined: (remoteUid) {
          if (!mounted) return;
          setState(() {
            _isRemoteUserJoined = true;
            _remoteUid = remoteUid;
          });
          debugPrint("👤 Remote user joined: $remoteUid");
          _notifyCallConnected();
        },
        onUserOffline: (remoteUid) {
          if (!mounted) return;
          setState(() {
            _isRemoteUserJoined = false;
          });
          debugPrint("👋 Remote user left: $remoteUid");
          _showSnackBar("${widget.otherUserName} left the call");
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) Navigator.pop(context);
          });
        },
        // ✅ FIXED: These parameters now match
        onRemoteAudioMuted: (muted) {
          if (!mounted) return;
          setState(() {
            _remoteAudioMuted = muted;
          });
          debugPrint("🎙 Remote audio muted: $muted");
        },
        onRemoteVideoMuted: (muted) {
          if (!mounted) return;
          setState(() {
            _remoteVideoMuted = muted;
          });
          debugPrint("📹 Remote video muted: $muted");
        },
        onConnectionStateChanged: (state) {
          if (!mounted) return;
          debugPrint("📡 Connection state: $state");
          _handleConnectionState(state);
        },
        onError: (errorCode, message) {
          debugPrint("❌ Agora error: $errorCode - $message");
          if (mounted) {
            _showSnackBar("Call error: $message");
          }
        },
      );

      if (engine == null) {
        debugPrint('❌ Agora engine initialization failed');
        if (mounted) {
          _showSnackBar('Unable to initialize calling service.');
        }
        return;
      }

      _engine = engine;
      debugPrint('🚀 Joining channel: ${widget.channelName}');

      // ✅ FIXED: joinCall without _engine parameter
      await AgoraService.joinCall(
        channelName: widget.channelName,
        uid: widget.uid,
        isVideoCall: widget.isVideoCall,
        token: null,
      );

      debugPrint('✅ joinCall completed');
    } catch (e, stackTrace) {
      debugPrint('❌ Call initialization error: $e');
      debugPrint(stackTrace.toString());
      if (mounted) {
        _showSnackBar('Unable to start call: $e');
      }
    }
  }

  // ============================================================
  // ✅ HANDLE CONNECTION STATE
  // ============================================================
  void _handleConnectionState(ConnectionStateType state) {
    switch (state) {
      case ConnectionStateType.connectionStateConnecting:
        debugPrint('📡 Connecting...');
        break;
      case ConnectionStateType.connectionStateConnected:
        debugPrint('📡 Connected');
        break;
      case ConnectionStateType.connectionStateDisconnected:
        debugPrint('📡 Disconnected');
        break;
      case ConnectionStateType.connectionStateReconnecting:
        debugPrint('📡 Reconnecting...');
        break;
      case ConnectionStateType.connectionStateFailed:
        debugPrint('📡 Connection failed');
        if (mounted) {
          _showSnackBar('Connection failed. Please try again.');
        }
        break;
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _seconds++);
      }
    });
  }

  // ============================================================
  // ✅ NOTIFY CALL CONNECTED
  // ============================================================
  Future<void> _notifyCallConnected() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await OneSignalNotificationService.sendNotificationToUser(
        userId: widget.otherUserId,
        title: widget.isVideoCall ? '📹 Video Call Connected' : '🔊 Voice Call Connected',
        body: 'You are in a ${widget.isVideoCall ? "video" : "voice"} call with ${user.displayName ?? 'User'}',
        data: {
          'type': 'call_connected',
          'channelName': widget.channelName,
          'isVideoCall': widget.isVideoCall.toString(),
        },
      );
    } catch (e) {
      debugPrint("❌ Notification error: $e");
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _leaveCall();
    super.dispose();
  }

  // ============================================================
  // ✅ LEAVE CALL
  // ============================================================
  Future<void> _leaveCall() async {
    await AgoraService.leaveCall();
    if (mounted) Navigator.pop(context);
  }

  // ============================================================
  // ✅ CONTROLS
  // ============================================================
  void _toggleMute() {
    setState(() => _isMuted = !_isMuted);
    AgoraService.muteAudio(_isMuted);
  }

  void _toggleSpeaker() {
    setState(() => _isSpeakerOn = !_isSpeakerOn);
    AgoraService.setSpeaker(_isSpeakerOn);
  }

  void _toggleCamera() {
    if (!widget.isVideoCall) return;
    setState(() => _isCameraOn = !_isCameraOn);
    AgoraService.setCameraEnabled(_isCameraOn);
  }

  void _switchCamera() {
    if (!widget.isVideoCall) return;
    AgoraService.switchCamera();
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // ============================================================
  // ✅ BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A237E),
      body: SafeArea(
        child: Stack(
          children: [
            // ✅ Remote Video (for video calls)
            if (widget.isVideoCall && _isRemoteUserJoined && _remoteUid != null && _engine != null)
              Positioned.fill(
                child: AgoraVideoView(
                  controller: VideoViewController(
                    rtcEngine: _engine!,
                    canvas: VideoCanvas(uid: _remoteUid),
                  ),
                ),
              ),

            // ✅ Background for voice call or no remote user
            if (!widget.isVideoCall || !_isRemoteUserJoined)
              Positioned.fill(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.green[700],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.isVideoCall ? Icons.videocam : Icons.phone,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        widget.otherUserName,
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isConnected ? _formatTime(_seconds) : 'Connecting...',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          color: _isConnected ? Colors.white70 : Colors.green[300],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isConnected ? 'Connected' : 'Ringing...',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: _isConnected ? Colors.green[300] : Colors.orange[300],
                        ),
                      ),
                      if (_remoteAudioMuted && _isConnected)
                        Container(
                          margin: const EdgeInsets.only(top: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${widget.otherUserName} has muted audio',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.red[300],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

            // ✅ Local Video Preview (for video calls)
            if (widget.isVideoCall && _isConnected && _engine != null)
              Positioned(
                top: 60,
                right: 20,
                child: Container(
                  width: 120,
                  height: 160,
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: AgoraVideoView(
                      controller: VideoViewController(
                        rtcEngine: _engine!,
                        canvas: const VideoCanvas(uid: 0),
                      ),
                    ),
                  ),
                ),
              ),

            // ✅ Back Button
            Positioned(
              top: 10,
              left: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: _leaveCall,
              ),
            ),

            // ✅ Call Controls
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // ✅ Mic Button
                    _buildControlButton(
                      icon: _isMuted ? Icons.mic_off : Icons.mic,
                      onPressed: _toggleMute,
                      color: _isMuted ? Colors.red : Colors.white,
                      label: _isMuted ? 'Unmute' : 'Mute',
                    ),

                    // ✅ End Call Button
                    _buildControlButton(
                      icon: Icons.call_end,
                      onPressed: _leaveCall,
                      color: Colors.red,
                      label: 'End',
                      size: 36,
                    ),

                    // ✅ Speaker Button
                    _buildControlButton(
                      icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_off,
                      onPressed: _toggleSpeaker,
                      color: _isSpeakerOn ? Colors.green : Colors.white,
                      label: _isSpeakerOn ? 'Speaker' : 'Earpiece',
                    ),

                    // ✅ Camera Button (Video only)
                    if (widget.isVideoCall)
                      _buildControlButton(
                        icon: _isCameraOn ? Icons.videocam : Icons.videocam_off,
                        onPressed: _toggleCamera,
                        color: _isCameraOn ? Colors.green : Colors.red,
                        label: _isCameraOn ? 'Camera' : 'Off',
                      ),

                    // ✅ Switch Camera (Video only)
                    if (widget.isVideoCall)
                      _buildControlButton(
                        icon: Icons.flip_camera_ios,
                        onPressed: _switchCamera,
                        color: Colors.blue,
                        label: 'Flip',
                      ),
                  ],
                ),
              ),
            ),

            // ✅ Connection Badge
            Positioned(
              top: 70,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: _isConnected
                        ? Colors.green.withValues(alpha: 0.15)
                        : Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: _isConnected ? Colors.green : Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        _isConnected ? 'Connected' : 'Connecting...',
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
    required String label,
    double size = 28,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: size,
          backgroundColor: color,
          child: IconButton(
            icon: Icon(icon, color: Colors.white, size: 24),
            onPressed: onPressed,
            padding: EdgeInsets.zero,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}