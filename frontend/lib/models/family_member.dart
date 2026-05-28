class FamilyMember {
  final int id;
  final int userId;
  final String name;
  final String relation;
  final String initials;

  FamilyMember({
    required this.id,
    required this.userId,
    required this.name,
    required this.relation,
    required this.initials,
  });

  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    return FamilyMember(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      relation: json['relation'],
      initials: json['initials'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'relation': relation,
      'initials': initials,
    };
  }

  FamilyMember copyWith({
    int? id,
    int? userId,
    String? name,
    String? relation,
    String? initials,
  }) {
    return FamilyMember(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      relation: relation ?? this.relation,
      initials: initials ?? this.initials,
    );
  }
}
