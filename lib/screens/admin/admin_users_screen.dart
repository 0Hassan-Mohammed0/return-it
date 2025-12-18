import 'package:flutter/material.dart';
import '../../widgets/admin/admin_scaffold.dart';
import '../../utils/routes.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  // Placeholder for fetching users
  Future<void> fetchUsersPlaceholder() async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Users Management',
      currentRoute: AppRoutes.users,
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search users...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                DropdownButtonHideUnderline(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<String>(
                      value: 'All',
                      items: const [
                        DropdownMenuItem(
                            value: 'All', child: Text('All Status')),
                        DropdownMenuItem(
                            value: 'Active', child: Text('Active')),
                        DropdownMenuItem(
                            value: 'Banned', child: Text('Banned')),
                      ],
                      onChanged: (value) {},
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Users Table
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(Colors.grey[50]),
                      columns: const [
                        DataColumn(label: Text('User ID')),
                        DataColumn(label: Text('Name')),
                        DataColumn(label: Text('Email')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: List.generate(10, (index) {
                        return DataRow(
                          cells: [
                            DataCell(Text('#${1001 + index}')),
                            DataCell(Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Colors.blue[100],
                                  child: Text(
                                    'U${index + 1}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text('User Name ${index + 1}'),
                              ],
                            )),
                            DataCell(Text('user${index + 1}@example.com')),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: index % 3 == 0
                                      ? Colors.red[100]
                                      : Colors.green[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  index % 3 == 0 ? 'Banned' : 'Active',
                                  style: TextStyle(
                                    color: index % 3 == 0
                                        ? Colors.red[800]
                                        : Colors.green[800],
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 20),
                                  color: Colors.blue,
                                  onPressed: () {},
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 20),
                                  color: Colors.red,
                                  onPressed: () {},
                                ),
                              ],
                            )),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Pagination
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: () {}, child: const Text('Previous')),
              const SizedBox(width: 16),
              TextButton(onPressed: () {}, child: const Text('Next')),
            ],
          ),
        ],
      ),
    );
  }
}
