import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
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
  // One controller per student, keyed by unique_student_id
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    final rawStudents = await DatabaseHelper.instance.getMarksByExam(widget.examId);
    // sqflite returns read-only QueryRow maps — copy to mutable maps
    final students = rawStudents.map((s) => Map<String, dynamic>.from(s)).toList();
    // Build controllers
    _controllers.clear();
    for (final s in students) {
      final uid = s['unique_student_id'] as String;
      final mark = s['obtained_marks'];
      _controllers[uid] = TextEditingController(text: mark != null ? mark.toString() : '');
    }
    setState(() {
      _students = students;
      _isLoading = false;
    });
  }

  Future<void> _saveAllMarks() async {
    FocusScope.of(context).unfocus();
    int saved = 0;
    for (final student in _students) {
      final uid = student['unique_student_id'] as String;
      final text = _controllers[uid]?.text ?? '';
      if (text.isNotEmpty) {
        final marks = double.tryParse(text);
        if (marks != null) {
          await DatabaseHelper.instance.addOrUpdateMark(uid, widget.examId, marks);
          saved++;
        }
      }
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$saved mark(s) saved successfully'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _saveIndividualMark(String uid) async {
    FocusScope.of(context).unfocus();
    final text = _controllers[uid]?.text ?? '';
    if (text.isEmpty) return;
    
    final marks = double.tryParse(text);
    if (marks != null) {
      await DatabaseHelper.instance.addOrUpdateMark(uid, widget.examId, marks);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mark saved successfully'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 1),
          ),
        );
      }
    }
  }

  Future<void> _generatePdf() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFFE11D48))),
      );
      final filePath = await PdfGenerator.generateExamResultPdf(widget.examId);
      if (mounted) {
        Navigator.pop(context);
        if (filePath != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('PDF Generated: $filePath'),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            )
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error generating PDF.'),
              backgroundColor: Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
            )
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          )
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: Text('${widget.examName} Marks', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFE11D48), // Rose Red
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded),
            onPressed: _generatePdf,
            tooltip: 'Generate PDF',
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Header Banner ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE11D48), Color(0xFFFB7185)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Record Marks',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter and save marks for the students.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          
          // ── Students List ──
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFE11D48)))
                : _students.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.assignment_ind_rounded, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text('No active students found for this class.', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 16, bottom: 24, left: 16, right: 16),
                        itemCount: _students.length,
                        itemBuilder: (context, index) {
                          final student = _students[index];
                          final uid = student['unique_student_id'] as String;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: const Color(0xFFE11D48).withValues(alpha: 0.1),
                                    child: const Icon(Icons.person_rounded, color: Color(0xFFE11D48)),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        AutoSizeText(
                                          student['name'],
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
                                          maxLines: 2,
                                          minFontSize: 10,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          uid,
                                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: TextField(
                                      controller: _controllers[uid],
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                      decoration: InputDecoration(
                                        labelText: 'Marks',
                                        labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                        isDense: true,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                        filled: true,
                                        fillColor: const Color(0xFFF8FAFC),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide.none,
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(color: Color(0xFFE11D48), width: 2),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.save_rounded, color: Color(0xFF10B981), size: 20),
                                      tooltip: 'Save individual mark',
                                      onPressed: () => _saveIndividualMark(uid),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          
          // ── Save All Action ──
          if (!_isLoading && _students.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4)),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_rounded),
                  label: const Text('Save All Marks', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE11D48),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 2,
                  ),
                  onPressed: _saveAllMarks,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
