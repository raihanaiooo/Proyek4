import 'package:mongo_dart/mongo_dart.dart';
import 'package:hive/hive.dart';
part 'log_model.g.dart';

@HiveType(typeId: 0)
class LogModel {
  @HiveField(0)
  final String? id;

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

  @HiveField(8)
  final bool isSynced;

  @HiveField(9)
  final bool isPublic;

  LogModel({
    this.id,
    required this.title,
    required this.date,
    required this.desc,
    required this.category,
    required this.username,
    required this.authorId,
    required this.teamId,
    this.isSynced = false,
    this.isPublic = false,
  });

  LogModel copyWith({
    String? id,
    String? title,
    String? desc,
    String? date,
    String? category,
    String? username,
    String? authorId,
    String? teamId,
    bool? isSynced,
    bool? isPublic,
  }) {
    return LogModel(
      id: id ?? this.id,
      title: title ?? this.title,
      desc: desc ?? this.desc,
      date: date ?? this.date,
      category: category ?? this.category,
      username: username ?? this.username,
      authorId: authorId ?? this.authorId,
      teamId: teamId ?? this.teamId,
      isSynced: isSynced ?? this.isSynced,
      isPublic: isPublic ?? this.isPublic,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      '_id': id != null ? ObjectId.fromHexString(id!) : ObjectId(),
      'title': title,
      'date': date,
      'desc': desc,
      'category': category,
      'username': username,
      'authorId': authorId,
      'teamId': teamId,
      'isPublic': isPublic,
    };
  }

  factory LogModel.fromMap(Map<String, dynamic> map) {
    return LogModel(
      id: (map['_id'] as ObjectId?)?.toHexString(),
      title: map['title'] ?? '',
      date: map['date'] ?? '',
      desc: map['desc'] ?? '',
      category: map['category'] ?? '',
      username: map['username'] ?? '',
      authorId: map['authorId'] ?? 'unknown_user',
      teamId: map['teamId'] ?? 'no_team',
      isPublic: map['isPublic'] ?? false,
    );
  }
}
