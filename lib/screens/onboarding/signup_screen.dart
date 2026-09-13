import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../l10n/app_strings.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/bol_mascot_widget.dart';
import '../home/home_shell_screen.dart';

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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  bool get _isUrdu => widget.languagePref == 'ur';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    setState(() {
      _errorMessage = null;
    });

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage =
            _isUrdu ? AppStrings.errorAllFieldsUr : AppStrings.errorAllFieldsEn;
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
      await SupabaseService.signUp(
        name: name,
        email: email,
        password: password,
        languagePref: widget.languagePref,
        personaTag: widget.personaTag,
      );

      if (!mounted) return;

      // Navigate to Home Shell upon success
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (_, _, _) => const HomeShellScreen(),
          transitionsBuilder: (_, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 350),
        ),
        (route) => false,
      );
    } on AuthException catch (e) {
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
    } catch (_) {
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
                      keyboardType: TextInputType.emailAddress,
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
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
