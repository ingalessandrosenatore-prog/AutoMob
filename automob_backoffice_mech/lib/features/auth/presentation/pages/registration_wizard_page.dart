import 'dart:async';
import 'dart:math' as math;

import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/italian_municipality.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

final class RegistrationWizardPage extends StatefulWidget {
  const RegistrationWizardPage({super.key});

  @override
  State<RegistrationWizardPage> createState() => _RegistrationWizardPageState();
}

final class _RegistrationWizardPageState extends State<RegistrationWizardPage> {
  late final PageController _pageController;
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _passwordConfirmation = TextEditingController();
  final _businessName = TextEditingController();
  final _vatNumber = TextEditingController();
  final _streetAddress = TextEditingController();
  final _postalCode = TextEditingController();

  @override
  void initState() {
    super.initState();
    final authBloc = context.read<AuthBloc>();
    _pageController = PageController(initialPage: _pageIndex(authBloc.state));
    if (authBloc.state is! AuthRegistration &&
        authBloc.state is! AuthEmailVerificationPending) {
      authBloc.add(const RegistrationStarted());
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fullName.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _passwordConfirmation.dispose();
    _businessName.dispose();
    _vatNumber.dispose();
    _streetAddress.dispose();
    _postalCode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          _pageIndex(previous) != _pageIndex(current) ||
          _dialogMessage(previous) != _dialogMessage(current),
      listener: (context, state) {
        final targetPage = _pageIndex(state);
        if (_pageController.hasClients &&
            _pageController.page?.round() != targetPage) {
          unawaited(
            _pageController.animateToPage(
              targetPage,
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeInOutCubic,
            ),
          );
        }
        final message = _dialogMessage(state);
        if (message != null) {
          unawaited(_showError(context, message));
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final page = _pageIndex(state);
          final colors = AmThemeColors.of(context);
          final keyboardOverlap = math.max(
            0.0,
            MediaQuery.viewInsetsOf(context).bottom -
                _WizardActions.extent(context),
          );
          _keepFocusedFieldVisible(keyboardOverlap);
          return Scaffold(
            backgroundColor: colors.background,
            resizeToAvoidBottomInset: false,
            body: SafeArea(
              maintainBottomViewPadding: true,
              child: Column(
                children: [
                  AmWizardProgress(
                    steps: const ['Anagrafica', 'Officina', 'Conferma'],
                    currentStep: page,
                  ),
                  Expanded(
                    child: Padding(
                      // La barra inferiore resta ferma e viene coperta dalla
                      // tastiera. Si restringe soltanto il viewport dello step,
                      // cosi' il campo focalizzato puo' scorrere sopra di essa.
                      padding: EdgeInsets.only(bottom: keyboardOverlap),
                      child: PageView(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _PersonalDataStep(
                            state: state,
                            fullName: _fullName,
                            email: _email,
                            phone: _phone,
                            password: _password,
                            passwordConfirmation: _passwordConfirmation,
                          ),
                          _WorkshopStep(
                            state: state,
                            businessName: _businessName,
                            vatNumber: _vatNumber,
                            streetAddress: _streetAddress,
                            postalCode: _postalCode,
                          ),
                          _EmailConfirmationStep(state: state),
                        ],
                      ),
                    ),
                  ),
                  _WizardActions(state: state, currentPage: page),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showError(BuildContext context, String message) async {
    await showAmStatusDialog<void>(
      context,
      iconColor: const Color(0xFFFF453A),
      title: message.startsWith('Non hai')
          ? 'Email non confermata'
          : 'Operazione non riuscita',
      message: message,
      actions: [
        AmDialogAction(
          label: 'Chiudi',
          color: const Color(0xFFFF6B00),
          filled: true,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
    if (context.mounted) {
      context.read<AuthBloc>().add(const AuthDialogDismissed());
    }
  }

  int _pageIndex(AuthState state) => switch (state) {
    AuthEmailVerificationPending() || AuthAuthenticated() => 2,
    AuthRegistration(step: RegistrationStep.workshop) => 1,
    _ => 0,
  };

  String? _dialogMessage(AuthState state) => switch (state) {
    AuthRegistration(:final dialogMessage) => dialogMessage,
    AuthEmailVerificationPending(:final dialogMessage) => dialogMessage,
    _ => null,
  };

  void _keepFocusedFieldVisible(double keyboardOverlap) {
    if (keyboardOverlap == 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final focusedContext = FocusManager.instance.primaryFocus?.context;
      if (focusedContext == null) return;
      final editableContext = _findEditableText(focusedContext);
      if (editableContext == null) return;
      unawaited(
        Scrollable.ensureVisible(
          editableContext,
          alignment: 0.5,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        ),
      );
    });
  }

  BuildContext? _findEditableText(BuildContext focusContext) {
    BuildContext? result;

    void visit(Element element) {
      if (result != null) return;
      if (element.widget is EditableText) {
        result = element;
        return;
      }
      element.visitChildElements(visit);
    }

    visit(focusContext as Element);
    return result;
  }
}

final class _PersonalDataStep extends StatelessWidget {
  const _PersonalDataStep({
    required this.state,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.password,
    required this.passwordConfirmation,
  });

  final AuthState state;
  final TextEditingController fullName;
  final TextEditingController email;
  final TextEditingController phone;
  final TextEditingController password;
  final TextEditingController passwordConfirmation;

  @override
  Widget build(BuildContext context) {
    final errors = state is AuthRegistration
        ? (state as AuthRegistration).errors
        : const RegistrationFieldErrors();
    return _StepScroll(
      title: 'I tuoi dati',
      subtitle: 'Inserisci i dati del titolare dell’officina.',
      children: [
        _FieldRow(
          child: AmTextField(
            label: 'Nome e cognome',
            placeholder: 'Mario Rossi',
            controller: fullName,
            isRequired: true,
            obscureText: false,
            keyboardType: TextInputType.name,
            errorText: errors.fullName,
            onChanged: (value) =>
                context.read<AuthBloc>().add(FullNameChanged(value as String)),
          ),
        ),
        _FieldRow(
          child: AmTextField(
            label: 'Email',
            placeholder: 'nome@officina.it',
            controller: email,
            isRequired: true,
            obscureText: false,
            keyboardType: TextInputType.emailAddress,
            errorText: errors.email,
            onChanged: (value) =>
                context.read<AuthBloc>().add(EmailChanged(value as String)),
          ),
        ),
        _FieldRow(
          child: AmTextField(
            label: 'Telefono',
            placeholder: '+39 333 1234567',
            controller: phone,
            isRequired: true,
            obscureText: false,
            keyboardType: TextInputType.phone,
            errorText: errors.phone,
            onChanged: (value) =>
                context.read<AuthBloc>().add(PhoneChanged(value as String)),
          ),
        ),
        _FieldRow(
          child: AmTextField(
            label: 'Password',
            placeholder: 'Almeno 8 caratteri',
            controller: password,
            isRequired: true,
            obscureText: true,
            keyboardType: TextInputType.visiblePassword,
            errorText: errors.password,
            onChanged: (value) =>
                context.read<AuthBloc>().add(PasswordChanged(value as String)),
          ),
        ),
        _FieldRow(
          child: AmTextField(
            label: 'Conferma password',
            placeholder: 'Ripeti la password',
            controller: passwordConfirmation,
            isRequired: true,
            obscureText: true,
            keyboardType: TextInputType.visiblePassword,
            errorText: errors.passwordConfirmation,
            onChanged: (value) => context.read<AuthBloc>().add(
              PasswordConfirmationChanged(value as String),
            ),
          ),
        ),
      ],
    );
  }
}

final class _WorkshopStep extends StatelessWidget {
  const _WorkshopStep({
    required this.state,
    required this.businessName,
    required this.vatNumber,
    required this.streetAddress,
    required this.postalCode,
  });

  final AuthState state;
  final TextEditingController businessName;
  final TextEditingController vatNumber;
  final TextEditingController streetAddress;
  final TextEditingController postalCode;

  @override
  Widget build(BuildContext context) {
    final registration = state is AuthRegistration
        ? state as AuthRegistration
        : const AuthRegistration(
            step: RegistrationStep.workshop,
            draft: RegistrationDraft(),
            municipalities: [],
          );
    return _StepScroll(
      title: 'La tua officina',
      subtitle: 'Questi dati saranno associati al profilo meccanico.',
      children: [
        _FieldRow(
          child: AmTextField(
            label: 'Nome officina',
            placeholder: 'Officina Rossi',
            controller: businessName,
            isRequired: true,
            obscureText: false,
            keyboardType: TextInputType.text,
            errorText: registration.errors.businessName,
            onChanged: (value) => context.read<AuthBloc>().add(
              BusinessNameChanged(value as String),
            ),
          ),
        ),
        _FieldRow(
          child: AmTextField(
            label: 'Partita IVA',
            placeholder: '12345678901',
            controller: vatNumber,
            isRequired: true,
            obscureText: false,
            keyboardType: TextInputType.number,
            errorText: registration.errors.vatNumber,
            onChanged: (value) =>
                context.read<AuthBloc>().add(VatNumberChanged(value as String)),
          ),
        ),
        _FieldRow(
          child: AmTextField(
            label: 'Via e numero civico',
            placeholder: 'Via Roma 10',
            controller: streetAddress,
            isRequired: true,
            obscureText: false,
            keyboardType: TextInputType.streetAddress,
            errorText: registration.errors.streetAddress,
            onChanged: (value) => context.read<AuthBloc>().add(
              StreetAddressChanged(value as String),
            ),
          ),
        ),
        _FieldRow(
          child: AmTextField(
            label: 'CAP',
            placeholder: '00100',
            controller: postalCode,
            isRequired: true,
            obscureText: false,
            keyboardType: TextInputType.number,
            errorText: registration.errors.postalCode,
            onChanged: (value) => context.read<AuthBloc>().add(
              PostalCodeChanged(value as String),
            ),
          ),
        ),
        _FieldRow(
          child: AmDropdownSearch<ItalianMunicipality>(
            label: 'Comune',
            items: registration.municipalities,
            value: registration.draft.municipality,
            itemLabelBuilder: (item) => item.label,
            onChanged: (value) =>
                context.read<AuthBloc>().add(MunicipalityChanged(value)),
            placeholder: 'Cerca il comune',
          ),
        ),
        if (registration.errors.municipality case final message?)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFFF453A),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

final class _EmailConfirmationStep extends StatelessWidget {
  const _EmailConfirmationStep({required this.state});
  final AuthState state;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    final email = state is AuthEmailVerificationPending
        ? (state as AuthEmailVerificationPending).email
        : '';
    return AmEdgeBlur(
      child: Center(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.mark_email_unread_outlined,
                size: 72,
                color: colors.accent,
              ),
              const SizedBox(height: 24),
              Text(
                'Conferma la tua email',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                email.isEmpty
                    ? 'Apri il link che ti abbiamo inviato.'
                    : 'Abbiamo inviato un link a $email. Aprilo sullo stesso dispositivo, poi torna qui.',
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.textSecondary, height: 1.45),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _StepScroll extends StatelessWidget {
  const _StepScroll({
    required this.title,
    required this.subtitle,
    required this.children,
  });
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return AmEdgeBlur(
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 25,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(subtitle, style: TextStyle(color: colors.textSecondary)),
            const SizedBox(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }
}

final class _FieldRow extends StatelessWidget {
  const _FieldRow({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Row(children: [child]),
  );
}

final class _WizardActions extends StatelessWidget {
  const _WizardActions({required this.state, required this.currentPage});
  final AuthState state;
  final int currentPage;

  /// Distanza fra il fondo del PageView e il bordo fisico dello schermo.
  /// Serve a non sottrarre due volte lo spazio gia' occupato dalla barra.
  static double extent(BuildContext context) =>
      10 + 54 + 20 + MediaQuery.viewPaddingOf(context).bottom;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    final submitting = switch (state) {
      AuthRegistration(:final isSubmitting) => isSubmitting,
      AuthEmailVerificationPending(:final checking) => checking,
      _ => false,
    };
    final label = switch (currentPage) {
      0 => 'Continua',
      1 => 'Crea officina',
      _ => 'Ho confermato',
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: SizedBox(
        height: 54,
        child: Row(
          children: [
            if (currentPage == 1) ...[
              AmIconButton(
                width: 54,
                height: 54,
                radius: 27,
                showShadow: true,
                shadowColor: colors.shadow.withValues(alpha: 0.18),
                backgroundColor: colors.surface,
                iconColor: colors.accent,
                icon: Icons.arrow_back_rounded,
                tooltip: 'Indietro',
                onPressed: () => context.read<AuthBloc>().add(
                  const RegistrationBackPressed(),
                ),
              ),
              const SizedBox(width: 14),
            ],
            Expanded(
              child: AmMainFab(
                label: label,
                color: colors.accent,
                isLoading: submitting,
                onPressed: () => context.read<AuthBloc>().add(
                  currentPage == 2
                      ? const EmailConfirmationPressed()
                      : const RegistrationContinuePressed(),
                ),
                width: double.infinity,
                height: 54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
