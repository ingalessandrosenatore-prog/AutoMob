import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/Buttons/FabPrinc.dart';
import '../../../../core/widgets/input/Textfield.dart';
import '../Bloc/authBloc.dart';
import '../Bloc/authEvent.dart';
import '../Bloc/authState.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 60),
                  const Text(
                    'BENVENUTO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Accedi per gestire i tuoi veicoli',
                    style: TextStyle(color: Color(0xFF636366), fontSize: 16),
                  ),
                  const SizedBox(height: 48),
                  Row(
                    children: [
                      AmTextField(
                        label: 'Email',
                        placeholder: 'Inserisci la tua email',
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
                        placeholder: '••••••••',
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
                  AmMainFab(
                    label: 'Login',
                    height: 60,
                    width: 180,
                    color: const Color(0xFFE85A1A),
                    icon: Icons.login,
                    isLoading: isLoading,
                    onPressed: () {  context.read<AuthBloc>().add(
                           LoginWithEmailEvent(
                              email: _emailController.text.trim(),
                              password: _passwordController.text,
                            ),
                          );

                    },
                  ),
                  const SizedBox(height: 48),
                  AmMainFab(
                    label: 'Registrati',
                    color: const Color(0xFF4A90E2),
                    icon: Icons.person_add,
                    height: 60,
                    width: 180,
                    onPressed: () => context.goNamed('registration'),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'oppure accedi con',
                    style: TextStyle(color: Color(0xFF636366), fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: isLoading
                            ? null
                            : () => context
                                .read<AuthBloc>()
                                .add(LoginWithGoogleEvent()),
                        icon: const Icon(Icons.g_mobiledata,
                            color: Colors.white, size: 40),
                        style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFF1C1C1E)),
                      ),
                      const SizedBox(width: 20),
                      IconButton(
                        onPressed: isLoading
                            ? null
                            : () => context
                                .read<AuthBloc>()
                                .add(LoginWithAppleEvent()),
                        icon: const Icon(Icons.apple,
                            color: Colors.white, size: 32),
                        style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFF1C1C1E)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
