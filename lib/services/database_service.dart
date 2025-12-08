import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:returnit/models/item_model.dart';
import 'package:returnit/models/user_model.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection References
  CollectionReference get _usersRef => _firestore.collection('users');
  CollectionReference get _itemsRef => _firestore.collection('items');
  CollectionReference get _notificationsRef => _firestore.collection('notifications');

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

  // --- Users ---

  // Get User by ID
  Future<UserModel?> getUser(String id) async {
    DocumentSnapshot doc = await _usersRef.doc(id).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data() as Map<String, dynamic>);
    }
    return null;
  }
  
  // Create/Update User
  Future<void> updateUser(UserModel user) async {
    await _usersRef.doc(user.id).set(user.toMap(), SetOptions(merge: true));
  }
}
