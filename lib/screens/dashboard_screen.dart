import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../database_helper.dart';
import 'batch_list_screen.dart';
import 'add_student_screen.dart';
import 'student_search_screen.dart';
import 'payment_screen.dart';
import 'exam_list_screen.dart';
import 'reports_screen.dart';
import 'promotion_screen.dart';
import 'settings_screen.dart';
import 'teacher_management_screen.dart';
import 'cost_management_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _totalStudents = 0;
  int _totalBatches = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final db = DatabaseHelper.instance;
    final totalStudents = await db.getTotalStudents();
    final totalBatches = await db.getTotalBatches();
    setState(() {
      _totalStudents = totalStudents;
      _totalBatches = totalBatches;
    });
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen))
        .then((_) => _loadStats());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Gradient Header ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: title + actions
                  Row(
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Coaching Manager', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                          Text('Admin Dashboard', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.settings, color: Colors.white),
                        onPressed: () => _navigateTo(context, const SettingsScreen()),
                        tooltip: 'Settings',
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout, color: Colors.white),
                        onPressed: () => Provider.of<AppState>(context, listen: false).logout(),
                        tooltip: 'Logout',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Quick Stats Row
                  Row(
                    children: [
                      _headerStat(_totalStudents.toString(), 'Students', Icons.people),
                      const SizedBox(width: 12),
                      _headerStat(_totalBatches.toString(), 'Batches', Icons.class_),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Feature Grid ──
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.15,
                children: [
                  _buildCard(context, Icons.person_add, 'Add Student',   const Color(0xFF1565C0), const Color(0xFF42A5F5), 'assets/images/cards/add_student.png', () => _navigateTo(context, const AddStudentScreen())),
                  _buildCard(context, Icons.search,      'Search Student', const Color(0xFF6A1B9A), const Color(0xFFAB47BC), 'assets/images/cards/search_student.png', () => _navigateTo(context, const SearchStudentScreen())),
                  _buildCard(context, Icons.class_,      'Manage Batches', const Color(0xFF2E7D32), const Color(0xFF66BB6A), 'assets/images/cards/manage_batches.png', () => _navigateTo(context, const BatchListScreen())),
                  _buildCard(context, Icons.payment,     'Payments',       const Color(0xFFE65100), const Color(0xFFFFA726), 'assets/images/cards/payments.png', () => _navigateTo(context, const PaymentScreen())),
                  _buildCard(context, Icons.assignment,  'Exams & Marks',  const Color(0xFFC62828), const Color(0xFFEF5350), 'assets/images/cards/exams.png', () => _navigateTo(context, const ExamListScreen())),
                  _buildCard(context, Icons.trending_up, 'Promotion',      const Color(0xFF4527A0), const Color(0xFF7E57C2), 'assets/images/cards/promotion.png', () => _navigateTo(context, const PromotionScreen())),
                  _buildCard(context, Icons.bar_chart,   'Reports',        const Color(0xFF00695C), const Color(0xFF26A69A), 'assets/images/cards/reports.png', () => _navigateTo(context, const ReportsScreen())),
                  _buildCard(context, Icons.school,      'Teachers',       const Color(0xFF827717), const Color(0xFFD4E157), 'assets/images/cards/teachers.png', () => _navigateTo(context, const TeacherManagementScreen())),
                  _buildCard(context, Icons.receipt_long,'Costs',          const Color(0xFF00838F), const Color(0xFF26C6DA), 'assets/images/cards/costs.png', () => _navigateTo(context, const CostManagementScreen())),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerStat(String value, String label, IconData icon) {
    return Expanded(
      child: Container(
        height: 60, // Fixed height to ensure all boxes are perfectly uniform
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, IconData icon, String title, Color dark, Color light, String? imagePath, VoidCallback onTap) {
    return Material(
      borderRadius: BorderRadius.circular(18),
      elevation: 3,
      shadowColor: dark.withValues(alpha: 0.4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [dark, light], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            // Decorative 3D background image
            if (imagePath != null)
              Positioned(
                right: -15,
                bottom: -15,
                child: Image.asset(
                  imagePath,
                  width: 110,
                  height: 110,
                  fit: BoxFit.cover,
                ),
              ),
            // Foreground Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: Colors.white, size: 28),
                  ),
                  const Spacer(),
                  Text(title,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
