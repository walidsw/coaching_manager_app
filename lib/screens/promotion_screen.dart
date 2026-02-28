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
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text('Promote Students', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF7C3AED), // Deep Purple
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // ── Header Banner ──
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF8B5CF6)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 12, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("From Class", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 13)),
                          DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: _selectedClass,
                              icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF7C3AED)),
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                              items: _classes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedClass = val);
                                  _loadStudentsForClass();
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_forward_rounded, color: Color(0xFF7C3AED), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("To Class", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 13)),
                          DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: _targetClass,
                              icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF7C3AED)),
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                              items: _classes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _targetClass = val);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED)))
              : _students.isEmpty 
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text('No students found in this class.', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _students.length,
                      itemBuilder: (context, index) {
                        final student = _students[index];
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF7C3AED).withValues(alpha: 0.15),
                              foregroundColor: const Color(0xFF7C3AED),
                              child: Text((student['name'] as String).substring(0, 1).toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            title: Text(
                              student['name'],
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
                            ),
                            subtitle: Text(
                              student['unique_student_id'],
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                            ),
                            trailing: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF7C3AED),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              ),
                              onPressed: () => _promoteStudent(student['unique_student_id'], student['name']),
                              icon: const Icon(Icons.upgrade_rounded, size: 18),
                              label: const Text("Promote", style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
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
