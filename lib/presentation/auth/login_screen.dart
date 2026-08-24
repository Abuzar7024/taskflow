import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/dev_settings.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/validators.dart';
import '../widgets/brand.dart';
import '../providers.dart';
import '../widgets/common.dart';
import 'auth_controller.dart';
import 'demo_accounts_sheet.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    await ref
        .read(authControllerProvider.notifier)
        .login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
    // On success the router redirect takes over; on failure the error is
    // rendered from auth state below.
  }

  Future<void> _pickDemoAccount() async {
    final credential = await showDemoAccountsSheet(context);
    if (credential == null || !mounted) return;
    setState(() {
      _emailController.text = credential.email;
      _passwordController.text = credential.password;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final devSettings = ref.watch(devSettingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - AppSpacing.xl * 2,
                  maxWidth: 420,
                ),
                child: Center(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const BrandHeader(
                          title: 'Welcome back',
                          subtitle:
                              'Manage projects. Organize tasks. Get work done.',
                        ),
                        const SizedBox(height: AppSpacing.xxl),

                        if (auth.error != null) ...[
                          InlineErrorBanner(message: auth.error!),
                          const SizedBox(height: AppSpacing.lg),
                        ],

                        // A live simulation can block sign-in entirely, so
                        // offer the reset right where the user is stuck.
                        if (!devSettings.isDefault) ...[
                          _SimulationNotice(settings: devSettings),
                          const SizedBox(height: AppSpacing.lg),
                        ],

                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            hintText: 'you@company.com',
                            prefixIcon: Icon(Icons.mail_outline),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autocorrect: false,
                          autofillHints: const [AutofillHints.email],
                          validator: Validators.email,
                          onEditingComplete: _passwordFocus.requestFocus,
                          enabled: !auth.isSubmitting,
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        TextFormField(
                          controller: _passwordController,
                          focusNode: _passwordFocus,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              tooltip: _obscurePassword
                                  ? 'Show password'
                                  : 'Hide password',
                            ),
                          ),
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          validator: Validators.loginPassword,
                          onFieldSubmitted: (_) => _submit(),
                          enabled: !auth.isSubmitting,
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        FilledButton(
                          onPressed: auth.isSubmitting ? null : _submit,
                          child: auth.isSubmitting
                              ? const ButtonSpinner()
                              : const Text('Sign in'),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        OutlinedButton.icon(
                          onPressed: auth.isSubmitting
                              ? null
                              : _pickDemoAccount,
                          icon: const Icon(Icons.people_outline, size: 18),
                          label: const Text('Use a demo account'),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        TextButton.icon(
                          onPressed: () => context.push(Routes.developerTools),
                          icon: const Icon(Icons.science_outlined, size: 18),
                          label: const Text('Developer options'),
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        // Wrap rather than Row so the prompt and the action
                        // stack instead of overflowing on narrow screens.
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              'New to TaskFlow?',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            TextButton(
                              onPressed: auth.isSubmitting
                                  ? null
                                  : () => context.push(Routes.register),
                              child: const Text('Create an account'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Explains that a simulation is active and offers a one-tap reset.
///
/// Shown on the login screen because the Unauthorized simulation signs the
/// user out, which would otherwise make the setting unreachable.
class _SimulationNotice extends ConsumerWidget {
  const _SimulationNotice({required this.settings});

  final DevSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final c = theme.c;

    final active = [
      if (settings.failure != SimulatedFailure.none) settings.failure.label,
      if (settings.offline) 'Offline mode',
      if (settings.slowNetwork) 'Slow network',
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: c.wash(c.warning),
        borderRadius: AppRadius.field,
        border: Border.all(color: c.warning.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.science_outlined, size: 18, color: c.warning),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Simulation active',
                  style: theme.textTheme.titleSmall?.copyWith(color: c.warning),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '$active. This can block sign-in until you turn it off.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () {
                ref.read(devSettingsProvider.notifier).reset();
                showAppSnackBar(context, 'Simulation reset. Try signing in.');
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Reset simulation'),
            ),
          ),
        ],
      ),
    );
  }
}
