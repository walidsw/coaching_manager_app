import 'package:flutter/material.dart';
import '../database_helper.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _isLoading = true;

  // All Time Stats
  int _totalStudents = 0;
  int _totalBatches = 0;

  // This Month Stats
  double _tutorFee = 0.0;
  double _earned = 0.0;
  double _cost = 0.0;
  double _due = 0.0;
  double _netRev = 0.0;
  int _newStudents = 0;

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    final db = DatabaseHelper.instance;

    _totalStudents = await db.getTotalStudents();
    _totalBatches = await db.getTotalBatches();

    _tutorFee = await db.getTotalTutorFeeThisMonth();
    _earned = await db.getTotalEarnedThisMonth();
    _cost = await db.getTotalCostThisMonth();
    _due = await db.getTotalDueThisMonth();
    _netRev = await db.getNetRevenueThisMonth();
    _newStudents = await db.getNewStudentsThisMonth();

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text('Analytics & Reports', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadMetrics,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Net Revenue Banner
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _netRev >= 0 
                            ? [Colors.teal.shade500, Colors.teal.shade800]
                            : [Colors.red.shade400, Colors.red.shade700],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: (_netRev >= 0 ? Colors.teal : Colors.red).withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "THIS MONTH'S NET REVENUE",
                          style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '৳${_netRev.toStringAsFixed(0)}',
                          style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: 1),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(_netRev >= 0 ? Icons.trending_up : Icons.trending_down, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              _netRev >= 0 ? 'Profitable' : 'Taking a Loss',
                              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Section Title
                  const Padding(
                    padding: EdgeInsets.only(left: 8, bottom: 12),
                    child: Text('FINANCIAL BREAKDOWN (THIS MONTH)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey, letterSpacing: 1.2)),
                  ),

                  // Financial Grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.3,
                    children: [
                      _metricCard('Earned', '৳${_earned.toStringAsFixed(0)}', Icons.account_balance_wallet, Colors.green),
                      _metricCard('Due Pending', '৳${_due.toStringAsFixed(0)}', Icons.warning_amber_rounded, Colors.orange),
                      _metricCard('Tutor Fees', '৳${_tutorFee.toStringAsFixed(0)}', Icons.group, Colors.indigo),
                      _metricCard('Other Costs', '৳${_cost.toStringAsFixed(0)}', Icons.receipt_long, Colors.red),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Section Title
                  const Padding(
                    padding: EdgeInsets.only(left: 8, bottom: 12),
                    child: Text('GROWTH & OVERVIEW', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey, letterSpacing: 1.2)),
                  ),

                  // Growth Grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                    children: [
                      _smallMetricCard('New\nStudents', '+$_newStudents', Icons.person_add, Colors.purple),
                      _smallMetricCard('Total\nStudents', '$_totalStudents', Icons.people, Colors.blue),
                      _smallMetricCard('Active\nBatches', '$_totalBatches', Icons.class_, Colors.teal),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _metricCard(String title, String mainValue, IconData icon, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.blueGrey.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: color.shade50, borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, size: 18, color: color.shade600),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            mainValue,
            style: TextStyle(color: Colors.blueGrey.shade900, fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _smallMetricCard(String title, String value, IconData icon, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.blueGrey.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 28, color: color.shade400),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(color: Colors.blueGrey.shade900, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 11, height: 1.2),
          ),
        ],
      ),
    );
  }
}
