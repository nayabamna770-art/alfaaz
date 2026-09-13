import 'package:flutter/material.dart';
import '../../l10n/app_strings.dart';
import '../../models/assessment_question.dart';
import '../../theme/app_colors.dart';
import '../../widgets/bol_mascot_widget.dart';
import 'signup_screen.dart';

class SelfAssessmentScreen extends StatefulWidget {
  final String selectedLang;

  const SelfAssessmentScreen({
    super.key,
    required this.selectedLang,
  });

  @override
  State<SelfAssessmentScreen> createState() => _SelfAssessmentScreenState();
}

class _SelfAssessmentScreenState extends State<SelfAssessmentScreen>
    with SingleTickerProviderStateMixin {
  // Map of question id -> bool (true = Yes, false = No)
  final Map<int, bool> _answers = {};

  // 2 Stages total per PART A
  int _currentStage = 0; // 0 = Stage 1 (Stuttering), 1 = Stage 2 (Confidence & Word-Finding)

  // Stage transition animation: "Bol carries you forward"
  late AnimationController _transitionController;
  late Animation<Offset> _slideOutAnimation;
  late Animation<double> _fadeAnimation;

  bool _isTransitioning = false;
  BolPose _currentBolPose = BolPose.thoughtful;

  bool get _isUrdu => widget.selectedLang == 'ur';

  List<AssessmentQuestion> get _currentQuestions {
    final category = _currentStage == 0
        ? PersonaCategory.stuttering
        : PersonaCategory.confidenceWordRetrieval;
    return AppStrings.assessmentQuestions
        .where((q) => q.category == category)
        .toList();
  }

  bool get _canProceedCurrentStage {
    for (final q in _currentQuestions) {
      if (!_answers.containsKey(q.id)) {
        return false;
      }
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    _transitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _slideOutAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-1.15, 0.0),
    ).animate(
      CurvedAnimation(
        parent: _transitionController,
        curve: const Interval(0.0, 0.55, curve: Curves.easeInOutCubic),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _transitionController,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _transitionController.dispose();
    super.dispose();
  }

  void _onAnswer(int questionId, bool value) {
    setState(() {
      _answers[questionId] = value;
    });
  }

  /// PART B: "Bol carries you forward" one-shot transition
  void _handleStageCompletion() {
    if (_currentStage == 0) {
      // 1. Bol does a one-shot hop gesture
      setState(() {
        _isTransitioning = true;
        _currentBolPose = BolPose.hop;
      });

      // 2. Visually usher current card off-screen and bring next card in
      _transitionController.forward().then((_) {
        setState(() {
          _currentStage = 1;
          _currentBolPose = BolPose.handOnChest; // Stage 2 pose
          _isTransitioning = false;
        });
        _transitionController.reset();
      });
    } else {
      _computeAndProceed();
    }
  }

  void _handleBack() {
    if (_currentStage > 0 && !_isTransitioning) {
      setState(() {
        _currentStage = 0;
        _currentBolPose = BolPose.thoughtful;
      });
    }
  }

  /// PART A: persona_tag logic
  /// - "stuttering" if Stage 1 gets ≥2 yes
  /// - "confidence_word_retrieval" if Stage 2 gets ≥2 yes
  /// - "blended" if both qualify
  /// - Internal only per Revision 4
  void _computeAndProceed() {
    int s1Yes = 0; // Stage 1 (questions 1, 2, 3)
    int s2Yes = 0; // Stage 2 (questions 4, 5, 6)

    for (int i = 1; i <= 3; i++) {
      if (_answers[i] == true) s1Yes++;
    }
    for (int i = 4; i <= 6; i++) {
      if (_answers[i] == true) s2Yes++;
    }

    final bool s1Qualifies = s1Yes >= 2;
    final bool s2Qualifies = s2Yes >= 2;

    String finalPersonaTag;
    if (s1Qualifies && s2Qualifies) {
      finalPersonaTag = 'blended';
    } else if (s1Qualifies) {
      finalPersonaTag = 'stuttering';
    } else if (s2Qualifies) {
      finalPersonaTag = 'confidence_word_retrieval';
    } else {
      // If neither gets >=2, assign based on higher yes count or blended
      if (s1Yes > s2Yes) {
        finalPersonaTag = 'stuttering';
      } else if (s2Yes > s1Yes) {
        finalPersonaTag = 'confidence_word_retrieval';
      } else {
        finalPersonaTag = 'blended';
      }
    }

    // Step 5: Signup Screen (passing internal persona_tag)
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => SignupScreen(
          languagePref: widget.selectedLang,
          personaTag: finalPersonaTag,
        ),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _isUrdu ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(
          backgroundColor: AppColors.cream,
          elevation: 0,
          leading: _currentStage > 0
              ? IconButton(
                  icon: Icon(
                    _isUrdu
                        ? Icons.arrow_forward_rounded
                        : Icons.arrow_back_rounded,
                    color: AppColors.deepCharcoal,
                  ),
                  onPressed: _handleBack,
                )
              : null,
          title: Text(
            '${_isUrdu ? AppStrings.stageCountUr : AppStrings.stageCountEn} ${_currentStage + 1} ${_isUrdu ? AppStrings.ofUr : AppStrings.ofEn} 2',
            style: const TextStyle(
              color: AppColors.mutedCharcoal,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Stage Progress Bar
              LinearProgressIndicator(
                value: (_currentStage + 1) / 2.0,
                backgroundColor: AppColors.borderCharcoal,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.darkOlive),
                minHeight: 4,
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 16,
                  ),
                  child: Column(
                    children: [
                      // Bol Mascot with Pose per Stage + Hop gesture on transition
                      BolMascotWidget(
                        key: ValueKey(_currentBolPose),
                        pose: _currentBolPose,
                        size: 105,
                        showSoundwave: _currentStage == 0,
                      ),
                      const SizedBox(height: 12),

                      // Animated Stage Card Container (Ushers off-screen per Part B)
                      AnimatedBuilder(
                        animation: _transitionController,
                        builder: (context, child) {
                          if (_isTransitioning) {
                            return SlideTransition(
                              position: _slideOutAnimation,
                              child: FadeTransition(
                                opacity: _fadeAnimation,
                                child: _buildStageContent(_currentStage),
                              ),
                            );
                          }
                          return _buildStageContent(_currentStage);
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom CTA
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: (_canProceedCurrentStage && !_isTransitioning)
                        ? _handleStageCompletion
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.darkOlive,
                      foregroundColor: AppColors.cream,
                      disabledBackgroundColor:
                          AppColors.darkOlive.withValues(alpha: 0.35),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      _currentStage == 0
                          ? (_isUrdu ? 'اگلا مرحلہ' : 'Next Stage')
                          : (_isUrdu ? AppStrings.continueBtnUr : AppStrings.continueBtnEn),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStageContent(int stageIndex) {
    final stageTitle = stageIndex == 0
        ? (_isUrdu ? AppStrings.stage1TitleUr : AppStrings.stage1TitleEn)
        : (_isUrdu ? AppStrings.stage2TitleUr : AppStrings.stage2TitleEn);

    final stageSubtitle = stageIndex == 0
        ? (_isUrdu ? AppStrings.stage1SubtitleUr : AppStrings.stage1SubtitleEn)
        : (_isUrdu ? AppStrings.stage2SubtitleUr : AppStrings.stage2SubtitleEn);

    return Column(
      children: [
        // Stage Header
        Text(
          stageTitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.deepCharcoal,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          stageSubtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.mutedCharcoal,
            fontSize: 13,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),

        // 3 Questions with Persona-Themed Icons (PART B: Item 3)
        ..._currentQuestions.map((q) => _buildQuestionCard(q, stageIndex)),
      ],
    );
  }

  Widget _buildQuestionCard(AssessmentQuestion question, int stageIndex) {
    final bool? currentAnswer = _answers[question.id];
    // Strict locale-separation per PART A
    final questionText =
        _isUrdu ? question.questionUr : question.questionEn;

    // Small persona-themed icon per question (PART B: Item 3)
    // Stage 1: soundwave icon | Stage 2: heartbeat icon
    final IconData questionIcon = stageIndex == 0
        ? Icons.graphic_eq_rounded
        : Icons.monitor_heart_outlined;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.creamSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderCharcoal),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Small persona-themed icon beside question
              Container(
                width: 32,
                height: 32,
                margin: EdgeInsets.only(
                  right: _isUrdu ? 0 : 12,
                  left: _isUrdu ? 12 : 0,
                  top: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.warmGolden.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  questionIcon,
                  color: AppColors.darkOlive,
                  size: 18,
                ),
              ),

              // Question Text
              Expanded(
                child: Text(
                  questionText,
                  style: const TextStyle(
                    color: AppColors.deepCharcoal,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Binary Yes / No options only (PART A)
          Row(
            children: [
              Expanded(
                child: _buildChoiceChip(
                  label: _isUrdu ? AppStrings.yesUr : AppStrings.yesEn,
                  isSelected: currentAnswer == true,
                  onTap: () => _onAnswer(question.id, true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildChoiceChip(
                  label: _isUrdu ? AppStrings.noUr : AppStrings.noEn,
                  isSelected: currentAnswer == false,
                  onTap: () => _onAnswer(question.id, false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 44,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.darkOlive : AppColors.cream,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.darkOlive : AppColors.borderCharcoal,
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.cream : AppColors.deepCharcoal,
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
