import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/utils/mobile_number.dart';
import '../../../core/utils/security_pin.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../controllers/auth_controller.dart';

class AuthView extends StatefulWidget {
  const AuthView({super.key});

  @override
  State<AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends State<AuthView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  final _confirmPinFieldKey = GlobalKey<FormFieldState<String>>();
  final _authController = Get.find<AuthController>();

  late bool _isCreatingAccount;
  bool _isPinVisible = false;
  bool _isConfirmPinVisible = false;
  bool _isSubmitting = false;
  bool get _hasLegacyEmail =>
      _authController.account.value?.phoneNumber.contains('@') ?? false;
  bool get _hasLegacyPassword =>
      _authController.account.value?.usesPin == false;

  @override
  void initState() {
    super.initState();
    _isCreatingAccount = !_authController.hasAccount;
    _pinController.addListener(_validatePinConfirmation);
  }

  void _validatePinConfirmation() {
    if (_isCreatingAccount && _confirmPinController.text.length == 6) {
      _confirmPinFieldKey.currentState?.validate();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _pinController.removeListener(_validatePinConfirmation);
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  String? _validatePhone(String? value) {
    if (!_isCreatingAccount && _hasLegacyEmail && (value ?? '').contains('@')) {
      final email = (value ?? '').trim();
      return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)
          ? null
          : 'Enter a valid mobile number';
    }
    return MobileNumber.validate(value);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSubmitting = true);

    try {
      if (_isCreatingAccount) {
        await _authController.createAccount(
          name: _nameController.text,
          phoneNumber: _phoneController.text,
          pin: _pinController.text,
        );
        SnackbarHelper.success('Your account is ready');
      } else {
        final success = await _authController.login(
          phoneNumber: _phoneController.text,
          credential: _pinController.text,
        );
        if (success) {
          SnackbarHelper.success('Welcome back');
        } else {
          SnackbarHelper.error(
            'Mobile number or '
            '${_hasLegacyPassword ? 'password' : 'PIN'} is incorrect',
          );
        }
      }
    } on PlatformException catch (error) {
      SnackbarHelper.error('Could not access local account storage: $error');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _switchAuthMode() {
    if (_isSubmitting || (!_isCreatingAccount && _authController.hasAccount)) {
      return;
    }

    setState(() {
      _isCreatingAccount = !_isCreatingAccount;
      _pinController.clear();
      _confirmPinController.clear();
      _isPinVisible = false;
      _isConfirmPinVisible = false;
    });
    _formKey.currentState?.reset();
  }

  Future<void> _recoverForgottenPassword() async {
    final values = await showDialog<_PinRecoveryValues>(
      context: context,
      builder: (_) => _PinRecoveryDialog(
        usesLegacyPassword: _hasLegacyPassword,
      ),
    );
    if (values == null) return;

    setState(() => _isSubmitting = true);
    try {
      final changed = await _authController.recoverPin(
        currentCredential: values.currentCredential,
        newPin: values.newPin,
      );
      if (changed) {
        SnackbarHelper.success('PIN updated. Sign in with your new PIN.');
      } else {
        SnackbarHelper.error('The current PIN or password is incorrect');
      }
    } on PlatformException catch (error) {
      SnackbarHelper.error('Could not access local account storage: $error');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(
        color: scheme.outlineVariant.withValues(alpha: 0.8),
      ),
    );

    return Scaffold(
      body: Theme(
        data: theme.copyWith(
          inputDecorationTheme: theme.inputDecorationTheme.copyWith(
            filled: true,
            fillColor: scheme.surface,
            border: fieldBorder,
            enabledBorder: fieldBorder,
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: scheme.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: scheme.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: scheme.error, width: 1.5),
            ),
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Image.asset(
                            'assets/app_icon.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 11),
                        Text(
                          'Expense Tracker',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 34),
                    Text(
                      _isCreatingAccount
                          ? 'Your money, in focus.'
                          : 'Welcome back.',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.7,
                      ),
                    ),
                    Text(
                      _isCreatingAccount
                          ? 'Create an account to keep your spending organized.'
                          : 'Sign in to continue to your expense tracker.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 26),
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                        side: BorderSide(
                          color: scheme.outlineVariant.withValues(alpha: 0.55),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (_isCreatingAccount) ...[
                                TextFormField(
                                  controller: _nameController,
                                  textCapitalization: TextCapitalization.words,
                                  autofillHints: const [AutofillHints.name],
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(
                                    labelText: 'Full name',
                                    prefixIcon: Icon(Icons.person_outline),
                                  ),
                                  validator: (value) =>
                                      value == null || value.trim().isEmpty
                                          ? 'Enter your name'
                                          : null,
                                ),
                                const SizedBox(height: 14),
                              ],
                              TextFormField(
                                controller: _phoneController,
                                keyboardType:
                                    !_isCreatingAccount && _hasLegacyEmail
                                        ? TextInputType.text
                                        : TextInputType.phone,
                                inputFormatters:
                                    !_isCreatingAccount && _hasLegacyEmail
                                        ? null
                                        : [
                                            FilteringTextInputFormatter.allow(
                                              RegExp(r'[0-9+\s()-]'),
                                            ),
                                          ],
                                autofillHints: [
                                  _isCreatingAccount
                                      ? AutofillHints.newUsername
                                      : AutofillHints.username,
                                ],
                                textInputAction: TextInputAction.next,
                                decoration: InputDecoration(
                                  labelText:
                                      !_isCreatingAccount && _hasLegacyEmail
                                          ? 'Mobile number or existing email'
                                          : 'Mobile number',
                                  hintText: '+880 1XXX-XXXXXX',
                                  prefixIcon:
                                      const Icon(Icons.phone_iphone_outlined),
                                  helperText: _isCreatingAccount
                                      ? 'No email or OTP required'
                                      : null,
                                ),
                                validator: _validatePhone,
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _pinController,
                                obscureText: !_isPinVisible,
                                keyboardType: _hasLegacyPassword
                                    ? TextInputType.text
                                    : TextInputType.number,
                                inputFormatters: _hasLegacyPassword
                                    ? null
                                    : [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(
                                          SecurityPin.length,
                                        ),
                                      ],
                                autofillHints: _hasLegacyPassword
                                    ? const [AutofillHints.password]
                                    : null,
                                textInputAction: _isCreatingAccount
                                    ? TextInputAction.next
                                    : TextInputAction.done,
                                onFieldSubmitted: (_) {
                                  if (!_isCreatingAccount) _submit();
                                },
                                decoration: InputDecoration(
                                  labelText: _hasLegacyPassword
                                      ? 'Previous password'
                                      : '6-digit PIN',
                                  hintText:
                                      _hasLegacyPassword ? null : '••••••',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    tooltip:
                                        _isPinVisible ? 'Hide PIN' : 'Show PIN',
                                    onPressed: () => setState(
                                      () => _isPinVisible = !_isPinVisible,
                                    ),
                                    icon: Icon(
                                      _isPinVisible
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                    ),
                                  ),
                                  helperText: _isCreatingAccount
                                      ? 'Choose a 6-digit PIN for sign in'
                                      : null,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return _hasLegacyPassword
                                        ? 'Enter your previous password'
                                        : 'Enter your PIN';
                                  }

                                  if (_hasLegacyPassword &&
                                      !_isCreatingAccount) {
                                    return null;
                                  }
                                  return SecurityPin.validate(value);
                                },
                              ),
                              if (_isCreatingAccount) ...[
                                const SizedBox(height: 14),
                                TextFormField(
                                  key: _confirmPinFieldKey,
                                  controller: _confirmPinController,
                                  obscureText: !_isConfirmPinVisible,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(
                                      SecurityPin.length,
                                    ),
                                  ],
                                  textInputAction: TextInputAction.done,
                                  onChanged: (value) {
                                    if (value.length == SecurityPin.length) {
                                      _confirmPinFieldKey.currentState
                                          ?.validate();
                                    }
                                  },
                                  onFieldSubmitted: (_) => _submit(),
                                  decoration: InputDecoration(
                                    labelText: 'Confirm 6-digit PIN',
                                    hintText: '••••••',
                                    prefixIcon:
                                        const Icon(Icons.lock_reset_outlined),
                                    suffixIcon: IconButton(
                                      tooltip: _isConfirmPinVisible
                                          ? 'Hide PIN'
                                          : 'Show PIN',
                                      onPressed: () => setState(
                                        () => _isConfirmPinVisible =
                                            !_isConfirmPinVisible,
                                      ),
                                      icon: Icon(
                                        _isConfirmPinVisible
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    final pinError =
                                        SecurityPin.validate(value);
                                    if (pinError != null) return pinError;
                                    return value != _pinController.text
                                        ? 'PINs do not match'
                                        : null;
                                  },
                                ),
                              ],
                              const SizedBox(height: 22),
                              FilledButton(
                                onPressed: _isSubmitting ? null : _submit,
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(52),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: _isSubmitting
                                    ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        _isCreatingAccount
                                            ? 'Create account'
                                            : 'Sign in',
                                      ),
                              ),
                              if (!_isCreatingAccount) ...[
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: _isSubmitting
                                      ? null
                                      : _recoverForgottenPassword,
                                  child: Text(
                                    _hasLegacyPassword
                                        ? 'Forgot password?'
                                        : 'Forgot PIN?',
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (_isCreatingAccount || !_authController.hasAccount) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _isCreatingAccount
                                ? 'Already have a profile?'
                                : 'Need a new profile?',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          TextButton(
                            onPressed: _switchAuthMode,
                            child: Text(
                              _isCreatingAccount ? 'Log in' : 'Create account',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock_outline,
                          size: 15,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Your profile stays on this device',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
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

class _PinRecoveryValues {
  const _PinRecoveryValues({
    required this.currentCredential,
    required this.newPin,
  });

  final String currentCredential;
  final String newPin;
}

class _PinRecoveryDialog extends StatefulWidget {
  const _PinRecoveryDialog({required this.usesLegacyPassword});

  final bool usesLegacyPassword;

  @override
  State<_PinRecoveryDialog> createState() => _PinRecoveryDialogState();
}

class _PinRecoveryDialogState extends State<_PinRecoveryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentCredentialController = TextEditingController();
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();

  @override
  void dispose() {
    _currentCredentialController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.pop(
      context,
      _PinRecoveryValues(
        currentCredential: _currentCredentialController.text,
        newPin: _newPinController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final credentialLabel =
        widget.usesLegacyPassword ? 'Current password' : 'Current PIN';
    final credentialInputFormatters = widget.usesLegacyPassword
        ? null
        : [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(SecurityPin.length),
          ];
    final pinInputFormatters = [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(SecurityPin.length),
    ];

    return AlertDialog(
      title: Text(widget.usesLegacyPassword ? 'Set a new PIN' : 'Forgot PIN?'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _currentCredentialController,
                obscureText: true,
                keyboardType: widget.usesLegacyPassword
                    ? TextInputType.text
                    : TextInputType.number,
                inputFormatters: credentialInputFormatters,
                decoration: InputDecoration(labelText: credentialLabel),
                validator: (value) {
                  if (widget.usesLegacyPassword) {
                    return value == null || value.isEmpty
                        ? 'Enter your current password'
                        : null;
                  }
                  return SecurityPin.validate(value);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _newPinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                inputFormatters: pinInputFormatters,
                decoration: const InputDecoration(labelText: 'New 6-digit PIN'),
                validator: SecurityPin.validate,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmPinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                inputFormatters: pinInputFormatters,
                decoration: const InputDecoration(labelText: 'Confirm new PIN'),
                validator: (value) {
                  final pinError = SecurityPin.validate(value);
                  if (pinError != null) return pinError;
                  return value != _newPinController.text
                      ? 'PINs do not match'
                      : null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Update PIN')),
      ],
    );
  }
}
