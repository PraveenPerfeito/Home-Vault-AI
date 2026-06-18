import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:home_vault/core/error/app_exception.dart';
import 'package:home_vault/core/router/app_router.dart';
import 'package:home_vault/core/theme/app_colors.dart';
import 'package:home_vault/features/auth/presentation/providers/auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _showEmailForm = false;
  late final ProviderSubscription<AsyncValue<void>> _authSubscription;

  @override
  void initState() {
    super.initState();
    // H1: moved from build() to initState via listenManual so the callback is
    // registered once and never re-subscribed on widget rebuild.
    _authSubscription = ref.listenManual<AsyncValue<void>>(
      authActionsProvider,
      fireImmediately: false,
      (_, next) {
        next.whenOrNull(
          error: (e, _) => _showError(
            e is AppException ? e.message : 'An error occurred. Please try again.',
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _authSubscription.close();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final authState = ref.watch(authActionsProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              const _AppLogo(),
              const SizedBox(height: 24),
              Text(
                'Welcome to\nHome Vault',
                textAlign: TextAlign.center,
                style: textTheme.displayMedium,
              ),
              const SizedBox(height: 10),
              Text(
                'Track expiry dates and household items\nin one place.',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(color: AppColors.grey600),
              ),
              const SizedBox(height: 40),

              // Google Sign-In
              OutlinedButton.icon(
                onPressed: isLoading
                    ? null
                    : () => ref
                        .read(authActionsProvider.notifier)
                        .signInWithGoogle(),
                icon: const Icon(Icons.g_mobiledata_rounded, size: 22),
                label: const Text('Continue with Google'),
              ),
              const SizedBox(height: 12),

              // Email toggle
              ElevatedButton.icon(
                onPressed: isLoading
                    ? null
                    : () => setState(() => _showEmailForm = !_showEmailForm),
                icon: const Icon(Icons.email_outlined, size: 20),
                label: Text(_showEmailForm ? 'Hide Email Form' : 'Sign In with Email'),
              ),

              // Inline email/password form
              if (_showEmailForm) ...[
                const SizedBox(height: 20),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        maxLength: 254,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          counterText: '',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Enter your email';
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v.trim())) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        maxLength: 128,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          counterText: '',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (v) =>
                            (v == null || v.length < 6) ? 'Min 6 characters' : null,
                        onFieldSubmitted: (_) => _signInWithEmail(),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: isLoading ? null : _signInWithEmail,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Sign In'),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => context.push(AppRoutes.register),
                        child: const Text('New here? Create Account'),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),
              const _Divider(),
              const SizedBox(height: 16),

              // Guest mode
              TextButton(
                onPressed: isLoading
                    ? null
                    : () => ref
                        .read(authActionsProvider.notifier)
                        .signInAnonymously(),
                child: Text(
                  'Continue as Guest',
                  style: TextStyle(color: AppColors.grey600),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'By continuing you agree to our Terms of Service\nand Privacy Policy.',
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(color: AppColors.grey400),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _signInWithEmail() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(authActionsProvider.notifier).signInWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}

class _AppLogo extends StatelessWidget {
  const _AppLogo();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.home_outlined, size: 40, color: AppColors.primary),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'or',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.grey400),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}
