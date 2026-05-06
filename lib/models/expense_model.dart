class Expense {
  int? id;
  int occasionId;
  String name;
  double totalAmount;
  String splitMode; // 'equal' or 'custom'

  Expense({
    this.id,
    required this.occasionId,
    required this.name,
    required this.totalAmount,
    required this.splitMode,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'occasionId': occasionId,
      'name': name,
      'totalAmount': totalAmount,
      'splitMode': splitMode,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      occasionId: map['occasionId'],
      name: map['name'],
      totalAmount: map['totalAmount'],
      splitMode: map['splitMode'],
    );
  }
}