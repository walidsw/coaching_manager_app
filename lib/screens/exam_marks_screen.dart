import 'package:flutter/material.dart';
import '../database_helper.dart';
import '../pdf_generator.dart';

class ExamMarksScreen extends StatefulWidget {
  final int examId;
  final String examName;

  const ExamMarksScreen({super.key, required this.examId, required this.examName});

  @override
  State<ExamMarksScreen> createState() => _ExamMarksScreenState();
}

class _ExamMarksScreenState extends State<ExamMarksScreen> {
  List<Map<String, dynamic>> _students = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    final students = await DatabaseHelper.instance.getMarksByExam(widget.examId);
    setState(() {
      _students = students;
      _isLoading = false;
    });
  }

  Future<void> _updateMark(String uid, String marksText) async {
    double? marks = double.tryParse(marksText);
    if (marksText.isEmpty || marks != null) {
      if (marks != null) {
        await DatabaseHelper.instance.addOrUpdateMark(uid, widget.examId, marks);
      }
    }
  }

  Future<void> _generatePdf() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      
      final filePath = await PdfGenerator.generateExamResultPdf(widget.examId);
      
      if (mounted) {
        Navigator.pop(context); // close loader
        if (filePath != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF Generated: $filePath')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error generating PDF.')));
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.examName} Marks'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _generatePdf,
            tooltip: 'Generate PDF',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _students.isEmpty
              ? const Center(child: Text('No active students found for this class.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _students.length,
                  itemBuilder: (context, index) {
                    final student = _students[index];
                    String initialMark = student['obtained_marks'] != null 
                        ? student['obtained_marks'].toString() 
                        : '';
                        
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Row(
                          children: [
                            Expanded(flex: 2, child: Text("${student['name']}\n(${student['unique_student_id']})")),
                            Expanded(
                              flex: 1,
                              child: TextField(
                                controller: TextEditingController(text: initialMark),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  labelText: 'Marks',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                onSubmitted: (val) => _updateMark(student['unique_student_id'], val),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
