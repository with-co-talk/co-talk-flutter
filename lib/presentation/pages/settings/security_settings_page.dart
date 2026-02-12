import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/settings/biometric_settings_cubit.dart';
import '../../blocs/settings/biometric_settings_state.dart';

/// 보안 설정 페이지
class SecuritySettingsPage extends StatelessWidget {
  const SecuritySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('보안')),
      body: BlocBuilder<BiometricSettingsCubit, BiometricSettingsState>(
        builder: (context, state) {
          if (state.status == BiometricSettingsStatus.loading ||
              state.status == BiometricSettingsStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            children: [
              if (!state.isSupported)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    '이 기기는 생체 인증을 지원하지 않습니다.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              SwitchListTile(
                secondary: const Icon(Icons.fingerprint),
                title: const Text('생체 인증'),
                subtitle: Text(
                  state.isSupported
                      ? '앱 잠금 해제 시 생체 인증을 사용합니다'
                      : '이 기기에서 사용할 수 없습니다',
                ),
                value: state.isEnabled,
                onChanged: state.isSupported
                    ? (_) => context.read<BiometricSettingsCubit>().toggle()
                    : null,
              ),
              if (state.isEnabled)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '앱을 30초 이상 백그라운드에 둔 후 복귀하면 생체 인증을 요청합니다.',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ),
              if (state.status == BiometricSettingsStatus.error &&
                  state.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    state.errorMessage!,
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
