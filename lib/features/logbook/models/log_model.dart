class LogModel {
  final String title;
  final String date;
  final String desc;

  LogModel({required this.title, required this.date, required this.desc});

  factory LogModel.fromMap(Map<String, dynamic> map) {
    return LogModel(title: map['title'], date: map['date'], desc: map['desc']);
  }

  Map<String, dynamic> toMap() {
    return {'title': title, 'date': date, 'desc': desc};
  }
}
