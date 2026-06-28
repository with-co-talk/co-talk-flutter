import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/app_haptics.dart';
import '../../../l10n/app_localizations.dart';
import '../../blocs/settings/biometric_settings_cubit.dart';
import '../../blocs/settings/biometric_settings_state.dart';

/// 보안 설정 페이지
class SecuritySettingsPage extends StatelessWidget {
  const SecuritySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.settingsSecurity)),
      body: BlocBuilder<BiometricSettingsCubit, BiometricSettingsState>(
        builder: (context, state) {
          if (state.status == BiometricSettingsStatus.loading ||
              state.status == BiometricSettingsStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            children: [
              if (!state.isSupported)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    AppLocalizations.of(context)!.settingsBiometricNotSupported,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              SwitchListTile(
                secondary: const Icon(Icons.fingerprint),
                title: Text(AppLocalizations.of(context)!.settingsBiometric),
                subtitle: Text(
                  state.isSupported
                      ? AppLocalizations.of(context)!.settingsBiometricEnabledDesc
                      : AppLocalizations.of(context)!.settingsBiometricUnavailable,
                ),
                value: state.isEnabled,
                onChanged: state.isSupported
                    ? (_) {
                        AppHaptics.selection();
                        context.read<BiometricSettingsCubit>().toggle();
                      }
                    : null,
              ),
              if (state.isEnabled)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    AppLocalizations.of(context)!.settingsBiometricBackgroundNotice,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ),
              if (state.status == BiometricSettingsStatus.error)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    AppLocalizations.of(context)!.settingsBiometricLoadFailed,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
