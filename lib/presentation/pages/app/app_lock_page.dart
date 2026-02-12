import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/app/app_lock_cubit.dart';
import '../../blocs/app/app_lock_state.dart';

/// 앱 잠금 화면
///
/// 생체 인증이 필요할 때 표시되는 오버레이 화면입니다.
class AppLockPage extends StatelessWidget {
  const AppLockPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppLockCubit, AppLockState>(
      builder: (context, state) {
        if (state.status == AppLockStatus.unlocked) {
          return const SizedBox.shrink();
        }

        return Material(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Co-Talk',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '잠금을 해제하려면 인증해주세요',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                  const SizedBox(height: 32),
                  if (state.status == AppLockStatus.authenticating)
                    const CircularProgressIndicator()
                  else
                    ElevatedButton.icon(
                      onPressed: () {
                        context.read<AppLockCubit>().authenticate();
                      },
                      icon: const Icon(Icons.fingerprint),
                      label: const Text('인증하기'),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
