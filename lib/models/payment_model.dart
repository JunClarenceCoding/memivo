class Payment {
  int? id;
  int expenseId;
  String fromPerson;
  String toPerson;
  double amount;

  Payment({
    this.id,
    required this.expenseId,
    required this.fromPerson,
    required this.toPerson,
    required this.amount,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'expenseId': expenseId,
      'fromPerson': fromPerson,
      'toPerson': toPerson,
      'amount': amount,
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'],
      expenseId: map['expenseId'],
      fromPerson: map['fromPerson'],
      toPerson: map['toPerson'],
      amount: map['amount'],
    );
  }
}