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
    this.paidBack = 0, 
  });

  String get status {
    final total = paidAtCounter + paidBack;
    if (total >= amountOwed - 0.01) return 'Already Paid';
    if (total > 0) return 'Partial';
    return 'Unpaid';
  }

  double get balance => paidAtCounter + paidBack - amountOwed;

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
      paidBack: map['paidBack'] ?? 0,
    );
  }
}