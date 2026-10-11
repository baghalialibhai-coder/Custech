import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/ai_matching_service.dart';
import '../../services/task_service.dart';
import '../../core/models/task_model.dart';

class AIMatchingScreen extends ConsumerStatefulWidget {
  final String category;
  final String pincode;
  final String address;
  final double budget;
  final String customerName;
  final String customerPhone;
  final String? note;
  final String? imageUrl;
  final String currencyCode;
  final String currencySymbol;

  const AIMatchingScreen({
    super.key,
    required this.category,
    required this.pincode,
    required this.address,
    required this.budget,
    required this.customerName,
    required this.customerPhone,
    this.note,
    this.imageUrl,
    required this.currencyCode,
    required this.currencySymbol,
  });

  @override
  ConsumerState<AIMatchingScreen> createState() => _AIMatchingScreenState();
}

class _AIMatchingScreenState extends ConsumerState<AIMatchingScreen> {
  final AIMatchingService _aiService = AIMatchingService();
  final TaskService _taskService = TaskService();

  final TextEditingController _commandController = TextEditingController();
  final TextEditingController _responseController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  String? _aiResponse;

  @override
  void initState() {
    super.initState();
    _commandController.text = 'Find technicians near ${widget.pincode} for ${widget.category}';
  }

  @override
  void dispose() {
    _commandController.dispose();
    _responseController.dispose();
    super.dispose();
  }

  Future<void> _runAIMatching() async {
    if (_commandController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your requirement'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _aiResponse = null;
    });

    try {
      final response = await _aiService.getAIResponse(
        command: _commandController.text.trim(),
        category: widget.category,
        pincode: widget.pincode,
        address: widget.address,
        budget: widget.budget,
      );

      setState(() {
        _aiResponse = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _postAsOpen() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not logged in');

      final task = TaskModel(
        id: '',
        title: widget.category,
        description: _responseController.text.trim().isEmpty
            ? _commandController.text.trim()
            : _responseController.text.trim(),
        customerId: user.uid,
        customerName: widget.customerName,
        customerPhone: widget.customerPhone,
        address: widget.address,
        pincode: widget.pincode,
        latitude: 0.0,
        longitude: 0.0,
        category: widget.category,
        subCategories: [],
        budget: widget.budget,
        currencyCode: widget.currencyCode,
        currencySymbol: widget.currencySymbol,
        countryCode: 'PK',
        createdAt: DateTime.now(),
        status: TaskStatus.open,
        isUrgent: false,
        images: widget.imageUrl != null ? [widget.imageUrl!] : [],
        scheduledDate: null,
        acceptedAt: null,
        startedAt: null,
        completedAt: null,
        cancelledAt: null,
        cancellationReason: null,
        technicianId: null,
        technicianName: null,
        technicianPhone: null,
        technicianRating: null,
        customerRating: null,
        customerReview: null,
        serviceCharge: 0.0,
      );

      await _taskService.createTask(task);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task posted successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'AI Smart Match',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _postAsOpen,
            child: Text(
              'Post',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // ✅ Info Card
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700], size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Describe your requirement and AI will find the best technicians.',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // ✅ Command Text Field
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _commandController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Describe your requirement...',
                    hintStyle: GoogleFonts.poppins(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF1A237E),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // ✅ Send Button
              SizedBox(
                width: double.infinity,
                height: 40,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _runAIMatching,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : Text(
                    '🔍 Ask AI',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // ✅ AI Response (Expanded)
              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                    : _errorMessage != null
                    ? _buildErrorState()
                    : _aiResponse != null
                    ? _buildAIResponse()
                    : _buildEmptyState(),
              ),

              const SizedBox(height: 8),

              // ✅ Response Text Field
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: TextField(
                  controller: _responseController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Write your response here...',
                    hintStyle: GoogleFonts.poppins(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    prefixIcon: Icon(
                      Icons.edit_note,
                      color: Colors.green[700],
                      size: 16,
                    ),
                  ),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF1A237E),
                  ),
                ),
              ),
              const SizedBox(height: 6),

              // ✅ Send Response Button
              SizedBox(
                width: double.infinity,
                height: 36,
                child: OutlinedButton(
                  onPressed: _responseController.text.trim().isEmpty
                      ? null
                      : _postAsOpen,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: _responseController.text.trim().isEmpty
                          ? Colors.grey[300]!
                          : Colors.green[700]!,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    '📤 Send Response',
                    style: GoogleFonts.poppins(
                      color: _responseController.text.trim().isEmpty
                          ? Colors.grey[400]
                          : Colors.green[700],
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A237E)),
            ),
            const SizedBox(height: 8),
            Text(
              '🤖 AI is analyzing...',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 32, color: Colors.red[400]),
            const SizedBox(height: 6),
            Text(
              _errorMessage!,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.red[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: _runAIMatching,
              child: Text(
                '🔄 Try Again',
                style: GoogleFonts.poppins(
                  color: Colors.blue[700],
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat,
              size: 32,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 6),
            Text(
              'Ask AI to find technicians',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
            Text(
              'Describe your requirement above',
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // lib/Presentations/ai_screen/ai_matching_screen.dart

// ✅ Update _buildAIResponse method to properly display data
  Widget _buildAIResponse() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: Colors.green[700],
                  size: 12,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '🤖 AI Response',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
          const Divider(height: 6),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(4),
              child: Text(
                _aiResponse!,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFF1A237E),
                  height: 1.6,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}