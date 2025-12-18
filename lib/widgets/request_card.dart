import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/request_model.dart';
import '../models/item_model.dart';
import '../models/user_model.dart';
import 'package:timeago/timeago.dart' as timeago;

class RequestCard extends StatefulWidget {
  final RequestModel request;
  final bool
      isReceived; // true if I am the owner (received request), false if I am the requester (sent request)

  const RequestCard({
    super.key,
    required this.request,
    required this.isReceived,
  });

  @override
  State<RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<RequestCard> {
  ItemModel? _item;
  UserModel? _counterparty;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    try {
      // Fetch Item
      final itemDoc = await FirebaseFirestore.instance
          .collection('items')
          .doc(widget.request.itemId)
          .get();

      if (itemDoc.exists && itemDoc.data() != null) {
        _item = ItemModel.fromMap(itemDoc.data()!, itemDoc.id);
      }

      // Fetch Counterparty
      // If received, I want to see the requester. If sent, I want to see the owner (or maybe just the item is enough? usually user wants to know who has their item or who they are asking).
      // Logic:
      // isReceived (I am owner) -> fetch requester details
      // !isReceived (I am requester) -> fetch owner details (optional, but helpful)

      final counterpartyId = widget.isReceived
          ? widget.request.requesterId
          : widget.request.ownerId;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(counterpartyId)
          .get();

      if (userDoc.exists && userDoc.data() != null) {
        _counterparty = UserModel.fromMap(userDoc.data()!);
      }
    } catch (e) {
      debugPrint('Error fetching request details: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final requestRef = FirebaseFirestore.instance
            .collection('requests')
            .doc(widget.request.id);

        // 1. Update Request Status
        transaction.update(requestRef, {'status': newStatus});

        if (newStatus == 'accepted') {
          // 2. Update Item Status (if accepted)
          final itemRef = FirebaseFirestore.instance
              .collection('items')
              .doc(widget.request.itemId);
          transaction.update(itemRef, {
            'isResolved': true,
            'handedToSecurity':
                false, // or true depending on business logic, assuming false for direct return
          });
        }

        // 3. Create Notification for the Requester
        final notificationRef =
            FirebaseFirestore.instance.collection('notifications').doc();
        transaction.set(notificationRef, {
          'id': notificationRef.id,
          'userId': widget
              .request.requesterId, // Notify the person who made the request
          'title':
              'Request ${newStatus == 'accepted' ? 'Accepted' : 'Rejected'}',
          'body': newStatus == 'accepted'
              ? 'Great news! Your request for "${_item?.title ?? 'item'}" has been accepted.'
              : 'Your request for "${_item?.title ?? 'item'}" has been rejected.',
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
          'relatedItemId': widget.request.itemId,
        });
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request $newStatus'),
            backgroundColor:
                newStatus == 'accepted' ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating request: $e')),
        );
      }
      debugPrint('Error updating request: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _item == null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        height: 100,
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
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_item == null) {
      return const SizedBox();
    }

    final theme = Theme.of(context);
    final statusColor = _getStatusColor(widget.request.status);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000B58).withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Item Info & Status
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: _item!.imageUrl != null && _item!.imageUrl!.isNotEmpty
                      ? Image.network(
                          _item!.imageUrl!,
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Container(
                            width: 70,
                            height: 70,
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: const Icon(Icons.image_not_supported,
                                color: Colors.grey),
                          ),
                        )
                      : Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                theme.colorScheme.primaryContainer,
                                theme.colorScheme.primary
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Icon(Icons.inventory_2,
                              color: theme.colorScheme.onPrimary, size: 30),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              _item!.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: const Color(0xFF000B58),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              widget.request.status.toUpperCase(),
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.location_on,
                              size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _item!.location,
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.access_time,
                              size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            timeago.format(widget.request.timestamp),
                            style: theme.textTheme.labelSmall
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
            ),

            // Counterparty Info and Actions
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2), // Border width
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.secondary
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundImage: _counterparty?.profileImageUrl != null
                        ? NetworkImage(_counterparty!.profileImageUrl!)
                        : null,
                    backgroundColor: Colors.white,
                    child: _counterparty?.profileImageUrl == null
                        ? Text(
                            _counterparty?.name.substring(0, 1).toUpperCase() ??
                                '?',
                            style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isReceived ? 'REQUESTED BY' : 'OWNER',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Text(
                        _counterparty?.name ?? 'Unknown User',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),

                // Actions
                if (widget.isReceived &&
                    widget.request.status == 'pending') ...[
                  if (_isLoading)
                    const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2)))
                  else ...[
                    GestureDetector(
                      onTap: () => _updateStatus('rejected'),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            color: Colors.red, size: 24),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => _updateStatus('accepted'),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check,
                            color: Colors.green, size: 24),
                      ),
                    ),
                  ]
                ] else ...[
                  if (widget.request.status == 'accepted')
                    ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                            context: context,
                            builder: (c) => AlertDialog(
                                  title: const Text('Contact Info'),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ListTile(
                                        leading: const Icon(Icons.person),
                                        title:
                                            Text(_counterparty?.name ?? 'N/A'),
                                        subtitle: const Text('Name'),
                                      ),
                                      ListTile(
                                        leading: const Icon(Icons.email),
                                        title:
                                            Text(_counterparty?.email ?? 'N/A'),
                                        subtitle: const Text('Email'),
                                      ),
                                      if (_counterparty?.phoneNumber != null)
                                        ListTile(
                                          leading: const Icon(Icons.phone),
                                          title:
                                              Text(_counterparty!.phoneNumber!),
                                          subtitle: const Text('Phone'),
                                        ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(c),
                                      child: const Text('Close'),
                                    )
                                  ],
                                ));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.contact_phone, size: 18),
                      label: const Text('Contact'),
                    )
                ]
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
