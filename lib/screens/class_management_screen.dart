import 'package:flutter/material.dart';
import '../database_helper.dart';

class ClassManagementScreen extends StatefulWidget {
  final String className;
  final double initialFee;

  const ClassManagementScreen({
    super.key,
    required this.className,
    required this.initialFee,
  });

  @override
  State<ClassManagementScreen> createState() => _ClassManagementScreenState();
}

class _ClassManagementScreenState extends State<ClassManagementScreen> {
  late TextEditingController _feeController;

  @override
  void initState() {
    super.initState();
    _feeController = TextEditingController(text: widget.initialFee.toStringAsFixed(2));
  }

  Future<void> _updateFee() async {
    final feeText = _feeController.text;
    final fee = double.tryParse(feeText);
    
    if (fee == null || fee < 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid fee amount')));
      return;
    }

    await DatabaseHelper.instance.updateClassFee(widget.className, fee);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fee Updated Successfully')));
      Navigator.pop(context); // Go back to batch list
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage ${widget.className}'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Update Monthly Fee', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: _feeController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Monthly Fee',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Save Fee Configuration'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                onPressed: _updateFee,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
