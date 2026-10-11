// lib/Presentations/chat/Screens/chat_screen.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../../core/models/message_model.dart';
import '../../../services/chat_service.dart';
import '../../../services/firebase_storage_service.dart';
import '../../../services/agora_service.dart';
import '../../../services/one_Signal_Service.dart';
import '../../../languages/localization/app_localizations.dart';
import '../../call/voice_call_screen.dart';
import '../../call/video_call_screen.dart';
import '../../User_Location/widgets/location_picker_screen.dart';
import '../widgets/chat_message_bubble.dart';
import '../widgets/chat_message_input.dart';
import '../widgets/chat_date_separator.dart';
import '../widgets/chat_upload_progress.dart';
import '../widgets/chat_recording_bar.dart';
import 'media_viewer_screen.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String taskId;
  final String taskTitle;
  final String otherUserName;
  final String otherUserId;
  final String? otherUserImage;
  final String? otherUserRole;

  const ChatScreen({
    super.key,
    required this.taskId,
    required this.taskTitle,
    required this.otherUserName,
    required this.otherUserId,
    this.otherUserImage,
    this.otherUserRole,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  String? _replyingToId;
  String? _replyingToMessage;
  bool _isTyping = false;
  bool _isSending = false;
  bool _isAppInBackground = false;

  // ✅ Upload Progress
  final ValueNotifier<bool> _isUploadingVN = ValueNotifier(false);
  final ValueNotifier<double> _uploadProgressVN = ValueNotifier(0.0);
  final ValueNotifier<String> _uploadStatusVN = ValueNotifier('');
  Timer? _progressTimer;

  // ✅ Voice Recording
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final ValueNotifier<bool> _isRecordingVN = ValueNotifier(false);
  final ValueNotifier<int> _recordSecondsVN = ValueNotifier(0);
  Timer? _recordTimer;
  String? _recordingPath;

  @override
  void initState() {
    super.initState();
    _markMessagesAsRead();
    _initRecorder();
    _checkAppState();

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _scrollToBottom();
      }
    });
  }

  void _checkAppState() {
    WidgetsBinding.instance.addObserver(
      _AppLifecycleObserver(onChange: (state) {
        _isAppInBackground = state == AppLifecycleState.paused ||
            state == AppLifecycleState.inactive;
      }),
    );
  }

  Future<void> _initRecorder() async {
    try {
      await _recorder.openRecorder();
    } catch (e) {
      debugPrint('❌ Recorder init error: $e');
    }
  }

  Future<void> _markMessagesAsRead() async {
    await _chatService.markAllMessagesAsRead(widget.taskId);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _progressTimer?.cancel();
    _recordTimer?.cancel();
    _isUploadingVN.dispose();
    _uploadProgressVN.dispose();
    _uploadStatusVN.dispose();
    _isRecordingVN.dispose();
    _recordSecondsVN.dispose();
    _recorder.closeRecorder();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFECE5DD),
      appBar: AppBar(
        title: Row(
          children: [
            GestureDetector(
              onTap: _showUserProfile,
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.grey[300],
                backgroundImage: widget.otherUserImage != null && widget.otherUserImage!.isNotEmpty
                    ? NetworkImage(widget.otherUserImage!)
                    : null,
                child: widget.otherUserImage == null || widget.otherUserImage!.isEmpty
                    ? Text(
                  widget.otherUserName.isNotEmpty
                      ? widget.otherUserName[0].toUpperCase()
                      : '?',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                )
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUserName,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    _isTyping ? context.tr('typing') : context.tr('online'),
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: _isTyping ? Colors.green[300] : Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green[700],
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: _startVideoCall,
          ),
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: _startVoiceCall,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'clear') {
                _showClearChatDialog();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'clear',
                child: Text(context.tr('clearChat')),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // ✅ Upload Progress
          ValueListenableBuilder<bool>(
            valueListenable: _isUploadingVN,
            builder: (context, isUploading, _) {
              if (!isUploading) return const SizedBox.shrink();
              return ChatUploadProgress(
                progress: _uploadProgressVN.value,
                status: _uploadStatusVN.value,
              );
            },
          ),

          // ✅ Messages List
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              key: ValueKey(widget.taskId),
              stream: _chatService.getMessages(widget.taskId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        Text(
                          context.tr('errorLoadingMessages'),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return _buildEmptyState();
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == user?.uid;
                    final showDate = _shouldShowDate(messages, index);

                    return Column(
                      children: [
                        if (showDate)
                          ChatDateSeparator(timestamp: message.timestamp),
                        ChatMessageBubble(
                          key: ValueKey(message.id),
                          message: message,
                          isMe: isMe,
                          otherUserName: widget.otherUserName,
                          otherUserImage: widget.otherUserImage,
                          onLongPress: () => _showMessageOptions(message),
                          onImageTap: () => _openMediaViewer(_extractUrl(message.message), true),
                          onVideoTap: () => _openMediaViewer(_extractUrl(message.message), false),
                          onAudioTap: () => _playAudio(_extractUrl(message.message)),
                          onLocationTap: () => _openLocation(_extractUrl(message.message)),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          if (_replyingToMessage != null)
            _buildReplyIndicator(),

          // ✅ Message Input
          ChatMessageInput(
            controller: _messageController,
            focusNode: _focusNode,
            isSending: _isSending,
            isRecording: _isRecordingVN.value,
            onSend: _sendMessage,
            onAttachment: _showAttachmentOptions,
            onMicPress: _startVoiceRecording,
            onCancelRecording: _cancelVoiceRecording,
            onSendRecording: _stopAndSendVoiceRecording,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ✅ HELPER: Extract URL from message
  // ============================================================
  String _extractUrl(String message) {
    final parts = message.split(' ');
    for (var part in parts) {
      if (part.startsWith('http://') || part.startsWith('https://')) {
        return part;
      }
    }
    return '';
  }

  // ============================================================
  // ✅ BUILD REPLY INDICATOR
  // ============================================================
  Widget _buildReplyIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            color: Colors.green[700],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${context.tr('replyingTo')} ${widget.otherUserName}',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.green[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _replyingToMessage!,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: Colors.grey),
            onPressed: () {
              setState(() {
                _replyingToId = null;
                _replyingToMessage = null;
              });
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ✅ BUILD EMPTY STATE
  // ============================================================
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.green[50],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_outlined,
              size: 64,
              color: Colors.green[700],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            context.tr('noMessagesYet'),
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A237E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${context.tr('sayHelloTo')} ${widget.otherUserName}',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              _messageController.text = '${context.tr('hello')}! 👋';
              _sendMessage();
            },
            icon: const Icon(Icons.send),
            label: Text(
              context.tr('sayHello'),
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ✅ SEND MESSAGE
  // ============================================================
  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isSending) return;

    final repliedId = _replyingToId;
    final repliedMsg = _replyingToMessage;

    _messageController.clear();
    setState(() {
      _isSending = true;
      _replyingToId = null;
      _replyingToMessage = null;
    });
    _focusNode.requestFocus();
    _scrollToBottom();

    try {
      await _chatService.sendMessage(
        taskId: widget.taskId,
        message: message,
        receiverId: widget.otherUserId,
        receiverName: widget.otherUserName,
        repliedToId: repliedId,
        repliedToMessage: repliedMsg,
      );

      if (_isAppInBackground) {
        await OneSignalNotificationService.sendMessageNotification(
          receiverId: widget.otherUserId,
          senderName: FirebaseAuth.instance.currentUser?.displayName ?? 'User',
          message: message,
          conversationId: widget.taskId,
          requestId: widget.taskId,
          senderId: FirebaseAuth.instance.currentUser!.uid,
          senderRole: 'customer',
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ ${context.tr('messageSendFailed')}: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _messageController.text = message;
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  // ============================================================
  // ✅ SEND MEDIA MESSAGE
  // ============================================================
  Future<void> _sendMediaMessage(String emoji, String url) async {
    final message = '$emoji $url';
    final repliedId = _replyingToId;
    final repliedMsg = _replyingToMessage;

    setState(() {
      _replyingToId = null;
      _replyingToMessage = null;
    });

    try {
      await _chatService.sendMessage(
        taskId: widget.taskId,
        message: message,
        receiverId: widget.otherUserId,
        receiverName: widget.otherUserName,
        repliedToId: repliedId,
        repliedToMessage: repliedMsg,
      );

      if (_isAppInBackground) {
        await OneSignalNotificationService.sendMessageNotification(
          receiverId: widget.otherUserId,
          senderName: FirebaseAuth.instance.currentUser?.displayName ?? 'User',
          message: emoji == '📍' ? '📍 Location Shared' : '$emoji Media Shared',
          conversationId: widget.taskId,
          requestId: widget.taskId,
          senderId: FirebaseAuth.instance.currentUser!.uid,
          senderRole: 'customer',
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ ${context.tr('sendFailed')}: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ============================================================
  // ✅ UPLOAD WITH PROGRESS
  // ============================================================
  Future<void> _uploadWithProgress({
    required Future<File?> Function() picker,
    required Future<String?> Function(File) uploader,
    required String emoji,
    required String statusText,
  }) async {
    _isUploadingVN.value = true;
    _uploadProgressVN.value = 0.0;
    _uploadStatusVN.value = statusText;

    try {
      final file = await picker();
      if (file == null) {
        _isUploadingVN.value = false;
        return;
      }

      int progress = 0;
      _progressTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
        progress += 5;
        if (progress <= 90) {
          _uploadProgressVN.value = progress / 100;
          _uploadStatusVN.value = '${context.tr('uploading')}... $progress%';
        }
      });

      final url = await uploader(file);
      _progressTimer?.cancel();

      if (url != null) {
        _uploadProgressVN.value = 1.0;
        _uploadStatusVN.value = '✅ ${context.tr('uploadComplete')}!';
        await _sendMediaMessage(emoji, url);
      } else {
        _uploadStatusVN.value = '❌ ${context.tr('uploadFailed')}';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('failedToUploadMedia')),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      _progressTimer?.cancel();
      _uploadStatusVN.value = '❌ ${context.tr('error')}: $e';
    } finally {
      Future.delayed(const Duration(milliseconds: 500), () {
        _isUploadingVN.value = false;
      });
    }
  }

  // ============================================================
  // ✅ VOICE RECORDING
  // ============================================================
  Future<void> _startVoiceRecording() async {
    try {
      if (!_recorder.isRecording) {
        await _recorder.openRecorder();
      }

      final dir = await getTemporaryDirectory();
      final filePath = path.join(
        dir.path,
        'voice_${DateTime.now().millisecondsSinceEpoch}.aac',
      );

      await _recorder.startRecorder(
        toFile: filePath,
        codec: Codec.aacADTS,
      );

      _recordingPath = filePath;
      _recordSecondsVN.value = 0;
      _isRecordingVN.value = true;

      _recordTimer?.cancel();
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _recordSecondsVN.value = _recordSecondsVN.value + 1;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ ${context.tr('unableToStartRecording')}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _cancelVoiceRecording() async {
    _recordTimer?.cancel();
    try {
      if (_recorder.isRecording) {
        await _recorder.stopRecorder();
      }
    } catch (_) {}

    if (_recordingPath != null) {
      final f = File(_recordingPath!);
      if (await f.exists()) {
        await f.delete();
      }
    }

    _recordingPath = null;
    _recordSecondsVN.value = 0;
    _isRecordingVN.value = false;
  }

  Future<void> _stopAndSendVoiceRecording() async {
    _recordTimer?.cancel();

    String? finalPath;
    try {
      if (_recorder.isRecording) {
        finalPath = await _recorder.stopRecorder();
      }
    } catch (e) {
      finalPath = null;
    }

    finalPath ??= _recordingPath;
    _isRecordingVN.value = false;
    _recordSecondsVN.value = 0;

    if (finalPath == null || finalPath.isEmpty) return;

    final file = File(finalPath);
    if (!await file.exists()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ ${context.tr('recordingNotFound')}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (await file.length() < 1000) {
      await file.delete();
      return;
    }

    await _uploadWithProgress(
      picker: () async => file,
      uploader: FirebaseStorageService.uploadAudio,
      emoji: '🎵',
      statusText: '🎤 ${context.tr('uploadingVoiceMessage')}...',
    );

    _recordingPath = null;
  }

  // ============================================================
  // ✅ CALLS
  // ============================================================
  void _startVoiceCall() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    if (!AgoraService.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('agoraNotConfigured')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VoiceCallScreen(
          channelName: widget.taskId,
          otherUserName: widget.otherUserName,
          otherUserId: widget.otherUserId,
          uid: user.uid.hashCode,
        ),
      ),
    );
  }

  void _startVideoCall() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    if (!AgoraService.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('agoraNotConfigured')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoCallScreen(
          channelName: widget.taskId,
          otherUserName: widget.otherUserName,
          otherUserId: widget.otherUserId,
          uid: user.uid.hashCode,
        ),
      ),
    );
  }

  // ============================================================
  // ✅ ATTACHMENT OPTIONS
  // ============================================================
  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildAttachmentOption(
                    icon: Icons.photo_library,
                    label: context.tr('gallery'),
                    color: Colors.blue,
                    onTap: () {
                      Navigator.pop(context);
                      _uploadWithProgress(
                        picker: FirebaseStorageService.pickImageFromGallery,
                        uploader: FirebaseStorageService.uploadImage,
                        emoji: '📷',
                        statusText: '📷 ${context.tr('pickingImageFromGallery')}...',
                      );
                    },
                  ),
                  _buildAttachmentOption(
                    icon: Icons.camera_alt,
                    label: context.tr('camera'),
                    color: Colors.green,
                    onTap: () {
                      Navigator.pop(context);
                      _uploadWithProgress(
                        picker: FirebaseStorageService.pickImageFromCamera,
                        uploader: FirebaseStorageService.uploadImage,
                        emoji: '📷',
                        statusText: '📷 ${context.tr('takingPhoto')}...',
                      );
                    },
                  ),
                  _buildAttachmentOption(
                    icon: Icons.video_library,
                    label: context.tr('video'),
                    color: Colors.purple,
                    onTap: () {
                      Navigator.pop(context);
                      _uploadWithProgress(
                        picker: FirebaseStorageService.pickVideo,
                        uploader: FirebaseStorageService.uploadVideo,
                        emoji: '📹',
                        statusText: '📹 ${context.tr('pickingVideoFromGallery')}...',
                      );
                    },
                  ),
                  _buildAttachmentOption(
                    icon: Icons.videocam,
                    label: context.tr('recordVideo'),
                    color: Colors.deepPurple,
                    onTap: () {
                      Navigator.pop(context);
                      _uploadWithProgress(
                        picker: FirebaseStorageService.recordVideo,
                        uploader: FirebaseStorageService.uploadVideo,
                        emoji: '📹',
                        statusText: '📹 ${context.tr('recordingVideo')}...',
                      );
                    },
                  ),
                  _buildAttachmentOption(
                    icon: Icons.location_on,
                    label: context.tr('location'),
                    color: Colors.red,
                    onTap: () {
                      Navigator.pop(context);
                      _shareLocation();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ✅ SHARE LOCATION
  // ============================================================
  Future<void> _shareLocation() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerScreen(
          onLocationSelected: (lat, lng, address, pincode) async {
            final locationUrl = 'https://www.google.com/maps?q=$lat,$lng';
            await _sendMediaMessage('📍', locationUrl);
          },
        ),
      ),
    );
  }

  // ============================================================
  // ✅ OPEN LOCATION
  // ============================================================
  Future<void> _openLocation(String url) async {
    try {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.black87,
          child: Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '📍 ${context.tr('location')}',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A237E),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        Image.network(
                          'https://maps.googleapis.com/maps/api/staticmap?center=${Uri.encodeComponent(url)}&zoom=15&size=600x400&markers=color:red%7C${Uri.encodeComponent(url)}&key=AIzaSyBxYDydLZKwEgw100J3Rcf95yQiGnkbUdA',
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.map, size: 50, color: Colors.grey),
                                  const SizedBox(height: 8),
                                  Text(
                                    context.tr('mapNotAvailable'),
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        Positioned(
                          bottom: 20,
                          left: 20,
                          right: 20,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              final uri = Uri.parse(url);
                              launchUrl(uri, mode: LaunchMode.externalApplication);
                            },
                            icon: const Icon(Icons.open_in_new),
                            label: Text(
                              context.tr('openInGoogleMaps'),
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[700],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ ${context.tr('unableToOpenLocation')}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // ✅ PLAY AUDIO
  // ============================================================
  void _playAudio(String url) {
    if (!mounted || url.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MediaViewerScreen(
          url: url,
          isImage: false,
          isAudio: true,
        ),
      ),
    );
  }

  // ============================================================
  // ✅ OPEN MEDIA VIEWER
  // ============================================================
  void _openMediaViewer(String url, bool isImage) {
    if (url.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MediaViewerScreen(
          url: url,
          isImage: isImage,
        ),
      ),
    );
  }

  // ============================================================
  // ✅ SCROLL TO BOTTOM
  // ============================================================
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  // ============================================================
  // ✅ CHECK IF DATE SHOULD SHOW
  // ============================================================
  bool _shouldShowDate(List<MessageModel> messages, int index) {
    if (index == 0) return true;
    final current = messages[index].timestamp;
    final previous = messages[index - 1].timestamp;
    final currentDate = DateTime(current.year, current.month, current.day);
    final previousDate = DateTime(previous.year, previous.month, previous.day);
    return currentDate != previousDate;
  }

  // ============================================================
  // ✅ MESSAGE OPTIONS
  // ============================================================
  void _showMessageOptions(MessageModel message) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.reply, color: Colors.blue),
                title: Text(context.tr('reply'), style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _replyingToId = message.id;
                    _replyingToMessage = message.message;
                  });
                  _focusNode.requestFocus();
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy, color: Colors.orange),
                title: Text(context.tr('copy'), style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                onTap: () => Navigator.pop(context),
              ),
              if (FirebaseAuth.instance.currentUser?.uid == message.senderId)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: Text(context.tr('deleteForMe'), style: GoogleFonts.poppins(fontWeight: FontWeight.w500, color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteConfirmation(message.id);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ✅ DELETE CONFIRMATION
  // ============================================================
  void _showDeleteConfirmation(String messageId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          context.tr('deleteMessage'),
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.red),
        ),
        content: Text(
          context.tr('deleteMessageConfirmation'),
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              context.tr('cancel'),
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _chatService.deleteMessage(messageId);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(context.tr('messageDeleted')),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${context.tr('error')}: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text(context.tr('delete')),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ✅ USER PROFILE
  // ============================================================
  void _showUserProfile() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey[300],
              backgroundImage: widget.otherUserImage != null && widget.otherUserImage!.isNotEmpty
                  ? NetworkImage(widget.otherUserImage!)
                  : null,
              child: widget.otherUserImage == null || widget.otherUserImage!.isEmpty
                  ? Text(
                widget.otherUserName.isNotEmpty ? widget.otherUserName[0].toUpperCase() : '?',
                style: GoogleFonts.poppins(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
              )
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              widget.otherUserName,
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1A237E)),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('online'),
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.green[700]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              context.tr('close'),
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ✅ CLEAR CHAT
  // ============================================================
  void _showClearChatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          context.tr('clearChat'),
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.red),
        ),
        content: Text(
          context.tr('clearChatConfirmation'),
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              context.tr('cancel'),
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(context.tr('chatCleared')),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text(context.tr('clear')),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ✅ APP LIFECYCLE OBSERVER
// ============================================================
class _AppLifecycleObserver extends WidgetsBindingObserver {
  final void Function(AppLifecycleState state) onChange;

  _AppLifecycleObserver({required this.onChange});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    onChange(state);
  }
}