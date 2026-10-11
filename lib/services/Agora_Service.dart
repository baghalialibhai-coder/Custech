// lib/services/agora_service.dart

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:permission_handler/permission_handler.dart';

class AgoraService {
  AgoraService._();

  static RtcEngine? _engine;

  static String get appId => dotenv.env['AGORA_APP_ID'] ?? '';

  static bool get isConfigured => appId.isNotEmpty;

  static RtcEngine? get engine => _engine;

  static Future<bool> requestPermissions({
    required bool video,
  }) async {
    final permissions = <Permission>[
      Permission.microphone,
    ];

    if (video) {
      permissions.add(Permission.camera);
    }

    final result = await permissions.request();

    final micGranted = result[Permission.microphone]?.isGranted ?? false;
    final cameraGranted = !video || (result[Permission.camera]?.isGranted ?? false);

    return micGranted && cameraGranted;
  }

  // ✅ ALL PARAMETERS DEFINED
  static Future<RtcEngine?> initializeEngine({
    required Function() onJoinChannel,
    required Function(int remoteUid) onUserJoined,
    required Function(int remoteUid) onUserOffline,
    Function(bool muted)? onRemoteAudioMuted,
    Function(bool muted)? onRemoteVideoMuted,
    Function(ConnectionStateType state)? onConnectionStateChanged,
    Function(int errorCode, String message)? onError,
  }) async {
    if (!isConfigured) {
      debugPrint('❌ AGORA_APP_ID missing');
      return null;
    }

    try {
      if (_engine != null) {
        return _engine;
      }

      _engine = createAgoraRtcEngine();

      await _engine!.initialize(
        RtcEngineContext(
          appId: appId,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );

      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            debugPrint('✅ Agora joined: ${connection.channelId}');
            onJoinChannel();
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            debugPrint('👤 Remote user joined: $remoteUid');
            onUserJoined(remoteUid);
          },
          onUserOffline: (
              RtcConnection connection,
              int remoteUid,
              UserOfflineReasonType reason,
              ) {
            debugPrint('👋 Remote user left: $remoteUid');
            onUserOffline(remoteUid);
          },
          onUserMuteAudio: (RtcConnection connection, int remoteUid, bool muted) {
            debugPrint('🎙 Remote audio muted=$muted');
            onRemoteAudioMuted?.call(muted);
          },
          onUserMuteVideo: (RtcConnection connection, int remoteUid, bool muted) {
            debugPrint('📹 Remote video muted=$muted');
            onRemoteVideoMuted?.call(muted);
          },
          onConnectionStateChanged: (
              RtcConnection connection,
              ConnectionStateType state,
              ConnectionChangedReasonType reason,
              ) {
            debugPrint('📡 Agora state=$state reason=$reason');
            onConnectionStateChanged?.call(state);
          },
          onFirstRemoteVideoFrame: (
              RtcConnection connection,
              int remoteUid,
              int width,
              int height,
              int elapsed,
              ) {
            debugPrint('🎥 Remote video frame: $remoteUid ${width}x$height');
          },
          onError: (ErrorCodeType errorCode, String message) {
            debugPrint('❌ Agora error: $errorCode - $message');
            onError?.call(errorCode.index, message);
          },
          onTokenPrivilegeWillExpire: (RtcConnection connection, String token) {
            debugPrint('⚠️ Agora token will expire');
          },
          onRequestToken: (RtcConnection connection) {
            debugPrint('🔑 Agora requested new token');
          },
        ),
      );

      return _engine;
    } catch (e) {
      debugPrint('❌ Agora initialization error: $e');
      return null;
    }
  }

  // ✅ JOIN CALL - NO _engine parameter
  static Future<void> joinCall({
    required String channelName,
    required int uid,
    required bool isVideoCall,
    String? token,
  }) async {
    if (_engine == null) {
      throw Exception('Agora engine not initialized');
    }

    final permissions = await requestPermissions(video: isVideoCall);

    if (!permissions) {
      throw Exception(
        'Microphone${isVideoCall ? ' and camera' : ''} permission denied',
      );
    }

    await _engine!.enableAudio();

    if (isVideoCall) {
      await _engine!.enableVideo();
      await _engine!.enableLocalVideo(true);
      await _engine!.startPreview();
    } else {
      await _engine!.disableVideo();
      await _engine!.enableLocalVideo(false);
    }

    await _engine!.setEnableSpeakerphone(isVideoCall);

    await _engine!.joinChannel(
      token: token ?? '',
      channelId: channelName,
      uid: uid,
      options: ChannelMediaOptions(
        channelProfile: ChannelProfileType.channelProfileCommunication,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        publishMicrophoneTrack: true,
        publishCameraTrack: isVideoCall,
        autoSubscribeAudio: true,
        autoSubscribeVideo: isVideoCall,
      ),
    );

    debugPrint('📞 Joined $channelName | uid=$uid | video=$isVideoCall');
  }

  static Future<void> muteAudio(bool muted) async {
    if (_engine == null) return;
    await _engine!.muteLocalAudioStream(muted);
  }

  static Future<void> setSpeaker(bool enabled) async {
    if (_engine == null) return;
    await _engine!.setEnableSpeakerphone(enabled);
  }

  static Future<void> setCameraEnabled(bool enabled) async {
    if (_engine == null) return;
    await _engine!.enableLocalVideo(enabled);
    await _engine!.muteLocalVideoStream(!enabled);
  }

  static Future<void> switchCamera() async {
    if (_engine == null) return;
    await _engine!.switchCamera();
  }

  static Future<void> stopPreview() async {
    if (_engine == null) return;
    try {
      await _engine!.stopPreview();
    } catch (_) {}
  }

  static Future<void> leaveCall() async {
    if (_engine == null) return;

    try {
      await _engine!.leaveChannel();
    } catch (_) {}

    try {
      await _engine!.stopPreview();
    } catch (_) {}

    try {
      await _engine!.release();
    } catch (_) {}

    _engine = null;
    debugPrint('📞 Agora call ended');
  }
}