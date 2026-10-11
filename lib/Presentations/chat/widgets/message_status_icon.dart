import 'package:flutter/material.dart';
import '../../../core/models/message_model.dart';

class MessageStatusIcon extends StatelessWidget {
  final MessageStatus status;
  final bool isMe;
  final double size;

  const MessageStatusIcon({
    super.key,
    required this.status,
    required this.isMe,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    if (!isMe) return const SizedBox.shrink();

    IconData icon;
    Color color;

    switch (status) {
      case MessageStatus.sent:
        icon = Icons.check;
        color = Colors.grey[400]!;
        break;
      case MessageStatus.delivered:
        icon = Icons.done_all;
        color = Colors.grey[400]!;
        break;
      case MessageStatus.read:
        icon = Icons.done_all;
        color = Colors.blue[400]!;
        break;
      case MessageStatus.failed:
        icon = Icons.sms_failed;
        color = Colors.red[400]!;
        break;

    }

    return Icon(
      icon,
      size: size,
      color: color,
    );
  }
}