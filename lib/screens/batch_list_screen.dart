import 'package:flutter/material.dart';
import '../database_helper.dart';
import 'batch_detail_screen.dart';

class BatchListScreen extends StatefulWidget {
  const BatchListScreen({super.key});

  @override
  State<BatchListScreen> createState() => _BatchListScreenState();
}

class _BatchListScreenState extends State<BatchListScreen> {
  List<Map<String, dynamic>> _classes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    setState(() => _isLoading = true);
    final classes = await DatabaseHelper.instance.getClasses();
    setState(() {
      _classes = classes;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text('Manage Batches', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(left: 20, right: 20, bottom: 24, top: 12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade800,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(color: Colors.blue.shade900.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Text(
                    'Select a batch below to manage its students, configure monthly fees, and track performance.',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 15),
                  ),
                ),
                
                const SizedBox(height: 16),

                Expanded(
                  child: _classes.isEmpty 
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.category_rounded, size: 80, color: Colors.blue.shade100),
                          const SizedBox(height: 16),
                          Text('No Batches Found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade700)),
                          const SizedBox(height: 8),
                          Text('Batches will appear here once created.', style: TextStyle(color: Colors.blueGrey.shade400)),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _classes.length,
                        itemBuilder: (context, index) {
                          final cls = _classes[index];
                          final String className = cls['class_name'] as String;
                          final double fee = (cls['monthly_fee'] as num).toDouble();

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.grey.shade100),
                              boxShadow: [
                                BoxShadow(color: Colors.blueGrey.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => BatchDetailScreen(
                                        className: className,
                                        monthlyFee: fee,
                                      ),
                                    ),
                                  ).then((_) => _loadClasses());
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 52,
                                        height: 52,
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Icon(Icons.school_rounded, color: Colors.blue.shade600, size: 28),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              className,
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blueGrey.shade900),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(Icons.monetization_on_outlined, size: 14, color: Colors.blueGrey.shade400),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Fee: ৳${fee.toStringAsFixed(0)} / mo',
                                                  style: TextStyle(color: Colors.blueGrey.shade600, fontSize: 13, fontWeight: FontWeight.w500),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade50,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(Icons.arrow_forward_ios_rounded, color: Colors.blue.shade300, size: 16),
                                      ),
                                    ],
                                  ),
                                ),
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
}
