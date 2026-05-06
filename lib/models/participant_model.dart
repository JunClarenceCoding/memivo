class Participant {
  int? id;
  int expenseId;
  String name;
  double amountOwed;
  double paidAtCounter;
  double paidBack;

  Participant({
    this.id,
    required this.expenseId,
    required this.name,
    required this.amountOwed,
    required this.paidAtCounter,
    required this.paidBack,
  });

  // Auto status
  String get status {
    final balance = paidAtCounter + paidBack - amountOwed;
    if (balance >= 0) return 'Already Paid';
    if (paidAtCounter > 0 || paidBack > 0) return 'Partial';
    return 'Unpaid';
  }

  // Net balance — positive means others owe them
  double get balance => paidAtCounter - amountOwed + paidBack;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'expenseId': expenseId,
      'name': name,
      'amountOwed': amountOwed,
      'paidAtCounter': paidAtCounter,
      'paidBack': paidBack,
    };
  }

  factory Participant.fromMap(Map<String, dynamic> map) {
    return Participant(
      id: map['id'],
      expenseId: map['expenseId'],
      name: map['name'],
      amountOwed: map['amountOwed'],
      paidAtCounter: map['paidAtCounter'],
      paidBack: map['paidBack'],
    );
  }
}