import 'package:cloud_firestore/cloud_firestore.dart';

class LostItem {
  final String id;
  final String title;
  final String status;
  final String category;
  final String location;
  final DateTime date;
  final String imageUrl;
  final String type;

  LostItem({
    required this.id,
    required this.title,
    required this.status,
    required this.category,
    required this.location,
    required this.date,
    required this.imageUrl,
    required this.type,
  });

  factory LostItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LostItem(
      id: doc.id,
      title: data['title'] ?? '',
      status: data.containsKey('isResolved') 
          ? (data['isResolved'] == true ? 'Claimed' : 'Unclaimed')
          : (data['status'] ?? 'Unclaimed'),
      category: data['category'] ?? '',
      location: data['location'] ?? '',
      date: (data['timestamp'] as Timestamp?)?.toDate() ?? (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      imageUrl: data['imageUrl'] ?? '',
      type: data['type'] ?? 'lost', // Default to lowercase lost
    );
  }
  
  bool get isClaimed => status.toLowerCase() == 'claimed';
}
