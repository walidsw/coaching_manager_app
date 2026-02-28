import 'package:flutter/material.dart';
import '../database_helper.dart';
import 'exam_marks_screen.dart';

class ExamListScreen extends StatefulWidget {
  const ExamListScreen({super.key});

  @override
  State<ExamListScreen> createState() => _ExamListScreenState();
}

class _ExamListScreenState extends State<ExamListScreen> {
  String? _selectedClass;
  List<String> _classes = [];
  List<Map<String, dynamic>> _exams = [];
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
        _loadExams();
      } else {
        _isLoading = false;
      }
    });
  }

  Future<void> _loadExams() async {
    if (_selectedClass == null) return;
    setState(() => _isLoading = true);
    
    final exams = await DatabaseHelper.instance.getExamsByClass(_selectedClass!);
    setState(() {
      _exams = exams;
      _isLoading = false;
    });
  }

  Future<void> _addExam() async {
    final nameCtrl = TextEditingController();
    final marksCtrl = TextEditingController();
    final dateCtrl = TextEditingController(text: DateTime.now().toString().split(' ')[0]);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Exam'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Exam Name')),
            TextField(controller: marksCtrl, decoration: const InputDecoration(labelText: 'Total Marks'), keyboardType: TextInputType.number),
            TextField(controller: dateCtrl, decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final marks = double.tryParse(marksCtrl.text);
              if (nameCtrl.text.isNotEmpty && marks != null) {
                await DatabaseHelper.instance.addExam({
                  'class_name': _selectedClass,
                  'exam_name': nameCtrl.text,
                  'total_marks': marks,
                  'exam_date': dateCtrl.text,
                });
                if (context.mounted) Navigator.pop(context);
                _loadExams();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteExam(int examId) async {
    await DatabaseHelper.instance.deleteExam(examId);
    _loadExams();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text('Exams', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFDC2626), // Red
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addExam,
        backgroundColor: const Color(0xFFDC2626),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Exam', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // ── Header Banner ──
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
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
                    const Icon(Icons.class_, color: Color(0xFFDC2626), size: 20),
                    const SizedBox(width: 8),
                    const Text("Select Class:", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedClass,
                          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFFDC2626)),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                          items: _classes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedClass = val);
                              _loadExams();
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFDC2626)))
              : _exams.isEmpty 
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.assignment_turned_in, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text('No exams found for this class.', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(top: 8, bottom: 80), // Padding to not hide behind fab
                      itemCount: _exams.length,
                      itemBuilder: (context, index) {
                        final exam = _exams[index];
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
                              radius: 24,
                              backgroundColor: const Color(0xFFDC2626).withValues(alpha: 0.1), 
                              child: const Icon(Icons.assignment_rounded, color: Color(0xFFDC2626), size: 28)
                            ),
                            title: Text(
                              exam['exam_name'],
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                "Date: ${exam['exam_date']} • Total: ${exam['total_marks']}",
                                style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500, fontSize: 13),
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
                              onPressed: () => _deleteExam(exam['exam_id'] as int)
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ExamMarksScreen(examId: exam['exam_id'] as int, examName: exam['exam_name']),
                                ),
                              );
                            },
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
