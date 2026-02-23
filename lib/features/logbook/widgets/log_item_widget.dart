import 'package:flutter/material.dart';
import '../models/log_model.dart';

class LogItemWidget extends StatelessWidget {
  final LogModel log;
  final VoidCallback onEdit;

  const LogItemWidget({
    super.key,
    required this.log,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: const Icon(Icons.note),
        title: Text(
          log.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(log.desc),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: onEdit,
            ),
          ],
        ),
      ),
    );
  }
}
