import '../../family/models/family_member.dart';

class SavingsGoal {
  const SavingsGoal({
    required this.id,
    this.familyId = 'family-main',
    required this.title,
    required this.target,
    required this.date,
    required this.contributions,
    this.shared = true,
    this.owner = 'Данияр',
  });
  String get ownerId => FamilyMember.idForName(owner);
  final String familyId;
  final String id, title, owner;
  final int target;
  final DateTime date;
  final bool shared;
  final Map<String, int> contributions;
  int get saved => contributions.values.fold(0, (a, b) => a + b);
  double get progress => target <= 0 ? 0 : (saved / target).clamp(0, 1);
  SavingsGoal contribute(String person, int amount) => SavingsGoal(
    id: id,
    familyId: familyId,
    title: title,
    target: target,
    date: date,
    shared: shared,
    owner: owner,
    contributions: {
      ...contributions,
      person: (contributions[person] ?? 0) + amount,
    },
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'familyId': familyId,
    'title': title,
    'target': target,
    'date': date.toIso8601String(),
    'shared': shared,
    'owner': owner,
    'ownerId': ownerId,
    'contributions': contributions,
  };
  factory SavingsGoal.fromJson(Map<String, dynamic> json) => SavingsGoal(
    id: json['id'] as String,
    familyId: json['familyId'] as String? ?? 'family-main',
    title: json['title'] as String,
    target: json['target'] as int,
    date: DateTime.parse(json['date'] as String),
    shared: json['shared'] as bool,
    owner: json['owner'] as String? ?? 'Данияр',
    contributions: Map<String, int>.from(json['contributions'] as Map),
  );
}
