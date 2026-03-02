import 'package:flutter/material.dart';
import '../controller/log_controller.dart';
import '../models/log_model.dart';

class EditLogDialog extends StatefulWidget {
  final LogController controller;
  final LogModel log;
  final int index;

  const EditLogDialog({
    super.key,
    required this.controller,
    required this.log,
    required this.index,
  });

  @override
  State<EditLogDialog> createState() => _EditLogDialogState();
}

class _EditLogDialogState extends State<EditLogDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descController;

  late String _selectedCategory;

  final List<String> _categories = ["Pekerjaan", "Pribadi", "Urgent"];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.log.title);
    _descController = TextEditingController(text: widget.log.desc);
    _selectedCategory = widget.log.category;
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.green.shade500;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(Icons.edit_note, color: primaryColor),
          const SizedBox(width: 8),
          const Text(
            "Edit Catatan",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: "Judul",
                prefixIcon: Icon(Icons.title, color: primaryColor),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: primaryColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: "Deskripsi",
                prefixIcon: Icon(Icons.description, color: primaryColor),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: primaryColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: InputDecoration(
                labelText: "Kategori",
                prefixIcon: Icon(Icons.category, color: primaryColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: _categories
                  .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Batal", style: TextStyle(color: Colors.grey.shade700)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () async {
            await widget.controller.updateLog(
              widget.log,
              _titleController.text,
              _descController.text,
              _selectedCategory,
            );
            Navigator.pop(context);
          },
          child: const Text("Update"),
        ),
      ],
    );
  }
}
