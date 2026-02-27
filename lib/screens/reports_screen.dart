import 'package:flutter/material.dart';
import '../database_helper.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int _totalStudents = 0;
  int _totalBatches = 0;
  int _totalExams = 0;
  double _totalRevenue = 0.0;
  int _totalPayments = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    final db = DatabaseHelper.instance;
    _totalStudents = await db.getTotalStudents();
    _totalBatches = await db.getTotalBatches();
    _totalExams = await db.getTotalExams();
    _totalRevenue = await db.getTotalRevenue();
    _totalPayments = await db.getTotalPayments();
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
            padding: const EdgeInsets.all(16.0),
            crossAxisSpacing: 16.0,
            mainAxisSpacing: 16.0,
            children: [
              _buildMetricCard("Active Students", _totalStudents.toString(), Icons.people, Colors.blue),
              _buildMetricCard("Active Batches", _totalBatches.toString(), Icons.class_, Colors.orange),
              _buildMetricCard("Total Exams", _totalExams.toString(), Icons.assignment, Colors.red),
              _buildMetricCard("Revenue (This Year)", "\$${_totalRevenue.toStringAsFixed(2)}", Icons.attach_money, Colors.green),
              _buildMetricCard("Payments (This Year)", _totalPayments.toString(), Icons.payment, Colors.teal),
            ],
          ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: color),
          const SizedBox(height: 16),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
