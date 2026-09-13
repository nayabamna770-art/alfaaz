enum PersonaCategory {
  stuttering,
  confidenceWordRetrieval,
}

class AssessmentQuestion {
  final int id;
  final PersonaCategory category;
  final String questionEn;
  final String questionUr;

  const AssessmentQuestion({
    required this.id,
    required this.category,
    required this.questionEn,
    required this.questionUr,
  });
}
