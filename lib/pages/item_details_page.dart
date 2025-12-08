import 'package:flutter/material.dart';
import 'package:returnit/models/item_model.dart';
class ItemDetailsPage extends StatelessWidget {
  const ItemDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Retrieve the item passed via arguments
    final item = ModalRoute.of(context)!.settings.arguments as ItemModel?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Item Details'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.build_circle_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Item Details Page\n(Under Construction)',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 24),
            if (item != null) ...[
              Text('Viewing Item: ${item.title}', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('ID: ${item.id}'),
            ] else
              const Text('No item data passed'),
          ],
        ),
      ),
    );
  }
}
