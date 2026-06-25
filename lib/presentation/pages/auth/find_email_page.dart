import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
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
        title: Text(AppLocalizations.of(context)!.authFindEmail),
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
                content: Text(state.message ?? AppLocalizations.of(context)!.authAccountNotFound),
                backgroundColor: AppColors.error,
              ),
            );
          } else if (state.status == FindEmailStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? AppLocalizations.of(context)!.authErrorOccurred),
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
                          AppLocalizations.of(context)!.authFindEmailGuide,
                          style: Theme.of(context).textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        TextFormField(
                          controller: _nicknameController,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.authNickname,
                            prefixIcon: const Icon(Icons.person_outlined),
                          ),
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return AppLocalizations.of(context)!.authNicknameRequired;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _phoneController,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.authPhoneNumber,
                            prefixIcon: const Icon(Icons.phone_outlined),
                            hintText: '010-1234-5678',
                          ),
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.done,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return AppLocalizations.of(context)!.authPhoneNumberRequired;
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
                                : Text(AppLocalizations.of(context)!.authFindEmailButton),
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
