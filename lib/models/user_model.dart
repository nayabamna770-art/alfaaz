class UserModel {
  final String id;
  final String alfaazId;
  final String? name;
  final int? age;
  final String languagePref;
  final String? personaTag;
  final String accountType;
  final DateTime? createdAt;

  UserModel({
    required this.id,
    required this.alfaazId,
    this.name,
    this.age,
    this.languagePref = 'ur',
    this.personaTag,
    this.accountType = 'learner',
    this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      alfaazId: map['alfaaz_id'] as String,
      name: map['name'] as String?,
      age: map['age'] != null ? (map['age'] as num).toInt() : null,
      languagePref: (map['language_pref'] as String?) ?? 'ur',
      personaTag: map['persona_tag'] as String?,
      accountType: (map['account_type'] as String?) ?? 'learner',
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'alfaaz_id': alfaazId,
      'name': name,
      ...?age == null ? null : {'age': age},
      'language_pref': languagePref,
      'persona_tag': personaTag,
      'account_type': accountType,
    };
  }
}

