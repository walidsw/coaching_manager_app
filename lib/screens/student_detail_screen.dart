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
    if (_isLoading) return Scaffold(backgroundColor: const Color(0xFFF0F4F8), body: const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5))));
    if (_student == null) return Scaffold(backgroundColor: const Color(0xFFF0F4F8), body: const Center(child: Text("Student not found", style: TextStyle(fontSize: 18, color: Colors.grey))));

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F4F8),
        appBar: AppBar(
          title: Text("${_student!['name']}'s Profile", style: const TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF4F46E5), // Indigo
          foregroundColor: Colors.white,
          elevation: 0,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: "Details", icon: Icon(Icons.person_rounded)),
              Tab(text: "Payments", icon: Icon(Icons.payments_rounded)),
              Tab(text: "Academics", icon: Icon(Icons.school_rounded)),
            ],
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4F46E5), Color(0xFFF0F4F8)],
              begin: Alignment.topCenter,
              end: Alignment(0, -0.8),
            ),
          ),
          child: TabBarView(
            children: [
              _buildDetailsTab(),
              _buildPaymentsTab(),
              _buildAcademicsTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsTab() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildInfoCard(
          "Personal Information",
          Icons.badge_rounded,
          const Color(0xFF4F46E5),
          [
            "ID: ${_student!['unique_student_id']}",
            "Name: ${_student!['name']}",
            "Father's Name: ${_student!['father_name']}",
            "Mother's Name: ${_student!['mother_name']}",
            "Father's Mobile: ${_student!['father_mobile']}",
            if ((_student!['alternative_mobile'] as String?)?.isNotEmpty == true)
              "Alt Mobile: ${_student!['alternative_mobile']}",
          ],
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          "Academic Profile",
          Icons.import_contacts_rounded,
          const Color(0xFF0F766E), // Teal
          [
            "Current Class: ${_student!['current_class']}",
            if ((_student!['section'] as String?)?.isNotEmpty == true)
              "Section: ${_student!['section']}",
            "Status: ${_student!['status']}",
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentsTab() {
    if (_payments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_rounded, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text("No payment history for this student.", style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _payments.length,
      itemBuilder: (context, index) {
        final payment = _payments[index];
        final bool isPaid = payment['paid_status'] == 'paid';
        final bool isPartial = payment['paid_status'] == 'partial';
        
        final Color statusColor = isPaid 
            ? const Color(0xFF10B981) // Green
            : isPartial 
                ? const Color(0xFFF59E0B) // Amber
                : const Color(0xFFEF4444); // Red
                
        final IconData statusIcon = isPaid 
            ? Icons.check_circle_rounded 
            : isPartial
                ? Icons.timelapse_rounded
                : Icons.error_rounded;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
            ],
            border: Border.all(color: statusColor.withValues(alpha: 0.3)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: statusColor.withValues(alpha: 0.15),
              child: Icon(statusIcon, color: statusColor),
            ),
            title: Text("${payment['month']} ${payment['year']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B))),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text("Amount: ৳${payment['amount']}", style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor.withValues(alpha: 0.5)),
              ),
              child: Text(
                payment['paid_status'].toString().toUpperCase(), 
                style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
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
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatBox("Total\nExams", "${_stats!['total']}", const Color(0xFF3B82F6), Icons.assignment_rounded), // Blue
                _buildStatBox("Attended", "${_stats!['attended']}", const Color(0xFF10B981), Icons.how_to_reg_rounded), // Green
                _buildStatBox("Missed", "${_stats!['missed']}", const Color(0xFFEF4444), Icons.person_off_rounded), // Red
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
        const Padding(
          padding: EdgeInsets.only(left: 8, bottom: 12),
          child: Text("Exam Results", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        ),
        if (_marks.isEmpty) 
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Icon(Icons.analytics_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text("No exam results found for this student.", style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                ],
              ),
            ),
          )
        else
          ..._marks.map((mark) {
            double percent = mark['obtained_marks'] != null ? (mark['obtained_marks'] / mark['total_marks']) * 100 : 0.0;
            final isAbsent = mark['obtained_marks'] == null;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
                ],
                border: isAbsent ? Border.all(color: Colors.red.withValues(alpha: 0.3)) : null,
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                title: Text(mark['exam_name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text("Date: ${mark['exam_date']} • Class: ${mark['class_name']}", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      isAbsent ? "Absent" : "${mark['obtained_marks']} / ${mark['total_marks']}", 
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        fontSize: 15,
                        color: isAbsent ? const Color(0xFFEF4444) : const Color(0xFF4F46E5),
                      )
                    ),
                    if (!isAbsent) 
                      Text("${percent.toStringAsFixed(1)}%", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600, fontSize: 12)),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildInfoCard(String title, IconData icon, Color color, List<String> details) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 8),
                Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: details.map((d) {
                final parts = d.split(': ');
                if (parts.length != 2) return Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(d));
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 120,
                        child: Text(parts[0], style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                      ),
                      Expanded(
                        child: Text(parts[1], style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
