import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../di/injection.dart';
import '../../../domain/entities/profile_history.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/profile/profile_bloc.dart';
import '../../blocs/profile/profile_event.dart';
import '../../blocs/profile/profile_state.dart';
import 'profile_history_page.dart';

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
  bool _hasChanges = false;

  // 원본 값 저장 (변경 감지용)
  String _originalNickname = '';
  String _originalStatusMessage = '';

  // ProfileBloc for avatar upload with history
  late final ProfileBloc _profileBloc;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthBloc>().state.user;
    _originalNickname = user?.nickname ?? '';
    _originalStatusMessage = user?.statusMessage ?? '';
    _nicknameController = TextEditingController(text: _originalNickname);
    _statusMessageController = TextEditingController(text: _originalStatusMessage);

    // 변경 감지 리스너
    _nicknameController.addListener(_checkForChanges);
    _statusMessageController.addListener(_checkForChanges);

    // ProfileBloc 초기화 (아바타 업로드 + 이력 생성용)
    _profileBloc = getIt<ProfileBloc>();
  }

  void _checkForChanges() {
    final hasChanges = _nicknameController.text.trim() != _originalNickname ||
        _statusMessageController.text.trim() != _originalStatusMessage;
    // 항상 setState 호출하여 글자 수 카운터 업데이트
    setState(() => _hasChanges = hasChanges);
  }

  @override
  void dispose() {
    _nicknameController.removeListener(_checkForChanges);
    _statusMessageController.removeListener(_checkForChanges);
    _nicknameController.dispose();
    _statusMessageController.dispose();
    _profileBloc.close();
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

  bool get _isDesktop =>
      Platform.isMacOS || Platform.isWindows || Platform.isLinux;

  Future<void> _pickImage() async {
    if (_isDesktop) {
      await _pickFromFile();
      return;
    }

    final user = context.read<AuthBloc>().state.user;
    final hasAvatar = user?.avatarUrl != null;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '프로필 사진',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt, color: AppColors.primary),
                ),
                title: const Text('카메라로 촬영'),
                subtitle: const Text('새 사진 찍기'),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _pickFromCamera();
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library, color: AppColors.primary),
                ),
                title: const Text('앨범에서 선택'),
                subtitle: const Text('저장된 사진 선택'),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _pickFromGallery();
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.history, color: AppColors.primary),
                ),
                title: const Text('기존 프로필에서 선택'),
                subtitle: const Text('이전에 사용한 사진 선택'),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _navigateToProfileHistory();
                },
              ),
              if (hasAvatar) ...[
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete_outline, color: Colors.red),
                  ),
                  title: const Text('기본 이미지로 변경', style: TextStyle(color: Colors.red)),
                  subtitle: const Text('현재 프로필 사진 삭제'),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    _showDeleteAvatarConfirmDialog();
                  },
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteAvatarConfirmDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('프로필 사진 삭제'),
        content: const Text('프로필 사진을 삭제하고 기본 이미지로 변경하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _deleteCurrentAvatar();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  void _deleteCurrentAvatar() {
    final userId = context.read<AuthBloc>().state.user?.id;
    if (userId == null) return;

    // AuthBloc에 아바타 URL을 null로 업데이트 (clearAvatar: true 사용)
    context.read<AuthBloc>().add(const AuthUserLocalUpdated(clearAvatar: true));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('프로필 사진이 삭제되었습니다'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: Colors.green,
      ),
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

  Future<void> _pickFromFile() async {
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
          SnackBar(
            content: const Text('파일을 선택할 수 없습니다'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
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
          SnackBar(
            content: const Text('카메라를 사용할 수 없습니다'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
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
          SnackBar(
            content: const Text('앨범에 접근할 수 없습니다'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  void _uploadImage(File imageFile) {
    final userId = context.read<AuthBloc>().state.user?.id;
    if (userId == null) return;

    setState(() => _selectedImage = imageFile);

    // ProfileHistory를 통해 아바타 업로드 (이력도 함께 생성)
    _profileBloc.add(ProfileHistoryCreateRequested(
      userId: userId,
      type: ProfileHistoryType.avatar,
      imageFile: imageFile,
      setCurrent: true,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // AuthBloc 리스너 (닉네임/상태메시지 변경)
        BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state.status == AuthStatus.loading) {
              setState(() => _isLoading = true);
            } else if (state.status == AuthStatus.authenticated) {
              setState(() {
                _isLoading = false;
                _selectedImage = null;
                // 원본 값 업데이트
                _originalNickname = state.user?.nickname ?? '';
                _originalStatusMessage = state.user?.statusMessage ?? '';
                _hasChanges = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 8),
                      Text('프로필이 수정되었습니다'),
                    ],
                  ),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  backgroundColor: Colors.green,
                ),
              );
            } else if (state.status == AuthStatus.failure) {
              setState(() {
                _isLoading = false;
                _selectedImage = null;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.white),
                      const SizedBox(width: 8),
                      Expanded(child: Text(state.errorMessage ?? '프로필 수정에 실패했습니다')),
                    ],
                  ),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
        // ProfileBloc 리스너 (아바타 업로드)
        BlocListener<ProfileBloc, ProfileState>(
          bloc: _profileBloc,
          listener: (context, state) {
            if (state.status == ProfileStatus.creating) {
              setState(() => _isLoading = true);
            } else if (state.status == ProfileStatus.success) {
              setState(() {
                _isLoading = false;
                _selectedImage = null;
              });
              // 새로 생성된 avatar history에서 URL 가져오기
              final newAvatarHistory = state.histories
                  .where((h) => h.type == ProfileHistoryType.avatar && h.isCurrent)
                  .firstOrNull;
              if (newAvatarHistory?.url != null) {
                context.read<AuthBloc>().add(AuthUserLocalUpdated(
                  avatarUrl: newAvatarHistory!.url,
                ));
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 8),
                      Text('프로필 사진이 변경되었습니다'),
                    ],
                  ),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  backgroundColor: Colors.green,
                ),
              );
            } else if (state.status == ProfileStatus.failure) {
              setState(() {
                _isLoading = false;
                _selectedImage = null;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.white),
                      const SizedBox(width: 8),
                      Expanded(child: Text(state.errorMessage ?? '사진 변경에 실패했습니다')),
                    ],
                  ),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  backgroundColor: Colors.red,
                ),
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
                          // 프로필 사진 섹션
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.05),
                            ),
                            child: Column(
                              children: [
                                // 프로필 이미지
                                GestureDetector(
                                  onTap: _isLoading ? null : _pickImage,
                                  child: Stack(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 4,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.1),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: CircleAvatar(
                                          radius: 56,
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
                                                    fontSize: 36,
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                )
                                              : null,
                                        ),
                                      ),
                                      // 로딩 오버레이
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
                                                strokeWidth: 3,
                                              ),
                                            ),
                                          ),
                                        ),
                                      // 편집 아이콘
                                      Positioned(
                                        right: 0,
                                        bottom: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: _isLoading ? Colors.grey : AppColors.primary,
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white, width: 3),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.2),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.camera_alt,
                                            size: 18,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // 사진 변경 버튼
                                TextButton.icon(
                                  onPressed: _isLoading ? null : _pickImage,
                                  icon: const Icon(Icons.edit, size: 16),
                                  label: const Text('사진 변경'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // 정보 입력 섹션
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 닉네임 카드
                                _buildEditCard(
                                  icon: Icons.person,
                                  label: '닉네임',
                                  child: TextFormField(
                                    controller: _nicknameController,
                                    decoration: InputDecoration(
                                      hintText: '닉네임을 입력하세요',
                                      hintStyle: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 15,
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                      isDense: true,
                                      errorStyle: const TextStyle(
                                        fontSize: 11,
                                        height: 0.8,
                                      ),
                                    ),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      height: 1.4,
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
                                ),

                                const SizedBox(height: 12),

                                // 상태메시지 카드
                                _buildEditCard(
                                  icon: Icons.chat_bubble_outline,
                                  label: '상태메시지',
                                  child: TextFormField(
                                    controller: _statusMessageController,
                                    decoration: InputDecoration(
                                      hintText: '상태메시지를 입력하세요 (선택)',
                                      hintStyle: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 15,
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                      isDense: true,
                                      counterText: '',
                                    ),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      height: 1.4,
                                    ),
                                    maxLength: 60,
                                    maxLines: 2,
                                    minLines: 1,
                                  ),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _statusMessageController.text.length > 50
                                          ? Colors.orange.withValues(alpha: 0.1)
                                          : Colors.grey[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${_statusMessageController.text.length}/60',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: _statusMessageController.text.length > 50
                                            ? Colors.orange[700]
                                            : Colors.grey[500],
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // 계정 정보 섹션
                                Text(
                                  '계정 정보',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // 이메일 (읽기 전용)
                                _buildInfoCard(
                                  icon: Icons.email,
                                  label: '이메일',
                                  value: user.email,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 저장 버튼
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

  /// 편집 가능한 카드 위젯 (개선된 디자인)
  Widget _buildEditCard({
    required IconData icon,
    required String label,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              const Spacer(),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey[200]!,
                width: 1,
              ),
            ),
            child: child,
          ),
        ],
      ),
    );
  }

  /// 읽기 전용 정보 카드 위젯 (개선된 디자인)
  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: Colors.grey[500]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline, size: 12, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  '수정불가',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
