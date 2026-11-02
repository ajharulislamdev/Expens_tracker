import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/currency_settings.dart';
import '../../../core/services/daily_expense_reminder_service.dart';
import '../../../core/utils/mobile_number.dart';
import '../../../core/utils/security_pin.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../data/models/account_model.dart';
import '../../auth/controllers/auth_controller.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final _authController = Get.find<AuthController>();
  final _currencySettings = Get.find<CurrencySettings>();
  final _reminderService = Get.find<DailyExpenseReminderService>();
  final _imagePicker = ImagePicker();
  bool _isPickingPhoto = false;

  Future<void> _pickPhoto() async {
    setState(() => _isPickingPhoto = true);
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 640,
        maxHeight: 640,
        imageQuality: 82,
      );
      if (image == null) return;

      final bytes = await image.readAsBytes();
      await _authController.updatePhoto(bytes);
      SnackbarHelper.success('Profile photo saved on this device');
    } on PlatformException catch (error) {
      SnackbarHelper.error(error.message ?? 'Could not open photo library');
    } finally {
      if (mounted) setState(() => _isPickingPhoto = false);
    }
  }

  Future<void> _removePhoto() async {
    await _authController.updatePhoto(null);
    SnackbarHelper.success('Profile photo removed');
  }

  Future<void> _editProfile(AccountModel account) async {
    final values = await showDialog<_ProfileValues>(
      context: context,
      builder: (_) => _ProfileEditorDialog(account: account),
    );
    if (values == null) return;

    await _authController.updateProfile(
      name: values.name,
      phoneNumber: values.phoneNumber,
    );
    SnackbarHelper.success('Account details updated');
  }

  Future<void> _changePin() async {
    final values = await showDialog<_PinValues>(
      context: context,
      builder: (_) => _PinEditorDialog(
        usesPin: _authController.account.value?.usesPin ?? true,
      ),
    );
    if (values == null) return;

    final changed = await _authController.changePin(
      currentCredential: values.currentCredential,
      newPin: values.newPin,
    );
    if (changed) {
      SnackbarHelper.success('PIN updated');
    } else {
      SnackbarHelper.error('Current PIN or password is incorrect');
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out?'),
        content: Text(
          _authController.account.value?.usesPin == false
              ? 'You will need your previous password to sign in again.'
              : 'You will need your PIN to sign in again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _authController.logout();
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete local account?'),
        content: const Text(
          'Your profile, photo, and PIN will be deleted from this device. '
          'Transactions and goals will remain stored locally.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.expense,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete account'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _authController.deleteAccount();
    SnackbarHelper.info('Local account deleted');
  }

  Future<void> _chooseCurrency() async {
    await showDialog<void>(
      context: context,
      builder: (_) => _CurrencyPickerDialog(settings: _currencySettings),
    );
  }

  Future<void> _setReminderEnabled(bool enabled) async {
    try {
      final granted = await _reminderService.setEnabled(enabled);
      if (!granted && mounted) {
        SnackbarHelper.error(
          'Allow notifications in device settings to use daily reminders.',
        );
      }
    } catch (error) {
      if (mounted) {
        SnackbarHelper.error('Could not update reminder: $error');
      }
    }
  }

  Future<void> _chooseReminderTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _reminderService.reminderTime.value,
    );
    if (selected == null) return;
    try {
      await _reminderService.setReminderTime(selected);
    } catch (error) {
      if (mounted) {
        SnackbarHelper.error('Could not save reminder time: $error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Obx(() {
        final account = _authController.account.value;
        final currency = CurrencySettings.current.value;
        final reminderEnabled = _reminderService.isEnabled.value;
        final reminderTime =
            _reminderService.reminderTime.value.format(context);
        if (account == null) return const SizedBox.shrink();

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 112),
          children: [
            _ProfileCard(
              account: account,
              isPickingPhoto: _isPickingPhoto,
              onPickPhoto: _pickPhoto,
              onEditProfile: () => _editProfile(account),
              onRemovePhoto: account.photoBytes == null ? null : _removePhoto,
            ),
            const SizedBox(height: 24),
            const _SettingsSectionTitle(title: 'Account security'),
            const SizedBox(height: 10),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const _SettingsIcon(
                      icon: Icons.lock_reset_outlined,
                      color: AppColors.chartPurple,
                    ),
                    title: const Text('Change PIN'),
                    subtitle: const Text('Update your local sign-in PIN'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _changePin,
                  ),
                  Divider(
                    height: 1,
                    indent: 64,
                    color: scheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                  ListTile(
                    leading: const _SettingsIcon(
                      icon: Icons.logout_rounded,
                      color: AppColors.chartBlue,
                    ),
                    title: const Text('Sign out'),
                    subtitle: const Text('Lock this account on this device'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _logout,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const _SettingsSectionTitle(title: 'Preferences'),
            const SizedBox(height: 10),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const _SettingsIcon(
                      icon: Icons.currency_exchange_outlined,
                      color: AppColors.income,
                    ),
                    title: const Text('Currency'),
                    subtitle: Text(currency.label),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _chooseCurrency,
                  ),
                  Divider(
                    height: 1,
                    indent: 64,
                    color: scheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                  ListTile(
                    leading: const _SettingsIcon(
                      icon: Icons.notifications_active_outlined,
                      color: AppColors.chartPurple,
                    ),
                    title: const Text('Expense reminder'),
                    subtitle: Text('Daily at $reminderTime'),
                    onTap: _chooseReminderTime,
                    trailing: Switch(
                      value: reminderEnabled,
                      onChanged: _setReminderEnabled,
                    ),
                  ),
                  Divider(
                    height: 1,
                    indent: 64,
                    color: scheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                  const ListTile(
                    leading: _SettingsIcon(
                      icon: Icons.storage_outlined,
                      color: AppColors.chartOrange,
                    ),
                    title: Text('On-device storage'),
                    subtitle: Text(
                      'Account and app data are stored locally with Hive. '
                      'Local sign-in does not encrypt transaction data.',
                    ),
                  ),
                  Divider(
                    height: 1,
                    indent: 64,
                    color: scheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                  const ListTile(
                    leading: _SettingsIcon(
                      icon: Icons.info_outline,
                      color: AppColors.primary,
                    ),
                    title: Text('About'),
                    subtitle: Text(AppConstants.appName),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const _SettingsSectionTitle(title: 'Danger zone'),
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                leading: const _SettingsIcon(
                  icon: Icons.person_remove_outlined,
                  color: AppColors.expense,
                ),
                title: const Text('Delete local account'),
                subtitle: const Text(
                  'Remove the profile from this device',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: _deleteAccount,
              ),
            ),
            const SizedBox(height: 12),
          ],
        );
      }),
    );
  }
}

class _CurrencyPickerDialog extends StatelessWidget {
  const _CurrencyPickerDialog({required this.settings});

  final CurrencySettings settings;

  Future<void> _addCurrency(BuildContext context) async {
    final values = await showDialog<_NewCurrencyValues>(
      context: context,
      builder: (_) => const _NewCurrencyDialog(),
    );
    if (values == null) return;

    try {
      await settings.addCustom(code: values.code, symbol: values.symbol);
    } on ArgumentError catch (error) {
      SnackbarHelper.error(error.message?.toString() ?? 'Invalid currency');
    } catch (error) {
      SnackbarHelper.error('Could not save currency: $error');
    }
  }

  Future<void> _removeCurrency(
    BuildContext context,
    CurrencyOption currency,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove custom currency?'),
        content: Text('${currency.label} will be removed from this device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await settings.removeCustom(currency);
    } catch (error) {
      SnackbarHelper.error('Could not remove currency: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Choose currency'),
      content: SizedBox(
        width: double.maxFinite,
        child: Obx(() {
          final selected = CurrencySettings.current.value;
          final options = settings.options;
          return ListView(
            shrinkWrap: true,
            children: [
              for (final option in options)
                ListTile(
                  leading: Icon(
                    selected.code == option.code &&
                            selected.symbol == option.symbol
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: selected.code == option.code &&
                            selected.symbol == option.symbol
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  title: Text(option.code),
                  subtitle: Text(option.symbol),
                  contentPadding: EdgeInsets.zero,
                  onTap: () async {
                    try {
                      await settings.select(option);
                      if (context.mounted) Navigator.pop(context);
                    } catch (error) {
                      SnackbarHelper.error('Could not save currency: $error');
                    }
                  },
                  trailing: option.isCustom
                      ? IconButton(
                          tooltip: 'Remove custom currency',
                          onPressed: () => _removeCurrency(context, option),
                          icon: const Icon(Icons.delete_outline),
                        )
                      : null,
                ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.add_circle_outline),
                title: const Text('Add custom currency'),
                onTap: () => _addCurrency(context),
              ),
            ],
          );
        }),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _NewCurrencyValues {
  const _NewCurrencyValues({required this.code, required this.symbol});

  final String code;
  final String symbol;
}

class _NewCurrencyDialog extends StatefulWidget {
  const _NewCurrencyDialog();

  @override
  State<_NewCurrencyDialog> createState() => _NewCurrencyDialogState();
}

class _NewCurrencyDialogState extends State<_NewCurrencyDialog> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _symbolController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    _symbolController.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.pop(
      context,
      _NewCurrencyValues(
        code: _codeController.text.trim().toUpperCase(),
        symbol: _symbolController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add custom currency'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _codeController,
              textCapitalization: TextCapitalization.characters,
              maxLength: 8,
              decoration: const InputDecoration(
                labelText: 'Currency code',
                hintText: 'e.g. BDT',
                counterText: '',
              ),
              validator: (value) {
                final code = value?.trim() ?? '';
                if (!RegExp(r'^[A-Za-z0-9]{2,8}$').hasMatch(code)) {
                  return 'Use 2–8 letters or numbers';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _symbolController,
              maxLength: 8,
              decoration: const InputDecoration(
                labelText: 'Currency symbol',
                hintText: r'e.g. ৳, $, kr',
                counterText: '',
              ),
              validator: (value) {
                if ((value?.trim() ?? '').isEmpty) {
                  return 'Enter a currency symbol';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.account, required this.radius});

  final AccountModel account;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final photo = account.photoBytes;
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.white,
      foregroundImage: photo == null ? null : MemoryImage(photo),
      child: photo == null
          ? Text(
              account.name.trim().isEmpty
                  ? '?'
                  : account.name.trim()[0].toUpperCase(),
              style: TextStyle(
                color: AppColors.primary,
                fontSize: radius * 0.72,
                fontWeight: FontWeight.w700,
              ),
            )
          : null,
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.account,
    required this.isPickingPhoto,
    required this.onPickPhoto,
    required this.onEditProfile,
    required this.onRemovePhoto,
  });

  final AccountModel account;
  final bool isPickingPhoto;
  final VoidCallback onPickPhoto;
  final VoidCallback onEditProfile;
  final VoidCallback? onRemovePhoto;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedWhite = Colors.white.withValues(alpha: 0.76);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF30347F), Color(0xFF5558D9), Color(0xFF7771EA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned(
            top: -54,
            right: -28,
            child: _ProfileGlow(size: 166),
          ),
          const Positioned(
            bottom: 30,
            left: -72,
            child: _ProfileGlow(size: 150),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 19, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.account_circle_outlined,
                      size: 17,
                      color: mutedWhite,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'MY PROFILE',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.15,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.17),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.verified_user_outlined,
                            color: Color(0xFFC9F2DE),
                            size: 14,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'PRIVATE',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 21),
                Row(
                  children: [
                    _EditableProfileAvatar(
                      account: account,
                      isPickingPhoto: isPickingPhoto,
                      onTap: onPickPhoto,
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            account.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            account.phoneNumber,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: mutedWhite,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: const CircleBorder(),
                      child: IconButton(
                        tooltip: 'Edit profile details',
                        onPressed: onEditProfile,
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: Colors.white,
                          size: 19,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 19),
                Divider(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                const SizedBox(height: 13),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.phone_iphone_rounded,
                          size: 15,
                          color: mutedWhite,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Saved on this device',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: mutedWhite,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Wrap(
                      spacing: 2,
                      children: [
                        TextButton.icon(
                          onPressed: isPickingPhoto ? null : onPickPhoto,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: const Size(0, 36),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: isPickingPhoto
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.photo_camera_outlined,
                                  size: 16),
                          label: Text(
                            account.photoBytes == null ? 'Add photo' : 'Change',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (onRemovePhoto != null)
                          IconButton(
                            tooltip: 'Remove profile photo',
                            onPressed: onRemovePhoto,
                            visualDensity: VisualDensity.compact,
                            icon: Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: mutedWhite,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EditableProfileAvatar extends StatelessWidget {
  const _EditableProfileAvatar({
    required this.account,
    required this.isPickingPhoto,
    required this.onTap,
  });

  final AccountModel account;
  final bool isPickingPhoto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.74)),
          ),
          child: _ProfileAvatar(account: account, radius: 34),
        ),
        Positioned(
          right: -2,
          bottom: -2,
          child: Material(
            color: Colors.white,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: isPickingPhoto ? null : onTap,
              child: SizedBox(
                width: 28,
                height: 28,
                child: Center(
                  child: isPickingPhoto
                      ? const SizedBox(
                          height: 14,
                          width: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(
                          Icons.camera_alt_outlined,
                          size: 15,
                          color: AppColors.primary,
                        ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileGlow extends StatelessWidget {
  const _ProfileGlow({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.055),
        ),
      ),
    );
  }
}

class _SettingsSectionTitle extends StatelessWidget {
  const _SettingsSectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

class _SettingsIcon extends StatelessWidget {
  const _SettingsIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 21,
      backgroundColor: color.withValues(alpha: 0.12),
      child: Icon(icon, color: color, size: 21),
    );
  }
}

class _ProfileValues {
  const _ProfileValues({required this.name, required this.phoneNumber});

  final String name;
  final String phoneNumber;
}

class _ProfileEditorDialog extends StatefulWidget {
  const _ProfileEditorDialog({required this.account});

  final AccountModel account;

  @override
  State<_ProfileEditorDialog> createState() => _ProfileEditorDialogState();
}

class _ProfileEditorDialogState extends State<_ProfileEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.account.name);
    _phoneController = TextEditingController(text: widget.account.phoneNumber);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.pop(
      context,
      _ProfileValues(
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit profile'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Full name',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter your name'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s()-]')),
              ],
              decoration: const InputDecoration(
                labelText: 'Mobile number',
                hintText: '+880 1XXX-XXXXXX',
                prefixIcon: Icon(Icons.phone_iphone_outlined),
              ),
              validator: MobileNumber.validate,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}

class _PinValues {
  const _PinValues({
    required this.currentCredential,
    required this.newPin,
  });

  final String currentCredential;
  final String newPin;
}

class _PinEditorDialog extends StatefulWidget {
  const _PinEditorDialog({required this.usesPin});

  final bool usesPin;

  @override
  State<_PinEditorDialog> createState() => _PinEditorDialogState();
}

class _PinEditorDialogState extends State<_PinEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _confirmPinFieldKey = GlobalKey<FormFieldState<String>>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isCurrentVisible = false;
  bool _isNewVisible = false;
  bool _isConfirmVisible = false;

  @override
  void initState() {
    super.initState();
    _newController.addListener(_validatePinConfirmation);
  }

  void _validatePinConfirmation() {
    if (_confirmController.text.length == SecurityPin.length) {
      _confirmPinFieldKey.currentState?.validate();
    }
  }

  @override
  void dispose() {
    _currentController.dispose();
    _newController.removeListener(_validatePinConfirmation);
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.pop(
      context,
      _PinValues(
        currentCredential: _currentController.text,
        newPin: _newController.text,
      ),
    );
  }

  InputDecoration _pinDecoration(
    String label,
    IconData icon,
    bool visible,
    VoidCallback toggle,
  ) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      suffixIcon: IconButton(
        tooltip: visible ? 'Hide PIN' : 'Show PIN',
        onPressed: toggle,
        icon: Icon(
          visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        ),
      ),
    );
  }

  List<TextInputFormatter> get _pinFormatters => [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(SecurityPin.length),
      ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change PIN'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _currentController,
                obscureText: !_isCurrentVisible,
                keyboardType:
                    widget.usesPin ? TextInputType.number : TextInputType.text,
                inputFormatters: widget.usesPin ? _pinFormatters : null,
                textInputAction: TextInputAction.next,
                decoration: _pinDecoration(
                  widget.usesPin ? 'Current PIN' : 'Previous password',
                  Icons.lock_outline,
                  _isCurrentVisible,
                  () => setState(() => _isCurrentVisible = !_isCurrentVisible),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? widget.usesPin
                        ? 'Enter your current PIN'
                        : 'Enter your previous password'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _newController,
                obscureText: !_isNewVisible,
                keyboardType: TextInputType.number,
                inputFormatters: _pinFormatters,
                textInputAction: TextInputAction.next,
                decoration: _pinDecoration(
                  'New 6-digit PIN',
                  Icons.lock_reset_outlined,
                  _isNewVisible,
                  () => setState(() => _isNewVisible = !_isNewVisible),
                ),
                validator: (value) {
                  final error = SecurityPin.validate(value);
                  if (error != null) return error;
                  if (value == _currentController.text) {
                    return 'Choose a different PIN';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: _confirmPinFieldKey,
                controller: _confirmController,
                obscureText: !_isConfirmVisible,
                keyboardType: TextInputType.number,
                inputFormatters: _pinFormatters,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _save(),
                onChanged: (value) {
                  if (value.length == SecurityPin.length) {
                    _confirmPinFieldKey.currentState?.validate();
                  }
                },
                decoration: _pinDecoration(
                  'Confirm new PIN',
                  Icons.verified_user_outlined,
                  _isConfirmVisible,
                  () => setState(() => _isConfirmVisible = !_isConfirmVisible),
                ),
                validator: (value) {
                  final error = SecurityPin.validate(value);
                  if (error != null) return error;
                  return value != _newController.text
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
