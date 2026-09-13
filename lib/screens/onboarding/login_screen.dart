import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../l10n/app_strings.dart';
import '../../services/storage_service.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/bol_mascot_widget.dart';
import '../home/caregiver_home_shell_screen.dart';
import '../home/home_shell_screen.dart';
import 'caregiver_claim_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  bool get _isUrdu => StorageService.getLanguagePref() == 'ur';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    setState(() {
      _errorMessage = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = _isUrdu
            ? AppStrings.errorAllFieldsUr
            : AppStrings.errorAllFieldsEn;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final profile = await SupabaseService.signIn(
        email: email,
        password: password,
      );

      if (!mounted) return;

      if (profile == null) {
        setState(() {
          _errorMessage = _isUrdu
              ? AppStrings.errorWrongCredentialsUr
              : AppStrings.errorWrongCredentialsEn;
        });
        return;
      }

      // Route based on account_type
      final Widget destination = profile.accountType == 'caregiver'
          ? const CaregiverHomeShellScreen()
          : const HomeShellScreen();

      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (_, _, _) => destination,
          transitionsBuilder: (_, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 350),
        ),
        (route) => false,
      );
    } on AuthException catch (e) {
      setState(() {
        final msg = e.message.toLowerCase();
        if (msg.contains('invalid') ||
            msg.contains('credentials') ||
            msg.contains('password') ||
            msg.contains('email')) {
          _errorMessage = _isUrdu
              ? AppStrings.errorWrongCredentialsUr
              : AppStrings.errorWrongCredentialsEn;
        } else {
          _errorMessage = e.message;
        }
      });
    } catch (_) {
      setState(() {
        _errorMessage = _isUrdu
            ? AppStrings.errorGeneralUr
            : AppStrings.errorGeneralEn;
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Bol mascot
                  const Center(
                    child: BolMascotWidget(
                      state: BolState.welcoming,
                      size: 100,
                      showSoundwave: true,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title
                  Text(
                    _isUrdu ? AppStrings.loginTitleUr : AppStrings.loginTitleEn,
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
                        ? AppStrings.loginSubtitleUr
                        : AppStrings.loginSubtitleEn,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.mutedCharcoal,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Error Box
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFECEC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE57373)),
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
                  TextField(
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
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    onSubmitted: (_) => _handleSignIn(),
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

                  // Sign In Button
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSignIn,
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
                                  ? AppStrings.signInBtnUr
                                  : AppStrings.signInBtnEn,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // No account ? back to Sign Up
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        _isUrdu
                            ? AppStrings.noAccountUr
                            : AppStrings.noAccountEn,
                        style: const TextStyle(
                          color: AppColors.mutedCharcoal,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Caregiver claim entry point
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          PageRouteBuilder(
                            pageBuilder: (_, _, _) =>
                                const CaregiverClaimScreen(),
                            transitionsBuilder:
                                (_, animation, _, child) =>
                                    FadeTransition(
                                        opacity: animation, child: child),
                            transitionDuration:
                                const Duration(milliseconds: 250),
                          ),
                        );
                      },
                      child: Text(
                        _isUrdu
                            ? AppStrings.invitedAsCaregiverUr
                            : AppStrings.invitedAsCaregiverEn,
                        style: const TextStyle(
                          color: AppColors.darkOlive,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.darkOlive,
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
    );
  }
}
