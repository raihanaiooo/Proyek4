import 'package:mongo_dart/mongo_dart.dart';
import 'package:hive/hive.dart';
part 'log_model.g.dart';

@HiveType(typeId: 0)
class LogModel {
  @HiveField(0)
  final ObjectId? id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String date;

  @HiveField(3)
  final String desc;

  @HiveField(4)
  final String category;

  @HiveField(5)
  final String username;

  @HiveField(6)
  final String authorId;

  @HiveField(7)
  final String teamId;

  LogModel({
    this.id,
    required this.title,
    required this.date,
    required this.desc,
    required this.category,
    required this.username,
    required this.authorId,
    required this.teamId,
  });

  Map<String, dynamic> toMap() {
    return {
      '_id': id ?? ObjectId(),
      'title': title,
      'date': date,
      'desc': desc,
      'category': category,
      'username': username,
      'authorId': authorId,
      'teamId': teamId,
    };
  }

  factory LogModel.fromMap(Map<String, dynamic> map) {
    return LogModel(
      id: map['_id'] as ObjectId?,
      title: map['title'] ?? '',
      date: map['date'] ?? '',
      desc: map['desc'] ?? '',
      category: map['category'] ?? '',
      username: map['username'] ?? '',
      authorId: map['authorId'] ?? 'unknown_user',
      teamId: map['teamId'] ?? 'no_team',
    );
  }
}
