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

  final String _currentMonth = _getConstMonth(DateTime.now().month);
  final String _currentYear = DateTime.now().year.toString();

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
    
    // Attach payment status
    List<Map<String, dynamic>> enrichedStudents = [];
    final fee = await db.getClassFee(_selectedClass!);
    
    for (var s in students) {
      final payments = await db.getPaymentsForStudent(s['unique_student_id']);
      bool isPaid = false;
      for (var p in payments) {
        if (p['month'] == _currentMonth && p['year'] == _currentYear && p['paid_status'] == 'paid') {
          isPaid = true;
          break;
        }
      }
      
      enrichedStudents.add({
        ...s,
        'is_paid': isPaid,
        'fee_amount': fee,
      });
    }

    setState(() {
      _students = enrichedStudents;
      _isLoading = false;
    });
  }

  Future<void> _togglePayment(Map<String, dynamic> student) async {
    final uid = student['unique_student_id'];
    final fee = student['fee_amount'];
    final bool currentlyPaid = student['is_paid'];
    final String newStatus = currentlyPaid ? 'unpaid' : 'paid';

    await DatabaseHelper.instance.addPayment(uid, _selectedClass!, _currentMonth, _currentYear, fee, paidStatus: newStatus);
    _loadStudentsForClass(); // Refresh
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Make Payment'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
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
                        _loadStudentsForClass();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Month: $_currentMonth $_currentYear", style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _students.isEmpty 
                  ? const Center(child: Text('No active students found in this class.'))
                  : ListView.builder(
                      itemCount: _students.length,
                      itemBuilder: (context, index) {
                        final student = _students[index];
                        final bool isPaid = student['is_paid'];
                        return ListTile(
                          title: Text("${student['name']} (${student['unique_student_id']})"),
                          subtitle: Text("Fee: \$${student['fee_amount']}"),
                          trailing: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isPaid ? Colors.grey : Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => _togglePayment(student),
                            child: Text(isPaid ? "Mark Unpaid" : "Pay Now"),
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
