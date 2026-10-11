// lib/Presentations/call/voice_call_screen.dart

import 'package:flutter/material.dart';
import 'call_screen.dart';

class VoiceCallScreen extends StatelessWidget {
  final String channelName;
  final String otherUserName;
  final String otherUserId;
  final int uid;

  const VoiceCallScreen({
    super.key,
    required this.channelName,
    required this.otherUserName,
    required this.otherUserId,
    required this.uid,
  });

  @override
  Widget build(BuildContext context) {
    return CallScreen(
      channelName: channelName,
      otherUserName: otherUserName,
      otherUserId: otherUserId,
      uid: uid,
      isVideoCall: false,
    );
  }
}