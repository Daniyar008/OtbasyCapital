class Family {
  const Family({required this.id, required this.name});
  final String id, name;
  Map<String, dynamic> toJson() => {'id': id, 'name': name};
  factory Family.fromJson(Map<String, dynamic> json) =>
      Family(id: json['id'] as String, name: json['name'] as String);
}
