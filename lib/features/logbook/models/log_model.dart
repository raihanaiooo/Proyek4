import 'package:mongo_dart/mongo_dart.dart';

class LogModel {
  final ObjectId? id;
  final String title;
  final String date;
  final String desc;
  final String category;

  LogModel({
    this.id,
    required this.title,
    required this.date,
    required this.desc,
    required this.category,
  });

  Map<String, dynamic> toMap() {
    return {
      '_id': id ?? ObjectId(),
      'title': title,
      'date': date,
      'desc': desc,
      'category': category,
    };
  }

  factory LogModel.fromMap(Map<String, dynamic> map) {
    return LogModel(
      id: map['_id'] as ObjectId?,
      title: map['title'] ?? '',
      date: map['date'] ?? '',
      desc: map['desc'] ?? '',
      category: map['category'] ?? '',
    );
  }
}
