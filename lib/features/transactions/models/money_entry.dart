import '../../family/models/family_member.dart';

/// Extends the title/amount/income model from practical work 1.
class MoneyEntry {
  const MoneyEntry({
    required this.id,
    this.familyId = 'family-main',
    required this.title,
    required this.amount,
    required this.income,
    required this.category,
    required this.date,
    required this.owner,
    this.shared = true,
    this.note = '',
    this.favorite = false,
  });
  String get ownerId => FamilyMember.idForName(owner);
  final String familyId;
  final String id, title, category, owner, note;
  final int amount;
  final bool income, shared, favorite;
  final DateTime date;
  String get icon => category == 'Азық-түлік' ? 'food' : 'wallet';
  MoneyEntry copyWith({bool? favorite}) => MoneyEntry(
    id: id,
    familyId: familyId,
    title: title,
    amount: amount,
    income: income,
    category: category,
    date: date,
    owner: owner,
    shared: shared,
    note: note,
    favorite: favorite ?? this.favorite,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'familyId': familyId,
    'title': title,
    'amount': amount,
    'income': income,
    'category': category,
    'date': date.toIso8601String(),
    'owner': owner,
    'ownerId': ownerId,
    'shared': shared,
    'note': note,
    'favorite': favorite,
  };
  factory MoneyEntry.fromJson(Map<String, dynamic> json) => MoneyEntry(
    id: json['id'] as String,
    familyId: json['familyId'] as String? ?? 'family-main',
    title: json['title'] as String,
    amount: json['amount'] as int,
    income: json['income'] as bool,
    category: json['category'] as String,
    date: DateTime.parse(json['date'] as String),
    owner: json['owner'] as String,
    shared: json['shared'] as bool,
    note: json['note'] as String,
    favorite: json['favorite'] as bool,
  );
}
