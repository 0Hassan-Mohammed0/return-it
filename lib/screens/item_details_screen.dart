import 'package:flutter/material.dart';
import 'package:returnit/models/lost_item.dart';

class ItemDetailsScreen extends StatelessWidget {
  final LostItem item;

  const ItemDetailsScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(item.title),
      ),
      body: Center(
        child: Text('Details for ${item.title}'),
      ),
    );
  }
}
