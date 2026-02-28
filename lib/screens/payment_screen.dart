import 'package:flutter/material.dart';
import '../database_helper.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String? _selectedClass;
  List<String> _classes = [];
  List<Map<String, dynamic>> _students = [];
  bool _isLoading = true;

  String _currentMonth = _getConstMonth(DateTime.now().month);
  String _currentYear = DateTime.now().year.toString();

  final List<String> _months = [
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December"
  ];

  final List<String> _years = List.generate(10, (index) => (DateTime.now().year - 5 + index).toString());

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  static String _getConstMonth(int monthIndex) {
    const months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
    return months[monthIndex - 1];
  }

  Future<void> _loadClasses() async {
    final c = await DatabaseHelper.instance.getClasses();
    setState(() {
      _classes = c.map((e) => e['class_name'] as String).toList();
      if (_classes.isNotEmpty) {
        _selectedClass = _classes.first;
        _loadStudentsForClass();
      } else {
        _isLoading = false;
      }
    });
  }

  Future<void> _loadStudentsForClass() async {
    if (_selectedClass == null) return;
    setState(() => _isLoading = true);

    final db = DatabaseHelper.instance;
    final students = await db.getStudentsByClass(_selectedClass!);
    final fee = await db.getClassFee(_selectedClass!);

    List<Map<String, dynamic>> enrichedStudents = [];

    for (var s in students) {
      final payments = await db.getPaymentsForStudent(s['unique_student_id']);

      double paidAmount = 0.0;

      for (var p in payments) {
        if (p['month'] == _currentMonth && p['year'] == _currentYear) {
          paidAmount = (p['amount'] as num).toDouble();
          break;
        }
      }

      final double dueAmount = fee - paidAmount;
      // Derive display status from actual due, not DB string (avoids stale status bugs)
      final String displayStatus = (dueAmount <= 0)
          ? 'paid'
          : (paidAmount > 0)
              ? 'partial'
              : 'unpaid';

      enrichedStudents.add({
        ...Map<String, dynamic>.from(s),
        'status': displayStatus,
        'paid_amount': paidAmount,
        'fee_amount': fee,
        'due_amount': dueAmount <= 0 ? 0.0 : dueAmount,
      });
    } // end for

    setState(() {
      _students = enrichedStudents;
      _isLoading = false;
    });
  }

  Future<void> _showPaymentDialog(Map<String, dynamic> student) async {
    final double feeAmount = student['fee_amount'] as double;
    final double paidSoFar = student['paid_amount'] as double;
    final double remaining = feeAmount - paidSoFar;
    final amountController = TextEditingController(text: remaining.toStringAsFixed(2));
    String? errorText;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Text('Record Payment for ${student['name']}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Monthly Fee: ৳$feeAmount', style: const TextStyle(fontWeight: FontWeight.bold)),
                if (paidSoFar > 0)
                  Text('Already Paid: ৳$paidSoFar', style: const TextStyle(color: Colors.orange)),
                Text('Remaining Due: ৳$remaining', style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Amount Paying Now (৳)',
                    border: const OutlineInputBorder(),
                    errorText: errorText,
                    prefixText: '৳ ',
                  ),
                  onChanged: (val) {
                    setDialogState(() => errorText = null);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  // If empty, default to the full remaining amount
                  final double entered = amountController.text.trim().isEmpty
                      ? remaining
                      : (double.tryParse(amountController.text) ?? -1);
                  if (entered <= 0) {
                    setDialogState(() => errorText = 'Enter a valid amount');
                    return;
                  }
                  if (entered > remaining + 0.001) {
                    setDialogState(() => errorText = 'Cannot exceed remaining due (৳$remaining)');
                    return;
                  }

                  final totalPaid = paidSoFar + entered;
                  final newStatus = (totalPaid >= feeAmount - 0.001) ? 'paid' : 'partial';

                  await DatabaseHelper.instance.addPayment(
                    student['unique_student_id'],
                    _selectedClass!,
                    _currentMonth,
                    _currentYear,
                    totalPaid,
                    paidStatus: newStatus,
                  );

                  if (ctx.mounted) Navigator.pop(ctx);
                  _loadStudentsForClass();
                },
                child: const Text('Confirm Payment'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _markUnpaid(Map<String, dynamic> student) async {
    await DatabaseHelper.instance.addPayment(
      student['unique_student_id'],
      _selectedClass!,
      _currentMonth,
      _currentYear,
      0.0,
      paidStatus: 'unpaid',
    );
    _loadStudentsForClass();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text('Make Payment', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFF59E0B), // Amber/Orange
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
                colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
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
                child: Column(
                  children: [
                    // Class selector
                    Row(
                      children: [
                        const Icon(Icons.class_, color: Color(0xFFF59E0B), size: 20),
                        const SizedBox(width: 8),
                        const Text("Class:", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: _selectedClass,
                              icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFFF59E0B)),
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
                        ),
                      ],
                    ),
                    const Divider(height: 24, thickness: 1, color: Color(0xFFF1F5F9)),
                    // Month / Year selector
                    Row(
                      children: [
                        const Icon(Icons.calendar_month, color: Color(0xFFF59E0B), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: _currentMonth,
                              icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFFF59E0B)),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                              items: _months.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _currentMonth = val);
                                  _loadStudentsForClass();
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: _currentYear,
                              icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFFF59E0B)),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                              items: _years.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _currentYear = val);
                                  _loadStudentsForClass();
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFF59E0B)))
                : _students.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.payment, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text('No active students found in this class.', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.only(top: 8),
                              itemCount: _students.length,
                              itemBuilder: (context, index) {
                                final student = _students[index];
                                final String status = student['status'] as String;
                                final double feeAmount = student['fee_amount'] as double;
                                final double paidAmount = student['paid_amount'] as double;
                                final double dueAmount = student['due_amount'] as double;

                                Color statusColor;
                                String subtitleText;

                                if (status == 'paid') {
                                  statusColor = const Color(0xFF10B981); // Emerald
                                  subtitleText = 'Fee: ৳${feeAmount.toStringAsFixed(0)} | Paid: ৳${paidAmount.toStringAsFixed(0)}';
                                } else if (status == 'partial') {
                                  statusColor = const Color(0xFFF59E0B); // Amber
                                  subtitleText = 'Fee: ৳${feeAmount.toStringAsFixed(0)} | Paid: ৳${paidAmount.toStringAsFixed(0)} | Due: ৳${dueAmount.toStringAsFixed(0)}';
                                } else {
                                  statusColor = const Color(0xFFEF4444); // Red
                                  subtitleText = 'Fee: ৳${feeAmount.toStringAsFixed(0)} | Due: ৳${dueAmount.toStringAsFixed(0)}';
                                }

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
                                      backgroundColor: statusColor.withValues(alpha: 0.15),
                                      child: Icon(
                                        status == 'paid' ? Icons.check_circle_rounded : status == 'partial' ? Icons.hourglass_bottom_rounded : Icons.cancel_rounded,
                                        color: statusColor,
                                        size: 28,
                                      ),
                                    ),
                                    title: Text(
                                      "${student['name']} (${student['unique_student_id']})",
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(subtitleText, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
                                    ),
                                    trailing: status == 'paid'
                                        ? TextButton(
                                            onPressed: () => _markUnpaid(student),
                                            style: TextButton.styleFrom(
                                              foregroundColor: Colors.grey.shade600,
                                            ),
                                            child: const Text('Undo', style: TextStyle(fontWeight: FontWeight.bold)),
                                          )
                                        : ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: statusColor,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                            ),
                                            onPressed: () => _showPaymentDialog(student),
                                            child: Text(status == 'partial' ? 'Pay More' : 'Pay Now', style: const TextStyle(fontWeight: FontWeight.bold)),
                                          ),
                                  ),
                                );
                              },
                            ),
                          ),
                          _buildSummaryCard(),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final int totalStudents = _students.length;
    final int noDue = _students.where((s) => (s['status'] as String) == 'paid').length;
    final int hasDue = totalStudents - noDue;
    final double totalEarned = _students.fold(0.0, (sum, s) => sum + (s['paid_amount'] as double));
    final double totalDue = _students.fold(0.0, (sum, s) => sum + (s['due_amount'] as double));

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: const Color(0xFFF59E0B).withValues(alpha: 0.15), blurRadius: 16, offset: const Offset(0, 4)),
        ],
        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_rounded, color: Color(0xFFF59E0B), size: 20),
              const SizedBox(width: 8),
              Text(
                'Class Summary — $_currentMonth $_currentYear',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFFD97706)), // Amber-600
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _summaryTile(Icons.check_circle_rounded, 'No Due', '$noDue students', const Color(0xFF10B981)),
              const SizedBox(width: 12),
              _summaryTile(Icons.cancel_rounded, 'Have Due', '$hasDue students', const Color(0xFFEF4444)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _summaryTile(Icons.payments_rounded, 'Total Earned', '৳${totalEarned.toStringAsFixed(0)}', const Color(0xFF3B82F6)),
              const SizedBox(width: 12),
              _summaryTile(Icons.money_off_rounded, 'Total Due', '৳${totalDue.toStringAsFixed(0)}', const Color(0xFFF59E0B)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryTile(IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
