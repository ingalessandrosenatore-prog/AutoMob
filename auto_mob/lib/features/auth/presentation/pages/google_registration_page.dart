import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/owner_registration.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class GoogleRegistrationPage extends StatefulWidget {
  const GoogleRegistrationPage({super.key});

  @override
  State<GoogleRegistrationPage> createState() => _GoogleRegistrationPageState();
}

class _GoogleRegistrationPageState extends State<GoogleRegistrationPage> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _postalCode = TextEditingController();

  @override
  void initState() {
    super.initState();
    _prefill(context.read<AuthBloc>().state);
  }

  void _prefill(AuthState state) {
    if (state is! AuthOwnerProfilePending) return;
    if (_name.text.isEmpty) _name.text = state.profile.fullName;
    if (_phone.text.isEmpty) _phone.text = state.profile.phone;
    if (_postalCode.text.isEmpty) _postalCode.text = state.profile.postalCode;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _postalCode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<AuthBloc, AuthState>(
    listener: (_, state) => _prefill(state),
    builder: (context, state) {
      final pending = state is AuthOwnerProfilePending ? state : null;
      final busy = state is AuthLoading || (pending?.busy ?? false);
      final message =
          pending?.message ?? (state is AuthError ? state.message : null);
      final colors = AmThemeColors.of(context);
      return PopScope(
        canPop: pending == null && !busy,
        child: Scaffold(
          backgroundColor: colors.background,
          appBar: AppBar(
            title: Text(
              pending == null ? 'Registrati con Google' : 'Completa il profilo',
            ),
            automaticallyImplyLeading: false,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: busy
                  ? null
                  : () {
                      if (pending != null) {
                        context.read<AuthBloc>().add(LogoutEvent());
                      } else {
                        context.go('/login');
                      }
                    },
            ),
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  pending == null
                      ? 'Inserisci telefono e CAP, poi scegli il tuo account Google.'
                      : 'Ancora pochi dati per iniziare a usare AutoMob.',
                ),
                const SizedBox(height: 24),
                if (pending != null) ...[
                  Row(
                    children: [
                      AmTextField(
                        label: 'Nome e cognome',
                        placeholder: 'Mario Rossi',
                        controller: _name,
                        isRequired: true,
                        obscureText: false,
                        keyboardType: TextInputType.name,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                ],
                Row(
                  children: [
                    AmTextField(
                      label: 'Telefono',
                      controller: _phone,
                      placeholder: '+39 333 1234567',
                      isRequired: true,
                      obscureText: false,
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    AmTextField(
                      label: 'CAP',
                      controller: _postalCode,
                      placeholder: '00000',
                      isRequired: true,
                      obscureText: false,
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (message != null) ...[
                  Text(message, style: TextStyle(color: colors.danger)),
                  const SizedBox(height: 16),
                ],
                if (state is AuthOAuthWaiting) ...[
                  const Text(
                    'Completa l’accesso nel browser. Se lo hai chiuso, puoi riprovare.',
                  ),
                  const SizedBox(height: 16),
                ],
                SmallPrincipal(
                  label: pending == null
                      ? 'Continua con Google'
                      : 'Completa registrazione',
                  color: colors.accent,
                  isLoading: busy,
                  onPressed: busy
                      ? null
                      : () {
                          final registration = OwnerRegistration(
                            fullName: _name.text,
                            phone: _phone.text,
                            postalCode: _postalCode.text,
                          );
                          context.read<AuthBloc>().add(
                            pending == null
                                ? LoginWithGoogleEvent(
                                    registration: registration,
                                  )
                                : CompleteOwnerProfileEvent(registration),
                          );
                        },
                ),
                if (pending != null)
                  TextButton(
                    onPressed: busy
                        ? null
                        : () =>
                              context.read<AuthBloc>().add(CheckSessionEvent()),
                    child: const Text('Riprova verifica profilo'),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
