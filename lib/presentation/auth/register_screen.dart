import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../providers.dart';
import '../widgets/brand.dart';
import '../widgets/common.dart';
import 'auth_controller.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscure = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    await ref
        .read(authControllerProvider.notifier)
        .register(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final defaultOrgName = ref.watch(defaultOrgNameProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: auth.isSubmitting
              ? null
              : () {
                  ref.read(authControllerProvider.notifier).clearError();
                  Navigator.of(context).pop();
                },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            0,
            AppSpacing.xl,
            AppSpacing.xl,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    BrandHeader(
                      title: 'Create your account',
                      subtitle: defaultOrgName == null
                          ? 'Join your team and start organising work.'
                          : 'You will join $defaultOrgName as a team member.',
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    if (auth.error != null) ...[
                      InlineErrorBanner(message: auth.error!),
                      const SizedBox(height: AppSpacing.lg),
                    ],

                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full name',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.name],
                      validator: Validators.fullName,
                      enabled: !auth.isSubmitting,
                    ),
                    const SizedBox(height: AppSpacing.lg),

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
                      enabled: !auth.isSubmitting,
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        helperText:
                            'At least ${Validators.minPasswordLength} characters',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          tooltip: _obscure ? 'Show password' : 'Hide password',
                        ),
                      ),
                      obscureText: _obscure,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.newPassword],
                      validator: Validators.password,
                      enabled: !auth.isSubmitting,
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    TextFormField(
                      controller: _confirmController,
                      decoration: const InputDecoration(
                        labelText: 'Confirm password',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      obscureText: _obscure,
                      textInputAction: TextInputAction.done,
                      validator: (value) => Validators.confirmPassword(
                        value,
                        _passwordController.text,
                      ),
                      onFieldSubmitted: (_) => _submit(),
                      enabled: !auth.isSubmitting,
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    FilledButton(
                      onPressed: auth.isSubmitting ? null : _submit,
                      child: auth.isSubmitting
                          ? const ButtonSpinner()
                          : const Text('Create account'),
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

/// Organization new sign-ups join, read from the mock data rather than named
/// in the widget.
final defaultOrgNameProvider = FutureProvider.autoDispose<String?>((ref) async {
  return ref.watch(mockDataSourceProvider).defaultOrganizationName();
});
