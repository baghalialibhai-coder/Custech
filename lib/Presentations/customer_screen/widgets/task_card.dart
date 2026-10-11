import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/task_model.dart';
import 'chat_bubble.dart';

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback? onCancel;
  final VoidCallback? onChat; // ✅ New: Chat button callback
  final void Function(double, String)? onRate;

  const TaskCard({
    super.key,
    required this.task,
    this.onCancel,
    this.onChat,
    this.onRate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ============================================================
          // ✅ HEADER: Title + Status Badge
          // ============================================================
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  task.title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A237E),
                  ),
                ),
              ),
              _buildStatusBadge(),
            ],
          ),
          const SizedBox(height: 4),

          // ============================================================
          // ✅ CATEGORY
          // ============================================================
          Text(
            'Category: ${task.category}',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),

          // ============================================================
          // ✅ TECHNICIAN INFO (if assigned)
          // ============================================================
          if (task.technicianName != null) ...[
            Row(
              children: [
                Icon(Icons.person_outline, size: 14, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text(
                  'Technician: ${task.technicianName}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                if (task.technicianRating != null) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.star, size: 14, color: Colors.amber),
                  Text(
                    task.technicianRating!.toStringAsFixed(1),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ],
          const SizedBox(height: 4),

          // ============================================================
          // ✅ ADDRESS
          // ============================================================
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[400]),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  task.address,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // ============================================================
          // ✅ DATE & BUDGET
          // ============================================================
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: Colors.grey[400]),
              const SizedBox(width: 4),
              Text(
                _formatDate(task.createdAt),
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.attach_money, size: 14, color: Colors.grey[400]),
              const SizedBox(width: 1),
              Text(
                task.budget.toStringAsFixed(0),
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ============================================================
          // ✅ ACTION BUTTONS
          // ============================================================
          _buildActionButtons(context),
        ],
      ),
    );
  }

  // ============================================================
  // ✅ STATUS BADGE
  // ============================================================
  Widget _buildStatusBadge() {
    Color color;
    switch (task.status) {
      case TaskStatus.open:
        color = Colors.blue;
        break;
      case TaskStatus.accepted:
        color = Colors.orange;
        break;
      case TaskStatus.inProgress:
        color = Colors.purple;
        break;
      case TaskStatus.completed:
        color = Colors.green;
        break;
      case TaskStatus.cancelled:
        color = Colors.red;
        break;
      case TaskStatus.rejected:
        color = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        task.status.name.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  // ============================================================
  // ✅ ACTION BUTTONS
  // ============================================================
  Widget _buildActionButtons(BuildContext context) {
    final isChatEnabled = task.status == TaskStatus.accepted ||
        task.status == TaskStatus.inProgress ||
        task.status == TaskStatus.completed;

    return Row(
      children: [
        // ✅ Chat Button (Enabled for Accepted, InProgress, Completed)
        if (isChatEnabled && onChat != null)
          Expanded(
            child: _buildChatButton(context),
          ),

        // ✅ Cancel Button
        if (onCancel != null) ...[
          if (isChatEnabled && onChat != null) const SizedBox(width: 8),
          Expanded(
            child: _buildCancelButton(),
          ),
        ],

        // ✅ Rate Button (Only for Completed)
        if (task.status == TaskStatus.completed && onRate != null) ...[
          if (onCancel != null || (isChatEnabled && onChat != null))
            const SizedBox(width: 8),
          Expanded(
            child: _buildRateButton(context),
          ),
        ],
      ],
    );
  }

  // ============================================================
  // ✅ CHAT BUTTON
  // ============================================================
  Widget _buildChatButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onChat,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue[700],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        minimumSize: const Size(0, 40),
      ),
      icon: const Icon(Icons.chat, color: Colors.white, size: 18),
      label: Text(
        'Chat',
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ============================================================
  // ✅ CANCEL BUTTON
  // ============================================================
  Widget _buildCancelButton() {
    return OutlinedButton(
      onPressed: onCancel,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.red),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        minimumSize: const Size(0, 40),
      ),
      child: Text(
        'Cancel',
        style: GoogleFonts.poppins(
          color: Colors.red,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ============================================================
  // ✅ RATE BUTTON
  // ============================================================
  Widget _buildRateButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _showRatingDialog(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green[700],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        minimumSize: const Size(0, 40),
      ),
      child: Text(
        'Rate',
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ============================================================
  // ✅ RATING DIALOG
  // ============================================================
  void _showRatingDialog(BuildContext context) {
    double rating = 5.0;
    final reviewController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(
              'Rate Technician',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 32,
                      ),
                      onPressed: () {
                        setState(() {
                          rating = index + 1.0;
                        });
                      },
                    );
                  }),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: reviewController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Review (optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Skip', style: GoogleFonts.poppins()),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  onRate?.call(rating, reviewController.text);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                ),
                child: Text(
                  'Submit',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // ✅ HELPERS
  // ============================================================
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${difference.inDays ~/ 7}w ago';
    }
  }
}