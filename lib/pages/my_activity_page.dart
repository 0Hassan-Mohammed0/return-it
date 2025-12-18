import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:returnit/models/item_model.dart';
import 'package:returnit/services/database_service.dart';
import 'package:timeago/timeago.dart' as timeago;

class MyActivityPage extends StatefulWidget {
  const MyActivityPage({super.key});

  @override
  State<MyActivityPage> createState() => _MyActivityPageState();
}

class _MyActivityPageState extends State<MyActivityPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Activity'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
          tabs: const [
            Tab(text: 'My Lost'),
            Tab(text: 'My Found'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _MyItemsList(type: 'lost'),
          _MyItemsList(type: 'found'),
        ],
      ),
    );
  }
}

class _MyItemsList extends StatelessWidget {
  final String type;

  const _MyItemsList({required this.type});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text('Please log in to view your items.'));
    }

    return StreamBuilder<List<ItemModel>>(
      stream: DatabaseService().getUserItems(user.uid, type),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final items = snapshot.data ?? [];

        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  type == 'lost'
                      ? Icons.search_off
                      : Icons.inventory_2_outlined,
                  size: 64,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  type == 'lost'
                      ? 'No lost items reported'
                      : 'No found items reported',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = items[index];
            return _MyItemCard(item: item);
          },
        );
      },
    );
  }
}

class _MyItemCard extends StatelessWidget {
  final ItemModel item;

  const _MyItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/item_details', arguments: item);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                image: item.imageUrl != null && item.imageUrl!.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(item.imageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: item.imageUrl == null || item.imageUrl!.isEmpty
                  ? Icon(Icons.image, color: Colors.grey[400])
                  : null,
            ),
            const SizedBox(width: 12),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _buildStatusBadge(item),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Category Badge & Location
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.category,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[800],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.location,
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Description
                  Text(
                    item.description,
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Time
                  Row(
                    children: [
                      Icon(Icons.access_time,
                          size: 12, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text(
                        timeago.format(item.timestamp),
                        style: TextStyle(color: Colors.grey[400], fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ItemModel item) {
    String text;
    Color color;
    Color bgColor;

    if (item.isResolved) {
      text = 'Claimed';
      color = Colors.green;
      bgColor = Colors.green.withValues(alpha: 0.1);
    } else {
      text = 'Unclaimed'; // Or Pending
      color = Colors.orange;
      bgColor = Colors.orange.withValues(alpha: 0.1);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10, // Slightly smaller for better fit
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
