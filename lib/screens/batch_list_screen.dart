import 'package:flutter/material.dart';
import '../database_helper.dart';
import 'class_management_screen.dart';

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
      appBar: AppBar(
        title: const Text('Manage Batches'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _classes.length,
              itemBuilder: (context, index) {
                final cls = _classes[index];
                final className = cls['class_name'];
                final fee = cls['monthly_fee'];

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade100,
                      child: const Icon(Icons.class_, color: Colors.blue),
                    ),
                    title: Text(className, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Monthly Fee: \$${fee.toStringAsFixed(2)}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ClassManagementScreen(
                              className: className, initialFee: fee is num ? fee.toDouble() : 0.0),
                        ),
                      ).then((_) => _loadClasses()); // Reload on return
                    },
                  ),
                );
              },
            ),
    );
  }
}
