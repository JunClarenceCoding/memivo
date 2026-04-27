class Birthday {
  int? id;
  String name;
  String relationship;
  String birthdate;
  String? notes;
  String? photoPath;

  Birthday({
    this.id,
    required this.name,
    required this.relationship,
    required this.birthdate,
    this.notes,
    this.photoPath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'relationship': relationship,
      'birthdate': birthdate,
      'notes': notes,
      'photoPath': photoPath,
    };
  }

  factory Birthday.fromMap(Map<String, dynamic> map) {
    return Birthday(
      id: map['id'],
      name: map['name'],
      relationship: map['relationship'],
      birthdate: map['birthdate'],
      notes: map['notes'],
      photoPath: map['photoPath'],
    );
  }
}