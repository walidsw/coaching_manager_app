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
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Student Details' : 'Registration Form'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionTitle('Personal Information'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Student Name *', border: OutlineInputBorder()),
                validator: (val) => val == null || val.isEmpty ? 'Please enter name' : null,
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('Parental Information'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: TextFormField(controller: _fatherNameController, decoration: const InputDecoration(labelText: "Father's Name", border: OutlineInputBorder()))),
                  const SizedBox(width: 16),
                  Expanded(child: TextFormField(controller: _motherNameController, decoration: const InputDecoration(labelText: "Mother's Name", border: OutlineInputBorder()))),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: TextFormField(controller: _fatherMobileController, decoration: const InputDecoration(labelText: "Father's Mobile", border: OutlineInputBorder()), keyboardType: TextInputType.phone)),
                  const SizedBox(width: 16),
                  Expanded(child: TextFormField(controller: _altMobileController, decoration: const InputDecoration(labelText: "Alt Mobile", border: OutlineInputBorder()), keyboardType: TextInputType.phone)),
                ],
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('Academic Details'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Class *', border: OutlineInputBorder()),
                      value: _selectedClass,
                      items: _classes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedClass = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _sectionController,
                      decoration: const InputDecoration(labelText: 'Section', border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              if (_isEditing) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                  initialValue: _selectedStatus,
                  items: const [
                    DropdownMenuItem(value: 'active', child: Text('Active')),
                    DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedStatus = val);
                  },
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveStudent,
                  icon: _isSaving ? const SizedBox.shrink() : const Icon(Icons.save),
                  label: _isSaving ? const CircularProgressIndicator() : Text(_isEditing ? 'Update Profile' : 'Register Student'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Colors.green.shade50,
      child: Text(
        title,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green.shade900),
      ),
    );
  }
}
