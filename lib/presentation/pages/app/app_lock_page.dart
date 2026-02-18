import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/app/app_lock_cubit.dart';
import '../../blocs/app/app_lock_state.dart';

/// 앱 잠금 화면
///
/// 생체 인증이 필요할 때 표시되는 오버레이 화면입니다.
/// Scaffold + resizeToAvoidBottomInset: false로 키보드에 영향받지 않습니다.
class AppLockPage extends StatefulWidget {
  const AppLockPage({super.key});

  @override
  State<AppLockPage> createState() => _AppLockPageState();
}

class _AppLockPageState extends State<AppLockPage> {
  Timer? _unfocusTimer;

  /// 현재 잠금 세션에서 자동 인증을 이미 시도했는지 여부
  bool _autoAuthTriggered = false;

  @override
  void initState() {
    super.initState();
    // 잠금 화면 진입 시 키보드를 반복적으로 해제
    // ChatRoomPage의 Timer 기반 requestFocus (100ms/300ms)보다 늦게까지 해제를 시도
    _dismissKeyboardRepeatedly();
    // 이미 locked 상태로 시작하면 자동 생체 인증 시도
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryAutoAuthenticate();
    });
  }

  @override
  void dispose() {
    _unfocusTimer?.cancel();
    super.dispose();
  }

  /// 키보드를 여러 번 반복 해제하여 Timer 기반 requestFocus를 이김
  void _dismissKeyboardRepeatedly() {
    _dismissKeyboard();
    int attempts = 0;
    _unfocusTimer?.cancel();
    _unfocusTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      attempts++;
      _dismissKeyboard();
      // 500ms 동안 5회 시도 후 중단
      if (attempts >= 5) {
        timer.cancel();
      }
    });
  }

  /// 키보드 강제 해제
  void _dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
    SystemChannels.textInput.invokeMethod('TextInput.hide');
  }

  /// 잠금 상태일 때 자동으로 생체 인증 시도
  ///
  /// 한 잠금 세션당 한 번만 자동 시도하며, 실패 시 수동 버튼으로 재시도합니다.
  void _tryAutoAuthenticate() {
    if (_autoAuthTriggered || !mounted) return;
    final cubit = context.read<AppLockCubit>();
    if (cubit.state.status == AppLockStatus.locked) {
      _autoAuthTriggered = true;
      cubit.authenticate();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AppLockCubit, AppLockState>(
      listenWhen: (previous, current) =>
          previous.status != current.status,
      listener: (context, state) {
        if (state.status == AppLockStatus.locked) {
          // 잠금 상태로 전환될 때마다 키보드 반복 해제
          _dismissKeyboardRepeatedly();
          // 새로운 잠금 세션이면 자동 인증 시도
          _tryAutoAuthenticate();
        } else if (state.status == AppLockStatus.unlocked) {
          // 잠금 해제되면 다음 잠금 시 자동 인증 재시도 가능하도록 초기화
          _autoAuthTriggered = false;
        }
      },
      child: BlocBuilder<AppLockCubit, AppLockState>(
        builder: (context, state) {
          if (state.status == AppLockStatus.unlocked) {
            return const SizedBox.shrink();
          }

          // Scaffold로 감싸서 키보드가 레이아웃에 영향 주지 않도록 함
          return Scaffold(
            resizeToAvoidBottomInset: false,
            body: SafeArea(
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
      ),
    );
  }
}
