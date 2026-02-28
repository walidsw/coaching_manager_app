import 'package:flutter/material.dart';
import '../database_helper.dart';

class TeacherManagementScreen extends StatefulWidget {
  const TeacherManagementScreen({super.key});

  @override
  State<TeacherManagementScreen> createState() => _TeacherManagementScreenState();
}

class _TeacherManagementScreenState extends State<TeacherManagementScreen> {
  List<Map<String, dynamic>> _teachers = [];
  bool _isLoading = true;

  final List<String> _months = ["January","February","March","April","May","June",
    "July","August","September","October","November","December"];
  late String _currentMonth;
  late String _currentYear;
  final List<String> _years = List.generate(5, (i) => (DateTime.now().year - 2 + i).toString());

  @override
  void initState() {
    super.initState();
    _currentMonth = _months[DateTime.now().month - 1];
    _currentYear = DateTime.now().year.toString();
    _loadTeachers();
  }

  Future<void> _loadTeachers() async {
    setState(() => _isLoading = true);
    final db = DatabaseHelper.instance;
    final rawTeachers = await db.getTeachers();
    List<Map<String, dynamic>> enriched = [];
    for (var t in rawTeachers) {
      final tid = t['teacher_id'] as int;
      final salary = await db.getSalaryRecord(tid, _currentMonth, _currentYear);
      final String salaryStatus;
      final double paidAmount = salary != null ? (salary['amount_paid'] as num).toDouble() : 0.0;
      final double monthlySalary = (t['monthly_salary'] as num).toDouble();
      final double due = monthlySalary - paidAmount;
      salaryStatus = paidAmount >= monthlySalary ? 'paid' : paidAmount > 0 ? 'partial' : 'unpaid';
      enriched.add({
        ...Map<String, dynamic>.from(t),
        'paid_amount': paidAmount,
        'salary_status': salaryStatus,
        'due': due > 0 ? due : 0.0,
      });
    }
    setState(() { _teachers = enriched; _isLoading = false; });
  }

  void _showTeacherDetails(Map<String, dynamic> teacher) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.indigo.shade50,
              child: const Icon(Icons.person, color: Colors.indigo),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(teacher['name'] ?? 'Teacher Details', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow(Icons.book_outlined, 'Subject', teacher['subject'] ?? 'N/A'),
              const Divider(height: 16),
              _detailRow(Icons.phone_outlined, 'Phone', teacher['phone'] ?? 'N/A'),
              const Divider(height: 16),
              _detailRow(Icons.account_balance_wallet_outlined, 'Monthly Salary', '৳${(teacher['monthly_salary'] as num).toStringAsFixed(0)}'),
              const Divider(height: 16),
              _detailRow(Icons.payments_outlined, 'Total Paid ($_currentMonth $_currentYear)', '৳${(teacher['paid_amount'] as num).toStringAsFixed(0)}', color: Colors.green.shade700),
              const Divider(height: 16),
              _detailRow(Icons.money_off_csred_outlined, 'Remaining Due', '৳${(teacher['due'] as num).toStringAsFixed(0)}', color: (teacher['due'] as num) > 0 ? Colors.red.shade700 : Colors.green.shade700),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade500),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(
                  fontSize: 15, 
                  fontWeight: FontWeight.w600, 
                  color: color ?? Colors.black87,
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddEditDialog({Map<String, dynamic>? teacher}) {
    final nameCtrl = TextEditingController(text: teacher?['name'] ?? '');
    final subjectCtrl = TextEditingController(text: teacher?['subject'] ?? '');
    final phoneCtrl = TextEditingController(text: teacher?['phone'] ?? '');
    final salaryCtrl = TextEditingController(text: teacher != null ? (teacher['monthly_salary'] as num).toStringAsFixed(0) : '');
    final isEdit = teacher != null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Edit Teacher' : 'Add Teacher'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name *', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: subjectCtrl, decoration: const InputDecoration(labelText: 'Subject', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: salaryCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Monthly Salary (৳) *', border: OutlineInputBorder(), prefixText: '৳ ')),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade700, foregroundColor: Colors.white),
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              final salary = double.tryParse(salaryCtrl.text) ?? 0.0;
              final data = {
                'name': nameCtrl.text.trim(),
                'subject': subjectCtrl.text.trim(),
                'phone': phoneCtrl.text.trim(),
                'monthly_salary': salary,
                'status': 'active',
              };
              if (isEdit) {
                await DatabaseHelper.instance.updateTeacher(teacher['teacher_id'] as int, data);
              } else {
                await DatabaseHelper.instance.addTeacher(data);
              }
              if (ctx.mounted) Navigator.pop(ctx);
              _loadTeachers();
            },
            child: Text(isEdit ? 'Update' : 'Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _showSalaryDialog(Map<String, dynamic> teacher) async {
    final double monthlySalary = (teacher['monthly_salary'] as num).toDouble();
    final double due = teacher['due'] as double;
    final amountCtrl = TextEditingController();
    String? errorText;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Salary — ${teacher['name']}'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            _salaryInfoRow('Monthly Salary', '৳${monthlySalary.toStringAsFixed(0)}', Colors.black87),
            _salaryInfoRow('Paid So Far', '৳${(teacher['paid_amount'] as double).toStringAsFixed(0)}', Colors.green),
            _salaryInfoRow('Remaining Due', '৳${due.toStringAsFixed(0)}', Colors.red),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount Paying Now (৳)',
                border: const OutlineInputBorder(),
                prefixText: '৳ ',
                errorText: errorText,
              ),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade700, foregroundColor: Colors.white),
              onPressed: () async {
                final double paying = amountCtrl.text.trim().isEmpty ? due : (double.tryParse(amountCtrl.text) ?? -1);
                if (paying <= 0) { setDialogState(() => errorText = 'Enter a valid amount'); return; }
                final double totalPaid = (teacher['paid_amount'] as double) + paying;
                final String status = totalPaid >= monthlySalary ? 'paid' : 'partial';
                await DatabaseHelper.instance.upsertSalaryPayment(
                  teacher['teacher_id'] as int, _currentMonth, _currentYear, totalPaid, status);
                if (ctx.mounted) Navigator.pop(ctx);
                _loadTeachers();
              },
              child: const Text('Confirm Payment'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _salaryInfoRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Future<void> _confirmRemove(Map<String, dynamic> teacher) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Teacher'),
        content: Text('Remove "${teacher['name']}" from active staff?'),
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
    if (ok == true) {
      await DatabaseHelper.instance.deleteTeacher(teacher['teacher_id'] as int);
      _loadTeachers();
    }
  }

  @override
  Widget build(BuildContext context) {
    final int paidCount = _teachers.where((t) => t['salary_status'] == 'paid').length;
    final double totalDue = _teachers.fold(0.0, (s, t) => s + (t['due'] as double));
    final double totalSalary = _teachers.fold(0.0, (s, t) => s + (t['monthly_salary'] as num).toDouble());

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text('Teacher Management', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFF59E0B), // Amber
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFF59E0B),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Add Teacher', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => _showAddEditDialog(),
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
              child: Column(
                children: [
                  Container(
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
                              const Text('Month:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 13)),
                              DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: _currentMonth,
                                  icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFFF59E0B)),
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                                  items: _months.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                                  onChanged: (v) { if (v != null) { setState(() => _currentMonth = v); _loadTeachers(); } },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Year:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 13)),
                              DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: _currentYear,
                                  icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFFF59E0B)),
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                                  items: _years.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                                  onChanged: (v) { if (v != null) { setState(() => _currentYear = v); _loadTeachers(); } },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!_isLoading && _teachers.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _statBox(Icons.people_rounded, '${_teachers.length}', 'Teachers', Colors.white),
                        _statBox(Icons.check_circle_rounded, '$paidCount/${_teachers.length}', 'Paid', Colors.greenAccent),
                        _statBox(Icons.money_off_rounded, '৳${totalDue.toStringAsFixed(0)}', 'Total Due', Colors.redAccent.shade100),
                        _statBox(Icons.account_balance_wallet_rounded, '৳${totalSalary.toStringAsFixed(0)}', 'Total Salary', Colors.white),
                      ],
                    ),
                  ]
                ],
              ),
            ),
          ),
          // ── Teacher List ──
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFF59E0B)))
                : _teachers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_off_rounded, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text('No active teachers.', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text('Tap + to add one.', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 8, bottom: 80),
                        itemCount: _teachers.length,
                        itemBuilder: (ctx, i) {
                          final t = _teachers[i];
                          final String status = t['salary_status'] as String;
                          final Color statusColor = status == 'paid' ? const Color(0xFF10B981) : status == 'partial' ? const Color(0xFFF59E0B) : const Color(0xFFEF4444);
                          
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
                                    backgroundColor: statusColor.withValues(alpha: 0.15),
                                    child: Text(
                                      (t['name'] as String).isNotEmpty ? (t['name'] as String)[0].toUpperCase() : 'T',
                                      style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 18),
                                    ),
                                  ),
                                  title: Text(t['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B))),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text('${t['subject'] ?? 'N/A'} • ${t['phone'] ?? ''}', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: statusColor.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                                        ),
                                        child: Text(
                                          status == 'paid' ? 'Salary Paid' : status == 'partial' ? 'Partial — Due: ৳${(t['due'] as double).toStringAsFixed(0)}' : 'Due: ৳${(t['monthly_salary'] as num).toStringAsFixed(0)}',
                                          style: TextStyle(fontSize: 12, color: statusColor, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ],
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
                                        icon: const Icon(Icons.info_outline_rounded, color: Color(0xFF6366F1), size: 22), 
                                        tooltip: 'Details', 
                                        onPressed: () => _showTeacherDetails(t)
                                      ),
                                      if (status != 'paid')
                                        IconButton(
                                          icon: const Icon(Icons.payments_rounded, color: Color(0xFFF59E0B), size: 22), 
                                          tooltip: 'Pay Salary', 
                                          onPressed: () => _showSalaryDialog(t)
                                        ),
                                      IconButton(
                                        icon: const Icon(Icons.edit_rounded, color: Color(0xFF3B82F6), size: 22), 
                                        tooltip: 'Edit', 
                                        onPressed: () => _showAddEditDialog(teacher: t)
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.person_remove_rounded, color: Color(0xFFEF4444), size: 22), 
                                        tooltip: 'Remove', 
                                        onPressed: () => _confirmRemove(t)
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _statBox(IconData icon, String value, String label, Color iconColor) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.8))),
      ],
    );
  }
}
