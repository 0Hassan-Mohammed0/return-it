import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:returnit/models/item_model.dart';
import 'package:returnit/pages/item_details_page.dart';
import 'package:intl/intl.dart';

class FoundItemsScreen extends StatefulWidget {
  const FoundItemsScreen({super.key});

  @override
  State<FoundItemsScreen> createState() => _FoundItemsScreenState();
}

class _FoundItemsScreenState extends State<FoundItemsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // Data
  List<ItemModel> _allItems = [];
  bool _isLoading = false;

  // Filters
  String? _selectedCategory;
  String? _selectedLocation;
  String? _selectedStatus;
  String? _selectedDate;
  
  // Frontend search query
  String _searchQuery = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchItems();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  Future<void> _fetchItems({bool refresh = false}) async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Client-Side Filtering approach: Fetch all, then filter in app.
      Query query = FirebaseFirestore.instance.collection('items')
          .where('type', isEqualTo: 'found') // Lowercase found
          .orderBy('timestamp', descending: true);

      final QuerySnapshot snapshot = await query.get();
      
      final newItems = snapshot.docs.map((doc) => ItemModel.fromFirestore(doc)).toList();
      
      if (mounted) {
        setState(() {
          _allItems = newItems;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching items: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _updateFilter(String type, String? value) {
    setState(() {
      if (type == 'Category') _selectedCategory = value;
      if (type == 'Location') _selectedLocation = value;
      if (type == 'Status') _selectedStatus = value;
      if (type == 'Date') _selectedDate = value;
    });
  }

  List<ItemModel> _getFilteredItems() {
    return _allItems.where((item) {
      // Search Query
      if (_searchQuery.isNotEmpty && !item.title.toLowerCase().contains(_searchQuery)) {
        return false;
      }
      
      // Category
      if (_selectedCategory != null && item.category != _selectedCategory) {
        return false;
      }
      
      // Location
      if (_selectedLocation != null && item.location != _selectedLocation) {
        return false;
      }

      // Status
      if (_selectedStatus != null) {
        if (_selectedStatus == 'Claimed' && item.status != 'Claimed') return false;
        if (_selectedStatus == 'Unclaimed' && item.status != 'Unclaimed') return false;
      }

      // Date
      if (_selectedDate != null) {
        final now = DateTime.now();
        final todayStart = DateTime(now.year, now.month, now.day);
        
        switch (_selectedDate) {
          case 'Today':
            if (item.timestamp.isBefore(todayStart)) return false;
            break;
          case 'Yesterday':
             final yesterdayStart = todayStart.subtract(const Duration(days: 1));
             if (item.timestamp.isBefore(yesterdayStart) || item.timestamp.isAfter(todayStart)) return false;
            break;
          case 'Last 7 days':
            if (item.timestamp.isBefore(now.subtract(const Duration(days: 7)))) return false;
            break;
          case 'Last 30 days':
             if (item.timestamp.isBefore(now.subtract(const Duration(days: 30)))) return false;
            break;
          case 'Older than 30 days':
             if (item.timestamp.isAfter(now.subtract(const Duration(days: 30)))) return false;
            break;
        }
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Apply filters
    final displayItems = _getFilteredItems();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildFilters(),
            Expanded(
              child: _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(
                            'Error loading items:\n$_error',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => _fetchItems(refresh: true),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : RefreshIndicator(
                onRefresh: () async => _fetchItems(refresh: true),
                child: displayItems.isEmpty && !_isLoading
                    ? const Center(child: Text('No items found'))
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: displayItems.length,
                        itemBuilder: (context, index) {
                          return FoundItemCard(item: displayItems[index]);
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 20),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            color: Colors.black87,
          ),
          const Expanded(
            child: Text(
              'Found Items',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24, // Increased font size
                fontWeight: FontWeight.w900, // Extra bold
                color: Colors.black, // Pure black
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 20),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search for items...',
            hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
            prefixIcon: Icon(Icons.search, color: Colors.grey[500], size: 22),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return SizedBox(
      height: 60,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        scrollDirection: Axis.horizontal,
        children: [
          _FilterChip(
            label: _selectedCategory ?? 'Category', 
            isSelected: _selectedCategory != null,
            onTap: () => _showFilterOptions('Category', ['Personal items', 'Study materials', 'Electronics', 'IDs/Cards', 'Documents', 'Others']),
          ),
          const SizedBox(width: 10),
          _FilterChip(
            label: _selectedLocation ?? 'Location', 
            isSelected: _selectedLocation != null,
            onTap: () => _showFilterOptions('Location', ['مبنى مدني', 'مبنى عمارة', 'مبنى الورش', 'مبنى4', 'مبنى5', 'الكانتين', 'شئون الطلاب', 'البرجولات', 'أخرى']),
          ),
          const SizedBox(width: 10),
          _FilterChip(
            label: _selectedDate ?? 'Date', // Use _selectedDate
            isSelected: _selectedDate != null,
            onTap: () => _showFilterOptions('Date', [
              'Today',
              'Yesterday',
              'Last 7 days',
              'Last 30 days',
              'Older than 30 days'
            ]),
          ),
          const SizedBox(width: 10),
           _FilterChip(
            label: _selectedStatus ?? 'Status', 
            isSelected: _selectedStatus != null,
            onTap: () => _showFilterOptions('Status', ['Claimed', 'Unclaimed']),
          ),
        ],
      ),
    );
  }

  void _showFilterOptions(String type, List<String> options) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.only(bottom: 20),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Text(
                    'Select $type',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ),
              ListTile(
                title: const Text('All'),
                onTap: () {
                  _updateFilter(type, null);
                  Navigator.pop(context);
                },
              ),
              ...options.map((option) => ListTile(
                title: Text(option),
                onTap: () {
                  _updateFilter(type, option);
                  Navigator.pop(context);
                },
              )),
            ],
          ),
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2196F3).withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFF2196F3) : Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? const Color(0xFF2196F3) : Colors.black87,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down, 
              size: 16, 
              color: isSelected ? const Color(0xFF2196F3) : Colors.grey[600]
            ),
          ],
        ),
      ),
    );
  }
}

class FoundItemCard extends StatelessWidget {
  final ItemModel item;

  const FoundItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final bool claimed = item.isResolved;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
             Navigator.pushNamed(
               context,
               '/item_details',
               arguments: item,
             );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Section
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Stack(
                  children: [
                    SizedBox(
                      height: 180,
                      width: double.infinity,
                      child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                          ? Image.network(
                              item.imageUrl!,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                                  ),
                                );
                              },
                            )
                          : Container(
                             color: Colors.grey[200],
                             child: const Center(
                               child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                             ),
                           ),
                    ),
                  ],
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and Status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: claimed ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.circle,
                                size: 8,
                                color: claimed ? const Color(0xFF4CAF50) : const Color(0xFFF44336), 
                              ),
                              const SizedBox(width: 4),
                              Text(
                                item.status,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: claimed ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
  
                    // Category Tag
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        item.category,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2196F3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
  
                    // Location and Date Row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      item.location,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                                  const SizedBox(width: 6),
                                  Text(
                                    DateFormat('MMMM d, y').format(item.timestamp),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        // Details Button (Visual only)
                        Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF2196F3),
                          ),
                          child: const Icon(
                            Icons.arrow_forward,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
