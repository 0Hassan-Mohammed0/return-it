import 'package:flutter/material.dart';
import '../../widgets/admin/admin_scaffold.dart';
import '../../widgets/admin/stat_card.dart';
import '../../utils/routes.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Dashboard',
      currentRoute: AppRoutes.dashboard,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Overview',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                int crossAxisCount = 1;
                if (width > 600) crossAxisCount = 2;
                if (width > 900) crossAxisCount = 4;

                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.5,
                  children: const [
                    StatCard(
                      title: 'Total Users',
                      value: '1,234',
                      icon: Icons.people,
                      color: Colors.blue,
                    ),
                    StatCard(
                      title: 'Total Items',
                      value: '567',
                      icon: Icons.inventory_2,
                      color: Colors.orange,
                    ),
                    StatCard(
                      title: 'Total Reports',
                      value: '23',
                      icon: Icons.flag,
                      color: Colors.red,
                    ),
                    StatCard(
                      title: 'Resolved Matches',
                      value: '89',
                      icon: Icons.check_circle,
                      color: Colors.green,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),
            const Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 5,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue [100],
                      child: const Icon(Icons.notifications, color: Colors.blue),
                    ),
                    title: Text('New item posted by User #${100 + index}'),
                    subtitle: Text('${index + 2} minutes ago'),
                    trailing: const Icon(Icons.chevron_right),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
