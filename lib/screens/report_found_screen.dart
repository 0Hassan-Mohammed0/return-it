import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:returnit/services/database_service.dart';
import 'package:returnit/models/item_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui'; // For formatting

class ReportFoundPage extends StatefulWidget {
  final ItemModel? itemToEdit;

  const ReportFoundPage({super.key, this.itemToEdit});

  @override
  State<ReportFoundPage> createState() => _ReportFoundPageState();
}

class _ReportFoundPageState extends State<ReportFoundPage> {
  @override
  void initState() {
    super.initState();
    _titleController.addListener(_onTitleChanged);

    // If editing, populate fields with existing data
    if (widget.itemToEdit != null) {
      final item = widget.itemToEdit!;
      _titleController.text = item.title;
      _descriptionController.text = item.description;
      _locationController.text = item.location;
      _selectedLocation = item.location;
      _category = item.category;
      _selectedDate = item.timestamp;
      _handedToSecurity = item.handedToSecurity;
      // Note: We can't pre-populate the image from URL easily, user will need to re-upload if they want to change it
    }
  }

  @override
  void dispose() {
    _titleController.removeListener(_onTitleChanged);
    _debounce?.cancel();
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  DateTime? _selectedDate;
  String? _category;
  XFile? _imageFile;
  bool _isLoading = false;
  bool _handedToSecurity = false;
  final DatabaseService _databaseService = DatabaseService();

  // Smart Suggestions
  List<ItemModel> _similarItems = [];
  Timer? _debounce;

  final List<String> _categories = [
    'All',
    'Personal items',
    'Study materials',
    'Electronics',
    'IDs/Cards',
    'Documents',
    'Others'
  ];

  final List<String> _locations = [
    'All',
    'مبنى مدني',
    'مبنى عمارة',
    'مبنى الورش',
    'مبنى 4',
    'مبنى 5',
    'الكانتين',
    'شئون الطلاب',
    'البرجولات',
    'أخرى'
  ];
  String? _selectedLocation;

  Future<void> _pickImage() async {
    _getImage(ImageSource.camera);
  }

  Future<void> _getImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile =
          await picker.pickImage(source: source, imageQuality: 80);

      if (pickedFile != null) {
        setState(() {
          _imageFile = pickedFile;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open camera: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _onTitleChanged() {
    _performSearch();
  }

  void _performSearch() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final title = _titleController.text.trim();

      if (title.isEmpty && _selectedLocation == null) {
        setState(() => _similarItems = []);
        return;
      }

      final matches = await _databaseService.findSimilarItems(
          title: title, typeToSearch: 'lost', location: _selectedLocation);

      if (mounted) {
        setState(() => _similarItems = matches);
      }
    });
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please select a date')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final bool isEditing = widget.itemToEdit != null;

      // Skip duplicate checks when editing
      if (!isEditing) {
        // 1. Check for Matches (Proactive Warning)
        // Check the OPPOSITE collection (if Found, check Lost)
        final similarItems = await _databaseService.findSimilarItems(
            title: _titleController.text.trim(), typeToSearch: 'lost');

        if (similarItems.isNotEmpty) {
          if (!mounted) return;
          bool? continueSubmit = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Wait! Similar Items Reported Lost'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                        'Someone might be looking for this! Check these lost reports:'),
                    const SizedBox(height: 10),
                    ...similarItems.take(3).map((item) => ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            color: Colors.grey[200],
                            child: item.imageUrl != null
                                ? Image.network(item.imageUrl!,
                                    fit: BoxFit.cover)
                                : const Icon(Icons.image_not_supported,
                                    size: 20),
                          ),
                          title: Text(item.title,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(item.location, maxLines: 1),
                        )),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel & Check'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Submit Anyway'),
                ),
              ],
            ),
          );

          if (continueSubmit != true) {
            setState(() => _isLoading = false);
            return;
          }
        }

        // 2. Check for soft duplicates (Self-Check)
        bool isDuplicate = await _databaseService.checkSoftDuplicate(
          type: 'found',
          title: _titleController.text.trim(),
          date: _selectedDate!,
        );

        if (isDuplicate) {
          if (!mounted) return;
          bool? continueSubmit = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Possible Duplicate'),
              content: const Text(
                  'You have already submitted a similar item today. Do you want to continue?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Continue'),
                ),
              ],
            ),
          );

          if (continueSubmit != true) {
            setState(() => _isLoading = false);
            return;
          }
        }
      }

      // 3. Check Auth BEFORE upload
      final user = FirebaseAuth.instance.currentUser;
      if (user == null)
        throw Exception('User not logged in. Please login first.');

      // 4. Upload Image if exists
      String? imageUrl = isEditing ? widget.itemToEdit!.imageUrl : null;
      if (_imageFile != null) {
        try {
          imageUrl = await _databaseService.uploadImage(_imageFile!, 'items');
        } catch (e) {
          throw Exception('Image Upload Failed: $e');
        }
      }

      // 5. Save to Firestore
      final item = ItemModel(
        id: isEditing ? widget.itemToEdit!.id : '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        location: _selectedLocation ?? _locationController.text,
        userId: user.uid,
        imageUrl: imageUrl,
        type: 'found',
        category: _category ?? 'Other',
        timestamp: _selectedDate!,
        handedToSecurity: _handedToSecurity,
        isResolved: isEditing ? widget.itemToEdit!.isResolved : false,
      );

      if (isEditing) {
        await _databaseService.updateItem(item);
      } else {
        await _databaseService.addItem(item);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(isEditing
                ? 'Item updated successfully!'
                : 'Report submitted successfully!')),
      );
      Navigator.pop(context); // Go back to Home
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- Widgets ---

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 4.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String placeholder, {Widget? suffixIcon}) {
    return InputDecoration(
      hintText: placeholder,
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF000B58)),
      ),
      suffixIcon: suffixIcon,
    );
  }

  Widget _buildSelectionField(
    BuildContext context, {
    required String label,
    required String? value,
    required List<String> options,
    required Function(String) onSelect,
  }) {
    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          backgroundColor: const Color(0xFFF3F4F6),
          builder: (context) {
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 300,
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: options.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final option = options[index];
                        return InkWell(
                          onTap: () {
                            onSelect(option);
                            Navigator.pop(context);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 4.0, horizontal: 8.0),
                            child: Text(
                              option,
                              style: const TextStyle(
                                  fontSize: 16, color: Colors.black87),
                              textAlign: TextAlign.start,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
      child: IgnorePointer(
        child: TextFormField(
          key: ValueKey(value),
          initialValue: value,
          decoration: _inputDecoration(label,
              suffixIcon: const Icon(Icons.keyboard_arrow_down)),
          validator: (v) => value == null ? 'Required' : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      appBar: AppBar(
        title: Text(widget.itemToEdit != null
            ? 'Edit Found Item'
            : 'Report Found Item'),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Image Upload Section
                    _buildLabel('Upload images'),
                    GestureDetector(
                      onTap: _pickImage,
                      child: DashedRect(
                        color: Colors.grey.shade400,
                        strokeWidth: 1.5,
                        gap: 5.0,
                        child: Container(
                          height: 180,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: _imageFile != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: kIsWeb
                                      ? Image.network(
                                          _imageFile!.path,
                                          fit: BoxFit.cover,
                                        )
                                      : Image.file(File(_imageFile!.path),
                                          fit: BoxFit.cover),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(Icons.camera_alt,
                                          color: Colors.grey[600], size: 24),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text('Tap to upload',
                                        style: TextStyle(
                                            fontWeight: FontWeight
                                                .bold)), // Changed text to match right mockup
                                  ],
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Item Name
                    _buildLabel('Item Name'),
                    TextFormField(
                      controller: _titleController,
                      decoration: _inputDecoration('e.g. Black Backpack'),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Please enter a title'
                          : null,
                    ),

                    // Smart Suggestions UI
                    if (_similarItems.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Colors.orange.withValues(alpha: 0.3)),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.orange.withValues(alpha: 0.05),
                                  blurRadius: 5)
                            ]),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.lightbulb_outline,
                                    color: Colors.orange, size: 18),
                                SizedBox(width: 8),
                                Text('Similar Lost Items',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.deepOrange)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ..._similarItems
                                .map((item) => Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 8.0),
                                      child: InkWell(
                                        onTap: () => Navigator.pushNamed(
                                            context, '/item_details',
                                            arguments: item),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                color: Colors.grey[200],
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                image: item.imageUrl != null
                                                    ? DecorationImage(
                                                        image: NetworkImage(
                                                            item.imageUrl!),
                                                        fit: BoxFit.cover)
                                                    : null,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(item.title,
                                                      style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.w500)),
                                                  Text(item.location,
                                                      style: TextStyle(
                                                          color:
                                                              Colors.grey[500],
                                                          fontSize: 12)),
                                                ],
                                              ),
                                            ),
                                            Icon(Icons.chevron_right,
                                                color: Colors.grey[400]),
                                          ],
                                        ),
                                      ),
                                    ))
                                .toList(),
                          ],
                        ),
                      )
                    ],
                    const SizedBox(height: 16),

                    // Description
                    _buildLabel('Description'),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: _inputDecoration('Add any details...'),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Please enter a description'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Category
                    _buildLabel('Category'),
                    _buildSelectionField(context,
                        label: 'Select Category',
                        value: _category,
                        options: _categories, onSelect: (val) {
                      setState(() => _category = val);
                    }),
                    const SizedBox(height: 16),

                    // Location
                    _buildLabel('Location found'),
                    _buildSelectionField(context,
                        label: 'Select Location',
                        value: _selectedLocation,
                        options: _locations, onSelect: (val) {
                      setState(() {
                        _selectedLocation = val;
                        if (val != 'Other') {
                          _locationController.text = val;
                        } else {
                          _locationController.clear();
                        }
                      });
                      _performSearch(); // Trigger search on location change
                    }),
                    const SizedBox(height: 16),

                    // Date
                    _buildLabel('Date found'),
                    InkWell(
                      onTap: () => _selectDate(context),
                      child: IgnorePointer(
                        child: TextFormField(
                          key: ValueKey(_selectedDate),
                          initialValue: _selectedDate != null
                              ? DateFormat('MM/dd/yyyy').format(_selectedDate!)
                              : null,
                          decoration: _inputDecoration(
                            'mm/dd/yyyy',
                            suffixIcon: const Icon(
                                Icons.calendar_today_outlined,
                                size: 20,
                                color: Colors.blueGrey),
                          ),
                          validator: (v) => _selectedDate == null
                              ? 'Please select a date'
                              : null,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Handed to Security Toggle
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Handed to Security?',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          Switch(
                            value: _handedToSecurity,
                            activeTrackColor: const Color(0xFF2563EB),
                            onChanged: (bool value) {
                              setState(() {
                                _handedToSecurity = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Submit Button
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _submitReport,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Submit Report',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }
}

// Duplicated DashedRect for independent files as preferred for small helper classes
class DashedRect extends StatelessWidget {
  final Color color;
  final double strokeWidth;
  final double gap;
  final Widget child;

  const DashedRect(
      {super.key,
      this.color = Colors.black,
      this.strokeWidth = 1.0,
      this.gap = 5.0,
      required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2), // dashed border width space
      child: CustomPaint(
        painter: _DashedRectPainter(
            color: color, strokeWidth: strokeWidth, gap: gap),
        child: Padding(padding: const EdgeInsets.all(4), child: child),
      ),
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  _DashedRectPainter(
      {required this.color, required this.strokeWidth, required this.gap});

  @override
  void paint(Canvas canvas, Size size) {
    Paint dashedPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    double x = 0;
    double y = 0;
    double w = size.width;
    double h = size.height;

    Path _topPath = Path();
    _topPath.moveTo(x, y);
    _topPath.lineTo(w, y);

    Path _rightPath = Path();
    _rightPath.moveTo(w, y);
    _rightPath.lineTo(w, h);

    Path _bottomPath = Path();
    _bottomPath.moveTo(w, h);
    _bottomPath.lineTo(x, h);

    Path _leftPath = Path();
    _leftPath.moveTo(x, h);
    _leftPath.lineTo(x, y);

    _drawDashedPath(canvas, _topPath, dashedPaint);
    _drawDashedPath(canvas, _rightPath, dashedPaint);
    _drawDashedPath(canvas, _bottomPath, dashedPaint);
    _drawDashedPath(canvas, _leftPath, dashedPaint);
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    PathMetrics pathMetrics = path.computeMetrics();
    for (PathMetric pathMetric in pathMetrics) {
      double distance = 0.0;
      while (distance < pathMetric.length) {
        canvas.drawPath(
          pathMetric.extractPath(distance, distance + 5), // 5 is dash width
          paint,
        );
        distance += 5 + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
