class Occasion {
  int? id;
  String name;
  String? date;
  String? notes;

  Occasion({
    this.id,
    required this.name,
    this.date,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'date': date,
      'notes': notes,
    };
  }

  factory Occasion.fromMap(Map<String, dynamic> map) {
    return Occasion(
      id: map['id'],
      name: map['name'],
      date: map['date'],
      notes: map['notes'],
    );
  }
}