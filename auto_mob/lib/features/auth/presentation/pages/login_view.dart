import 'package:go_router/go_router.dart';
import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';

import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/auth_action_bar.dart';
import '../widgets/auth_brand_header.dart';
import '../widgets/auth_form_pages.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key, this.initialPage = 0});

  final int initialPage;

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  late final PageController _pageController;
  late final TextEditingController _loginEmailController;
  late final TextEditingController _loginPasswordController;
  late final TextEditingController _registrationNameController;
  late final TextEditingController _registrationEmailController;
  late final TextEditingController _registrationPhoneController;
  late final TextEditingController _registrationPostalCodeController;
  late final TextEditingController _registrationPasswordController;
  late final TextEditingController _passwordConfirmationController;
  bool _dialogOpen = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialPage);
    _loginEmailController = TextEditingController();
    _loginPasswordController = TextEditingController();
    _registrationNameController = TextEditingController();
    _registrationEmailController = TextEditingController();
    _registrationPhoneController = TextEditingController();
    _registrationPostalCodeController = TextEditingController();
    _registrationPasswordController = TextEditingController();
    _passwordConfirmationController = TextEditingController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _registrationNameController.dispose();
    _registrationEmailController.dispose();
    _registrationPhoneController.dispose();
    _registrationPostalCodeController.dispose();
    _registrationPasswordController.dispose();
    _passwordConfirmationController.dispose();
    super.dispose();
  }

  double get _registrationProgress {
    if (!_pageController.hasClients) return widget.initialPage.toDouble();
    return (_pageController.page ?? widget.initialPage.toDouble()).clamp(
      0.0,
      1.0,
    );
  }

  void _closeDialogIfOpen() {
    if (!_dialogOpen) return;
    Navigator.of(context, rootNavigator: true).pop();
    _dialogOpen = false;
  }

  void _onAuthStateChanged(BuildContext context, AuthState state) {
    _closeDialogIfOpen();
    if (state is! AuthError) return;

    final isRegistration = _registrationProgress >= 0.5;
    if (!state.emailNotConfirmed && !isRegistration) return;

    _dialogOpen = true;
    showAmStatusDialog(
      context,
      icon: state.emailNotConfirmed
          ? HugeIcons.strokeRoundedMail01
          : HugeIcons.strokeRoundedAlert01,
      iconColor: AmThemeColors.of(context).danger,
      title: state.emailNotConfirmed
          ? 'Email non verificata'
          : 'Registrazione non riuscita',
      message: state.message,
      actions: [
        AmDialogAction(
          label: state.emailNotConfirmed ? 'Riprova' : 'Chiudi',
          color: AmThemeColors.of(context).accent,
          filled: true,
          onPressed: _closeDialogIfOpen,
        ),
      ],
    );
  }

  void _syncSharedCredentials(int page) {
    if (page == 1) {
      _registrationEmailController.text = _loginEmailController.text;
      _registrationPasswordController.text = _loginPasswordController.text;
      return;
    }
    _loginEmailController.text = _registrationEmailController.text;
    _loginPasswordController.text = _registrationPasswordController.text;
  }

  Future<void> _showLogin() async {
    if ((_pageController.page ?? widget.initialPage) >= 0.5) {
      await _pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    if (!mounted) return;
    context.read<AuthBloc>().add(
      LoginWithEmailEvent(
        email: _loginEmailController.text.trim(),
        password: _loginPasswordController.text,
      ),
    );
  }

  Future<void> _showRegistration() async {
    if ((_pageController.page ?? widget.initialPage) < 0.5) {
      await _pageController.animateToPage(
        1,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    if (!mounted) return;
    context.read<AuthBloc>().add(
      SignupWithEmailEvent(
        name: _registrationNameController.text.trim(),
        email: _registrationEmailController.text.trim(),
        phone: _registrationPhoneController.text.trim(),
        postalCode: _registrationPostalCodeController.text.trim(),
        password: _registrationPasswordController.text,
        passwordConfirmation: _passwordConfirmationController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => BlocListener<AuthBloc, AuthState>(
    listener: _onAuthStateChanged,
    child: BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final colors = AmThemeColors.of(context);
        final isLoading = state is AuthLoading;
        final errorMessage = state is AuthError && !state.emailNotConfirmed
            ? state.message
            : null;

        return Scaffold(
          backgroundColor: colors.background,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  AnimatedBuilder(
                    animation: _pageController,
                    builder: (context, _) => AuthBrandHeader(
                      registrationProgress: _registrationProgress,
                    ),
                  ),
                  Expanded(
                    child: PageView(
                      key: const Key('auth-page-view'),
                      controller: _pageController,
                      onPageChanged: _syncSharedCredentials,
                      children: [
                        AuthLoginForm(
                          emailController: _loginEmailController,
                          passwordController: _loginPasswordController,
                          errorMessage: errorMessage,
                        ),
                        AuthRegistrationForm(
                          nameController: _registrationNameController,
                          emailController: _registrationEmailController,
                          phoneController: _registrationPhoneController,
                          postalCodeController:
                              _registrationPostalCodeController,
                          passwordController: _registrationPasswordController,
                          passwordConfirmationController:
                              _passwordConfirmationController,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 18),
                    child: AnimatedBuilder(
                      animation: _pageController,
                      builder: (context, _) => AuthActionBar(
                        registrationProgress: _registrationProgress,
                        isLoading: isLoading,
                        onLoginPressed: _showLogin,
                        onRegistrationPressed: _showRegistration,
                        onGooglePressed: () {
                          if (_registrationProgress >= 0.5) {
                            context.go('/google-registration');
                          } else {
                            context.read<AuthBloc>().add(
                              LoginWithGoogleEvent(),
                            );
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}
