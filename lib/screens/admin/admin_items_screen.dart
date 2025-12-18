import 'package:flutter/material.dart';
import '../../widgets/admin/admin_scaffold.dart';
import '../../utils/routes.dart';

class AdminItemsScreen extends StatefulWidget {
  const AdminItemsScreen({super.key});

  @override
  State<AdminItemsScreen> createState() => _AdminItemsScreenState();
}

class _AdminItemsScreenState extends State<AdminItemsScreen> {
  // Placeholder for items
  Future<void> fetchItemsPlaceholder() async {
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Items Management',
      currentRoute: AppRoutes.items,
      body: Column(
        children: [
          // Filter Bar
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
                      hintText: 'Search items...',
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
                      value: 'All Categories',
                      items: const [
                        DropdownMenuItem(
                            value: 'All Categories',
                            child: Text('All Categories')),
                        DropdownMenuItem(
                            value: 'Electronics', child: Text('Electronics')),
                        DropdownMenuItem(
                            value: 'Documents', child: Text('Documents')),
                      ],
                      onChanged: (value) {},
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Items Table
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
                        DataColumn(label: Text('Item ID')),
                        DataColumn(label: Text('Title')),
                        DataColumn(label: Text('Category')),
                        DataColumn(label: Text('Date Posted')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: List.generate(10, (index) {
                        String status = 'Pending';
                        Color statusColor = Colors.orange;
                        if (index % 3 == 0) {
                          status = 'Approved';
                          statusColor = Colors.green;
                        } else if (index % 3 == 1) {
                          status = 'Rejected';
                          statusColor = Colors.red;
                        }

                        return DataRow(
                          cells: [
                            DataCell(Text('#${5001 + index}')),
                            DataCell(Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Icon(Icons.image, size: 16),
                                ),
                                const SizedBox(width: 8),
                                Text('Lost Item ${index + 1}'),
                              ],
                            )),
                            DataCell(
                                Text(index % 2 == 0 ? 'Electronics' : 'Keys')),
                            DataCell(Text('2023-12-0${index + 1}')),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border:
                                      Border.all(color: statusColor, width: 1),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.visibility, size: 20),
                                  color: Colors.grey,
                                  onPressed: () {},
                                  tooltip: 'View',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.check, size: 20),
                                  color: Colors.green,
                                  onPressed: () {},
                                  tooltip: 'Approve',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 20),
                                  color: Colors.red,
                                  onPressed: () {},
                                  tooltip: 'Reject',
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
        ],
      ),
    );
  }
}
