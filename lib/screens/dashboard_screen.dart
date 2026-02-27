import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import 'batch_list_screen.dart';
import 'add_student_screen.dart';
import 'student_search_screen.dart';
import 'payment_screen.dart';
import 'exam_list_screen.dart';
import 'reports_screen.dart';
import 'promotion_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Coaching Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _navigateTo(context, const SettingsScreen()),
            tooltip: 'Settings',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Provider.of<AppState>(context, listen: false).logout();
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: GridView.count(
        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
        padding: const EdgeInsets.all(16.0),
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        children: [
          _buildCard(context, Icons.person_add, 'Add Student', Colors.blue, () => _navigateTo(context, const AddStudentScreen())),
          _buildCard(context, Icons.search, 'Search Student', Colors.purple, () => _navigateTo(context, const SearchStudentScreen())),
          _buildCard(context, Icons.class_, 'Manage Batches', Colors.green, () => _navigateTo(context, const BatchListScreen())),
          _buildCard(context, Icons.payment, 'Payments', Colors.orange, () => _navigateTo(context, const PaymentScreen())),
          _buildCard(context, Icons.assignment, 'Exams & Marks', Colors.red, () => _navigateTo(context, const ExamListScreen())),
          _buildCard(context, Icons.trending_up, 'Promotion', Colors.deepPurple, () => _navigateTo(context, const PromotionScreen())),
          _buildCard(context, Icons.bar_chart, 'Reports', Colors.teal, () => _navigateTo(context, const ReportsScreen())),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, IconData icon, String title, Color color, VoidCallback onTap) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: color),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
