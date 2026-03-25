import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:logbook_app_01/features/logbook/models/log_model.dart';
import 'package:logbook_app_01/features/logbook/controller/log_controller.dart';

class LogEditorPage extends StatefulWidget {
  final LogModel? log;
  final LogController controller;
  final String currentUserId;

  const LogEditorPage({
    super.key,
    this.log,
    required this.controller,
    required this.currentUserId,
  });

  @override
  State<LogEditorPage> createState() => _LogEditorPageState();
}

class _LogEditorPageState extends State<LogEditorPage> {
  late TextEditingController _titleController;
  late TextEditingController _descController;

  // Homework: kategori sesuai spesifikasi tugas
  final List<String> categories = ["Mechanical", "Electronic", "Software"];
  String? _selectedCategory;
  bool _isPublic = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.log?.title ?? '');
    _descController = TextEditingController(text: widget.log?.desc ?? '');
    _selectedCategory = widget.log?.category ?? categories.first;
    _isPublic = widget.log?.isPublic ?? false;
    _descController.addListener(() => setState(() {}));
  }

  void _save() async {
    if (_titleController.text.isEmpty || _descController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Judul dan isi tidak boleh kosong")),
      );
      return;
    }

    if (widget.log == null) {
      await widget.controller.addLog(
        _titleController.text,
        _descController.text,
        _selectedCategory!,
        isPublic: _isPublic,
      );
    } else {
      await widget.controller.updateLog(
        widget.log!,
        _titleController.text,
        _descController.text,
        _selectedCategory!,
        isPublic: _isPublic,
      );
    }

    if (mounted) Navigator.pop(context);
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case "Mechanical":
        return Colors.green;
      case "Electronic":
        return Colors.blue;
      case "Software":
        return Colors.purple;
      default:
        return Colors.grey;
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
        return Icons.label;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.log == null ? "Catatan Baru" : "Edit Catatan"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Editor"),
              Tab(text: "Pratinjau"),
            ],
          ),
          actions: [IconButton(icon: const Icon(Icons.save), onPressed: _save)],
        ),
        body: TabBarView(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: "Judul",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Homework: Dropdown Mechanical / Electronic / Software
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    items: categories.map((cat) {
                      return DropdownMenuItem(
                        value: cat,
                        child: Row(
                          children: [
                            Icon(
                              _getCategoryIcon(cat),
                              color: _getCategoryColor(cat),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(cat),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) =>
                        setState(() => _selectedCategory = value!),
                    decoration: const InputDecoration(
                      labelText: "Kategori",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Task 5: Toggle visibilitas privat/publik
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      _isPublic
                          ? "Publik (dapat dilihat tim)"
                          : "Privat (hanya saya)",
                      style: const TextStyle(fontSize: 14),
                    ),
                    secondary: Icon(
                      _isPublic ? Icons.public : Icons.lock,
                      color: _isPublic ? Colors.green : Colors.grey,
                    ),
                    value: _isPublic,
                    onChanged: (val) => setState(() => _isPublic = val),
                  ),
                  const SizedBox(height: 10),

                  Expanded(
                    child: TextField(
                      controller: _descController,
                      maxLines: null,
                      expands: true,
                      keyboardType: TextInputType.multiline,
                      decoration: const InputDecoration(
                        hintText: "Tulis laporan dengan format Markdown...",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Markdown(data: _descController.text),
          ],
        ),
      ),
    );
  }
}
