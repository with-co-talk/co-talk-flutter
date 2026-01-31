import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final TextEditingController _nicknameController;
  late final TextEditingController _statusMessageController;
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();
  bool _isLoading = false;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthBloc>().state.user;
    _nicknameController = TextEditingController(text: user?.nickname ?? '');
    _statusMessageController = TextEditingController(text: user?.statusMessage ?? '');
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _statusMessageController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    if (!_formKey.currentState!.validate()) return;

    final nickname = _nicknameController.text.trim();
    context.read<AuthBloc>().add(AuthProfileUpdateRequested(nickname: nickname));
  }

  /// 플랫폼이 데스크톱(macOS, Windows, Linux)인지 확인
  bool get _isDesktop =>
      Platform.isMacOS || Platform.isWindows || Platform.isLinux;

  Future<void> _pickImage() async {
    // 데스크톱에서는 파일 선택기를 바로 열기
    if (_isDesktop) {
      await _pickFromFile();
      return;
    }

    // 모바일에서는 카메라/갤러리 선택 시트 표시
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.primary),
                title: const Text('카메라로 촬영'),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _pickFromCamera();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.primary),
                title: const Text('갤러리에서 선택'),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _pickFromGallery();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  /// 데스크톱에서 파일 선택기로 이미지 선택
  Future<void> _pickFromFile() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery, // 데스크톱에서는 파일 선택기로 동작
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        _uploadImage(File(pickedFile.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('파일을 선택할 수 없습니다')),
        );
      }
    }
  }

  Future<void> _pickFromCamera() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        _uploadImage(File(pickedFile.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('카메라를 사용할 수 없습니다')),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        _uploadImage(File(pickedFile.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('갤러리에 접근할 수 없습니다')),
        );
      }
    }
  }

  void _uploadImage(File imageFile) {
    setState(() => _selectedImage = imageFile);
    context.read<AuthBloc>().add(AuthAvatarUploadRequested(imageFile: imageFile));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.loading) {
          setState(() => _isLoading = true);
        } else if (state.status == AuthStatus.authenticated) {
          setState(() {
            _isLoading = false;
            _selectedImage = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('프로필이 수정되었습니다')),
          );
        } else if (state.status == AuthStatus.failure) {
          setState(() {
            _isLoading = false;
            _selectedImage = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? '프로필 수정에 실패했습니다'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('프로필 편집'),
          actions: [
            TextButton(
              onPressed: _isLoading ? null : _saveProfile,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('저장'),
            ),
          ],
        ),
        body: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final user = state.user;
            if (user == null) {
              return const Center(child: CircularProgressIndicator());
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // 아바타
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: AppColors.primaryLight,
                            backgroundImage: _selectedImage != null
                                ? FileImage(_selectedImage!)
                                : user.avatarUrl != null
                                    ? NetworkImage(user.avatarUrl!) as ImageProvider
                                    : null,
                            child: (_selectedImage == null && user.avatarUrl == null)
                                ? Text(
                                    user.nickname.isNotEmpty
                                        ? user.nickname[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      fontSize: 40,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                          if (_isLoading)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: GestureDetector(
                              onTap: _isLoading ? null : _pickImage,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _isLoading ? Colors.grey : AppColors.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  size: 20,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // 닉네임 입력
                    TextFormField(
                      controller: _nicknameController,
                      decoration: const InputDecoration(
                        labelText: '닉네임',
                        hintText: '닉네임을 입력하세요',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '닉네임을 입력해주세요';
                        }
                        if (value.trim().length < 2) {
                          return '닉네임은 2자 이상이어야 합니다';
                        }
                        if (value.trim().length > 20) {
                          return '닉네임은 20자 이하여야 합니다';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // 상태메시지 입력
                    TextFormField(
                      controller: _statusMessageController,
                      decoration: const InputDecoration(
                        labelText: '상태메시지',
                        hintText: '상태메시지를 입력하세요 (최대 60자)',
                        prefixIcon: Icon(Icons.chat_bubble_outline),
                        border: OutlineInputBorder(),
                      ),
                      maxLength: 60,
                      validator: (value) {
                        if (value != null && value.length > 60) {
                          return '상태메시지는 60자 이하여야 합니다';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // 이메일 (읽기 전용)
                    TextFormField(
                      initialValue: user.email,
                      decoration: const InputDecoration(
                        labelText: '이메일',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                      ),
                      enabled: false,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
