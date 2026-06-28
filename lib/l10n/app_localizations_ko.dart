// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'Co-Talk';

  @override
  String get authSignUp => '회원가입';

  @override
  String get authSignUpFailed => '회원가입에 실패했습니다';

  @override
  String get authLogin => '로그인';

  @override
  String get authLoginFailed => '로그인에 실패했습니다';

  @override
  String get authEmail => '이메일';

  @override
  String get authNickname => '닉네임';

  @override
  String get authPassword => '비밀번호';

  @override
  String get authConfirmPassword => '비밀번호 확인';

  @override
  String get authKoreanInputWarning => '한글이 입력되어 있습니다. 영문 키보드를 확인하세요.';

  @override
  String get authNoAccountSignUp => '계정이 없으신가요? 회원가입';

  @override
  String get authForgotEmail => '아이디를 잊으셨나요?';

  @override
  String get authForgotPassword => '비밀번호를 잊으셨나요?';

  @override
  String get authEmailVerification => '이메일 인증';

  @override
  String get authErrorOccurred => '오류가 발생했습니다';

  @override
  String get authVerificationEmailResent => '인증 이메일이 재발송되었습니다. 이메일을 확인해주세요.';

  @override
  String get authEmailVerificationRequired => '이메일 인증이 필요합니다';

  @override
  String authVerificationEmailSentTo(Object email) {
    return '$email 으로\n인증 이메일이 발송되었습니다.';
  }

  @override
  String get authVerificationLinkGuide => '이메일의 인증 링크를 클릭하여\n인증을 완료해주세요.';

  @override
  String get authResendVerificationEmail => '인증 이메일 재발송';

  @override
  String get authBackToLogin => '로그인으로 돌아가기';

  @override
  String get authFindEmailResult => '아이디 찾기 결과';

  @override
  String get authEmailFound => '가입된 이메일을 찾았습니다';

  @override
  String get authGoToLogin => '로그인하기';

  @override
  String get authForgotPasswordTitle => '비밀번호 찾기';

  @override
  String get authFindEmail => '아이디 찾기';

  @override
  String get authAccountNotFound => '일치하는 계정을 찾을 수 없습니다.';

  @override
  String get authFindEmailGuide => '가입 시 등록한 닉네임과 전화번호를\n입력해주세요.';

  @override
  String get authNicknameRequired => '닉네임을 입력해주세요';

  @override
  String get authPhoneNumber => '전화번호';

  @override
  String get authPhoneNumberRequired => '전화번호를 입력해주세요';

  @override
  String get authFindEmailButton => '이메일 찾기';

  @override
  String get authPasswordChanged => '비밀번호가 성공적으로 변경되었습니다';

  @override
  String get authForgotPasswordEmailGuide =>
      '가입한 이메일 주소를 입력해주세요.\n인증 코드를 발송해드립니다.';

  @override
  String get authRequestCode => '인증 코드 받기';

  @override
  String authCodeSentTo(Object email) {
    return '$email으로\n인증 코드를 발송했습니다.';
  }

  @override
  String get authVerificationCode => '인증 코드 (6자리)';

  @override
  String get authCodeRequired => '인증 코드를 입력해주세요';

  @override
  String get authCodeLengthInvalid => '6자리 코드를 입력해주세요';

  @override
  String get authVerifyCode => '인증 코드 확인';

  @override
  String get authResendCode => '인증 코드 재발송';

  @override
  String get authNewPasswordGuide => '새로운 비밀번호를 입력해주세요.';

  @override
  String get authNewPassword => '새 비밀번호';

  @override
  String get authConfirmNewPassword => '새 비밀번호 확인';

  @override
  String get authChangePassword => '비밀번호 변경';

  @override
  String get chatTitle => '채팅';

  @override
  String get chatSelfChatTitle => '나와의 채팅';

  @override
  String chatTypingSingle(String nickname) {
    return '$nickname님이 입력 중...';
  }

  @override
  String chatTypingMultiple(int count) {
    return '$count명이 입력 중...';
  }

  @override
  String get chatSearchHint => '채팅방 검색';

  @override
  String get chatListLoadFailed => '채팅방을 불러오는데 실패했습니다';

  @override
  String get chatListEmpty => '채팅방이 없습니다\n친구를 추가하고 대화를 시작해보세요';

  @override
  String chatSearchNoResults(Object query) {
    return '\"$query\" 검색 결과가 없습니다';
  }

  @override
  String get chatSelfName => '나';

  @override
  String get chatDirectTitle => '1:1 채팅';

  @override
  String chatRoomLoadFailed(Object error) {
    return '채팅방을 불러올 수 없습니다: $error';
  }

  @override
  String get chatRoomPreparing => '채팅방을 준비 중...';

  @override
  String get chatUnknownError => '알 수 없는 오류가 발생했습니다';

  @override
  String get chatRoomImageUpdated => '채팅방 이미지가 변경되었습니다.';

  @override
  String get chatRoomImageUpdateFailed => '이미지 변경에 실패했습니다.';

  @override
  String get chatRoomChangeImage => '채팅방 이미지 변경';

  @override
  String get chatMediaGallery => '미디어 모아보기';

  @override
  String get chatRoomLeave => '채팅방 나가기';

  @override
  String get chatRoomLeaveConfirm => '채팅방을 나가시겠습니까?\n대화 내용은 삭제됩니다.';

  @override
  String get chatRoomLeaveAction => '나가기';

  @override
  String chatReinviteSuccess(Object nickname) {
    return '$nickname님을 다시 초대했습니다';
  }

  @override
  String chatReinviteFailed(Object error) {
    return '재초대 실패: $error';
  }

  @override
  String get chatMessageForwarded => '메시지가 전달되었습니다';

  @override
  String get chatOtherUser => '상대방';

  @override
  String get chatMediaTabPhotos => '사진';

  @override
  String get chatMediaTabFiles => '파일';

  @override
  String get chatMediaTabLinks => '링크';

  @override
  String get chatMediaLoadFailed => '미디어를 불러올 수 없습니다';

  @override
  String get chatMediaEmptyPhotos => '사진이 없습니다';

  @override
  String get chatMediaEmptyFiles => '파일이 없습니다';

  @override
  String get chatMediaEmptyLinks => '링크가 없습니다';

  @override
  String get chatFileFallback => '파일';

  @override
  String get chatLinkFallback => '링크';

  @override
  String get chatDeletedMessage => '삭제된 메시지';

  @override
  String get chatDeletedMessageBubble => '삭제된 메시지입니다';

  @override
  String get chatOriginalMessageNotFound => '원본 메시지를 찾을 수 없습니다';

  @override
  String get chatUnknownSender => '알 수 없음';

  @override
  String get chatForwarded => '전달됨';

  @override
  String get chatResend => '재전송';

  @override
  String chatCannotOpenUrl(Object url) {
    return 'URL을 열 수 없습니다: $url';
  }

  @override
  String get chatViewFullScreen => '전체 화면 보기';

  @override
  String get chatSaveToGallery => '갤러리에 저장';

  @override
  String get chatImageSavedToGallery => '사진이 갤러리에 저장되었습니다';

  @override
  String chatSaveFailed(Object error) {
    return '저장 실패: $error';
  }

  @override
  String get chatDownload => '다운로드';

  @override
  String chatCannotOpenFile(Object file) {
    return '파일을 열 수 없습니다: $file';
  }

  @override
  String chatDownloadFailed(Object error) {
    return '다운로드 실패: $error';
  }

  @override
  String get chatEditMessageTitle => '메시지 수정';

  @override
  String get chatMessageInputHint => '메시지를 입력하세요';

  @override
  String get chatDeleteMessageTitle => '메시지 삭제';

  @override
  String get chatDeleteMessageConfirm => '이 메시지를 삭제하시겠습니까?';

  @override
  String get chatReply => '답장';

  @override
  String get chatForward => '전달';

  @override
  String get chatReport => '신고';

  @override
  String get chatVideo => '동영상';

  @override
  String get chatTapToViewImage => '탭하여 이미지 보기';

  @override
  String get chatImageLoadFailed => '이미지를 불러올 수 없습니다';

  @override
  String get chatSelectRoom => '채팅방 선택';

  @override
  String get chatRoomListEmpty => '채팅방이 없습니다';

  @override
  String chatImagePasteFailed(Object error) {
    return '이미지 붙여넣기 실패: $error';
  }

  @override
  String get chatPickFromGallery => '갤러리에서 선택';

  @override
  String get chatPickFromGallerySubtitle => '사진 또는 동영상을 선택합니다';

  @override
  String get chatCamera => '카메라';

  @override
  String get chatCameraSubtitle => '사진을 촬영합니다';

  @override
  String get chatFile => '파일';

  @override
  String get chatFileSubtitle => '문서, PDF 등의 파일을 선택합니다';

  @override
  String get chatImagePathUnavailable => '이미지 경로를 사용할 수 없습니다. 파일 선택을 이용해 주세요.';

  @override
  String get chatImageFileNotFound => '선택한 이미지 파일을 찾을 수 없습니다.';

  @override
  String get chatImageUnavailable => '이미지를 사용할 수 없습니다. 파일 선택을 이용해 주세요.';

  @override
  String chatImagePickFailed(Object error) {
    return '이미지를 선택할 수 없습니다: $error';
  }

  @override
  String get chatCameraImageUnavailable =>
      '촬영한 이미지를 사용할 수 없습니다. 파일 선택을 이용해 주세요.';

  @override
  String chatCameraFailed(Object error) {
    return '카메라를 사용할 수 없습니다: $error';
  }

  @override
  String chatFilePickFailed(Object error) {
    return '파일을 선택할 수 없습니다: $error';
  }

  @override
  String get chatFileUploading => '파일 업로드 중...';

  @override
  String chatOtherUserLeft(Object nickname) {
    return '$nickname님이 채팅방을 나갔습니다';
  }

  @override
  String get chatOtherUserInfoNotFound => '상대방 정보를 찾을 수 없습니다';

  @override
  String get chatReinviting => '초대 중...';

  @override
  String get chatReinvite => '다시 초대하기';

  @override
  String get chatKeyboard => '키보드';

  @override
  String get chatEmoji => '이모지';

  @override
  String get chatAttach => '첨부';

  @override
  String get chatEmojiSearch => '이모지 검색';

  @override
  String get chatNoMessages => '메시지가 없습니다';

  @override
  String get chatStartConversation => '대화를 시작해보세요';

  @override
  String get chatVideoPlaybackFailed => '비디오를 재생할 수 없습니다';

  @override
  String get commonCancel => '취소';

  @override
  String get commonDelete => '삭제';

  @override
  String get commonEdit => '수정';

  @override
  String get commonRetry => '다시 시도';

  @override
  String get friendsTitle => '친구';

  @override
  String get friendsAdd => '친구 추가';

  @override
  String get friendsAddShort => '추가';

  @override
  String get friendsManage => '친구 관리';

  @override
  String friendsCount(Object count) {
    return '친구 $count명';
  }

  @override
  String get friendsListLoadError => '친구 목록을 불러오는데 실패했습니다';

  @override
  String get friendsEmptyTitle => '친구가 없습니다';

  @override
  String get friendsEmptyDesc => '친구를 추가하고 대화를 시작해보세요';

  @override
  String get friendsHide => '숨김';

  @override
  String get friendsBlock => '차단';

  @override
  String get friendsHideTitle => '친구 숨김';

  @override
  String friendsHideConfirm(Object name) {
    return '$name님을 숨기시겠습니까?\n친구 관리에서 다시 볼 수 있습니다.';
  }

  @override
  String get friendsHideSuccess => '친구를 숨김 처리했습니다';

  @override
  String get friendsBlockTitle => '친구 차단';

  @override
  String friendsBlockConfirm(Object name) {
    return '$name님을 차단하시겠습니까?';
  }

  @override
  String get friendsBlockSuccess => '친구를 차단했습니다';

  @override
  String get friendsDeleteTitle => '친구 삭제';

  @override
  String get friendsDeleteSuccess => '친구를 삭제했습니다';

  @override
  String friendsDeleteConfirm(Object name) {
    return '$name님을 친구에서 삭제하시겠습니까?';
  }

  @override
  String get friendsSearchHint => '닉네임으로 검색';

  @override
  String get friendsSearchPrompt => '닉네임을 입력하여 검색하세요';

  @override
  String get friendsSearchError => '검색 중 오류가 발생했습니다';

  @override
  String get friendsSearchNoResults => '검색 결과가 없습니다';

  @override
  String friendsSearchNoResultsFor(Object query) {
    return '\"$query\"에 대한 결과가 없습니다';
  }

  @override
  String get friendsRequestSent => '친구 요청을 보냈습니다';

  @override
  String get friendSettingsTitle => '친구 관리';

  @override
  String get friendSettingsRequestSection => '친구 요청';

  @override
  String get friendSettingsReceivedRequests => '받은 친구 요청';

  @override
  String get friendSettingsReceivedRequestsDesc => '수락 대기 중인 요청을 확인하세요';

  @override
  String get friendSettingsSentRequests => '보낸 친구 요청';

  @override
  String get friendSettingsSentRequestsDesc => '보낸 요청을 확인하세요';

  @override
  String get friendSettingsManageSection => '친구 관리';

  @override
  String get friendSettingsHiddenFriends => '숨김 친구 관리';

  @override
  String get friendSettingsHiddenFriendsDesc => '숨긴 친구를 확인하세요';

  @override
  String get friendSettingsBlockedUsers => '차단 사용자 관리';

  @override
  String get friendSettingsBlockedUsersDesc => '차단한 사용자를 관리하세요';

  @override
  String get friendsHiddenTitle => '숨김 친구';

  @override
  String get friendsHiddenLoadError => '숨김 친구 목록을 불러오는데 실패했습니다';

  @override
  String get friendsHiddenEmptyTitle => '숨긴 친구가 없습니다';

  @override
  String get friendsHiddenEmptyDesc => '친구 목록에서 숨긴 친구가 여기에 표시됩니다';

  @override
  String get friendsUnhide => '숨김 해제';

  @override
  String friendsUnhideSuccess(Object name) {
    return '$name님을 숨김 해제했습니다';
  }

  @override
  String get friendsBlockedTitle => '차단 사용자';

  @override
  String get friendsBlockedLoadError => '차단 목록을 불러오는데 실패했습니다';

  @override
  String get friendsBlockedEmptyTitle => '차단한 사용자가 없습니다';

  @override
  String get friendsBlockedEmptyDesc => '차단한 사용자가 여기에 표시됩니다';

  @override
  String get friendsUnblock => '차단 해제';

  @override
  String friendsUnblockConfirm(Object name) {
    return '$name님의 차단을 해제하시겠습니까?';
  }

  @override
  String friendsUnblockSuccess(Object name) {
    return '$name님의 차단을 해제했습니다';
  }

  @override
  String get friendsReceivedTitle => '받은 친구 요청';

  @override
  String get friendsReceivedLoadError => '받은 친구 요청을 불러오는데 실패했습니다';

  @override
  String get friendsReceivedEmptyTitle => '받은 친구 요청이 없습니다';

  @override
  String get friendsReceivedEmptyDesc => '다른 사용자가 친구 요청을 보내면 여기에 표시됩니다';

  @override
  String get friendsReject => '거절';

  @override
  String get friendsAccept => '수락';

  @override
  String get friendsSentTitle => '보낸 친구 요청';

  @override
  String get friendsSentLoadError => '보낸 친구 요청을 불러오는데 실패했습니다';

  @override
  String get friendsSentEmptyTitle => '보낸 친구 요청이 없습니다';

  @override
  String get friendsSentEmptyDesc => '친구를 검색하여 요청을 보내보세요';

  @override
  String get friendsSentPending => '대기 중';

  @override
  String get mainTabFriends => '친구';

  @override
  String get mainTabChat => '채팅';

  @override
  String get appLockPrompt => '잠금을 해제하려면 인증해주세요';

  @override
  String get appLockAuthenticate => '인증하기';

  @override
  String get reportSubmitted => '신고가 접수되었습니다';

  @override
  String reportSubmitFailed(Object error) {
    return '신고 접수에 실패했습니다: $error';
  }

  @override
  String get reportTargetUser => '사용자';

  @override
  String get reportTargetMessage => '메시지';

  @override
  String reportTitle(Object target) {
    return '$target 신고';
  }

  @override
  String get reportSelectReason => '신고 사유를 선택해주세요';

  @override
  String get reportDescriptionLabel => '상세 설명 (선택)';

  @override
  String get reportDescriptionHint => '추가 설명을 입력해주세요';

  @override
  String get reportSubmit => '신고하기';

  @override
  String get errorTitle => '오류';

  @override
  String get errorPageLoadFailed => '페이지를 불러올 수 없습니다';

  @override
  String get errorGoHome => '홈으로 돌아가기';

  @override
  String get imageEditorProcessing => '처리 중...';

  @override
  String get imageEditorCloseWarningTitle => '편집 취소';

  @override
  String get imageEditorCloseWarningMessage => '편집 내용을 취소하시겠습니까?';

  @override
  String get imageEditorContinueEditing => '계속 편집';

  @override
  String get imageEditorPaint => '그리기';

  @override
  String get imageEditorFreestyle => '자유';

  @override
  String get imageEditorArrow => '화살표';

  @override
  String get imageEditorLine => '직선';

  @override
  String get imageEditorRectangle => '사각형';

  @override
  String get imageEditorCircle => '원';

  @override
  String get imageEditorDashLine => '점선';

  @override
  String get imageEditorLineWidth => '두께';

  @override
  String get imageEditorToggleFill => '채우기';

  @override
  String get imageEditorUndo => '실행 취소';

  @override
  String get imageEditorRedo => '다시 실행';

  @override
  String get imageEditorDone => '완료';

  @override
  String get imageEditorBack => '뒤로';

  @override
  String get imageEditorTextInputHint => '텍스트 입력';

  @override
  String get imageEditorText => '텍스트';

  @override
  String get imageEditorCrop => '자르기';

  @override
  String get imageEditorRotate => '회전';

  @override
  String get imageEditorFlip => '뒤집기';

  @override
  String get imageEditorRatio => '비율';

  @override
  String get imageEditorReset => '초기화';

  @override
  String get imageEditorFilter => '필터';

  @override
  String get imageEditorEmoji => '이모지';

  @override
  String get imageEditorSaving => '저장 중...';

  @override
  String get widgetConnectionFailed => '연결 실패 - 재시도가 중단되었습니다';

  @override
  String get widgetConnectionLost => '연결이 끊어졌습니다';

  @override
  String get widgetReconnect => '재연결';

  @override
  String widgetCannotOpenUrl(Object url) {
    return 'URL을 열 수 없습니다: $url';
  }

  @override
  String get widgetMessageSearchHint => '메시지 검색';

  @override
  String get widgetSearchError => '검색 중 오류가 발생했습니다';

  @override
  String get widgetSearchNoResults => '검색 결과가 없습니다';

  @override
  String get widgetSearchPrompt => '검색어를 입력하세요';

  @override
  String get widgetUnknownSender => '알 수 없음';

  @override
  String get profileTitle => '프로필';

  @override
  String get profileEditTitle => '프로필 편집';

  @override
  String get profileStatusLabel => '상태';

  @override
  String get profileOnlineStatusLabel => '온라인 상태';

  @override
  String get profileJoinDateLabel => '가입일';

  @override
  String get profileStatusActive => '활성';

  @override
  String get profileStatusInactive => '비활성';

  @override
  String get profileStatusSuspended => '정지됨';

  @override
  String get profileStatusUnknown => '알 수 없음';

  @override
  String get profileOnlineStatusOnline => '온라인';

  @override
  String get profileOnlineStatusAway => '자리 비움';

  @override
  String get profileOnlineStatusOffline => '오프라인';

  @override
  String profileFilePickFailed(Object error) {
    return '파일을 선택할 수 없습니다: $error';
  }

  @override
  String get profileCameraUnavailable => '카메라를 사용할 수 없습니다';

  @override
  String get profileGalleryUnavailable => '앨범에 접근할 수 없습니다';

  @override
  String get profileImageFileNotFound => '선택한 이미지 파일을 찾을 수 없습니다.';

  @override
  String profileImageEditUnavailable(Object error) {
    return '이미지 편집을 사용할 수 없습니다: $error';
  }

  @override
  String get profileAvatarDeleted => '프로필 사진이 삭제되었습니다';

  @override
  String get profileUpdated => '프로필이 수정되었습니다';

  @override
  String get profileUpdateFailed => '프로필 수정에 실패했습니다';

  @override
  String get profileUpdateSuccess => '프로필이 업데이트되었습니다.';

  @override
  String get profileSetPrivateSuccess => '나만보기로 설정되었습니다.';

  @override
  String get profileSetPublicSuccess => '공개로 설정되었습니다.';

  @override
  String get profileHistoryDeleteSuccess => '프로필 이력이 삭제되었습니다.';

  @override
  String get profileSetCurrentSuccess => '현재 프로필로 설정되었습니다.';

  @override
  String get profileBackgroundChanged => '배경이 변경되었습니다';

  @override
  String get profileAvatarChanged => '프로필 사진이 변경되었습니다';

  @override
  String get profileImageChangeFailed => '이미지 변경에 실패했습니다';

  @override
  String get profileSaveButton => '저장하기';

  @override
  String get profileNoChanges => '변경사항 없음';

  @override
  String get profileLoadFailed => '프로필을 불러올 수 없습니다';

  @override
  String get profileStatusMessage => '상태메시지';

  @override
  String get profileStatusMessageHint => '상태메시지를 입력하세요';

  @override
  String get profileBackground => '배경화면';

  @override
  String get profileAvatar => '프로필 사진';

  @override
  String get profileViewFullScreen => '전체 화면 보기';

  @override
  String get profileBackgroundChange => '배경화면 변경';

  @override
  String get profileBackgroundChangeSubtitle => '앨범에서 새 배경 선택';

  @override
  String get profileBackgroundHistory => '배경화면 이력';

  @override
  String get profileBackgroundHistorySubtitle => '이전 배경화면 보기';

  @override
  String get profileAvatarChange => '프로필 사진 변경';

  @override
  String get profileAvatarChangeSubtitle => '앨범에서 새 사진 선택';

  @override
  String get profileAvatarHistory => '프로필 사진 이력';

  @override
  String get profileAvatarHistorySubtitle => '이전 프로필 사진 보기';

  @override
  String get profileMakePublic => '전체 공개로 변경';

  @override
  String get profileMakePrivate => '나만 보기';

  @override
  String get profilePublicDescription => '다른 사람에게 공개됩니다';

  @override
  String get profilePrivateDescription => '나만 볼 수 있습니다';

  @override
  String profileDeleteItemTitle(Object item) {
    return '$item 삭제';
  }

  @override
  String profileDeleteItemConfirm(Object item) {
    return '$item을(를) 삭제하시겠습니까?';
  }

  @override
  String get profileImagePickFailed => '이미지를 선택할 수 없습니다';

  @override
  String get profileAddStatusMessage => '상태메시지 추가';

  @override
  String get profileDirectChat => '1:1 채팅';

  @override
  String get profileReport => '신고';

  @override
  String get profileSelfChat => '나와의 채팅';

  @override
  String get profileEditAction => '프로필 편집';

  @override
  String get profileLoginInfoNotFound => '로그인 정보를 찾을 수 없습니다';

  @override
  String profileHistoryEmpty(Object type) {
    return '아직 $type 이력이 없습니다';
  }

  @override
  String get profileAddAvatar => '사진 추가하기';

  @override
  String get profileAddBackground => '배경 추가하기';

  @override
  String get profileMore => '더보기';

  @override
  String get profileBadgeCurrent => '현재';

  @override
  String get profileBadgePrivate => '나만보기';

  @override
  String get profileNickname => '닉네임';

  @override
  String get profileNicknameHint => '닉네임을 입력하세요';

  @override
  String get profileStatusMessageOptionalHint => '상태메시지를 입력하세요 (선택)';

  @override
  String get profileAccountInfo => '계정 정보';

  @override
  String get profileEmail => '이메일';

  @override
  String get profileNotEditable => '수정불가';

  @override
  String get profileBackgroundChangeShort => '배경 변경';

  @override
  String get profileBackgroundHistoryShort => '배경 이력';

  @override
  String get profileChangePhoto => '사진 변경';

  @override
  String get profileSetAsCurrent => '현재 프로필로 설정';

  @override
  String get profileMakePublicShort => '공개로 변경';

  @override
  String get profileDeleteConfirmTitle => '삭제 확인';

  @override
  String get profileDeleteCurrentWarning =>
      '현재 프로필로 사용 중입니다.\n삭제하면 이전 이력으로 변경됩니다.';

  @override
  String get profileDeleteHistoryConfirm => '이 이력을 삭제하시겠습니까?';

  @override
  String get profileTakePhoto => '카메라로 촬영';

  @override
  String get profileTakePhotoSubtitle => '새 사진 찍기';

  @override
  String get profileSelectFromAlbum => '앨범에서 선택';

  @override
  String get profileSelectFromAlbumSubtitle => '저장된 사진 선택';

  @override
  String get profileSelectFromExisting => '기존 프로필에서 선택';

  @override
  String get profileSelectFromExistingSubtitle => '이전에 사용한 사진 선택';

  @override
  String get profileResetToDefault => '기본 이미지로 변경';

  @override
  String get profileResetToDefaultSubtitle => '현재 프로필 사진 삭제';

  @override
  String get profileSelectFromFile => '파일에서 선택';

  @override
  String get profileSelectFromFileSubtitle => '이미지 파일을 선택합니다';

  @override
  String get profileSelectFromBackgroundHistory => '배경 이력에서 선택';

  @override
  String get profileSelectBackgroundFileSubtitle => '배경 이미지 파일을 선택합니다';

  @override
  String get profileAvatarDeleteTitle => '프로필 사진 삭제';

  @override
  String get profileAvatarDeleteConfirm => '프로필 사진을 삭제하고 기본 이미지로 변경하시겠습니까?';

  @override
  String get profileNicknameRequired => '닉네임을 입력해주세요';

  @override
  String get profileNicknameTooShort => '닉네임은 2자 이상이어야 합니다';

  @override
  String get profileNicknameTooLong => '닉네임은 20자 이하여야 합니다';

  @override
  String get profileStatusMessageTooLong => '상태메시지는 60자 이하여야 합니다';

  @override
  String get commonSave => '저장';

  @override
  String get settingsTitle => '설정';

  @override
  String get settingsProfile => '프로필';

  @override
  String get settingsMyProfile => '내 프로필';

  @override
  String get settingsNotification => '알림';

  @override
  String get settingsNotificationSettings => '알림 설정';

  @override
  String get settingsNotificationDesc => '메시지, 친구 요청, 그룹 초대 알림';

  @override
  String get settingsChat => '채팅';

  @override
  String get settingsChatSettings => '채팅 설정';

  @override
  String get settingsChatDesc => '글꼴 크기, 미디어 자동 다운로드';

  @override
  String get settingsFriends => '친구';

  @override
  String get settingsFriendManagement => '친구 관리';

  @override
  String get settingsFriendManagementDesc => '친구 요청, 숨김, 차단 관리';

  @override
  String get settingsGeneral => '일반';

  @override
  String get settingsLanguage => '언어';

  @override
  String get settingsLanguageKorean => '한국어 (기본)';

  @override
  String get settingsDarkMode => '다크 모드';

  @override
  String get settingsSecurity => '보안';

  @override
  String get settingsBiometric => '생체 인증';

  @override
  String get settingsBiometricDesc => '앱 잠금 해제 시 생체 인증 사용';

  @override
  String get settingsAccount => '계정';

  @override
  String get settingsChangePassword => '비밀번호 변경';

  @override
  String get settingsAccountDeletion => '회원 탈퇴';

  @override
  String get settingsInfo => '정보';

  @override
  String get settingsAppVersion => '앱 버전';

  @override
  String get settingsTerms => '이용약관';

  @override
  String get settingsPrivacyPolicy => '개인정보 처리방침';

  @override
  String get settingsOpenSourceLicense => '오픈소스 라이선스';

  @override
  String get settingsLogout => '로그아웃';

  @override
  String get settingsLogoutConfirm => '정말 로그아웃하시겠습니까?';

  @override
  String get settingsErrorOccurred => '오류가 발생했습니다';

  @override
  String get settingsNotificationType => '알림 유형';

  @override
  String get settingsMessageNotification => '메시지 알림';

  @override
  String get settingsMessageNotificationDesc => '새 메시지를 받을 때 알림';

  @override
  String get settingsFriendRequestNotification => '친구 요청 알림';

  @override
  String get settingsFriendRequestNotificationDesc => '새 친구 요청을 받을 때 알림';

  @override
  String get settingsGroupInviteNotification => '그룹 초대 알림';

  @override
  String get settingsGroupInviteNotificationDesc => '그룹 채팅에 초대받을 때 알림';

  @override
  String get settingsNotificationMethod => '알림 방식';

  @override
  String get settingsSound => '소리';

  @override
  String get settingsSoundDesc => '알림 소리 재생';

  @override
  String get settingsVibration => '진동';

  @override
  String get settingsVibrationDesc => '알림 시 진동';

  @override
  String get settingsDoNotDisturb => '방해 금지';

  @override
  String get settingsDoNotDisturbMode => '방해 금지 모드';

  @override
  String get settingsDoNotDisturbDesc => '설정된 시간 동안 알림 무음';

  @override
  String get settingsStartTime => '시작 시간';

  @override
  String get settingsEndTime => '종료 시간';

  @override
  String get settingsNotificationPreview => '알림 미리보기';

  @override
  String get settingsNotificationPreviewDesc => '알림에 표시할 내용을 선택합니다';

  @override
  String get settingsPreviewNameAndMessage => '이름 + 메시지';

  @override
  String get settingsPreviewNameAndMessageDesc => '보낸 사람 이름과 메시지 내용을 표시';

  @override
  String get settingsPreviewNameOnly => '이름만';

  @override
  String get settingsPreviewNameOnlyDesc => '보낸 사람 이름만 표시';

  @override
  String get settingsPreviewNothing => '표시 안함';

  @override
  String get settingsPreviewNothingDesc => '이름과 메시지 내용 모두 숨김';

  @override
  String get settingsBiometricNotSupported => '이 기기는 생체 인증을 지원하지 않습니다.';

  @override
  String get settingsBiometricEnabledDesc => '앱 잠금 해제 시 생체 인증을 사용합니다';

  @override
  String get settingsBiometricUnavailable => '이 기기에서 사용할 수 없습니다';

  @override
  String get settingsBiometricBackgroundNotice =>
      '앱을 30초 이상 백그라운드에 둔 후 복귀하면 생체 인증을 요청합니다.';

  @override
  String get settingsBiometricLoadFailed => '생체 인증 설정을 불러오는데 실패했습니다.';

  @override
  String get settingsAccountDeletionComplete => '회원 탈퇴가 완료되었습니다';

  @override
  String get settingsAccountDeletionInvalidConfirmation => '올바른 확인 텍스트를 입력해주세요';

  @override
  String get settingsAccountDeletionEmptyPassword => '비밀번호를 입력해주세요';

  @override
  String get settingsAccountDeletionUserNotFound => '사용자 정보를 찾을 수 없습니다';

  @override
  String get settingsAccountDeletionUnknownError =>
      '회원 탈퇴 처리 중 오류가 발생했습니다. 비밀번호를 확인해주세요.';

  @override
  String get settingsAccountDeletionProcessing => '탈퇴 처리 중...';

  @override
  String get settingsWarning => '주의';

  @override
  String get settingsDeletionWarningTitle => '회원 탈퇴 시 다음 데이터가 영구적으로 삭제됩니다:';

  @override
  String get settingsDeletionItemChats => '모든 채팅 내역';

  @override
  String get settingsDeletionItemFriends => '친구 목록';

  @override
  String get settingsDeletionItemProfile => '프로필 정보';

  @override
  String get settingsDeletionItemNotifications => '알림 설정';

  @override
  String get settingsDeletionIrreversible => '이 작업은 되돌릴 수 없습니다.';

  @override
  String get settingsDeletionStep1 => '1. 비밀번호 확인';

  @override
  String get settingsCurrentPassword => '현재 비밀번호';

  @override
  String get settingsDeletionStep2 => '2. 탈퇴 확인';

  @override
  String get settingsDeletionConfirmInstruction =>
      '탈퇴를 확인하려면 아래에 \"삭제합니다\"를 입력하세요.';

  @override
  String get settingsDeletionConfirmKeyword => '삭제합니다';

  @override
  String get settingsDeletionConfirmMismatch => '\"삭제합니다\"를 정확히 입력해주세요';

  @override
  String settingsDeletionCountdown(Object count) {
    return '$count초 후 탈퇴 버튼이 활성화됩니다';
  }

  @override
  String settingsAccountDeletionButtonDisabled(Object detail) {
    return '회원 탈퇴 ($detail)';
  }

  @override
  String get settingsDeletionNeedInput => '입력 완료 필요';

  @override
  String settingsDeletionSeconds(Object count) {
    return '$count초';
  }

  @override
  String get settingsFinalConfirm => '최종 확인';

  @override
  String get settingsDeletionFinalConfirmContent =>
      '정말로 탈퇴하시겠습니까?\n\n모든 데이터가 영구적으로 삭제되며, 이 작업은 되돌릴 수 없습니다.';

  @override
  String get settingsDeletionConfirmButton => '탈퇴';

  @override
  String get settingsClearingCache => '캐시를 삭제하는 중...';

  @override
  String get settingsCacheCleared => '캐시가 삭제되었습니다';

  @override
  String get settingsCacheClearFailed => '캐시 삭제에 실패했습니다';

  @override
  String get settingsFontSize => '글꼴 크기';

  @override
  String get settingsMediaAutoDownload => '미디어 자동 다운로드';

  @override
  String get settingsImage => '이미지';

  @override
  String get settingsOnWifi => 'Wi-Fi 연결 시';

  @override
  String get settingsOnMobileData => '모바일 데이터 사용 시';

  @override
  String get settingsVideo => '동영상';

  @override
  String get settingsImageAutoDownload => '이미지 자동 다운로드';

  @override
  String get settingsVideoAutoDownload => '동영상 자동 다운로드';

  @override
  String get settingsTypingDisplay => '입력 표시';

  @override
  String get settingsTypingIndicator => '입력중 표시';

  @override
  String get settingsTypingIndicatorDesc =>
      '상대방이 메시지를 입력 중일 때 표시합니다. 켜면 나의 입력 상태도 상대방에게 전송됩니다.';

  @override
  String get settingsStorage => '저장 공간';

  @override
  String get settingsClearCache => '캐시 삭제';

  @override
  String get settingsClearCacheDesc => '임시 저장된 데이터를 삭제합니다';

  @override
  String get settingsClearCacheConfirm =>
      '임시 저장된 데이터를 삭제하시겠습니까?\n다운로드한 이미지와 동영상 캐시가 삭제됩니다.';

  @override
  String get settingsFontSizeSmall => '작게';

  @override
  String get settingsFontSizeLarge => '크게';

  @override
  String get settingsPreview => '미리보기';

  @override
  String get settingsFontPreviewKorean => '안녕하세요! 글꼴 크기를 조절해보세요.';

  @override
  String get settingsFontPreviewEnglish =>
      'Hello! Try adjusting the font size.';

  @override
  String get settingsFontSizeVerySmall => '아주 작게';

  @override
  String get settingsFontSizeNormal => '보통';

  @override
  String get settingsFontSizeVeryLarge => '아주 크게';

  @override
  String get settingsFontSizeExtraLarge => '매우 크게';

  @override
  String get settingsPasswordChangeSuccess => '비밀번호가 성공적으로 변경되었습니다.';

  @override
  String get settingsPasswordChangeFailed =>
      '비밀번호 변경에 실패했습니다. 현재 비밀번호를 확인해주세요.';

  @override
  String get settingsNewPassword => '새 비밀번호';

  @override
  String get settingsConfirmNewPassword => '새 비밀번호 확인';

  @override
  String get settingsCurrentPasswordRequired => '현재 비밀번호를 입력해주세요';

  @override
  String get settingsNewPasswordRequired => '새 비밀번호를 입력해주세요';

  @override
  String get settingsPasswordMinLength => '비밀번호는 8자 이상이어야 합니다';

  @override
  String get settingsPasswordAlphanumeric => '영문과 숫자를 포함해야 합니다';

  @override
  String get settingsConfirmPasswordRequired => '새 비밀번호를 다시 입력해주세요';

  @override
  String get settingsPasswordMismatch => '비밀번호가 일치하지 않습니다';

  @override
  String get settingsPasswordRequirements => '비밀번호 요구 사항';

  @override
  String get settingsPasswordReqMinLength => '최소 8자 이상';

  @override
  String get settingsPasswordReqLetters => '영문 대/소문자 포함';

  @override
  String get settingsPasswordReqNumbers => '숫자 포함';

  @override
  String get settingsPasswordReqSpecial => '특수문자 포함';
}
