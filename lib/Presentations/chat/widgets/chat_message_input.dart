// lib/Presentations/chat/widgets/chat_message_input.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatMessageInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSending;
  final bool isRecording;
  final VoidCallback onSend;
  final VoidCallback onAttachment;
  final VoidCallback onMicPress;
  final VoidCallback onCancelRecording;
  final VoidCallback onSendRecording;

  const ChatMessageInput({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isSending,
    required this.isRecording,
    required this.onSend,
    required this.onAttachment,
    required this.onMicPress,
    required this.onCancelRecording,
    required this.onSendRecording,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: isRecording ? _buildRecordingBar() : _buildTextInputRow(),
    );
  }

  Widget _buildTextInputRow() {
    return Row(
      children: [
        // ✅ Text Field
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(24),
            ),
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: GoogleFonts.poppins(
                  color: Colors.grey[500],
                  fontSize: 15,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
            ),
          ),
        ),

        // ✅ Attachment Button
        IconButton(
          icon: const Icon(Icons.attach_file, color: Colors.grey),
          onPressed: onAttachment,
        ),

        // ✅ Send/Mic Button
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) {
            final hasText = value.text.trim().isNotEmpty;
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: hasText
                  ? CircleAvatar(
                key: const ValueKey('send'),
                backgroundColor: Colors.green[700],
                radius: 22,
                child: isSending
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : IconButton(
                  icon: const Icon(
                    Icons.send,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: onSend,
                  padding: EdgeInsets.zero,
                ),
              )
                  : CircleAvatar(
                key: const ValueKey('mic'),
                backgroundColor: Colors.green[700],
                radius: 22,
                child: IconButton(
                  icon: const Icon(
                    Icons.mic,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: onMicPress,
                  padding: EdgeInsets.zero,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecordingBar() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: onCancelRecording,
        ),
        Expanded(
          child: Row(
            children: [
              _PulsingDot(),
              const SizedBox(width: 10),
              Text(
                'Recording...',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.red[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        CircleAvatar(
          backgroundColor: Colors.green[700],
          radius: 22,
          child: IconButton(
            icon: const Icon(Icons.send, color: Colors.white, size: 20),
            onPressed: onSendRecording,
            padding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}

// ✅ Pulsing Dot
class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..repeat(reverse: true);

  late final Animation<double> _opacity = Tween<double>(begin: 0.3, end: 1.0).animate(
    CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}