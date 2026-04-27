class Todo {
  int? id;
  String title;
  String priority;
  String status;
  String? dueDate;

  Todo({
    required this.id,
    required this.title,
    required this.priority,
    required this.status,
    this.dueDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'priority': priority,
      'status': status,
      'dueDate': dueDate,
    };
  }

  factory Todo.fromMap(Map<String, dynamic> map) {
    return Todo(
      id: map['id'],
      title: map['title'],
      priority: map['priority'],
      status: map['status'],
      dueDate: map['dueDate'],
    );
  }
}