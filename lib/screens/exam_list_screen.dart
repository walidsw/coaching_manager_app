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
      appBar: AppBar(
        title: const Text('Exams'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addExam,
        backgroundColor: Colors.red,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Text("Select Class: ", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedClass,
                    items: _classes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedClass = val);
                        _loadExams();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _exams.isEmpty 
                  ? const Center(child: Text('No exams found for this class.'))
                  : ListView.builder(
                      itemCount: _exams.length,
                      itemBuilder: (context, index) {
                        final exam = _exams[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: ListTile(
                            leading: CircleAvatar(backgroundColor: Colors.red.shade100, child: const Icon(Icons.assignment, color: Colors.red)),
                            title: Text(exam['exam_name']),
                            subtitle: Text("Date: ${exam['exam_date']} | Total: ${exam['total_marks']}"),
                            trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteExam(exam['exam_id'] as int)),
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
