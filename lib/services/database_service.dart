import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:returnit/models/item_model.dart';
import 'package:returnit/models/user_model.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection References
  CollectionReference get _usersRef => _firestore.collection('users');
  CollectionReference get _itemsRef => _firestore.collection('items');
  CollectionReference get _notificationsRef => _firestore.collection('notifications');
  
  // ImgBB API Key
  final String _imgbbApiKey = '8bf35dc69e3ae8fe7d1f576f19bcfb45';

  // --- Notifications ---
  Stream<int> getUnreadNotificationsCount(String userId) {
    return _notificationsRef
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // --- Items ---

  // Get Recent Items (Limit 10, ordered by timestamp desc)
  Stream<List<ItemModel>> getRecentItems() {
    return _itemsRef
        .orderBy('timestamp', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ItemModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // Get All Items for Search (No limit, be careful with large DBs)
  Stream<List<ItemModel>> getAllItems() {
    return _itemsRef
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ItemModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // Add a new Item
  Future<void> addItem(ItemModel item) async {
    await _itemsRef.add(item.toMap());
  }

  // Get Item by ID
  Future<ItemModel?> getItem(String id) async {
    DocumentSnapshot doc = await _itemsRef.doc(id).get();
    if (doc.exists) {
      return ItemModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  // Upload Image using ImgBB
  Future<String?> uploadImage(File imageFile, String folder) async {
    try {
      final uri = Uri.parse('https://api.imgbb.com/1/upload');
      final request = http.MultipartRequest('POST', uri)
        ..fields['key'] = _imgbbApiKey
        ..files.add(await http.MultipartFile.fromPath('image', imageFile.path));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(responseBody);
        return jsonResponse['data']['url'];
      } else {
        print('ImgBB Upload Error: ${response.statusCode} - $responseBody');
        throw Exception('ImgBB Failed: ${response.statusCode}');
      }
    } catch (e) {
      print('Error uploading image to ImgBB: $e');
      throw Exception('Upload Failed: $e'); 
    }
  }

  // Check Soft Duplicate
  Future<bool> checkSoftDuplicate({
    required String title,
    required DateTime date,
    required String type,
  }) async {
    try {
      DateTime startOfDay = DateTime(date.year, date.month, date.day);
      DateTime endOfDay = startOfDay.add(const Duration(days: 1));

      QuerySnapshot query = await _itemsRef
          .where('type', isEqualTo: type)
          .where('title', isEqualTo: title)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      print('Error checking duplicates: $e');
      return false;
    }
  }

  // Find Similar Items (Client-Side Filtering to avoid Index errors)
  Future<List<ItemModel>> findSimilarItems({
    required String title,
    required String typeToSearch, 
    String? location,
  }) async {
    if (title.isEmpty && location == null) return [];
    
    try {
      Query query = _itemsRef;

      // PRIORITY 1: Location (User requested high priority)
      if (location != null && location != 'All') {
        // Query by Type AND Location (Multiple equalities are allowed without custom index)
        query = query
            .where('type', isEqualTo: typeToSearch)
            .where('location', isEqualTo: location);
            
        // Limit results
        query = query.limit(50); 

        QuerySnapshot snapshot = await query.get();
        List<ItemModel> results = snapshot.docs.map((doc) {
          return ItemModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        }).toList();

        // Check Title locally if provided
        if (title.isNotEmpty) {
          final searchLower = title.toLowerCase();
          results = results.where((item) {
            return item.title.toLowerCase().contains(searchLower);
          }).toList();
        }
        
        return results;
      } 
      
      // PRIORITY 2: Global Search (If no location selected)
      // To support Case-Insensitive AND Substring search (e.g. "Bag" finds "black bag")
      // without Algolia/ElasticSearch, we will fetch a batch of recent items and filter client-side.
      else if (title.isNotEmpty) {
        // Fetch last 100 items of this type (most likely to contain relevant active items)
        query = _itemsRef
             .where('type', isEqualTo: typeToSearch)
             .orderBy('timestamp', descending: true)
             .limit(100);

        QuerySnapshot snapshot = await query.get();

        List<ItemModel> results = snapshot.docs.map((doc) {
          return ItemModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        }).toList();

        final searchLower = title.toLowerCase();
        
        // Robust Client-Side Filtering
        return results.where((item) {
           final itemTitle = item.title.toLowerCase();
           final itemDesc = item.description.toLowerCase();
           // Check Title OR Description
           return itemTitle.contains(searchLower) || itemDesc.contains(searchLower);
        }).toList();
      }
      
      return [];
      
    } catch (e) {
      print('Error finding similar items: $e');
      return [];
    }
  }

  // Find Items by Date (Smart Suggestions by Date)
  Future<List<ItemModel>> findItemsByDate({
    required DateTime date,
    required String typeToSearch,
  }) async {
    // try-catch block removed to allow UI to handle errors (specifically missing Index)
    DateTime startOfDay = DateTime(date.year, date.month, date.day);
    DateTime endOfDay = startOfDay.add(const Duration(days: 1));

    QuerySnapshot query = await _itemsRef
        .where('type', isEqualTo: typeToSearch)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay))
        .limit(10) 
        .get();

    return query.docs.map((doc) {
      return ItemModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }).toList();
  }

  // --- Users ---

  Future<UserModel?> getUser(String id) async {
    DocumentSnapshot doc = await _usersRef.doc(id).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data() as Map<String, dynamic>);
    }
    return null;
  }
  
  Future<void> updateUser(UserModel user) async {
    await _usersRef.doc(user.id).set(user.toMap(), SetOptions(merge: true));
  }
}
