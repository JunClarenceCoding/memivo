class Cafe {
  int? id;
  String drinkName;
  String cafeName;
  String drinkType;
  int rating;
  String? price;
  String? date;
  String? location;
  String? notes;
  String? photoPath;

  Cafe({
    this.id,
    required this.drinkName,
    required this.cafeName,
    required this.drinkType,
    required this.rating,
    this.price,
    this.date,
    this.location,
    this.notes,
    this.photoPath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'drinkName': drinkName,
      'cafeName': cafeName,
      'drinkType': drinkType,
      'rating': rating,
      'price': price,
      'date': date,
      'location': location,
      'notes': notes,
      'photoPath': photoPath,
    };
  }

  factory Cafe.fromMap(Map<String, dynamic> map) {
    return Cafe(
      id: map['id'],
      drinkName: map['drinkName'],
      cafeName: map['cafeName'],
      drinkType: map['drinkType'],
      rating: map['rating'],
      price: map['price'],
      date: map['date'],
      location: map['location'],
      notes: map['notes'],
      photoPath: map['photoPath'],
    );
  }
}