import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../l10n/app_strings.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/bol_mascot_widget.dart';
import '../home/home_shell_screen.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  final String languagePref;
  final String personaTag;

  const SignupScreen({
    super.key,
    required this.languagePref,
    required this.personaTag,
  });

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _caregiverNameController = TextEditingController();
  final _caregiverEmailController = TextEditingController();

  final _nameFocusNode = FocusNode();
  final _ageFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _caregiverNameFocusNode = FocusNode();
  final _caregiverEmailFocusNode = FocusNode();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  bool _caregiverSectionExpanded = false;

  bool get _isUrdu => widget.languagePref == 'ur';

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _caregiverNameController.dispose();
    _caregiverEmailController.dispose();
    _nameFocusNode.dispose();
    _ageFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _caregiverNameFocusNode.dispose();
    _caregiverEmailFocusNode.dispose();
    super.dispose();
  }


  Future<void> _handleSignup() async {
    setState(() {
      _errorMessage = null;
    });

    final name = _nameController.text.trim();
    final ageText = _ageController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty || ageText.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage =
            _isUrdu ? AppStrings.errorAllFieldsUr : AppStrings.errorAllFieldsEn;
      });
      return;
    }

    final parsedAge = int.tryParse(ageText);
    if (parsedAge == null || parsedAge < 3 || parsedAge > 100) {
      setState(() {
        _errorMessage = _isUrdu
            ? AppStrings.errorInvalidAgeUr
            : AppStrings.errorInvalidAgeEn;
      });
      return;
    }

    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(email)) {
      setState(() {
        _errorMessage = _isUrdu
            ? AppStrings.errorInvalidEmailUr
            : AppStrings.errorInvalidEmailEn;
      });
      return;
    }

    if (password.length < 6) {
      setState(() {
        _errorMessage = _isUrdu
            ? AppStrings.errorWeakPasswordUr
            : AppStrings.errorWeakPasswordEn;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userModel = await SupabaseService.signUp(
        name: name,
        age: parsedAge,
        email: email,
        password: password,
        languagePref: widget.languagePref,
        personaTag: widget.personaTag,
      );

      // Optional caregiver invite — silently ignored if it fails
      final cgName = _caregiverNameController.text.trim();
      final cgEmail = _caregiverEmailController.text.trim();
      if (cgName.isNotEmpty && cgEmail.isNotEmpty) {
        try {
          await SupabaseService.insertCaregiverInvite(
            learnerId: userModel.id,
            caregiverName: cgName,
            caregiverEmail: cgEmail,
            learnerName: name,
          );
        } catch (_) {
          // Invite insertion failure must never block learner signup
        }
      }

      if (!mounted) return;

      // Navigate to Home Shell upon success (first time arrival)
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (_, _, _) => const HomeShellScreen(isFirstTime: true),
          transitionsBuilder: (_, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 350),
        ),
        (route) => false,
      );

    } on AuthException catch (e) {
      debugPrint('[DEBUG_SIGNUP] Caught AuthException: $e');
      setState(() {
        if (e.message.toLowerCase().contains('already registered') ||
            e.message.toLowerCase().contains('user already exists')) {
          _errorMessage = _isUrdu
              ? AppStrings.errorDuplicateEmailUr
              : AppStrings.errorDuplicateEmailEn;
        } else if (e.message.toLowerCase().contains('weak') ||
            e.message.toLowerCase().contains('password')) {
          _errorMessage = _isUrdu
              ? AppStrings.errorWeakPasswordUr
              : AppStrings.errorWeakPasswordEn;
        } else {
          _errorMessage = e.message;
        }
      });
    } catch (e, st) {
      debugPrint('[DEBUG_SIGNUP] Caught unexpected error during signup: $e\n$st');
      setState(() {
        _errorMessage =
            _isUrdu ? AppStrings.errorGeneralUr : AppStrings.errorGeneralEn;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _isUrdu ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppColors.cream,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Bol Mascot in Encouraging state
                    const Center(
                      child: BolMascotWidget(
                        state: BolState.encouraging,
                        size: 100,
                        showSoundwave: false,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Title
                    Text(
                      _isUrdu
                          ? AppStrings.signupTitleUr
                          : AppStrings.signupTitleEn,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.deepCharcoal,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Subtitle
                    Text(
                      _isUrdu
                          ? AppStrings.signupSubtitleUr
                          : AppStrings.signupSubtitleEn,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.mutedCharcoal,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Error Box (if any)
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFECEC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFFE57373),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: Color(0xFFC62828),
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: Color(0xFFC62828),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],

                    // Name Field
                    Text(
                      _isUrdu
                          ? AppStrings.nameLabelUr
                          : AppStrings.nameLabelEn,
                      style: const TextStyle(
                        color: AppColors.deepCharcoal,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _nameController,
                      focusNode: _nameFocusNode,
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) {
                        FocusScope.of(context).requestFocus(_ageFocusNode);
                      },
                      decoration: InputDecoration(
                        hintText: _isUrdu
                            ? AppStrings.nameHintUr
                            : AppStrings.nameHintEn,
                        prefixIcon: const Icon(
                          Icons.person_outline_rounded,
                          color: AppColors.mutedCharcoal,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Age Field
                    Text(
                      _isUrdu
                          ? AppStrings.ageLabelUr
                          : AppStrings.ageLabelEn,
                      style: const TextStyle(
                        color: AppColors.deepCharcoal,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _ageController,
                      focusNode: _ageFocusNode,
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) {
                        FocusScope.of(context).requestFocus(_emailFocusNode);
                      },
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return _isUrdu
                              ? AppStrings.errorAllFieldsUr
                              : AppStrings.errorAllFieldsEn;
                        }
                        final parsed = int.tryParse(value.trim());
                        if (parsed == null || parsed < 3 || parsed > 100) {
                          return _isUrdu
                              ? AppStrings.errorInvalidAgeUr
                              : AppStrings.errorInvalidAgeEn;
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: _isUrdu
                            ? AppStrings.ageHintUr
                            : AppStrings.ageHintEn,
                        prefixIcon: const Icon(
                          Icons.cake_outlined,
                          color: AppColors.mutedCharcoal,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Email Field
                    Text(
                      _isUrdu
                          ? AppStrings.emailLabelUr
                          : AppStrings.emailLabelEn,
                      style: const TextStyle(
                        color: AppColors.deepCharcoal,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _emailController,
                      focusNode: _emailFocusNode,
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) {
                        FocusScope.of(context).requestFocus(_passwordFocusNode);
                      },
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return null;
                        }
                        final emailRegex = RegExp(
                            r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                        if (!emailRegex.hasMatch(value.trim())) {
                          return _isUrdu
                              ? AppStrings.errorInvalidEmailUr
                              : AppStrings.errorInvalidEmailEn;
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: _isUrdu
                            ? AppStrings.emailHintUr
                            : AppStrings.emailHintEn,
                        prefixIcon: const Icon(
                          Icons.mail_outline_rounded,
                          color: AppColors.mutedCharcoal,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Password Field
                    Text(
                      _isUrdu
                          ? AppStrings.passwordLabelUr
                          : AppStrings.passwordLabelEn,
                      style: const TextStyle(
                        color: AppColors.deepCharcoal,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _passwordController,
                      focusNode: _passwordFocusNode,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _handleSignup(),
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: _isUrdu
                            ? AppStrings.passwordHintUr
                            : AppStrings.passwordHintEn,
                        prefixIcon: const Icon(
                          Icons.lock_outline_rounded,
                          color: AppColors.mutedCharcoal,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppColors.mutedCharcoal,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Submit Button
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSignup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.darkOlive,
                          foregroundColor: AppColors.cream,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.cream,
                                  ),
                                ),
                              )
                            : Text(
                                _isUrdu
                                    ? AppStrings.createAccountBtnUr
                                    : AppStrings.createAccountBtnEn,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Optional Caregiver Section ──────────────────────────
                    AnimatedCrossFade(
                      duration: const Duration(milliseconds: 280),
                      crossFadeState: _caregiverSectionExpanded
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      firstChild: Center(
                        child: TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _caregiverSectionExpanded = true;
                            });
                          },
                          icon: const Icon(
                            Icons.person_add_outlined,
                            size: 18,
                            color: AppColors.darkOlive,
                          ),
                          label: Text(
                            _isUrdu
                                ? AppStrings.addCaregiverUr
                                : AppStrings.addCaregiverEn,
                            style: const TextStyle(
                              color: AppColors.darkOlive,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      secondChild: _buildCaregiverSection(),
                    ),
                    const SizedBox(height: 16),

                    // ── Sign In Link ─────────────────────────────────────────
                    Center(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            PageRouteBuilder(
                              pageBuilder: (_, _, _) => const LoginScreen(),
                              transitionsBuilder: (_, animation, _, child) =>
                                  FadeTransition(
                                      opacity: animation, child: child),
                              transitionDuration:
                                  const Duration(milliseconds: 250),
                            ),
                          );
                        },
                        child: Text(
                          _isUrdu
                              ? AppStrings.alreadyHaveAccountUr
                              : AppStrings.alreadyHaveAccountEn,
                          style: const TextStyle(
                            color: AppColors.mutedCharcoal,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCaregiverSection() {
    return Container(
      padding: const EdgeInsets.all(18),
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
              const Icon(
                Icons.supervisor_account_outlined,
                color: AppColors.darkOlive,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isUrdu
                          ? AppStrings.caregiverSectionTitleUr
                          : AppStrings.caregiverSectionTitleEn,
                      style: const TextStyle(
                        color: AppColors.deepCharcoal,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isUrdu
                          ? AppStrings.caregiverSectionSubtitleUr
                          : AppStrings.caregiverSectionSubtitleEn,
                      style: const TextStyle(
                        color: AppColors.mutedCharcoal,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Caregiver Name
          Text(
            _isUrdu
                ? AppStrings.caregiverNameLabelUr
                : AppStrings.caregiverNameLabelEn,
            style: const TextStyle(
              color: AppColors.deepCharcoal,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _caregiverNameController,
            focusNode: _caregiverNameFocusNode,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) {
              FocusScope.of(context).requestFocus(_caregiverEmailFocusNode);
            },
            decoration: InputDecoration(
              hintText: _isUrdu
                  ? AppStrings.caregiverNameHintUr
                  : AppStrings.caregiverNameHintEn,
              prefixIcon: const Icon(
                Icons.person_outline_rounded,
                color: AppColors.mutedCharcoal,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Caregiver Email
          Text(
            _isUrdu
                ? AppStrings.caregiverEmailLabelUr
                : AppStrings.caregiverEmailLabelEn,
            style: const TextStyle(
              color: AppColors.deepCharcoal,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _caregiverEmailController,
            focusNode: _caregiverEmailFocusNode,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleSignup(),
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: _isUrdu
                  ? AppStrings.caregiverEmailHintUr
                  : AppStrings.caregiverEmailHintEn,
              prefixIcon: const Icon(
                Icons.mail_outline_rounded,
                color: AppColors.mutedCharcoal,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Skip link
          Center(
            child: TextButton(
              onPressed: () {
                setState(() {
                  _caregiverNameController.clear();
                  _caregiverEmailController.clear();
                  _caregiverSectionExpanded = false;
                });
              },
              child: Text(
                _isUrdu
                    ? AppStrings.skipAddLaterUr
                    : AppStrings.skipAddLaterEn,
                style: const TextStyle(
                  color: AppColors.mutedCharcoal,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

