import 'package:flutter/material.dart';
import '../database_helper.dart';

const List<String> kCostCategories = [
  'Electricity', 'Rent', 'Housing', 'Development', 'Stationery', 'Internet', 'Cleaning', 'Other'
];

class CostManagementScreen extends StatefulWidget {
  const CostManagementScreen({super.key});

  @override
  State<CostManagementScreen> createState() => _CostManagementScreenState();
}

class _CostManagementScreenState extends State<CostManagementScreen> {
  List<Map<String, dynamic>> _costs = [];
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
    _loadCosts();
  }

  Future<void> _loadCosts() async {
    setState(() => _isLoading = true);
    final costs = await DatabaseHelper.instance.getCostsByMonth(_currentMonth, _currentYear);
    setState(() { _costs = costs.map((c) => Map<String, dynamic>.from(c)).toList(); _isLoading = false; });
  }

  void _showAddEditDialog({Map<String, dynamic>? cost}) {
    String selectedCategory = cost?['category'] as String? ?? kCostCategories.first;
    final nameCtrl = TextEditingController(text: cost?['name'] ?? '');
    final amountCtrl = TextEditingController(text: cost != null ? (cost['amount'] as num).toStringAsFixed(0) : '');
    final noteCtrl = TextEditingController(text: cost?['note'] ?? '');
    final isEdit = cost != null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit Cost Entry' : 'Add Cost Entry'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Category picker
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                items: kCostCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) { if (v != null) setDialogState(() => selectedCategory = v); },
              ),
              const SizedBox(height: 10),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name / Description *', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: amountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount (৳) *', border: OutlineInputBorder(), prefixText: '৳ ')),
              const SizedBox(height: 10),
              TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: 'Note (optional)', border: OutlineInputBorder()), maxLines: 2),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan.shade700, foregroundColor: Colors.white),
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                final amount = double.tryParse(amountCtrl.text) ?? 0.0;
                if (amount <= 0) return;
                final data = {
                  'category': selectedCategory,
                  'name': nameCtrl.text.trim(),
                  'amount': amount,
                  'month': _currentMonth,
                  'year': _currentYear,
                  'note': noteCtrl.text.trim(),
                };
                final db = DatabaseHelper.instance;
                if (isEdit && cost != null) {
                  await db.updateCost(cost['cost_id'] as int, data);
                } else {
                  await db.addCost(data);
                }
                if (ctx.mounted) Navigator.pop(ctx);
                _loadCosts();
              },
              child: Text(isEdit ? 'Update' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteCost(Map<String, dynamic> cost) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Entry'),
        content: Text('Delete "${cost['name']}" — ৳${cost['amount']}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) { await DatabaseHelper.instance.deleteCost(cost['cost_id'] as int); _loadCosts(); }
  }

  @override
  Widget build(BuildContext context) {
    final double totalThisMonth = _costs.fold(0.0, (s, c) => s + (c['amount'] as num).toDouble());

    // Category totals for summary
    final Map<String, double> catTotals = {};
    for (var c in _costs) {
      final cat = c['category'] as String;
      catTotals[cat] = (catTotals[cat] ?? 0) + (c['amount'] as num).toDouble();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text('Cost Management', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0F766E), // Teal
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Cost', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => _showAddEditDialog(),
      ),
      body: Column(
        children: [
          // ── Header Banner ──
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
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
                                  icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF0F766E)),
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                                  items: _months.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                                  onChanged: (v) { if (v != null) { setState(() => _currentMonth = v); _loadCosts(); } },
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
                                  icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF0F766E)),
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                                  items: _years.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                                  onChanged: (v) { if (v != null) { setState(() => _currentYear = v); _loadCosts(); } },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!_isLoading) ...[
                    const SizedBox(height: 20),
                    Column(
                      children: [
                        Text('Total: ৳${totalThisMonth.toStringAsFixed(0)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 12),
                        if (catTotals.isNotEmpty)
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: catTotals.entries.map((e) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                                ),
                                child: Text('${e.key}: ৳${e.value.toStringAsFixed(0)}',
                                  style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ]
                ],
              ),
            ),
          ),
          // ── Cost List ──
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F766E)))
                : _costs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long_rounded, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text('No costs recorded for $_currentMonth.', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text('Tap + to add one.', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 8, bottom: 80),
                        itemCount: _costs.length,
                        itemBuilder: (ctx, i) {
                          final cost = _costs[i];
                          final Color color = _categoryColor(cost['category'] as String);
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
                                backgroundColor: color.withValues(alpha: 0.15),
                                child: Icon(_categoryIcon(cost['category'] as String), color: color, size: 24),
                              ),
                              title: Text(cost['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B))),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  '${cost['category']}'
                                  '${(cost['note'] as String?)?.isNotEmpty == true ? ' • ${cost['note']}' : ''}',
                                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min, 
                                children: [
                                  Text(
                                    '৳${(cost['amount'] as num).toStringAsFixed(0)}',
                                    style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.edit_rounded, size: 20, color: Color(0xFF3B82F6)), 
                                    onPressed: () => _showAddEditDialog(cost: cost),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Color(0xFFEF4444)), 
                                    onPressed: () => _deleteCost(cost),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'Electricity': return Colors.amber.shade700;
      case 'Rent': return Colors.red.shade600;
      case 'Housing': return Colors.brown.shade600;
      case 'Development': return Colors.blue.shade700;
      case 'Stationery': return Colors.green.shade700;
      case 'Internet': return Colors.purple.shade600;
      case 'Cleaning': return Colors.teal;
      default: return Colors.grey.shade700;
    }
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Electricity': return Icons.electric_bolt;
      case 'Rent': return Icons.home_work;
      case 'Housing': return Icons.house;
      case 'Development': return Icons.construction;
      case 'Stationery': return Icons.edit_note;
      case 'Internet': return Icons.wifi;
      case 'Cleaning': return Icons.cleaning_services;
      default: return Icons.receipt_long;
    }
  }
}
