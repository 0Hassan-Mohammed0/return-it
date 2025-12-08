import 'package:cloud_firestore/cloud_firestore.dart';

class RequestModel {
  final String id;
  final String itemId;
  final String requesterId;
  final String ownerId;
  final String status; // 'pending', 'accepted', 'rejected'
  final DateTime timestamp;

  RequestModel({
    required this.id,
    required this.itemId,
    required this.requesterId,
    required this.ownerId,
    required this.status,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'itemId': itemId,
      'requesterId': requesterId,
      'ownerId': ownerId,
      'status': status,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory RequestModel.fromMap(Map<String, dynamic> map, String docId) {
    return RequestModel(
      id: docId,
      itemId: map['itemId'] ?? '',
      requesterId: map['requesterId'] ?? '',
      ownerId: map['ownerId'] ?? '',
      status: map['status'] ?? 'pending',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }
}
