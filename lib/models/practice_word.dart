class PracticeWord {
  final String id;
  final String textUr;
  final String textEn;
  final String? category;
  final String? difficulty;
  final String? exerciseType;
  final String? personaTag;
  final String? ageGroup;
  final int? phase;

  PracticeWord({
    required this.id,
    required this.textUr,
    required this.textEn,
    this.category,
    this.difficulty,
    this.exerciseType,
    this.personaTag,
    this.ageGroup,
    this.phase,
  });

  factory PracticeWord.fromMap(Map<String, dynamic> map) {
    return PracticeWord(
      id: map['id'] as String,
      textUr: (map['text_ur'] as String?) ?? '',
      textEn: (map['text_en'] as String?) ?? '',
      category: map['category'] as String?,
      difficulty: map['difficulty'] as String?,
      exerciseType: map['exercise_type'] as String?,
      personaTag: map['persona_tag'] as String?,
      ageGroup: map['age_group'] as String?,
      phase: map['phase'] != null ? (map['phase'] as num).toInt() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text_ur': textUr,
      'text_en': textEn,
      'category': category,
      'difficulty': difficulty,
      'exercise_type': exerciseType,
      'persona_tag': personaTag,
      'age_group': ageGroup,
      'phase': phase,
    };
  }
}
