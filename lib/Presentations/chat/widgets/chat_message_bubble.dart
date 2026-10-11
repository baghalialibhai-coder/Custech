// lib/Presentations/chat/widgets/chat_message_bubble.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/models/message_model.dart';

class ChatMessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final String otherUserName;
  final String? otherUserImage;
  final VoidCallback onLongPress;
  final VoidCallback onImageTap;
  final VoidCallback onVideoTap;
  final VoidCallback onAudioTap;
  final VoidCallback onLocationTap;

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.otherUserName,
    this.otherUserImage,
    required this.onLongPress,
    required this.onImageTap,
    required this.onVideoTap,
    required this.onAudioTap,
    required this.onLocationTap,
  });

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('hh:mm a').format(message.timestamp);
    final isImage = message.message.contains('📷') || message.message.contains('🖼️');
    final isVideo = message.message.contains('📹') || message.message.contains('🎬');
    final isAudio = message.message.contains('🎵') || message.message.contains('🔊');
    final isLocation = message.message.contains('📍');

    String? mediaUrl;
    if (isImage || isVideo || isAudio || isLocation) {
      final parts = message.message.split(' ');
      for (var part in parts) {
        if (part.startsWith('http://') || part.startsWith('https://')) {
          mediaUrl = part;
          break;
        }
      }
    }

    String displayText = message.message;
    if (mediaUrl != null) {
      displayText = displayText.replaceFirst(mediaUrl, '').trim();
      if (displayText.length <= 2 &&
          (displayText.contains('📷') ||
              displayText.contains('📹') ||
              displayText.contains('🎵') ||
              displayText.contains('📍'))) {
        displayText = '';
      }
    }

    return GestureDetector(
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(right: 8, bottom: 18),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: otherUserImage != null && otherUserImage!.isNotEmpty
                      ? NetworkImage(otherUserImage!)
                      : null,
                  child: otherUserImage == null || otherUserImage!.isEmpty
                      ? Text(
                    otherUserName.isNotEmpty
                        ? otherUserName[0].toUpperCase()
                        : '?',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  )
                      : null,
                ),
              ),

            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? Colors.green[700] : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
                  topRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
                  bottomLeft: const Radius.circular(16),
                  bottomRight: const Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.repliedToMessage != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isMe ? Colors.green[600] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isMe ? Colors.green[500]! : Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Replying to $otherUserName',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: isMe ? Colors.white70 : Colors.grey[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            message.repliedToMessage!,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: isMe ? Colors.white70 : Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                  if (mediaUrl != null)
                    _buildMediaContent(mediaUrl, isImage, isVideo, isAudio, isLocation, isMe),

                  if (displayText.isNotEmpty)
                    Text(
                      displayText,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: isMe ? Colors.white : Colors.black87,
                      ),
                    ),
                  const SizedBox(height: 4),

                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        time,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: isMe ? Colors.white70 : Colors.grey[500],
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          _getStatusIcon(message.status),
                          size: 14,
                          color: _getStatusColor(message.status),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaContent(String url, bool isImage, bool isVideo, bool isAudio, bool isLocation, bool isMe) {
    if (isImage) {
      return GestureDetector(
        onTap: onImageTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            url,
            height: 150,
            width: double.infinity,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                height: 150,
                color: Colors.grey[300],
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 150,
                color: Colors.grey[300],
                child: const Icon(Icons.broken_image, size: 50),
              );
            },
          ),
        ),
      );
    }

    if (isVideo) {
      return GestureDetector(
        onTap: onVideoTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              Container(
                height: 150,
                width: double.infinity,
                color: Colors.grey[900],
                child: Center(
                  child: Icon(Icons.play_circle_filled, size: 50, color: Colors.white),
                ),
              ),
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Video',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (isAudio) {
      return GestureDetector(
        onTap: onAudioTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: isMe ? Colors.green[600] : Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.play_arrow,
                color: isMe ? Colors.white : Colors.black87,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: isMe ? Colors.white30 : Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Container(
                    width: 50,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isMe ? Colors.white : Colors.green[700],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '0:30',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: isMe ? Colors.white70 : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (isLocation) {
      return GestureDetector(
        onTap: onLocationTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isMe ? Colors.green[600] : Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.location_on,
                color: isMe ? Colors.white : Colors.red,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '📍 Location Shared',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: isMe ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox();
  }

  IconData _getStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sent:
        return Icons.check;
      case MessageStatus.delivered:
        return Icons.done_all;
      case MessageStatus.read:
        return Icons.done_all;
      case MessageStatus.failed:
        return Icons.error_outline;
      default:
        return Icons.check;
    }
  }

  Color _getStatusColor(MessageStatus status) {
    switch (status) {
      case MessageStatus.sent:
        return Colors.grey;
      case MessageStatus.delivered:
        return Colors.blue;
      case MessageStatus.read:
        return Colors.green[700]!;
      case MessageStatus.failed:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}