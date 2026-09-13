import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../l10n/app_strings.dart';
import '../../services/storage_service.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/bol_mascot_widget.dart';
import '../home/caregiver_home_shell_screen.dart';

/// Two-step claim screen:
///   Step 0 — email lookup (find pending invite)
///   Step 1 — set password (complete account creation)
class CaregiverClaimScreen extends StatefulWidget {
  const CaregiverClaimScreen({super.key});

  @override
  State<CaregiverClaimScreen> createState() => _CaregiverClaimScreenState();
}

class _CaregiverClaimScreenState extends State<CaregiverClaimScreen>
    with SingleTickerProviderStateMixin {
  // Step 0
  final _emailController = TextEditingController();
  // Step 1
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _errorMessage;

  int _step = 0; // 0 = email lookup, 1 = set password
  Map<String, dynamic>? _inviteRow; // populated after successful lookup

  late AnimationController _stepController;
  late Animation<Offset> _slideIn;

  bool get _isUrdu => StorageService.getLanguagePref() == 'ur';

  @override
  void initState() {
    super.initState();
    _stepController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _slideIn = Tween<Offset>(
      begin: const Offset(1.0, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _stepController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _stepController.dispose();
    super.dispose();
  }

  // ── Step 0: look up invite ────────────────────────────────────────────────

  Future<void> _handleLookup() async {
    setState(() {
      _errorMessage = null;
    });

    final email = _emailController.text.trim();
    if (email.isEmpty) {
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
      final row = await SupabaseService.lookupInviteByEmail(email);

      if (!mounted) return;

      if (row == null) {
        setState(() {
          _errorMessage = _isUrdu
              ? AppStrings.noInviteFoundUr
              : AppStrings.noInviteFoundEn;
        });
        return;
      }

      // Found — animate to step 1
      setState(() {
        _inviteRow = row;
        _step = 1;
      });
      _stepController.forward(from: 0);
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

  // ── Step 1: complete caregiver signup ────────────────────────────────────

  Future<void> _handleClaimSignup() async {
    setState(() {
      _errorMessage = null;
    });

    final password = _passwordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();

    if (password.isEmpty || confirm.isEmpty) {
      setState(() {
        _errorMessage = _isUrdu
            ? AppStrings.errorAllFieldsUr
            : AppStrings.errorAllFieldsEn;
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

    if (password != confirm) {
      setState(() {
        _errorMessage = _isUrdu
            ? AppStrings.errorPasswordMismatchUr
            : AppStrings.errorPasswordMismatchEn;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await SupabaseService.claimCaregiverInvite(
        inviteRow: _inviteRow!,
        password: password,
      );

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (_, _, _) => const CaregiverHomeShellScreen(),
          transitionsBuilder: (_, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 350),
        ),
        (route) => false,
      );
    } on AuthException catch (e) {
      setState(() {
        final msg = e.message.toLowerCase();
        if (msg.contains('already registered') ||
            msg.contains('user already exists')) {
          _errorMessage = _isUrdu
              ? AppStrings.errorDuplicateEmailUr
              : AppStrings.errorDuplicateEmailEn;
        } else if (msg.contains('weak') || msg.contains('password')) {
          _errorMessage = _isUrdu
              ? AppStrings.errorWeakPasswordUr
              : AppStrings.errorWeakPasswordEn;
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

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _isUrdu ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(
          backgroundColor: AppColors.cream,
          elevation: 0,
          leading: _step == 1
              ? IconButton(
                  icon: Icon(
                    _isUrdu
                        ? Icons.arrow_forward_rounded
                        : Icons.arrow_back_rounded,
                    color: AppColors.deepCharcoal,
                  ),
                  onPressed: _isLoading
                      ? null
                      : () {
                          setState(() {
                            _step = 0;
                            _errorMessage = null;
                            _passwordController.clear();
                            _confirmPasswordController.clear();
                          });
                          _stepController.reverse();
                        },
                )
              : null,
          title: Text(
            _isUrdu ? AppStrings.claimTitleUr : AppStrings.claimTitleEn,
            style: const TextStyle(
              color: AppColors.deepCharcoal,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
            child: _step == 0
                ? _buildStep0()
                : SlideTransition(
                    position: _slideIn,
                    child: _buildStep1(),
                  ),
          ),
        ),
      ),
    );
  }

  // ── Step 0 UI ─────────────────────────────────────────────────────────────

  Widget _buildStep0() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(
          child: BolMascotWidget(
            state: BolState.attentive,
            size: 100,
            showSoundwave: false,
          ),
        ),
        const SizedBox(height: 20),

        Text(
          _isUrdu ? AppStrings.claimTitleUr : AppStrings.claimTitleEn,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.deepCharcoal,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isUrdu ? AppStrings.claimSubtitleUr : AppStrings.claimSubtitleEn,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.mutedCharcoal,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 28),

        // Error
        if (_errorMessage != null) ...[
          _buildErrorBox(_errorMessage!),
          const SizedBox(height: 18),
        ],

        Text(
          _isUrdu ? AppStrings.emailLabelUr : AppStrings.emailLabelEn,
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
          onSubmitted: (_) => _handleLookup(),
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
        const SizedBox(height: 28),

        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleLookup,
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
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.cream),
                    ),
                  )
                : Text(
                    _isUrdu
                        ? AppStrings.lookupInviteBtnUr
                        : AppStrings.lookupInviteBtnEn,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  // ── Step 1 UI ─────────────────────────────────────────────────────────────

  Widget _buildStep1() {
    final caregiverName =
        (_inviteRow?['caregiver_name'] as String?) ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(
          child: BolMascotWidget(
            state: BolState.encouraging,
            size: 100,
            showSoundwave: false,
          ),
        ),
        const SizedBox(height: 20),

        // Welcome greeting using name from invite
        Text(
          '${_isUrdu ? AppStrings.claimWelcomeUr : AppStrings.claimWelcomeEn} $caregiverName!',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.deepCharcoal,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isUrdu
              ? AppStrings.claimPasswordPromptUr
              : AppStrings.claimPasswordPromptEn,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.mutedCharcoal,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 28),

        // Error
        if (_errorMessage != null) ...[
          _buildErrorBox(_errorMessage!),
          const SizedBox(height: 18),
        ],

        // Password
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
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Confirm Password
        Text(
          _isUrdu
              ? AppStrings.confirmPasswordLabelUr
              : AppStrings.confirmPasswordLabelEn,
          style: const TextStyle(
            color: AppColors.deepCharcoal,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirm,
          onSubmitted: (_) => _handleClaimSignup(),
          decoration: InputDecoration(
            hintText: _isUrdu
                ? AppStrings.confirmPasswordHintUr
                : AppStrings.confirmPasswordHintEn,
            prefixIcon: const Icon(
              Icons.lock_outline_rounded,
              color: AppColors.mutedCharcoal,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirm
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppColors.mutedCharcoal,
              ),
              onPressed: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
            ),
          ),
        ),
        const SizedBox(height: 28),

        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleClaimSignup,
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
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.cream),
                    ),
                  )
                : Text(
                    _isUrdu
                        ? AppStrings.completeSignupBtnUr
                        : AppStrings.completeSignupBtnEn,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  // ── Shared Widgets ────────────────────────────────────────────────────────

  Widget _buildErrorBox(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              message,
              style: const TextStyle(
                color: Color(0xFFC62828),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
