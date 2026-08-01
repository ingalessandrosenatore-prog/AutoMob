import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:common_ui_widget/common_ui_widget.dart';

import 'package:go_router/go_router.dart';

import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class RegistrationView extends StatefulWidget {
  const RegistrationView({super.key});

  @override
  State<RegistrationView> createState() => _RegistrationViewState();
}

class _RegistrationViewState extends State<RegistrationView> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Solo BlocBuilder: dopo la registrazione lo stato diventa
    // AuthAuthenticated e la redirect del router porta a /home.
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        final errorMessage = state is AuthError ? state.message : null;
        final colors = AmThemeColors.of(context);

        return Scaffold(
          backgroundColor: colors.background,
          body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 60),
                    Text(
                      'REGISTRATI',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Crea un account per iniziare',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 48),
                    Row(
                      children: [
                        AmTextField(
                          label: 'Nome',
                          placeholder: 'Il tuo nome',
                          controller: _nameController,
                          isRequired: true,
                          obscureText: false,
                          keyboardType: TextInputType.name,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        AmTextField(
                          label: 'Email',
                          placeholder: 'La tua email migliore',
                          controller: _emailController,
                          isRequired: true,
                          obscureText: false,
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        AmTextField(
                          label: 'Password',
                          placeholder: 'Almeno 8 caratteri',
                          controller: _passwordController,
                          isRequired: true,
                          obscureText: true,
                          keyboardType: TextInputType.visiblePassword,
                        ),
                      ],
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedAlert01,
                            color: colors.danger,
                            size: 16,
                            strokeWidth: 2.2,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              errorMessage,
                              style: TextStyle(
                                color: colors.danger,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 48),
                    Center(
                      child: AmMainFab(
                        label: 'Registrati',
                        color: colors.accent,
                        icon: HugeIcons.strokeRoundedUserAdd01,
                        isLoading: isLoading,
                        height: 60,
                        width: 180,
                        onPressed: () {
                          context.read<AuthBloc>().add(
                            SignupWithEmailEvent(
                              name: _nameController.text.trim(),
                              email: _emailController.text.trim(),
                              password: _passwordController.text,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 48),
                    Center(
                      child: TextButton(
                        onPressed: () => context.goNamed('login'),
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 14,
                            ),
                            children: [
                              const TextSpan(text: 'Hai già un account? '),
                              TextSpan(
                                text: 'Accedi',
                                style: TextStyle(
                                  color: colors.info,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
