import 'dart:convert';

class FamilyMember {
  const FamilyMember({
    required this.id,
    required this.familyId,
    required this.name,
  });
  final String id, familyId, name;
  // Names are immutable in this local demo. This also gives legacy records
  // deterministic IDs when migrating the previous lesson's saved data.
  static String idForName(String name) =>
      'member-${base64Url.encode(utf8.encode(name))}';
  Map<String, dynamic> toJson() => {
    'id': id,
    'familyId': familyId,
    'name': name,
  };
  factory FamilyMember.fromJson(Map<String, dynamic> json) => FamilyMember(
    id: json['id'] as String,
    familyId: json['familyId'] as String,
    name: json['name'] as String,
  );
}
