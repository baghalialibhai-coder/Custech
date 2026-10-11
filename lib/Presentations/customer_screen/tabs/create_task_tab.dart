import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/models/task_model.dart';
import '../../../services/task_service.dart';

class CreateTaskTab extends ConsumerStatefulWidget {
  final String? selectedCategory; // ✅ Pre-selected category from home

  const CreateTaskTab({
    super.key,
    this.selectedCategory,
  });

  @override
  ConsumerState<CreateTaskTab> createState() => _CreateTaskTabState();
}

class _CreateTaskTabState extends ConsumerState<CreateTaskTab> {
  final TaskService _taskService = TaskService();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _budgetController = TextEditingController();

  String? _selectedCategory;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // ✅ Set pre-selected category if provided
    _selectedCategory = widget.selectedCategory;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _pincodeController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = _taskService.getAllCategories();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ============================================================
            // ✅ HEADER
            // ============================================================
            Text(
              'Create New Task',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Describe your task and find the right technician',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),

            // ============================================================
            // ✅ TASK TITLE
            // ============================================================
            _buildTextField(
              controller: _titleController,
              label: 'Task Title',
              hint: 'e.g., AC Repair needed',
              icon: Icons.title,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a task title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // ============================================================
            // ✅ CATEGORY DROPDOWN (FIXED OVERFLOW)
            // ============================================================
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonFormField<String>(
                value: _selectedCategory,
                isExpanded: true, // ✅ Prevents overflow
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                items: categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(
                      category,
                      style: GoogleFonts.poppins(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a category';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 16),

            // ============================================================
            // ✅ DESCRIPTION
            // ============================================================
            _buildTextField(
              controller: _descriptionController,
              label: 'Description',
              hint: 'Describe your task in detail',
              icon: Icons.description,
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // ============================================================
            // ✅ ADDRESS
            // ============================================================
            _buildTextField(
              controller: _addressController,
              label: 'Address',
              hint: 'Enter your address',
              icon: Icons.location_on,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your address';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // ============================================================
            // ✅ PINCODE
            // ============================================================
            _buildTextField(
              controller: _pincodeController,
              label: 'Pincode',
              hint: 'Enter your pincode',
              icon: Icons.pin_drop,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your pincode';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // ============================================================
            // ✅ BUDGET
            // ============================================================
            _buildTextField(
              controller: _budgetController,
              label: 'Budget (PKR)',
              hint: 'Enter your budget',
              icon: Icons.attach_money,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your budget';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // ============================================================
            // ✅ SERVICE DETAILS PREVIEW (Category-specific)
            // ============================================================
            if (_selectedCategory != null) ...[
              _buildServiceDetailsPreview(_selectedCategory!),
              const SizedBox(height: 16),
            ],

            // ============================================================
            // ✅ SUBMIT BUTTON
            // ============================================================
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createTask,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                  'Create Task',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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

  // ============================================================
  // ✅ BUILD TEXT FIELD
  // ============================================================
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      style: GoogleFonts.poppins(),
    );
  }

  // ============================================================
  // ✅ SERVICE DETAILS PREVIEW (Category-specific)
  // ============================================================
  Widget _buildServiceDetailsPreview(String category) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.blue[700],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Service Details',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildDetailRow('Category', category),
          _buildDetailRow('Service Type', _getServiceType(category)),
          _buildDetailRow('Estimated Time', _getEstimatedTime(category)),
          _buildDetailRow('Price Range', _getPriceRange(category)),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.blue[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ✅ SERVICE TYPE LOGIC
  // ============================================================
  String _getServiceType(String category) {
    final manualCategories = [
      'Plumber',
      'Electrician',
      'Carpenter',
      'Painter',
      'Mechanic',
      'Welding',
      'Locksmith',
      'Roofing',
      'Tiling',
      'Flooring',
    ];
    return manualCategories.contains(category) ? 'Manual Service' : 'Auto Service';
  }

  // ============================================================
  // ✅ ESTIMATED TIME LOGIC
  // ============================================================
  String _getEstimatedTime(String category) {
    final times = {
      'AC Repair': '1-2 hours',
      'Plumber': '1-3 hours',
      'Electrician': '1-2 hours',
      'Carpenter': '2-4 hours',
      'Painter': '3-6 hours',
      'Mechanic': '1-3 hours',
      'Cleaning Services': '2-4 hours',
      'Pest Control': '1-2 hours',
      'Locksmith': '30-60 mins',
      'Welding': '1-3 hours',
      'Refrigerator Repair': '1-2 hours',
      'Washing Machine Repair': '1-2 hours',
      'TV Repair': '1-2 hours',
      'Computer Repair': '1-2 hours',
      'Mobile Repair': '30-60 mins',
      'Gardening': '2-4 hours',
      'Roofing': '4-8 hours',
      'Tiling': '4-8 hours',
      'Furniture Assembly': '1-3 hours',
      'Interior Design': '2-4 hours',
      'Building Construction': '1-7 days',
      'EV Charger Installation': '2-4 hours',
      'Smart Home Setup': '2-4 hours',
      'CCTV Installation': '2-4 hours',
      'Pet Grooming': '1-2 hours',
      'Gym Equipment Installation': '2-4 hours',
    };
    return times[category] ?? '1-3 hours';
  }

  // ============================================================
  // ✅ PRICE RANGE LOGIC
  // ============================================================
  String _getPriceRange(String category) {
    final prices = {
      'AC Repair': 'PKR 1,500 - 3,000',
      'Plumber': 'PKR 1,000 - 2,500',
      'Electrician': 'PKR 1,000 - 2,500',
      'Carpenter': 'PKR 1,500 - 4,000',
      'Painter': 'PKR 2,000 - 5,000',
      'Mechanic': 'PKR 1,500 - 3,500',
      'Cleaning Services': 'PKR 1,500 - 3,000',
      'Pest Control': 'PKR 2,000 - 4,000',
      'Locksmith': 'PKR 500 - 1,500',
      'Welding': 'PKR 1,500 - 4,000',
      'Refrigerator Repair': 'PKR 1,500 - 3,000',
      'Washing Machine Repair': 'PKR 1,500 - 3,000',
      'TV Repair': 'PKR 1,000 - 3,000',
      'Computer Repair': 'PKR 1,000 - 3,000',
      'Mobile Repair': 'PKR 500 - 2,000',
      'Gardening': 'PKR 1,500 - 3,500',
      'Roofing': 'PKR 5,000 - 15,000',
      'Tiling': 'PKR 3,000 - 8,000',
      'Furniture Assembly': 'PKR 1,000 - 3,000',
      'Interior Design': 'PKR 3,000 - 10,000',
      'Building Construction': 'PKR 20,000 - 100,000',
      'EV Charger Installation': 'PKR 10,000 - 25,000',
      'Smart Home Setup': 'PKR 5,000 - 15,000',
      'CCTV Installation': 'PKR 3,000 - 8,000',
      'Pet Grooming': 'PKR 1,000 - 2,500',
      'Gym Equipment Installation': 'PKR 2,000 - 5,000',
    };
    return prices[category] ?? 'PKR 1,000 - 5,000';
  }

  // ============================================================
  // ✅ CREATE TASK
  // ============================================================
  Future<void> _createTask() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) throw Exception('Not logged in');

        final task = TaskModel(
          id: '',
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          customerId: user.uid,
          customerName: user.displayName ?? 'Customer',
          customerPhone: '',
          address: _addressController.text.trim(),
          pincode: _pincodeController.text.trim(),
          latitude: 0.0,
          longitude: 0.0,
          category: _selectedCategory!,
          budget: double.parse(_budgetController.text.trim()),
          createdAt: DateTime.now(),
          status: TaskStatus.open, // ✅ OPEN by default
        );

        await _taskService.createTask(task);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task created successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Clear form
        _titleController.clear();
        _descriptionController.clear();
        _addressController.clear();
        _pincodeController.clear();
        _budgetController.clear();
        setState(() {
          _selectedCategory = null;
          _isLoading = false;
        });

        // ✅ Navigate to My Tasks tab
        // You can use a provider or callback to switch tabs
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }
}