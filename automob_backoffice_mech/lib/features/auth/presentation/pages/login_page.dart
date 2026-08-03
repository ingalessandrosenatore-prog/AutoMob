import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

final class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.onRegistrationPressed});

  final VoidCallback onRegistrationPressed;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

final class _LoginPageState extends State<LoginPage> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    final state = context.read<AuthBloc>().state;
    final draft = state is AuthLogin ? state.draft : const LoginDraft();
    _emailController = TextEditingController(text: draft.email);
    _passwordController = TextEditingController(text: draft.password);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          _dialogMessage(previous) != _dialogMessage(current) &&
          _dialogMessage(current) != null,
      listener: (context, state) async {
        await showAmStatusDialog<void>(
          context,
          iconColor: colors.danger,
          title: 'Accesso non riuscito',
          message: _dialogMessage(state),
          actions: [
            AmDialogAction(
              label: 'Chiudi',
              color: colors.textSecondary,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
        if (context.mounted) {
          context.read<AuthBloc>().add(const AuthDialogDismissed());
        }
      },
      builder: (context, state) {
        final login = state is AuthLogin ? state : const AuthLogin();
        return Scaffold(
          resizeToAvoidBottomInset: true,
          body: SafeArea(
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.all(24),
              children: [
                SizedBox(height: MediaQuery.sizeOf(context).height * 0.12),
                Text(
                  'AutoMob Officina',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Accedi alla tua officina.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.textSecondary),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    AmTextField(
                      label: 'Email',
                      placeholder: 'email@officina.it',
                      controller: _emailController,
                      isRequired: true,
                      obscureText: false,
                      keyboardType: TextInputType.emailAddress,
                      errorText: login.errors.email,
                      onChanged: (value) => context.read<AuthBloc>().add(
                        LoginEmailChanged(value as String),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    AmTextField(
                      label: 'Password',
                      placeholder: 'Inserisci la password',
                      controller: _passwordController,
                      isRequired: true,
                      obscureText: true,
                      keyboardType: TextInputType.visiblePassword,
                      errorText: login.errors.password,
                      onChanged: (value) => context.read<AuthBloc>().add(
                        LoginPasswordChanged(value as String),
                      ),
                      onEditingComplete: () =>
                          context.read<AuthBloc>().add(const LoginSubmitted()),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                AmMainFab(
                  label: login.isSubmitting ? 'Accesso...' : 'Accedi',
                  color: colors.accent,
                  onPressed: () =>
                      context.read<AuthBloc>().add(const LoginSubmitted()),
                  width: double.infinity,
                  height: 54,
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: login.isSubmitting
                      ? null
                      : () {
                          context.read<AuthBloc>().add(
                            const RegistrationStarted(),
                          );
                          widget.onRegistrationPressed();
                        },
                  child: Text(
                    'Crea la tua officina',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String? _dialogMessage(AuthState state) =>
      state is AuthLogin ? state.dialogMessage : null;
}
