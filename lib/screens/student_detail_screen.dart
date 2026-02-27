import 'package:flutter/material.dart';
import '../database_helper.dart';

class StudentDetailScreen extends StatefulWidget {
  final String studentId;

  const StudentDetailScreen({super.key, required this.studentId});

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  Map<String, dynamic>? _student;
  List<Map<String, dynamic>> _payments = [];
  List<Map<String, dynamic>> _marks = [];
  Map<String, int>? _stats;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final db = DatabaseHelper.instance;
    final std = await db.getStudentById(widget.studentId);
    
    if (std != null) {
      final payments = await db.getPaymentsForStudent(widget.studentId);
      final marks = await db.getMarksForStudent(widget.studentId);
      final stats = await db.getStudentExamStats(widget.studentId, std['current_class']);

      setState(() {
        _student = std;
        _payments = payments;
        _marks = marks;
        _stats = stats;
      });
    }
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_student == null) return const Scaffold(body: Center(child: Text("Student not found")));

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text("${_student!['name']}'s Profile"),
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: "Details", icon: Icon(Icons.person)),
              Tab(text: "Payments", icon: Icon(Icons.payment)),
              Tab(text: "Academics", icon: Icon(Icons.school)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildDetailsTab(),
            _buildPaymentsTab(),
            _buildAcademicsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsTab() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildInfoCard("Personal", [
          "ID: ${_student!['unique_student_id']}",
          "Name: ${_student!['name']}",
          "Father's Name: ${_student!['father_name']}",
          "Mother's Name: ${_student!['mother_name']}",
          "Father's Mobile: ${_student!['father_mobile']}",
          "Alt Mobile: ${_student!['alternative_mobile']}",
        ]),
        const SizedBox(height: 16),
        _buildInfoCard("Academic info", [
          "Current Class: ${_student!['current_class']}",
          "Section: ${_student!['section']}",
          "Status: ${_student!['status']}",
        ]),
      ],
    );
  }

  Widget _buildPaymentsTab() {
    if (_payments.isEmpty) return const Center(child: Text("No payment history"));
    
    return ListView.builder(
      itemCount: _payments.length,
      itemBuilder: (context, index) {
        final payment = _payments[index];
        final isPaid = payment['paid_status'] == 'paid';
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: Icon(isPaid ? Icons.check_circle : Icons.warning, color: isPaid ? Colors.green : Colors.red),
            title: Text("${payment['month']} ${payment['year']}"),
            subtitle: Text("Amount: \$${payment['amount']}"),
            trailing: Text(payment['paid_status'].toString().toUpperCase(), style: TextStyle(color: isPaid ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }

  Widget _buildAcademicsTab() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        if (_stats != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatChip("Exams: ${_stats!['total']}", Colors.blue),
              _buildStatChip("Attended: ${_stats!['attended']}", Colors.green),
              _buildStatChip("Missed: ${_stats!['missed']}", Colors.red),
            ],
          ),
          const SizedBox(height: 16),
        ],
        const Text("Exam Results", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (_marks.isEmpty) 
          const Text("No exam results found for this student.")
        else
          ..._marks.map((mark) {
            double percent = mark['obtained_marks'] != null ? (mark['obtained_marks'] / mark['total_marks']) * 100 : 0.0;
            return Card(
              child: ListTile(
                title: Text(mark['exam_name']),
                subtitle: Text("Date: ${mark['exam_date']} | Class: ${mark['class_name']}"),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text("${mark['obtained_marks'] ?? 'Absent'} / ${mark['total_marks']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    if (mark['obtained_marks'] != null) Text("${percent.toStringAsFixed(1)}%", style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildInfoCard(String title, List<String> details) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
            const Divider(),
            ...details.map((d) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(d, style: const TextStyle(fontSize: 16)),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, Color color) {
    return Chip(
      label: Text(label, style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
    );
  }
}
