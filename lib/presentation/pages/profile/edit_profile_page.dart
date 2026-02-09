import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../di/injection.dart';
import '../../../domain/entities/profile_history.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/profile/profile_bloc.dart';
import '../../blocs/profile/profile_event.dart';
import '../../blocs/profile/profile_state.dart';
import 'handlers/image_cropper_handler.dart';
import 'handlers/image_picker_handler.dart';
import 'handlers/profile_submit_handler.dart';
import 'profile_history_page.dart';
import 'widgets/background_image_section.dart';
import 'widgets/profile_dialogs.dart';
import 'widgets/profile_form_fields.dart';
import 'widgets/profile_image_section.dart';

class EditProfilePage extends StatefulWidget {
  final ProfileBloc? profileBloc;

  const EditProfilePage({super.key, this.profileBloc});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final TextEditingController _nicknameController;
  late final TextEditingController _statusMessageController;
  final _formKey = GlobalKey<FormState>();

  // Handlers
  late final ImagePickerHandler _imagePickerHandler;
  late final ImageCropperHandler _imageCropperHandler;

  // State
  bool _isLoading = false;
  File? _selectedImage;
  File? _selectedBackgroundImage;
  bool _hasChanges = false;

  // Original values for change detection
  String _originalNickname = '';
  String _originalStatusMessage = '';

  // ProfileBloc for avatar upload with history
  late final ProfileBloc _profileBloc;

  @override
  void initState() {
    super.initState();
    _imagePickerHandler = ImagePickerHandler();
    _imageCropperHandler = ImageCropperHandler();

    final user = context.read<AuthBloc>().state.user;
    _originalNickname = user?.nickname ?? '';
    _originalStatusMessage = user?.statusMessage ?? '';
    _nicknameController = TextEditingController(text: _originalNickname);
    _statusMessageController = TextEditingController(text: _originalStatusMessage);

    _nicknameController.addListener(_checkForChanges);
    _statusMessageController.addListener(_checkForChanges);

    _profileBloc = widget.profileBloc ?? getIt<ProfileBloc>();
  }

  void _checkForChanges() {
    final hasChanges = ProfileSubmitHandler.hasChanges(
      currentNickname: _nicknameController.text,
      currentStatusMessage: _statusMessageController.text,
      originalNickname: _originalNickname,
      originalStatusMessage: _originalStatusMessage,
    );
    setState(() => _hasChanges = hasChanges);
  }

  @override
  void dispose() {
    _nicknameController.removeListener(_checkForChanges);
    _statusMessageController.removeListener(_checkForChanges);
    _nicknameController.dispose();
    _statusMessageController.dispose();
    if (widget.profileBloc == null) _profileBloc.close();
    super.dispose();
  }

  void _saveProfile() {
    if (!_formKey.currentState!.validate()) return;

    final nickname = _nicknameController.text.trim();
    final statusMessage = _statusMessageController.text.trim();
    context.read<AuthBloc>().add(AuthProfileUpdateRequested(
      nickname: nickname,
      statusMessage: statusMessage.isEmpty ? null : statusMessage,
    ));
  }

  // Avatar image picking methods
  Future<void> _pickImage() async {
    if (_imagePickerHandler.isDesktop) {
      await _showDesktopAvatarPicker();
      return;
    }

    final user = context.read<AuthBloc>().state.user;
    final hasAvatar = user?.avatarUrl != null;

    if (!mounted) return;
    await ProfileDialogs.showAvatarSourcePicker(
      context,
      hasAvatar: hasAvatar,
      onCamera: _pickFromCamera,
      onGallery: _pickFromGallery,
      onHistory: _navigateToProfileHistory,
      onDelete: _showDeleteAvatarConfirmDialog,
    );
  }

  Future<void> _showDesktopAvatarPicker() async {
    if (!mounted) return;
    await ProfileDialogs.showDesktopFilePicker(
      context,
      onFilePick: _pickFromFile,
    );
  }

  Future<void> _pickFromFile() async {
    try {
      final imageFile = await _imagePickerHandler.pickFromFile();
      if (imageFile != null && mounted) {
        _uploadImage(imageFile);
      }
    } catch (e) {
      if (mounted) {
        ProfileSubmitHandler.showSnackbar(
          context,
          '파일을 선택할 수 없습니다: $e',
        );
      }
    }
  }

  Future<void> _pickFromCamera() async {
    try {
      final imageFile = await _imagePickerHandler.pickFromCamera();
      if (imageFile == null || !mounted) return;
      await _pickImageForAvatar(imageFile.path);
    } catch (e) {
      if (mounted) {
        ProfileSubmitHandler.showSnackbar(context, '카메라를 사용할 수 없습니다');
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final imageFile = await _imagePickerHandler.pickFromGallery();
      if (imageFile == null || !mounted) return;
      await _pickImageForAvatar(imageFile.path);
    } catch (e) {
      if (mounted) {
        ProfileSubmitHandler.showSnackbar(context, '앨범에 접근할 수 없습니다');
      }
    }
  }

  Future<void> _pickImageForAvatar(String sourcePath) async {
    if (!mounted) return;

    if (!_imagePickerHandler.isImageCropperSupported) {
      _uploadImage(File(sourcePath));
      return;
    }

    final sourceFile = File(sourcePath);
    if (!sourceFile.existsSync()) {
      if (mounted) {
        ProfileSubmitHandler.showSnackbar(
          context,
          '선택한 이미지 파일을 찾을 수 없습니다.',
        );
      }
      return;
    }

    try {
      final cropped = await _imageCropperHandler.cropImageForAvatar(sourcePath);
      final pathToUse = _imageCropperHandler.resolveUploadPath(
        pickedPath: sourcePath,
        croppedPath: cropped?.path,
        cropSupported: _imagePickerHandler.isImageCropperSupported,
      );
      if (pathToUse != null && mounted) _uploadImage(File(pathToUse));
    } catch (e) {
      if (mounted) {
        ProfileSubmitHandler.showSnackbar(
          context,
          '이미지 편집을 사용할 수 없습니다: $e',
        );
        _uploadImage(File(sourcePath));
      }
    }
  }

  void _uploadImage(File imageFile) {
    final userId = context.read<AuthBloc>().state.user?.id;
    if (userId == null) return;

    setState(() => _selectedImage = imageFile);

    _profileBloc.add(ProfileHistoryCreateRequested(
      userId: userId,
      type: ProfileHistoryType.avatar,
      imageFile: imageFile,
      setCurrent: true,
    ));
  }

  void _showDeleteAvatarConfirmDialog() async {
    final confirmed = await ProfileDialogs.showDeleteAvatarConfirmation(context);
    if (confirmed == true && mounted) {
      _deleteCurrentAvatar();
    }
  }

  void _deleteCurrentAvatar() {
    final userId = context.read<AuthBloc>().state.user?.id;
    if (userId == null) return;

    context.read<AuthBloc>().add(const AuthUserLocalUpdated(clearAvatar: true));

    ProfileSubmitHandler.showSuccessSnackbar(
      context,
      '프로필 사진이 삭제되었습니다',
    );
  }

  void _navigateToProfileHistory() {
    final userId = context.read<AuthBloc>().state.user?.id;
    if (userId == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: _profileBloc,
          child: ProfileHistoryPage(
            userId: userId,
            type: ProfileHistoryType.avatar,
            isMyProfile: true,
          ),
        ),
      ),
    );
  }

  // Background image picking methods
  Future<void> _pickBackgroundImage() async {
    if (_imagePickerHandler.isDesktop) {
      await _showDesktopBackgroundPicker();
      return;
    }

    if (!mounted) return;
    await ProfileDialogs.showBackgroundSourcePicker(
      context,
      onGallery: _pickBackgroundFromGallery,
      onHistory: _navigateToBackgroundHistory,
    );
  }

  Future<void> _showDesktopBackgroundPicker() async {
    if (!mounted) return;
    await ProfileDialogs.showDesktopBackgroundFilePicker(
      context,
      onFilePick: _pickBackgroundFromFile,
    );
  }

  Future<void> _pickBackgroundFromFile() async {
    try {
      final imageFile = await _imagePickerHandler.pickBackgroundFromFile();
      if (imageFile != null && mounted) _uploadBackgroundImage(imageFile);
    } catch (e) {
      if (mounted) {
        ProfileSubmitHandler.showSnackbar(
          context,
          '파일을 선택할 수 없습니다: $e',
        );
      }
    }
  }

  Future<void> _pickBackgroundFromGallery() async {
    try {
      final imageFile = await _imagePickerHandler.pickBackgroundFromGallery();
      if (imageFile == null || !mounted) return;
      await _pickBackgroundImageForUpload(imageFile.path);
    } catch (e) {
      if (mounted) {
        ProfileSubmitHandler.showSnackbar(context, '앨범에 접근할 수 없습니다');
      }
    }
  }

  Future<void> _pickBackgroundImageForUpload(String sourcePath) async {
    if (!mounted) return;

    if (!_imagePickerHandler.isImageCropperSupported) {
      _uploadBackgroundImage(File(sourcePath));
      return;
    }

    final sourceFile = File(sourcePath);
    if (!sourceFile.existsSync()) {
      if (mounted) {
        ProfileSubmitHandler.showSnackbar(
          context,
          '선택한 이미지 파일을 찾을 수 없습니다.',
        );
      }
      return;
    }

    try {
      final cropped = await _imageCropperHandler.cropImageForBackground(sourcePath);
      final pathToUse = _imageCropperHandler.resolveUploadPath(
        pickedPath: sourcePath,
        croppedPath: cropped?.path,
        cropSupported: _imagePickerHandler.isImageCropperSupported,
      );
      if (pathToUse != null && mounted) _uploadBackgroundImage(File(pathToUse));
    } catch (e) {
      if (mounted) {
        ProfileSubmitHandler.showSnackbar(
          context,
          '이미지 편집을 사용할 수 없습니다: $e',
        );
        _uploadBackgroundImage(File(sourcePath));
      }
    }
  }

  void _uploadBackgroundImage(File imageFile) {
    final userId = context.read<AuthBloc>().state.user?.id;
    if (userId == null) return;

    setState(() => _selectedBackgroundImage = imageFile);

    _profileBloc.add(ProfileHistoryCreateRequested(
      userId: userId,
      type: ProfileHistoryType.background,
      imageFile: imageFile,
      setCurrent: true,
    ));
  }

  void _navigateToBackgroundHistory() {
    final userId = context.read<AuthBloc>().state.user?.id;
    if (userId == null) return;
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: _profileBloc,
          child: ProfileHistoryPage(
            userId: userId,
            type: ProfileHistoryType.background,
            isMyProfile: true,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // AuthBloc listener
        BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state.status == AuthStatus.loading) {
              setState(() => _isLoading = true);
            } else if (state.status == AuthStatus.authenticated) {
              setState(() {
                _isLoading = false;
                _selectedImage = null;
                _originalNickname = state.user?.nickname ?? '';
                _originalStatusMessage = state.user?.statusMessage ?? '';
                _hasChanges = false;
              });
              ProfileSubmitHandler.showSuccessSnackbar(
                context,
                '프로필이 수정되었습니다',
              );
            } else if (state.status == AuthStatus.failure) {
              setState(() {
                _isLoading = false;
                _selectedImage = null;
              });
              ProfileSubmitHandler.showErrorSnackbar(
                context,
                state.errorMessage ?? '프로필 수정에 실패했습니다',
              );
            }
          },
        ),
        // ProfileBloc listener
        BlocListener<ProfileBloc, ProfileState>(
          bloc: _profileBloc,
          listener: (context, state) {
            if (state.status == ProfileStatus.creating) {
              setState(() => _isLoading = true);
            } else if (state.status == ProfileStatus.success) {
              final wasBackground = _selectedBackgroundImage != null;
              setState(() {
                _isLoading = false;
                _selectedImage = null;
                _selectedBackgroundImage = null;
              });

              final newAvatarHistory = state.histories
                  .where((h) => h.type == ProfileHistoryType.avatar && h.isCurrent)
                  .firstOrNull;
              final newBackgroundHistory = state.histories
                  .where((h) => h.type == ProfileHistoryType.background && h.isCurrent)
                  .firstOrNull;

              if (newAvatarHistory?.url != null || newBackgroundHistory?.url != null) {
                context.read<AuthBloc>().add(AuthUserLocalUpdated(
                  avatarUrl: newAvatarHistory?.url,
                  backgroundUrl: newBackgroundHistory?.url,
                ));
              }

              ProfileSubmitHandler.showSuccessSnackbar(
                context,
                wasBackground ? '배경이 변경되었습니다' : '프로필 사진이 변경되었습니다',
              );
            } else if (state.status == ProfileStatus.failure) {
              setState(() {
                _isLoading = false;
                _selectedImage = null;
                _selectedBackgroundImage = null;
              });
              ProfileSubmitHandler.showErrorSnackbar(
                context,
                state.errorMessage ?? '이미지 변경에 실패했습니다',
              );
            }
          },
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('프로필 편집'),
          centerTitle: true,
          elevation: 0,
        ),
        body: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final user = state.user;
            if (user == null) {
              return const Center(child: CircularProgressIndicator());
            }

            return Form(
              key: _formKey,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // Profile image section
                          ProfileImageSection(
                            avatarUrl: user.avatarUrl,
                            nickname: user.nickname,
                            selectedImage: _selectedImage,
                            isLoading: _isLoading,
                            onTap: _pickImage,
                          ),

                          const SizedBox(height: 16),

                          // Background image section
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: BackgroundImageSection(
                              backgroundUrl: user.backgroundUrl,
                              selectedBackgroundImage: _selectedBackgroundImage,
                              isLoading: _isLoading,
                              onChangeBackground: _pickBackgroundImage,
                              onViewHistory: _navigateToBackgroundHistory,
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Form fields section
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: ProfileFormFields(
                              nicknameController: _nicknameController,
                              statusMessageController: _statusMessageController,
                              email: user.email,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Save button
                  Container(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      12,
                      16,
                      12 + MediaQuery.of(context).padding.bottom,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: (_isLoading || !_hasChanges) ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey[300],
                          disabledForegroundColor: Colors.grey[500],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _hasChanges ? '저장하기' : '변경사항 없음',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
