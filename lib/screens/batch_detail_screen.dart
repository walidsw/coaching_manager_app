import 'package:flutter/material.dart';
import '../database_helper.dart';
import 'student_detail_screen.dart';
import 'class_management_screen.dart';

class BatchDetailScreen extends StatefulWidget {
  final String className;
  final double monthlyFee;

  const BatchDetailScreen({
    super.key,
    required this.className,
    required this.monthlyFee,
  });

  @override
  State<BatchDetailScreen> createState() => _BatchDetailScreenState();
}

class _BatchDetailScreenState extends State<BatchDetailScreen> {
  List<Map<String, dynamic>> _students = [];
  bool _isLoading = true;

  // Batch stats
  int _totalStudents = 0;
  int _paidCount = 0;
  double _avgMarksPercent = 0.0;
  double _totalDue = 0.0;

  final String _currentMonth = _getMonth(DateTime.now().month);
  final String _currentYear = DateTime.now().year.toString();

  static String _getMonth(int m) {
    const months = ["January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"];
    return months[m - 1];
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final db = DatabaseHelper.instance;

    final rawStudents = await db.getStudentsByClass(widget.className);

    List<Map<String, dynamic>> enriched = [];
    double totalPercent = 0.0;
    int marksCount = 0;
    int paidCount = 0;
    double totalDue = 0.0;

    for (var s in rawStudents) {
      final uid = s['unique_student_id'] as String;

      // Payment status this month
      final payments = await db.getPaymentsForStudent(uid);
      double paidAmount = 0.0;
      for (var p in payments) {
        if (p['month'] == _currentMonth && p['year'] == _currentYear) {
          paidAmount = (p['amount'] as num).toDouble();
          break;
        }
      }
      final double due = widget.monthlyFee - paidAmount;
      final bool isPaid = due <= 0;
      if (isPaid) paidCount++;
      totalDue += due > 0 ? due : 0;

      // Academic: avg percentage across all exams
      final marks = await db.getMarksForStudent(uid);
      double studentAvg = 0.0;
      if (marks.isNotEmpty) {
        double sum = 0;
        for (var m in marks) {
          if (m['obtained_marks'] != null && m['total_marks'] != null) {
            sum += ((m['obtained_marks'] as num).toDouble() /
                (m['total_marks'] as num).toDouble()) * 100;
          }
        }
        studentAvg = sum / marks.length;
        totalPercent += studentAvg;
        marksCount++;
      }

      enriched.add({
        ...Map<String, dynamic>.from(s),
        'paid_amount': paidAmount,
        'due': due > 0 ? due : 0.0,
        'is_paid': isPaid,
        'avg_percent': studentAvg,
        'exams_taken': marks.length,
      });
    }

    setState(() {
      _students = enriched;
      _totalStudents = enriched.length;
      _paidCount = paidCount;
      _avgMarksPercent = marksCount > 0 ? totalPercent / marksCount : 0.0;
      _totalDue = totalDue;
      _isLoading = false;
    });
  }

  Future<void> _confirmRemoveStudent(Map<String, dynamic> student) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Student'),
        content: Text(
          'Are you sure you want to remove "${student['name']}" from ${widget.className}?\n\nThis will mark the student as inactive (not deleted).'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DatabaseHelper.instance.updateStudent(student['unique_student_id'], {'status': 'inactive'});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${student['name']} removed from ${widget.className}')),
        );
      }
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: Text(widget.className, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Fee Settings',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ClassManagementScreen(
                  className: widget.className,
                  initialFee: widget.monthlyFee,
                ),
              ),
            ).then((_) => _loadData()),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ── Header Banner ──
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
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
                    child: _buildStatsBanner(),
                  ),
                ),
                // ── List Header ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    children: [
                      Text(
                        'Students ($_totalStudents)',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E293B)),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)],
                        ),
                        child: Text(
                          '$_currentMonth $_currentYear',
                          style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                // ── Student List ──
                Expanded(
                  child: _students.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.group_off, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text('No active students in this batch.', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          itemCount: _students.length,
                          itemBuilder: (ctx, i) => _buildStudentCard(_students[i]),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatsBanner() {
    final paymentRate = _totalStudents > 0
        ? (_paidCount / _totalStudents * 100).toStringAsFixed(0)
        : '0';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _statBox(Icons.people_alt_rounded, '$_totalStudents', 'Students', const Color(0xFF3B82F6)),
          _statBox(Icons.check_circle_rounded, '$_paidCount / $_totalStudents\n($paymentRate%)', 'Paid', const Color(0xFF10B981)),
          _statBox(Icons.money_off_rounded, '৳${_totalDue.toStringAsFixed(0)}', 'Total Due', const Color(0xFFEF4444)),
          _statBox(Icons.leaderboard_rounded, '${_avgMarksPercent.toStringAsFixed(1)}%', 'Avg Score', const Color(0xFF8B5CF6)),
        ],
      ),
    );
  }

  Widget _statBox(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(value, textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color, height: 1.2)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
    final bool isPaid = student['is_paid'] as bool;
    final double due = student['due'] as double;
    final double avgPercent = student['avg_percent'] as double;
    final int examsTaken = student['exams_taken'] as int;

    Color paymentColor = isPaid ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    String paymentLabel = isPaid ? 'Paid' : 'Due: ৳${due.toStringAsFixed(0)}';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: paymentColor.withValues(alpha: 0.15),
              child: Icon(
                isPaid ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                color: paymentColor,
                size: 28,
              ),
            ),
            title: Text(
              "${student['name']} (${student['unique_student_id']})",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: paymentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: paymentColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(paymentLabel,
                        style: TextStyle(fontSize: 12, color: paymentColor, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 6),
                  if (examsTaken > 0)
                    Text(
                      'Avg: ${avgPercent.toStringAsFixed(1)}% ($examsTaken exams)',
                      style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                    )
                  else
                    const Text('No exams yet', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            isThreeLine: true,
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.info_outline_rounded, color: Color(0xFF3B82F6), size: 22),
                  tooltip: 'View Profile',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StudentDetailScreen(studentId: student['unique_student_id']),
                    ),
                  ).then((_) => _loadData()),
                ),
                IconButton(
                  icon: const Icon(Icons.person_remove_rounded, color: Color(0xFFEF4444), size: 22),
                  tooltip: 'Remove from batch',
                  onPressed: () => _confirmRemoveStudent(student),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
