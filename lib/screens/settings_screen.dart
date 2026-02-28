import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isExporting = false;
  bool _isImporting = false;
  String _defaultFee = '500';

  @override
  void initState() {
    super.initState();
    _loadDefaultFee();
  }

  Future<void> _loadDefaultFee() async {
    final classes = await DatabaseHelper.instance.getClasses();
    if (classes.isNotEmpty) {
      final fee = (classes.first['monthly_fee'] as num).toStringAsFixed(0);
      if (mounted) setState(() => _defaultFee = fee);
    }
  }

  // ── Change Password ──────────────────────────────────────
  void _showChangePasswordDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.lock_outline, color: Colors.blueGrey),
          SizedBox(width: 8),
          Text('Change Password'),
        ]),
        content: TextField(
          controller: ctrl,
          obscureText: true,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'New Password',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.lock),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey, foregroundColor: Colors.white),
            onPressed: () async {
              final v = ctrl.text.trim();
              if (v.isEmpty) return;
              await DatabaseHelper.instance.updateAdminPassword(v);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                _showSnack('Password updated successfully!');
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  // ── Default Fee ──────────────────────────────────────────
  void _showDefaultFeeDialog() {
    final ctrl = TextEditingController(text: _defaultFee);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.attach_money, color: Colors.green),
          SizedBox(width: 8),
          Text('Default Monthly Fee'),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('This fee will be shown as reference when adding new batches.', style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Amount (৳)',
                border: OutlineInputBorder(),
                prefixText: '৳ ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
            onPressed: () async {
              final fee = double.tryParse(ctrl.text);
              if (fee == null || fee <= 0) return;
              setState(() => _defaultFee = fee.toStringAsFixed(0));
              Navigator.pop(ctx);
              _showSnack('Default fee set to ৳${fee.toStringAsFixed(0)}');
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // ── Export DB ──────────────────────────────────────────────
  Future<void> _exportDB() async {
    setState(() => _isExporting = true);
    try {
      await DatabaseHelper.instance.close();
      final dbPath = await getDatabasesPath();
      final dbFile = File(p.join(dbPath, 'coaching_center.db'));
      if (!await dbFile.exists()) { _showSnack('Database file not found!', isError: true); return; }
      final tempDir = await getTemporaryDirectory();
      final now = DateTime.now();
      final stamp = '${now.year}${now.month.toString().padLeft(2,'0')}${now.day.toString().padLeft(2,'0')}_${now.hour.toString().padLeft(2,'0')}${now.minute.toString().padLeft(2,'0')}';
      final exportFile = File(p.join(tempDir.path, 'coaching_backup_$stamp.db'));
      await dbFile.copy(exportFile.path);
      await DatabaseHelper.instance.database;
      await SharePlus.instance.share(ShareParams(
        files: [XFile(exportFile.path, mimeType: 'application/octet-stream')],
        subject: 'Coaching Manager DB Backup — $stamp',
        text: 'Coaching Manager database backup file.',
      ));
    } catch (e) {
      if (mounted) _showSnack('Export failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  // ── Import DB ──────────────────────────────────────────────
  Future<void> _importDB() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange),
          SizedBox(width: 8),
          Text('Replace All Data?'),
        ]),
        content: const Text('This will REPLACE all current data with the selected backup.\nExport first if you want to keep current data.', style: TextStyle(height: 1.5)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, Replace'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isImporting = true);
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.any, withData: false);
      if (result == null || result.files.isEmpty) { setState(() => _isImporting = false); return; }
      final pickedPath = result.files.single.path;
      if (pickedPath == null) { _showSnack('Could not access the file.', isError: true); return; }
      await DatabaseHelper.instance.close();
      final dbPath = await getDatabasesPath();
      await File(pickedPath).copy(p.join(dbPath, 'coaching_center.db'));
      await DatabaseHelper.instance.database;
      if (mounted) _showSnack('✅ Database imported! Restart the app for full effect.');
    } catch (e) {
      if (mounted) _showSnack('Import failed: $e', isError: true);
      await DatabaseHelper.instance.database;
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  // ── Fresh Start (Reset DB) ────────────────────────────────
  Future<void> _resetDatabase() async {
    // Step 1 — first confirmation
    final step1 = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.delete_forever, color: Colors.red),
          SizedBox(width: 8),
          Text('Fresh Start?'),
        ]),
        content: const Text(
          'This will permanently DELETE all your data:\n\n'
          '• All students & their records\n'
          '• All payments & exam marks\n'
          '• All batches, teachers & costs\n\n'
          'The app will restart with a completely clean database.',
          style: TextStyle(height: 1.6),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('I Understand, Continue'),
          ),
        ],
      ),
    );
    if (step1 != true || !mounted) return;

    // Step 2 — type "RESET" to confirm
    final confirmCtrl = TextEditingController();
    final step2 = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Type RESET to confirm', style: TextStyle(color: Colors.red)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('This is your last chance. There is NO undo.', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            TextField(
              controller: confirmCtrl,
              autofocus: true,
              onChanged: (_) => setSt(() {}),
              decoration: const InputDecoration(
                hintText: 'Type RESET here',
                border: OutlineInputBorder(),
              ),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: confirmCtrl.text == 'RESET' ? Colors.red : Colors.grey,
                foregroundColor: Colors.white,
              ),
              onPressed: confirmCtrl.text == 'RESET' ? () => Navigator.pop(ctx, true) : null,
              child: const Text('Delete Everything'),
            ),
          ],
        ),
      ),
    );
    if (step2 != true || !mounted) return;

    // Perform the reset
    try {
      await DatabaseHelper.instance.resetDatabase();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ Database reset! A fresh database has been created.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ));
        // Pop back to login/root so all screens reload fresh data
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) _showSnack('Reset failed: $e', isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : Colors.green.shade700,
      duration: const Duration(seconds: 4),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.blueGrey.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [

          // ── ACCOUNT ─────────────────────────────────────────
          _sectionHeader('Account'),
          _settingsTile(
            icon: Icons.lock_outline,
            iconColor: Colors.blueGrey,
            title: 'Change Admin Password',
            subtitle: 'Update your login password',
            onTap: _showChangePasswordDialog,
          ),

          const SizedBox(height: 16),

          // ── PREFERENCES ─────────────────────────────────────
          _sectionHeader('Preferences'),
          _settingsTile(
            icon: Icons.attach_money,
            iconColor: Colors.green.shade700,
            title: 'Default Monthly Fee',
            subtitle: '৳$_defaultFee per student',
            onTap: _showDefaultFeeDialog,
          ),

          const SizedBox(height: 16),

          // ── DATA & BACKUP ────────────────────────────────────
          _sectionHeader('Data & Backup'),
          _settingsTile(
            icon: Icons.upload_rounded,
            iconColor: Colors.blue.shade700,
            title: 'Export Database',
            subtitle: 'Share a backup of all your data',
            trailing: _isExporting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : null,
            onTap: _isExporting ? null : _exportDB,
          ),
          _settingsTile(
            icon: Icons.download_rounded,
            iconColor: Colors.orange.shade700,
            title: 'Import Database',
            subtitle: 'Restore data from a backup file',
            trailing: _isImporting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : null,
            onTap: _isImporting ? null : _importDB,
          ),
          _settingsTile(
            icon: Icons.restart_alt,
            iconColor: Colors.red.shade700,
            title: 'Fresh Start',
            subtitle: 'Delete everything & start with a clean database',
            onTap: _resetDatabase,
          ),

          const SizedBox(height: 16),

          // ── ABOUT ───────────────────────────────────────────
          _sectionHeader('About'),
          _settingsTile(
            icon: Icons.apps,
            iconColor: Colors.teal,
            title: 'App Version',
            subtitle: 'Coaching Manager v1.0.0',
            onTap: null,
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(8)),
              child: const Text('v1.0.0', style: TextStyle(fontSize: 12, color: Colors.teal, fontWeight: FontWeight.bold)),
            ),
          ),
          _expandableTile(
            icon: Icons.info_outline,
            iconColor: Colors.purple.shade700,
            title: 'About Developer',
            subtitle: '',
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Card(
                  elevation: 0,
                  color: Colors.purple.shade50,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.purple.shade100,
                          child: const Text('SW', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple, fontSize: 18)),
                        ),
                        const SizedBox(height: 10),
                        const Text('Swadhin', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                        const Text('CSE, RUET', style: TextStyle(color: Colors.grey, fontSize: 13)),
                        const SizedBox(height: 10),
                        const Divider(),
                        _infoRow(Icons.email_outlined, 'waccub@gmail.com'),
                        const SizedBox(height: 6),
                        _infoRow(Icons.phone_outlined, '01771822407'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 16, 8),
      child: Text(title.toUpperCase(),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade500, letterSpacing: 1.2)),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        trailing: trailing ?? (onTap != null ? Icon(Icons.chevron_right, color: Colors.grey.shade400) : null),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _expandableTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ExpansionTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          subtitle: subtitle.isEmpty ? null : Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          childrenPadding: EdgeInsets.zero,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          children: children,
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(children: [
      Icon(icon, size: 17, color: Colors.blueGrey),
      const SizedBox(width: 8),
      Text(text, style: const TextStyle(fontSize: 14)),
    ]);
  }
}
