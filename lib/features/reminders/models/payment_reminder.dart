class PaymentReminder {
  const PaymentReminder({
    required this.id,
    this.familyId = 'family-main',
    required this.title,
    required this.date,
    this.monthly = true,
    this.done = false,
  });
  final String familyId;
  final String id, title;
  final DateTime date;
  final bool monthly, done;
  PaymentReminder toggle() => PaymentReminder(
    id: id,
    familyId: familyId,
    title: title,
    date: date,
    monthly: monthly,
    done: !done,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'familyId': familyId,
    'title': title,
    'date': date.toIso8601String(),
    'monthly': monthly,
    'done': done,
  };
  factory PaymentReminder.fromJson(Map<String, dynamic> json) =>
      PaymentReminder(
        id: json['id'] as String,
        familyId: json['familyId'] as String? ?? 'family-main',
        title: json['title'] as String,
        date: DateTime.parse(json['date'] as String),
        monthly: json['monthly'] as bool,
        done: json['done'] as bool,
      );
}
