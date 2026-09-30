import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';

class AuthLoginForm extends StatelessWidget {
  const AuthLoginForm({
    super.key,
    required this.emailController,
    required this.passwordController,
    this.errorMessage,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) => ListView(
    key: const PageStorageKey('auth-login-form'),
    padding: const EdgeInsets.only(top: 24, bottom: 24),
    children: [
      Row(
        children: [
          AmTextField(
            label: 'Email',
            placeholder: 'Inserisci la tua email',
            controller: emailController,
            isRequired: true,
            obscureText: false,
            keyboardType: TextInputType.emailAddress,
            height: 52,
          ),
        ],
      ),
      const SizedBox(height: 18),
      Row(
        children: [
          AmTextField(
            label: 'Password',
            placeholder: '••••••••',
            controller: passwordController,
            isRequired: true,
            obscureText: true,
            keyboardType: TextInputType.visiblePassword,
            height: 52,
          ),
        ],
      ),
      if (errorMessage != null) ...[
        const SizedBox(height: 14),
        Text(
          errorMessage!,
          style: TextStyle(
            color: AmThemeColors.of(context).danger,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ],
  );
}

class AuthRegistrationForm extends StatelessWidget {
  const AuthRegistrationForm({
    super.key,
    required this.nameController,
    required this.emailController,
    required this.phoneController,
    required this.postalCodeController,
    required this.passwordController,
    required this.passwordConfirmationController,
  });

  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController postalCodeController;
  final TextEditingController passwordController;
  final TextEditingController passwordConfirmationController;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    key: const PageStorageKey('auth-registration-form'),
    padding: const EdgeInsets.only(top: 4, bottom: 24),
    child: Column(
      children: [
        _AuthFormField(
          AmTextField(
            label: 'Nome e cognome',
            placeholder: 'Mario Rossi',
            controller: nameController,
            isRequired: true,
            obscureText: false,
            keyboardType: TextInputType.name,
            height: 52,
          ),
        ),
        _AuthFormField(
          AmTextField(
            label: 'Email',
            placeholder: 'La tua email migliore',
            controller: emailController,
            isRequired: true,
            obscureText: false,
            keyboardType: TextInputType.emailAddress,
            height: 52,
          ),
        ),
        _AuthFormField(
          AmTextField(
            label: 'Telefono',
            placeholder: '+39 333 1234567',
            controller: phoneController,
            isRequired: true,
            obscureText: false,
            keyboardType: TextInputType.phone,
            height: 52,
          ),
        ),
        _AuthFormField(
          AmTextField(
            label: 'CAP',
            placeholder: '00000',
            controller: postalCodeController,
            isRequired: true,
            obscureText: false,
            keyboardType: TextInputType.number,
            height: 52,
          ),
        ),
        _AuthFormField(
          AmTextField(
            label: 'Password',
            placeholder: 'Almeno 8 caratteri',
            controller: passwordController,
            isRequired: true,
            obscureText: true,
            keyboardType: TextInputType.visiblePassword,
            height: 52,
          ),
        ),
        Row(
          children: [
            AmTextField(
              label: 'Conferma password',
              placeholder: 'Ripeti la password',
              controller: passwordConfirmationController,
              isRequired: true,
              obscureText: true,
              keyboardType: TextInputType.visiblePassword,
              height: 52,
            ),
          ],
        ),
      ],
    ),
  );
}

class _AuthFormField extends StatelessWidget {
  const _AuthFormField(this.child);

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(children: [child]),
  );
}
