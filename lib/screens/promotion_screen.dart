import 'package:flutter/material.dart';
import '../database_helper.dart';

class PromotionScreen extends StatefulWidget {
  const PromotionScreen({super.key});

  @override
  State<PromotionScreen> createState() => _PromotionScreenState();
}

class _PromotionScreenState extends State<PromotionScreen> {
  String? _selectedClass;
  String? _targetClass;
  List<String> _classes = [];
  List<Map<String, dynamic>> _students = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    final c = await DatabaseHelper.instance.getClasses();
    setState(() {
      _classes = c.map((e) => e['class_name'] as String).toList();
      if (_classes.isNotEmpty) {
        _selectedClass = _classes.first;
        _targetClass = _classes.length > 1 ? _classes[1] : _classes.first;
        _loadStudentsForClass();
      } else {
        _isLoading = false;
      }
    });
  }

  Future<void> _loadStudentsForClass() async {
    if (_selectedClass == null) return;
    setState(() => _isLoading = true);
    final students = await DatabaseHelper.instance.getStudentsByClass(_selectedClass!);
    setState(() {
      _students = students;
      _isLoading = false;
    });
  }

  Future<void> _promoteStudent(String uid, String name) async {
    if (_targetClass == null || _targetClass == _selectedClass) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a different target class.')));
      return;
    }

    // Optional: Get summary or calculate it. We'll pass a basic string for now.
    String summary = "Promoted from $_selectedClass to $_targetClass";
    
    await DatabaseHelper.instance.promoteStudent(uid, _targetClass!, overallSummary: summary);
    if(mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Promoted $name to $_targetClass')));
    }
    _loadStudentsForClass(); // Refresh
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Promote Students'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("From Class", style: TextStyle(fontWeight: FontWeight.bold)),
                      DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedClass,
                        items: _classes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedClass = val);
                            _loadStudentsForClass();
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.arrow_forward),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("To Class", style: TextStyle(fontWeight: FontWeight.bold)),
                      DropdownButton<String>(
                        isExpanded: true,
                        value: _targetClass,
                        items: _classes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _targetClass = val);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _students.isEmpty 
                  ? const Center(child: Text('No students found in the selected class.'))
                  : ListView.builder(
                      itemCount: _students.length,
                      itemBuilder: (context, index) {
                        final student = _students[index];
                        return ListTile(
                          title: Text("${student['name']} (${student['unique_student_id']})"),
                          trailing: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => _promoteStudent(student['unique_student_id'], student['name']),
                            child: const Text("Promote"),
                          ),
                        );
                      },
                    ),
          )
        ],
      ),
    );
  }
}
