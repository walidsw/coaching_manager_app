import 'package:flutter/material.dart';
import '../database_helper.dart';

class AddStudentScreen extends StatefulWidget {
  final Map<String, dynamic>? prefill; // Use for editing

  const AddStudentScreen({super.key, this.prefill});

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _fatherNameController;
  late TextEditingController _motherNameController;
  late TextEditingController _fatherMobileController;
  late TextEditingController _altMobileController;
  late TextEditingController _sectionController;

  String _selectedClass = 'Class 3';
  String _selectedStatus = 'active';

  List<String> _classes = [];
  bool _isLoadingClasses = true;
  bool _isSaving = false;

  bool get _isEditing => widget.prefill != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.prefill?['name'] ?? '');
    _fatherNameController = TextEditingController(text: widget.prefill?['father_name'] ?? '');
    _motherNameController = TextEditingController(text: widget.prefill?['mother_name'] ?? '');
    _fatherMobileController = TextEditingController(text: widget.prefill?['father_mobile'] ?? '');
    _altMobileController = TextEditingController(text: widget.prefill?['alternative_mobile'] ?? '');
    _sectionController = TextEditingController(text: widget.prefill?['section'] ?? '');
    
    if (_isEditing) {
      _selectedClass = widget.prefill?['current_class'] ?? 'Class 3';
      _selectedStatus = widget.prefill?['status'] ?? 'active';
    }

    _loadClasses();
  }

  Future<void> _loadClasses() async {
    final clsList = await DatabaseHelper.instance.getClasses();
    setState(() {
      _classes = clsList.map((e) => e['class_name'] as String).toList();
      if (!_classes.contains(_selectedClass) && _classes.isNotEmpty) {
        _selectedClass = _classes.first;
      }
      _isLoadingClasses = false;
    });
  }

  Future<void> _saveStudent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final studentData = {
        'name': _nameController.text.trim(),
        'father_name': _fatherNameController.text.trim(),
        'mother_name': _motherNameController.text.trim(),
        'father_mobile': _fatherMobileController.text.trim(),
        'alternative_mobile': _altMobileController.text.trim(),
        'current_class': _selectedClass,
        'section': _sectionController.text.trim(),
        'status': _selectedStatus,
      };

      if (_isEditing) {
        final uid = widget.prefill!['unique_student_id'];
        await DatabaseHelper.instance.updateStudent(uid, studentData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Student updated')));
          Navigator.pop(context, true); // Pop and signal refresh
        }
      } else {
        final newId = await DatabaseHelper.instance.addStudent(studentData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added new student: $newId')));
          _formKey.currentState!.reset(); // Clear form
          _resetControllers();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _resetControllers() {
    _nameController.clear();
    _fatherNameController.clear();
    _motherNameController.clear();
    _fatherMobileController.clear();
    _altMobileController.clear();
    _sectionController.clear();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingClasses) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Student Profile' : 'Student Registration', style: const TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.indigo.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 24, top: 12),
              decoration: BoxDecoration(
                color: Colors.indigo.shade800,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Text(
                _isEditing ? 'Update the details below to keep the student records current.' : 'Fill out the form below to enroll a new student into a batch.',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 15),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSectionCard(
                      'Personal Information',
                      Icons.person_outline,
                      Colors.teal,
                      [
                        _buildTextField(_nameController, "Student's Full Name", Icons.badge_outlined, isRequired: true),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _buildSectionCard(
                      'Parental Information',
                      Icons.family_restroom,
                      Colors.orange,
                      [
                        _buildResponsiveFields(
                          _buildTextField(_fatherNameController, "Father's Name", null),
                          _buildTextField(_motherNameController, "Mother's Name", null),
                        ),
                        const SizedBox(height: 16),
                        _buildResponsiveFields(
                          _buildTextField(_fatherMobileController, "Father's Mobile", Icons.phone_android, isPhone: true),
                          _buildTextField(_altMobileController, "Alt Mobile", Icons.phone_android, isPhone: true),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    _buildSectionCard(
                      'Academic Details',
                      Icons.school_outlined,
                      Colors.blue,
                      [
                        _buildResponsiveFields(
                          DropdownButtonFormField<String>(
                            decoration: _inputDecoration('Class *', Icons.class_outlined),
                            value: _selectedClass,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.indigo),
                            dropdownColor: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            items: _classes.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontWeight: FontWeight.w500)))).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedClass = val);
                            },
                          ),
                          _buildTextField(_sectionController, "Section", Icons.meeting_room_outlined),
                        ),
                        if (_isEditing) ...[
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            decoration: _inputDecoration('Status', Icons.check_circle_outline),
                            initialValue: _selectedStatus,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.indigo),
                            dropdownColor: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            items: const [
                              DropdownMenuItem(value: 'active', child: Text('Active Enrollment', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
                              DropdownMenuItem(value: 'inactive', child: Text('Inactive / Left', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedStatus = val);
                            },
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 32),

                    Container(
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF00BFA5), Color(0xFF0097A7)]),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF00BFA5).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: _isSaving ? null : _saveStudent,
                        child: _isSaving 
                            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                            : Text(
                                _isEditing ? 'Save Changes' : 'Complete Registration',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
                              ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsiveFields(Widget child1, Widget child2) {
    if (MediaQuery.of(context).size.width < 500) {
      return Column(
        children: [
          child1,
          const SizedBox(height: 16),
          child2,
        ],
      );
    } else {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: child1),
          const SizedBox(width: 12),
          Expanded(child: child2),
        ],
      );
    }
  }

  Widget _buildSectionCard(String title, IconData icon, MaterialColor color, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.blueGrey.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.shade50, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, size: 20, color: color.shade700),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.blueGrey.shade800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData? icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
      prefixIcon: icon != null ? Icon(icon, color: Colors.indigo.shade300, size: 20) : null,
      filled: true,
      fillColor: Colors.grey.shade50,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.indigo.shade400, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.red.shade300),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData? icon, {bool isRequired = false, bool isPhone = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
      decoration: _inputDecoration(label, icon),
      validator: isRequired ? (val) => val == null || val.isEmpty ? 'Required' : null : null,
    );
  }
}
