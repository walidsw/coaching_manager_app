import 'package:flutter/material.dart';
import '../database_helper.dart';
import 'student_detail_screen.dart';

class SearchStudentScreen extends StatefulWidget {
  const SearchStudentScreen({super.key});

  @override
  State<SearchStudentScreen> createState() => _SearchStudentScreenState();
}

class _SearchStudentScreenState extends State<SearchStudentScreen> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _hasSearched = false;

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    final db = await DatabaseHelper.instance.database;
    final results = await db.query(
      'Students',
      where: 'unique_student_id LIKE ? OR father_mobile LIKE ? OR alternative_mobile LIKE ? OR name LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%', '%$query%'],
    );

    setState(() {
      _searchResults = results;
      _hasSearched = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text('Search Student', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.purple.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header Banner with Search Bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 24, top: 12),
            decoration: BoxDecoration(
              color: Colors.purple.shade800,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
              boxShadow: [
                BoxShadow(color: Colors.purple.shade900.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Search by ID, Name or Mobile...',
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search, color: Colors.purple.shade400),
                  suffixIcon: Container(
                    margin: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Colors.purple.shade600, Colors.purple.shade400]),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                      onPressed: _performSearch,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                onSubmitted: (_) => _performSearch(),
              ),
            ),
          ),
          
          const SizedBox(height: 16),

          Expanded(
            child: !_hasSearched 
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_search_rounded, size: 80, color: Colors.purple.shade100),
                    const SizedBox(height: 16),
                    Text('Find Any Student', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade700)),
                    const SizedBox(height: 8),
                    Text('Enter a query above to start searching.', style: TextStyle(color: Colors.blueGrey.shade400)),
                  ],
                )
              : _searchResults.isEmpty
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off_rounded, size: 80, color: Colors.red.shade100),
                      const SizedBox(height: 16),
                      Text('No Results Found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade700)),
                      const SizedBox(height: 8),
                      Text('Try a different name, ID, or phone number.', style: TextStyle(color: Colors.blueGrey.shade400)),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final student = _searchResults[index];
                      final isActive = student['status'] == 'active';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: Colors.blueGrey.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                          border: Border.all(color: Colors.grey.shade100),
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
                                  builder: (_) => StudentDetailScreen(studentId: student['unique_student_id']),
                                ),
                              ).then((_) {
                                // Optional: refresh if data might have changed
                                if (mounted && _hasSearched) _performSearch();
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: isActive ? Colors.purple.shade50 : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: Icon(Icons.person, color: isActive ? Colors.purple.shade400 : Colors.grey.shade400),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          student['name'] ?? 'Unknown',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blueGrey.shade900),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "ID: ${student['unique_student_id']} • Class: ${student['current_class']}",
                                          style: TextStyle(color: Colors.blueGrey.shade500, fontSize: 13),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isActive ? Colors.green.shade50 : Colors.red.shade50,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            (student['status'] ?? '').toString().toUpperCase(),
                                            style: TextStyle(
                                              color: isActive ? Colors.green.shade700 : Colors.red.shade700,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey.shade300, size: 16),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          )
        ],
      ),
    );
  }
}
