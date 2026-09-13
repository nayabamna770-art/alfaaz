class UserModel {
  final String id;
  final String alfaazId;
  final String? name;
  final String languagePref;
  final String? personaTag;
  final DateTime? createdAt;

  UserModel({
    required this.id,
    required this.alfaazId,
    this.name,
    this.languagePref = 'ur',
    this.personaTag,
    this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      alfaazId: map['alfaaz_id'] as String,
      name: map['name'] as String?,
      languagePref: (map['language_pref'] as String?) ?? 'ur',
      personaTag: map['persona_tag'] as String?,
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
      'language_pref': languagePref,
      'persona_tag': personaTag,
    };
  }
}
