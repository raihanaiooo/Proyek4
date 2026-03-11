import 'package:flutter/material.dart';
import '../models/log_model.dart';

class LogItemWidget extends StatelessWidget {
  final LogModel log;
  final VoidCallback? onEdit;
  final String formattedDate;

  const LogItemWidget({
    super.key,
    required this.log,
    this.onEdit,
    required this.formattedDate,
  });

  Color _getCategoryColor(String category) {
    switch (category) {
      case "Pekerjaan":
        return Colors.green.shade100;
      case "Pribadi":
        return Colors.blue.shade100;
      case "Urgent":
        return Colors.red.shade100;
      default:
        return Colors.grey.shade200;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: _getCategoryColor(log.category),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.note_alt_outlined, color: Colors.blue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      log.desc,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),

              // AREA TAP DIPERBESAR
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onEdit,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: const Icon(Icons.edit_outlined, color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
