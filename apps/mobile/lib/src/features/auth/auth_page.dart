import 'package:flutter/material.dart';

import '../../data/account_repository.dart';
import '../../data/api_account_repository.dart';
import '../../domain/user_profile.dart';
import '../../theme/livearound_theme.dart';

enum _AuthMode { login, register }

/// Reinitialisation en deux etapes : demande du code par email, puis saisie
/// du code et du nouveau mot de passe. En developpement, le code est affiche
/// directement (l'envoi par email reste a brancher cote API).
class PasswordResetDialog extends StatefulWidget {
  const PasswordResetDialog({
    required this.accountRepository,
    this.initialEmail = '',
    super.key,
  });

  final AccountRepository accountRepository;
  final String initialEmail;

  @override
  State<PasswordResetDialog> createState() => _PasswordResetDialogState();
}

class _PasswordResetDialogState extends State<PasswordResetDialog> {
  late final TextEditingController _emailController;
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  var _codeRequested = false;
  var _isBusy = false;
  String? _devCode;
  String? _error;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    final email = _emailController.text.trim();
    if (!email.contains('@')) {
      setState(() => _error = 'Saisissez un e-mail valide.');
      return;
    }

    setState(() {
      _isBusy = true;
      _error = null;
    });

    try {
      final devCode = await widget.accountRepository.requestPasswordReset(
        email: email,
      );
      if (!mounted) return;
      setState(() {
        _codeRequested = true;
        _devCode = devCode;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Demande impossible, reessayez plus tard.');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _submitReset() async {
    if (_codeController.text.trim().length != 6) {
      setState(() => _error = 'Le code contient 6 chiffres.');
      return;
    }
    if (_passwordController.text.length < 8) {
      setState(() => _error = 'Nouveau mot de passe : minimum 8 caracteres.');
      return;
    }

    setState(() {
      _isBusy = true;
      _error = null;
    });

    try {
      await widget.accountRepository.resetPassword(
        email: _emailController.text.trim(),
        code: _codeController.text.trim(),
        newPassword: _passwordController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Code invalide ou expire.');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Mot de passe oublie'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _emailController,
              enabled: !_codeRequested,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.alternate_email_rounded),
                labelText: 'E-mail',
              ),
            ),
            if (_codeRequested) ...[
              const SizedBox(height: 12),
              if (_devCode != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Code (mode developpement) : $_devCode',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.pin_rounded),
                  labelText: 'Code a 6 chiffres',
                  counterText: '',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.lock_outline_rounded),
                  labelText: 'Nouveau mot de passe',
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isBusy ? null : () => Navigator.of(context).pop(false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _isBusy
              ? null
              : _codeRequested
                  ? _submitReset
                  : _requestCode,
          child: Text(
            _isBusy
                ? 'Patientez...'
                : _codeRequested
                    ? 'Reinitialiser'
                    : 'Recevoir un code',
          ),
        ),
      ],
    );
  }
}

class AuthPage extends StatefulWidget {
  const AuthPage({
    required this.accountRepository,
    required this.onAuthenticated,
    super.key,
  });

  final AccountRepository accountRepository;
  final ValueChanged<UserProfile> onAuthenticated;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  var _mode = _AuthMode.login;
  var _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _errorMessage = null;
    });

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final profile = _mode == _AuthMode.login
          ? await widget.accountRepository.login(
              email: _emailController.text,
              password: _passwordController.text,
            )
          : await widget.accountRepository.register(
              displayName: _nameController.text,
              email: _emailController.text,
              password: _passwordController.text,
            );

      if (!mounted) return;
      widget.onAuthenticated(profile);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _describeError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _openPasswordReset() async {
    final success = await showDialog<bool>(
      context: context,
      builder: (context) => PasswordResetDialog(
        accountRepository: widget.accountRepository,
        initialEmail: _emailController.text,
      ),
    );

    if (success == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mot de passe reinitialise, connectez-vous.'),
        ),
      );
    }
  }

  String _describeError(Object error) {
    if (error is ApiUnavailableException) {
      return 'Serveur injoignable. Verifiez votre connexion ou que l\'API est demarree.';
    }
    if (error is ApiRequestException) {
      if (error.statusCode == 401) {
        return 'Identifiants invalides.';
      }
      if (error.statusCode == 409) {
        return 'Un compte existe deja avec cet e-mail.';
      }
      if (error.statusCode == 503) {
        return 'Service temporairement indisponible. Reessayez plus tard.';
      }
    }
    return _mode == _AuthMode.login
        ? 'Connexion impossible avec ces identifiants.'
        : 'Creation du compte impossible.';
  }

  @override
  Widget build(BuildContext context) {
    final isRegister = _mode == _AuthMode.register;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'LiveAround',
                      style:
                          Theme.of(context).textTheme.headlineLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: LiveAroundTheme.ink,
                              ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Connectez-vous pour retrouver vos preferences et vos favoris.',
                      style: TextStyle(
                        color: Colors.black.withValues(alpha: 0.62),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SegmentedButton<_AuthMode>(
                      segments: const [
                        ButtonSegment(
                          value: _AuthMode.login,
                          icon: Icon(Icons.login_rounded),
                          label: Text('Connexion'),
                        ),
                        ButtonSegment(
                          value: _AuthMode.register,
                          icon: Icon(Icons.person_add_alt_rounded),
                          label: Text('Creer'),
                        ),
                      ],
                      selected: {_mode},
                      onSelectionChanged: _isSubmitting
                          ? null
                          : (selection) {
                              setState(() {
                                _mode = selection.first;
                                _errorMessage = null;
                              });
                            },
                    ),
                    const SizedBox(height: 18),
                    if (isRegister) ...[
                      TextFormField(
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.badge_outlined),
                          labelText: 'Nom',
                        ),
                        validator: (value) {
                          if (!isRegister) return null;
                          if ((value ?? '').trim().isEmpty) {
                            return 'Saisissez un nom.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.alternate_email_rounded),
                        labelText: 'E-mail',
                      ),
                      validator: (value) {
                        final email = (value ?? '').trim();
                        if (!email.contains('@') || !email.contains('.')) {
                          return 'Saisissez un e-mail valide.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _isSubmitting ? null : _submit(),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.lock_outline_rounded),
                        labelText: 'Mot de passe',
                      ),
                      validator: (value) {
                        if ((value ?? '').length < 8) {
                          return 'Minimum 8 caracteres.';
                        }
                        return null;
                      },
                    ),
                    if (!isRegister)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _isSubmitting ? null : _openPasswordReset,
                          child: const Text('Mot de passe oublie ?'),
                        ),
                      ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    FilledButton.icon(
                      onPressed: _isSubmitting ? null : _submit,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              isRegister
                                  ? Icons.person_add_alt_rounded
                                  : Icons.login_rounded,
                            ),
                      label: Text(
                        _isSubmitting
                            ? 'Verification...'
                            : isRegister
                                ? 'Creer le compte'
                                : 'Se connecter',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
