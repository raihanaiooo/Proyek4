class LogModel {
  final String title;
  final String date;
  final String desc;
  final String category;

  LogModel({
    required this.title,
    required this.date,
    required this.desc,
    required this.category,
  });

  factory LogModel.fromMap(Map<String, dynamic> map) {
    return LogModel(
      title: map['title'] ?? '',
      date: map['date'] ?? '',
      desc: map['desc'] ?? '',
      category: map['category'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {'title': title, 'date': date, 'desc': desc, 'category': category};
  }
}
