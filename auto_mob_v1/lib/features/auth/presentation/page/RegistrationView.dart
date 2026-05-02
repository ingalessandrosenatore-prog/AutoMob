import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/Buttons/FabPrinc.dart';
import '../../../../core/widgets/input/Textfield.dart';
import '../Bloc/authBloc.dart';
import '../Bloc/authEvent.dart';
import '../Bloc/authState.dart';

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
    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (_, state) => state is AuthAuthenticated,
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          context.go('/home');
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        final errorMessage = state is AuthError ? state.message : null;

        return Scaffold(
          backgroundColor: const Color(0xFF000000),
          body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 60),
                    const Text(
                      'REGISTRATI',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Crea un account per iniziare',
                      style:
                          TextStyle(color: Color(0xFF636366), fontSize: 16),
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
                          suffixIcon: const Icon(
                            Icons.visibility_off,
                            color: Color(0xFF48484A),
                          ),
                        ),
                      ],
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: Color(0xFFFF453A), size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              errorMessage,
                              style: const TextStyle(
                                color: Color(0xFFFF453A),
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
                        color: const Color(0xFFE85A1A),
                        icon: Icons.person_add,
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
                          text: const TextSpan(
                            style: TextStyle(
                                color: Color(0xFF636366), fontSize: 14),
                            children: [
                              TextSpan(text: 'Hai già un account? '),
                              TextSpan(
                                text: 'Accedi',
                                style: TextStyle(
                                  color: Color(0xFF4A90E2),
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
