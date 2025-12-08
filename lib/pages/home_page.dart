import 'package:flutter/material.dart';
import 'package:returnit/services/database_service.dart';
import 'package:returnit/models/item_model.dart';
import 'package:returnit/utils/theme.dart';
import 'package:returnit/pages/my_activity_page.dart';
import 'package:returnit/pages/placeholder_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 1; // Start at Home (Middle)

  final List<Widget> _pages = [
    const MyActivityPage(),
    const _HomeContent(), // Extracted Home Content
    const PlaceholderPage(title: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primaryBlue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'My Activity',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            // Ensure logo exists in assets
            Image.asset('assets/images/logo.png', width: 40, height: 40),
            const SizedBox(width: 8),
            const Text('ReturnIt', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          StreamBuilder<int>(
            stream: DatabaseService().getUnreadNotificationsCount('test_user_001'), // Using test user for demo
            builder: (context, snapshot) {
              int count = snapshot.data ?? 0;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none),
                    onPressed: () {
                      Navigator.pushNamed(context, '/notifications');
                    },
                  ),
                  if (count > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 14,
                          minHeight: 14,
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.perm_data_setting), // Temp Icon
            onPressed: () {
               Navigator.pushNamed(context, '/test_db');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search items, categories, or locations..',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                ),
              ),
              const SizedBox(height: 24),
              
              // 2x2 Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.3, // Made smaller (shorter)
                children: [
                  _buildMenuCard(
                    context, 
                    'Lost Items', 
                    'Browse lost items', 
                    Icons.search_outlined, 
                    Colors.blue,
                    '/lost_items'
                  ),
                  _buildMenuCard(
                    context, 
                    'Found Items', 
                    'Browse found items', 
                    Icons.inventory_2_outlined, 
                    Colors.orange,
                    '/found_items'
                  ),
                   _buildMenuCard(
                    context, 
                    'Report Lost', 
                    'You lost something?', 
                    Icons.add_circle_outline, 
                    AppTheme.primaryBlue,
                    '/report_lost'
                  ),
                  _buildMenuCard(
                    context, 
                    'Report Found', 
                    'You found something?', 
                    Icons.playlist_add_check, 
                    AppTheme.teal,
                    '/report_found'
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Recent Items Header
              const Text(
                'Recently Added',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              
              // Recent Items List (Horizontal) with Firebase
              SizedBox(
                height: 260,
                child: StreamBuilder<List<ItemModel>>(
                  stream: DatabaseService().getRecentItems(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('No recent items found.'));
                    }

                    final items = snapshot.data!;
                    return ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: items.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 16),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return _buildItemCard(context, item);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, String title, String subtitle, IconData icon, Color iconColor, String route) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.pushNamed(context, route);
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                   // decoration: BoxDecoration(
                   //   color: iconColor.withOpacity(0.1),
                   //   borderRadius: BorderRadius.circular(8),
                   // ),
                  child: Icon(icon, color: iconColor, size: 28),
                ),
                const Spacer(),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItemCard(BuildContext context, ItemModel item) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pushNamed(
              context,
              '/item_details',
              arguments: item,
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 180,
            decoration: const BoxDecoration(
              // REMOVED color: white to let InkWell show on top if needed, 
              // but usually InkWell needs to be ON Material.
              // So we keep formatting simple.
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Hero( // Added Hero for smooth transition
                    tag: item.id,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        image: item.imageUrl != null && item.imageUrl!.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(item.imageUrl!),
                                fit: BoxFit.contain,
                              )
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: item.imageUrl == null || item.imageUrl!.isEmpty
                          ? Icon(Icons.image_not_supported, color: Colors.grey[400], size: 50)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.type == 'lost' ? 'Lost' : 'Found'}: ${item.location}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                   maxLines: 1,
                   overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
