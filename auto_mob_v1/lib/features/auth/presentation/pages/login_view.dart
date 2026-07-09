import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/buttons/fab_princ.dart';
import '../../../../core/widgets/dialog/am_status_dialog.dart';
import '../../../../core/widgets/input/textfield.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;

  // Tiene traccia se un pop-up di stato e' attualmente aperto, per poterlo
  // chiudere prima di mostrarne un altro (evita pop-up sovrapposti).
  bool _dialogOpen = false;

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

  void _closeDialogIfOpen() {
    if (_dialogOpen) {
      Navigator.of(context, rootNavigator: true).pop();
      _dialogOpen = false;
    }
  }

  /// Email non confermata: pop-up dedicato invece del banner generico,
  /// con "Riprova" che chiude il pop-up (l'utente verifica la casella di
  /// posta fuori dall'app e poi ritenta il login dal form).
  void _onStateForDialogs(BuildContext context, AuthState s) {
    if (s is AuthError && s.emailNotConfirmed) {
      _dialogOpen = true;
      showAmStatusDialog(
        context,
        icon: Icons.mark_email_unread_outlined,
        iconColor: const Color(0xFFFFB4AB),
        title: 'Email non verificata',
        message: s.message,
        actions: [
          AmDialogAction(
            label: 'Riprova',
            color: const Color(0xFFE85A1A),
            filled: true,
            onPressed: _closeDialogIfOpen,
          ),
        ],
      );
    } else {
      _closeDialogIfOpen();
    }
  }

  @override
  Widget build(BuildContext context) {
    // BlocListener per i pop-up di stato + BlocBuilder per il resto della UI:
    // la navigazione verso /home la decide la redirect del router quando lo
    // stato diventa AuthAuthenticated. Qui gestisco solo la UI.
    return BlocListener<AuthBloc, AuthState>(
      listener: _onStateForDialogs,
      child: BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        final errorMessage =
            (state is AuthError && !state.emailNotConfirmed)
                ? state.message
                : null;

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
      ),
    );
  }
}
