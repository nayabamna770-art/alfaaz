import '../models/assessment_question.dart';

class AppStrings {
  // Splash & Tagline
  static const String appName = 'Alfaaz';
  static const String appNameUrdu = 'الفاظ';
  static const String taglineEn = 'Every word, truly yours.';
  static const String taglineUr = 'ہر لفظ، تمہارا۔';

  // Intro Slides
  static const String intro1TitleEn = 'Comfortable alone, hesitant with others?';
  static const String intro1TitleUr = 'اکیلے روانی، محفل میں جھجک؟';
  static const String intro1BodyEn =
      'That is completely normal. Most people speak with ease in private, but feel their words freeze around others.';
  static const String intro1BodyUr =
      'یہ بالکل قدرتی بات ہے۔ اکثر لوگ تنہائی میں آسانی سے بولتے ہیں، مگر دوسروں کے سامنے الفاظ رکنے لگتے ہیں۔';

  static const String intro2TitleEn = 'How Alfaaz works for you';
  static const String intro2TitleUr = 'الفاظ کس طرح آپ کی مدد کرتا ہے؟';
  static const String intro2BodyEn =
      'Listen to clear speech models, record your own voice, and reflect on your own progress at your own pace.';
  static const String intro2BodyUr =
      'الفاظ کی آواز سنیں، اپنی آواز ریکارڈ کریں، اور بغیر کسی فیصلے یا پریشر کے اپنی روانی کو بہتر بنائیں۔';

  static const String intro3TitleEn = 'Two languages, one seamless journey';
  static const String intro3TitleUr = 'دونوں زبانوں میں مکمل آسانی';
  static const String intro3BodyEn =
      'Practice in Urdu or English anytime. Switch instantly with full bilingual support designed from day one.';
  static const String intro3BodyUr =
      'اردو ہو یا انگریزی، اپنی مرضی کے مطابق مشق کریں۔ روز اول سے دونوں زبانوں کے لیے تیار۔';

  static const String nextEn = 'Next';
  static const String nextUr = 'آگے بڑھیں';
  static const String getStartedEn = 'Get Started';
  static const String getStartedUr = 'شروع کریں';
  static const String skipEn = 'Skip';
  static const String skipUr = 'چھوڑیں';

  // Language Selection
  static const String chooseLanguageTitleEn = 'Choose your preferred language';
  static const String chooseLanguageTitleUr = 'اپنی پسندیدہ زبان منتخب کریں';
  static const String chooseLanguageSubtitleEn =
      'You can always change this later in Settings.';
  static const String chooseLanguageSubtitleUr =
      'آپ اسے بعد میں ترتیبات میں بھی بدل سکتے ہیں۔';
  static const String urduOptionTitle = 'اردو';
  static const String urduOptionSubtitle = 'Urdu (پاکستانی لہجہ)';
  static const String englishOptionTitle = 'English';
  static const String englishOptionSubtitle = 'English (UK / US)';
  static const String continueBtnEn = 'Continue';
  static const String continueBtnUr = 'جاری رکھیں';

  // Self-Assessment (Restructured: 2 categories, 6 questions, 2 stages)
  static const String assessmentTitleEn = 'Your Speaking Reflections';
  static const String assessmentTitleUr = 'آپ کے بولنے کے تجربات';
  static const String stage1TitleEn = 'Speech Rhythm & Flow';
  static const String stage1TitleUr = 'آواز کی روانی اور آسانی';
  static const String stage1SubtitleEn =
      'Reflecting on ease and physical comfort when starting words.';
  static const String stage1SubtitleUr =
      'بات شروع کرتے وقت الفاظ کی روانی اور طبعی آسانی کا جائزہ۔';

  static const String stage2TitleEn = 'Confidence & Word-Finding';
  static const String stage2TitleUr = 'خود اعتمادی اور الفاظ کا چناؤ';
  static const String stage2SubtitleEn =
      'Reflecting on speaking around others and finding words under pressure.';
  static const String stage2SubtitleUr =
      'لوگوں کے سامنے بات چیت اور گفتگو کے دوران الفاظ یاد آنے کا احساس۔';

  static const String stageCountEn = 'Stage';
  static const String stageCountUr = 'مرحلہ';
  static const String ofEn = 'of';
  static const String ofUr = 'از';

  static const String yesEn = 'Yes';
  static const String yesUr = 'ہاں';
  static const String noEn = 'No';
  static const String noUr = 'نہیں';

  // The 6 questions across 2 stages (PART A)
  static const List<AssessmentQuestion> assessmentQuestions = [
    // Stage 1 — Stuttering (questions 1, 2, 3 unchanged from doc §3.3)
    AssessmentQuestion(
      id: 1,
      category: PersonaCategory.stuttering,
      questionEn:
          'Do you sometimes notice repetitions, prolongations, or blocks when beginning to speak?',
      questionUr:
          'کیا آپ کو بات شروع کرتے وقت آواز کا رکنا، دہرانا یا کھنچ جانا محسوس ہوتا ہے؟',
    ),
    AssessmentQuestion(
      id: 2,
      category: PersonaCategory.stuttering,
      questionEn:
          'Do you feel physical tightness in your throat, mouth, or chest before certain words?',
      questionUr:
          'کیا مخصوص الفاظ بولنے سے پہلے آپ کو گلے، منہ یا سینے میں کھچاؤ محسوس ہوتا ہے؟',
    ),
    AssessmentQuestion(
      id: 3,
      category: PersonaCategory.stuttering,
      questionEn:
          'Do you ever pause, hesitate, or switch words to avoid speech tension?',
      questionUr:
          'کیا آپ بات کرتے ہوئے الجھن سے بچنے کے لیے لفظ بدل دیتے ہیں یا کچھ دیر خاموش ہو جاتے ہیں؟',
    ),

    // Stage 2 — Confidence & Word-Finding (questions 4, 5, 6 consolidated per PART A)
    AssessmentQuestion(
      id: 4,
      category: PersonaCategory.confidenceWordRetrieval,
      questionEn:
          'Do you speak fine alone or with close family, but feel nervous in groups?',
      questionUr:
          'کیا آپ اکیلے یا قریبی گھر والوں کے ساتھ روانی سے بولتے ہیں، مگر محفل یا لوگوں میں گھبراہٹ محسوس کرتے ہیں؟',
    ),
    AssessmentQuestion(
      id: 5,
      category: PersonaCategory.confidenceWordRetrieval,
      questionEn:
          'Do you often know what to say but the exact word won\'t come, especially when rushed or speaking to others?',
      questionUr:
          'کیا آپ کو معلوم ہوتا ہے کہ کیا کہنا ہے مگر صحیح لفظ عین وقت پر یاد نہیں آتا، خاص طور پر جلدی میں یا دوسروں سے بات کرتے ہوئے؟',
    ),
    AssessmentQuestion(
      id: 6,
      category: PersonaCategory.confidenceWordRetrieval,
      questionEn:
          'Do you avoid speaking up in class, at family gatherings, or when talking to new people, because of this?',
      questionUr:
          'کیا آپ اس وجہ سے کلاس میں، خاندانی تقریبات میں یا نئے لوگوں کے سامنے بولنے سے گریز کرتے ہیں؟',
    ),
  ];

  // Signup Screen
  static const String signupTitleEn = 'Create your Alfaaz account';
  static const String signupTitleUr = 'اپنا الفاظ اکاؤنٹ بنائیں';
  static const String signupSubtitleEn =
      'Save your daily practice and keep track of your unique speaking journey.';
  static const String signupSubtitleUr =
      'اپنے مشق کے سفر کو محفوظ کریں اور اپنی پیش رفت جاری رکھیں۔';
  static const String nameLabelEn = 'Full Name';
  static const String nameLabelUr = 'پورا نام';
  static const String nameHintEn = 'Enter your name';
  static const String nameHintUr = 'اپنا نام درج کریں';
  static const String ageLabelEn = 'Age';
  static const String ageLabelUr = 'عمر';
  static const String ageHintEn = 'Enter your age';
  static const String ageHintUr = 'اپنی عمر درج کریں';
  static const String errorInvalidAgeEn = 'Please enter a valid age.';
  static const String errorInvalidAgeUr = 'براہ کرم درست عمر درج کریں۔';
  static const String emailLabelEn = 'Email Address';
  static const String emailLabelUr = 'ای میل ایڈریس';
  static const String emailHintEn = 'you@example.com';
  static const String emailHintUr = 'name@example.com';
  static const String passwordLabelEn = 'Password';
  static const String passwordLabelUr = 'پاس ورڈ';
  static const String passwordHintEn = 'At least 6 characters';
  static const String passwordHintUr = 'کم از کم 6 حروف';
  static const String createAccountBtnEn = 'Create Account';
  static const String createAccountBtnUr = 'اکاؤنٹ بنائیں';
  static const String alreadyHaveAccountEn = 'Already have an account? Sign In';
  static const String alreadyHaveAccountUr = 'پہلے سے اکاؤنٹ موجود ہے؟ سائن ان کریں';
  static const String errorAllFieldsEn = 'Please fill in all fields.';
  static const String errorAllFieldsUr = 'براہ کرم تمام خانے پر کریں۔';
  static const String errorInvalidEmailEn = 'Enter a valid email address.';
  static const String errorInvalidEmailUr = 'درست ای میل ایڈریس درج کریں۔';
  static const String errorWeakPasswordEn = 'Password must be at least 6 characters.';
  static const String errorWeakPasswordUr = 'پاس ورڈ کم از کم 6 حروف کا ہونا چاہیے۔';
  static const String errorDuplicateEmailEn =
      'An account with this email already exists.';
  static const String errorDuplicateEmailUr =
      'اس ای میل پر پہلے سے اکاؤنٹ موجود ہے۔';
  static const String errorGeneralEn =
      'Something went wrong. Please check your connection and try again.';
  static const String errorGeneralUr =
      'کچھ غلط ہو گیا۔ براہ کرم اپنا انٹرنیٹ چیک کریں اور دوبارہ کوشش کریں۔';

  // Home Shell
  static const String homeWelcomeEn = 'Welcome to Alfaaz';
  static const String homeWelcomeUr = 'الفاظ میں خوش آمدید';
  static const String homeSubtitleEn = 'Every day is a steady step forward.';
  static const String homeSubtitleUr = 'ہر دن ایک نیا اور پُراعتماد قدم ہے۔';
  static const String alfaazIdLabelEn = 'Alfaaz ID:';
  static const String alfaazIdLabelUr = 'الفاظ شناختی کوڈ:';
  static const String navPracticeEn = 'Practice';
  static const String navPracticeUr = 'مشق';
  static const String navConfidenceEn = 'Confidence';
  static const String navConfidenceUr = 'خود اعتمادی';
  static const String navProgressEn = 'Progress';
  static const String navProgressUr = 'کارکردگی';
  static const String navSettingsEn = 'Settings';
  static const String navSettingsUr = 'ترتیبات';

  // Login Screen
  static const String loginTitleEn = 'Welcome back';
  static const String loginTitleUr = 'واپس خوش آمدید';
  static const String loginSubtitleEn = 'Sign in to continue your Alfaaz journey.';
  static const String loginSubtitleUr = 'اپنے الفاظ سفر کو جاری رکھنے کے لیے سائن ان کریں۔';
  static const String signInBtnEn = 'Sign In';
  static const String signInBtnUr = 'سائن ان کریں';
  static const String noAccountEn = "Don't have an account? Sign Up";
  static const String noAccountUr = 'اکاؤنٹ نہیں ہے؟ سائن اپ کریں';
  static const String invitedAsCaregiverEn = 'I was invited as a caregiver →';
  static const String invitedAsCaregiverUr = 'مجھے دیکھ بھال کرنے والے کے طور پر مدعو کیا گیا →';
  static const String errorWrongCredentialsEn =
      'Incorrect email or password. Please try again.';
  static const String errorWrongCredentialsUr =
      'ای میل یا پاس ورڈ غلط ہے۔ براہ کرم دوبارہ کوشش کریں۔';

  // Signup — Caregiver Section
  static const String caregiverRequiredUnder15En =
      'A caregiver is required for learners under 15.';
  static const String caregiverRequiredUnder15Ur =
      '15 سال سے کم عمر سیکھنے والوں کے لیے دیکھ بھال کرنے والا لازمی ہے۔';
  static const String caregiverSectionTitleEn = 'Add a caregiver — optional';
  static const String caregiverSectionTitleUr = 'دیکھ بھال کرنے والے کو شامل کریں — اختیاری';
  static const String caregiverSectionSubtitleEn =
      'A caregiver can view your progress and streaks. You can always add one later from Settings.';
  static const String caregiverSectionSubtitleUr =
      'دیکھ بھال کرنے والا آپ کی پیش رفت دیکھ سکتا ہے۔ آپ بعد میں ترتیبات سے بھی شامل کر سکتے ہیں۔';
  static const String caregiverNameLabelEn = 'Caregiver Full Name';
  static const String caregiverNameLabelUr = 'دیکھ بھال کرنے والے کا پورا نام';
  static const String caregiverNameHintEn = "Caregiver's name";
  static const String caregiverNameHintUr = 'دیکھ بھال کرنے والے کا نام';
  static const String caregiverEmailLabelEn = 'Caregiver Email';
  static const String caregiverEmailLabelUr = 'دیکھ بھال کرنے والے کی ای میل';
  static const String caregiverEmailHintEn = "caregiver@example.com";
  static const String caregiverEmailHintUr = 'caregiver@example.com';
  static const String skipAddLaterEn = 'Skip — add later';
  static const String skipAddLaterUr = 'چھوڑیں — بعد میں شامل کریں';
  static const String addCaregiverEn = '+ Add a caregiver';
  static const String addCaregiverUr = '+ دیکھ بھال کرنے والا شامل کریں';

  // Caregiver Claim Screen
  static const String claimTitleEn = 'Caregiver Signup';
  static const String claimTitleUr = 'دیکھ بھال کرنے والے کا سائن اپ';
  static const String claimSubtitleEn =
      'Enter the email address your learner used to invite you.';
  static const String claimSubtitleUr =
      'وہ ای میل درج کریں جس پر آپ کو مدعو کیا گیا تھا۔';
  static const String lookupInviteBtnEn = 'Look up my invite';
  static const String lookupInviteBtnUr = 'میری دعوت تلاش کریں';
  static const String noInviteFoundEn = 'No invite found for this email address.';
  static const String noInviteFoundUr = 'اس ای میل پر کوئی دعوت نہیں ملی۔';
  static const String claimWelcomeEn = 'Welcome,';
  static const String claimWelcomeUr = 'خوش آمدید،';
  static const String claimPasswordPromptEn =
      'Set a password to complete your caregiver account.';
  static const String claimPasswordPromptUr =
      'اپنے اکاؤنٹ کو مکمل کرنے کے لیے پاس ورڈ ترتیب دیں۔';
  static const String confirmPasswordLabelEn = 'Confirm Password';
  static const String confirmPasswordLabelUr = 'پاس ورڈ کی تصدیق';
  static const String confirmPasswordHintEn = 'Re-enter your password';
  static const String confirmPasswordHintUr = 'پاس ورڈ دوبارہ درج کریں';
  static const String completeSignupBtnEn = 'Complete Signup';
  static const String completeSignupBtnUr = 'سائن اپ مکمل کریں';
  static const String errorPasswordMismatchEn = 'Passwords do not match.';
  static const String errorPasswordMismatchUr = 'پاس ورڈ میل نہیں کھاتے۔';
  static const String claimSuccessEn =
      'Your caregiver account is ready!';
  static const String claimSuccessUr = 'آپ کا اکاؤنٹ تیار ہے!';

  // Caregiver Home Shell
  static const String caregiverHomeWelcomeEn = 'Caregiver View';
  static const String caregiverHomeWelcomeUr = 'دیکھ بھال کرنے والے کا صفحہ';
  static const String linkedLearnerEn = 'Linked Learner';
  static const String linkedLearnerUr = 'منسلک سیکھنے والا';
  static const String noLinkedLearnerEn =
      'No linked learner found. Ask your learner to add you from their Settings.';
  static const String noLinkedLearnerUr =
      'کوئی منسلک سیکھنے والا نہیں ملا۔ اپنے سیکھنے والے سے کہیں کہ وہ آپ کو ترتیبات سے شامل کرے۔';
  static const String currentStreakEn = 'Current streak';
  static const String currentStreakUr = 'موجودہ اسٹریک';
  static const String longestStreakEn = 'Longest streak';
  static const String longestStreakUr = 'سب سے لمبی اسٹریک';
  static const String daysEn = 'days';
  static const String daysUr = 'دن';
  static const String navLearnerEn = 'Learner';
  static const String navLearnerUr = 'سیکھنے والا';
  static const String signOutBtnEn = 'Sign Out';
  static const String signOutBtnUr = 'سائن آؤٹ';
  static const String caregiverIdLabelEn = 'Your Alfaaz ID:';
  static const String caregiverIdLabelUr = 'آپ کا الفاظ شناختی کوڈ:';

  // Practice Test Card (Slice 1)
  static const String practiceTestTitleEn = 'Practice Word';
  static const String practiceTestTitleUr = 'الفاظ کی مشق';
  static const String listenWordBtnEn = 'Listen to Word';
  static const String listenWordBtnUr = 'لفظ سنیں';
  static const String recordVoiceBtnEn = 'Record Your Voice';
  static const String recordVoiceBtnUr = 'اپنی آواز ریکارڈ کریں';
  static const String stopRecordingBtnEn = 'Stop Recording';
  static const String stopRecordingBtnUr = 'ریکارڈنگ روکیں';
  static const String ttsGuideClipEn = 'TTS Guide (Model)';
  static const String ttsGuideClipUr = 'رہنما تلفظ سنیں';
  static const String yourRecordingClipEn = 'Your Recording';
  static const String yourRecordingClipUr = 'آپ کی ریکارڈنگ';
  static const String reRecordBtnEn = 'Try Again';
  static const String reRecordBtnUr = 'دوبارہ ریکارڈ کریں';
  static const String howDidItFeelEn = 'How did it feel?';
  static const String howDidItFeelUr = 'آپ کو بولنا کیسا لگا؟';
  static const String feltEasyEn = 'Felt easy';
  static const String feltEasyUr = 'آسان لگا';
  static const String feltHardEn = 'Felt hard';
  static const String feltHardUr = 'مشکل لگا';
  static const String savedConfirmationEn = 'Saved! Great practice session.';
  static const String savedConfirmationUr = 'محفوظ ہو گیا! بہترین مشق۔';
  static const String practiceTestCardBtnEn = 'Try Practice Test Card →';
  static const String practiceTestCardBtnUr = 'مشق ٹیسٹ کارڈ آزمائیں ←';
}
