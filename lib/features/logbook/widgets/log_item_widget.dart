import 'package:flutter/material.dart';
import '../models/log_model.dart';

class LogItemWidget extends StatelessWidget {
  final LogModel log;
  final VoidCallback? onEdit;
  final String formattedDate;
  final Color? categoryColor;

  const LogItemWidget({
    super.key,
    required this.log,
    this.onEdit,
    required this.formattedDate,
    this.categoryColor,
  });

  Color _getDefaultColor(String category) {
    switch (category) {
      case "Mechanical":
        return Colors.green.shade100;
      case "Electronic":
        return Colors.blue.shade100;
      case "Software":
        return Colors.purple.shade100;
      default:
        return Colors.grey.shade200;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case "Mechanical":
        return Icons.build;
      case "Electronic":
        return Icons.electrical_services;
      case "Software":
        return Icons.code;
      default:
        return Icons.note_alt_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = categoryColor ?? _getDefaultColor(log.category);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: color,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ikon kategori
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getCategoryIcon(log.category),
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Judul + ikon sync & privasi
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          log.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            log.isSynced ? Icons.cloud_done : Icons.cloud_off,
                            size: 14,
                            color: log.isSynced
                                ? Colors.green.shade400
                                : Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            log.isPublic ? Icons.public : Icons.lock,
                            size: 14,
                            color: Colors.grey.shade500,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Deskripsi
                  Text(
                    log.desc,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                  ),
                  const SizedBox(height: 8),

                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          log.category,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Tombol edit — hanya muncul jika isOwner
            if (onEdit != null)
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onEdit,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Icon(Icons.edit_outlined, color: Colors.grey.shade600),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
