import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/request_model.dart';
import '../widgets/request_card.dart';

class RequestsScreen extends StatelessWidget {
  const RequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view requests.')),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[50], // Slightly off-white background
        appBar: AppBar(
          title: const Text('Requests'),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF000B58),
          elevation: 0,
          bottom: TabBar(
            labelColor: const Color(0xFF000B58),
            unselectedLabelColor: Colors.grey[400],
            indicatorColor: const Color(0xFF000B58),
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            unselectedLabelStyle:
                const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
            tabs: const [
              Tab(text: 'Received'),
              Tab(text: 'Sent'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Received Requests (I am the owner)
            _RequestsList(
              query: FirebaseFirestore.instance
                  .collection('requests')
                  .where('ownerId', isEqualTo: user.uid)
                  .orderBy('timestamp', descending: true),
              isReceived: true,
            ),
            // Sent Requests (I am the requester)
            _RequestsList(
              query: FirebaseFirestore.instance
                  .collection('requests')
                  .where('requesterId', isEqualTo: user.uid)
                  .orderBy('timestamp', descending: true),
              isReceived: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestsList extends StatelessWidget {
  final Query query;
  final bool isReceived;

  const _RequestsList({required this.query, required this.isReceived});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Something went wrong',
                    style: TextStyle(color: Colors.grey[800])),
                Text('${snapshot.error}',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isReceived ? Icons.inbox_rounded : Icons.outbox_rounded,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  isReceived
                      ? 'No pending requests'
                      : 'You haven\'t sent any requests',
                  style: const TextStyle(
                    color: Color(0xFF000B58),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isReceived
                      ? 'Requests from other users will appear here.'
                      : 'When you request a lost item, it will show up here.',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final docs = snapshot.data!.docs;

        return ListView.builder(
          itemCount: docs.length,
          padding: const EdgeInsets.only(top: 10, bottom: 20),
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final request = RequestModel.fromMap(data, docs[index].id);
            return RequestCard(request: request, isReceived: isReceived);
          },
        );
      },
    );
  }
}
