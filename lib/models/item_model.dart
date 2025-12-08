import 'package:cloud_firestore/cloud_firestore.dart';

class ItemModel {
  final String id;
  final String title;
  final String description;
  final String location;
  final String userId;
  final String? imageUrl;
  final String type; // 'lost' or 'found'
  final String category;
  final DateTime timestamp;
  final bool isResolved;

  ItemModel({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.userId,
    this.imageUrl,
    required this.type,
    required this.category,
    required this.timestamp,
    this.isResolved = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'location': location,
      'userId': userId,
      'imageUrl': imageUrl,
      'type': type,
      'category': category,
      'timestamp': Timestamp.fromDate(timestamp),
      'isResolved': isResolved,
    };
  }

  factory ItemModel.fromMap(Map<String, dynamic> map, String docId) {
    return ItemModel(
      id: docId,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      location: map['location'] ?? '',
      userId: map['userId'] ?? '',
      imageUrl: map['imageUrl'],
      type: map['type'] ?? 'lost',
      category: map['category'] ?? 'Other',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      isResolved: map['isResolved'] ?? false,
    );
  }

  // Compatibility with merged screens
  factory ItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ItemModel.fromMap(data, doc.id);
  }

  // Derived status for UI
  String get status => isResolved ? 'Claimed' : 'Unclaimed';
}
