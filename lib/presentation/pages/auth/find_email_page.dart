import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../blocs/auth/find_email_bloc.dart';

class FindEmailPage extends StatefulWidget {
  const FindEmailPage({super.key});

  @override
  State<FindEmailPage> createState() => _FindEmailPageState();
}

class _FindEmailPageState extends State<FindEmailPage> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _nicknameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    if (_formKey.currentState!.validate()) {
      context.read<FindEmailBloc>().add(
            FindEmailRequested(
              nickname: _nicknameController.text.trim(),
              phoneNumber: _phoneController.text.trim(),
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('아이디 찾기'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.login),
        ),
      ),
      body: BlocConsumer<FindEmailBloc, FindEmailState>(
        listener: (context, state) {
          if (state.status == FindEmailStatus.success) {
            context.go(
              '${AppRoutes.findEmailResult}?email=${Uri.encodeComponent(state.maskedEmail ?? '')}',
            );
          } else if (state.status == FindEmailStatus.notFound) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message ?? '일치하는 계정을 찾을 수 없습니다.'),
                backgroundColor: AppColors.error,
              ),
            );
          } else if (state.status == FindEmailStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? '오류가 발생했습니다'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(
                          Icons.person_search_rounded,
                          size: 64,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '가입 시 등록한 닉네임과 전화번호를\n입력해주세요.',
                          style: Theme.of(context).textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        TextFormField(
                          controller: _nicknameController,
                          decoration: const InputDecoration(
                            labelText: '닉네임',
                            prefixIcon: Icon(Icons.person_outlined),
                          ),
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return '닉네임을 입력해주세요';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: '전화번호',
                            prefixIcon: Icon(Icons.phone_outlined),
                            hintText: '010-1234-5678',
                          ),
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.done,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return '전화번호를 입력해주세요';
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) => _onSubmit(),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: state.status == FindEmailStatus.loading
                                ? null
                                : _onSubmit,
                            child: state.status == FindEmailStatus.loading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('이메일 찾기'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
