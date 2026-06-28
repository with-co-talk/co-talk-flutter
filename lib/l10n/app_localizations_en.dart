// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Co-Talk';

  @override
  String get authSignUp => 'Sign Up';

  @override
  String get authSignUpFailed => 'Sign up failed';

  @override
  String get authLogin => 'Log In';

  @override
  String get authLoginFailed => 'Login failed';

  @override
  String get authEmail => 'Email';

  @override
  String get authNickname => 'Nickname';

  @override
  String get authPassword => 'Password';

  @override
  String get authConfirmPassword => 'Confirm Password';

  @override
  String get authKoreanInputWarning =>
      'Korean characters detected. Please check your English keyboard.';

  @override
  String get authNoAccountSignUp => 'Don\'t have an account? Sign up';

  @override
  String get authForgotEmail => 'Forgot your ID?';

  @override
  String get authForgotPassword => 'Forgot your password?';

  @override
  String get authEmailVerification => 'Email Verification';

  @override
  String get authErrorOccurred => 'An error occurred';

  @override
  String get authVerificationEmailResent =>
      'Verification email resent. Please check your email.';

  @override
  String get authEmailVerificationRequired => 'Email verification required';

  @override
  String authVerificationEmailSentTo(Object email) {
    return 'A verification email has been sent to\n$email.';
  }

  @override
  String get authVerificationLinkGuide =>
      'Click the verification link in the email\nto complete verification.';

  @override
  String get authResendVerificationEmail => 'Resend Verification Email';

  @override
  String get authBackToLogin => 'Back to Login';

  @override
  String get authFindEmailResult => 'Find Email Result';

  @override
  String get authEmailFound => 'We found your registered email';

  @override
  String get authGoToLogin => 'Go to Login';

  @override
  String get authForgotPasswordTitle => 'Find Password';

  @override
  String get authFindEmail => 'Find Email';

  @override
  String get authAccountNotFound => 'No matching account found.';

  @override
  String get authFindEmailGuide =>
      'Please enter the nickname and phone number\nyou registered with.';

  @override
  String get authNicknameRequired => 'Please enter a nickname';

  @override
  String get authPhoneNumber => 'Phone Number';

  @override
  String get authPhoneNumberRequired => 'Please enter a phone number';

  @override
  String get authFindEmailButton => 'Find Email';

  @override
  String get authPasswordChanged => 'Password changed successfully';

  @override
  String get authForgotPasswordEmailGuide =>
      'Please enter your registered email address.\nWe\'ll send you a verification code.';

  @override
  String get authRequestCode => 'Request Code';

  @override
  String authCodeSentTo(Object email) {
    return 'A verification code has been sent to\n$email.';
  }

  @override
  String get authVerificationCode => 'Verification Code (6 digits)';

  @override
  String get authCodeRequired => 'Please enter the verification code';

  @override
  String get authCodeLengthInvalid => 'Please enter a 6-digit code';

  @override
  String get authVerifyCode => 'Verify Code';

  @override
  String get authInvalidCode =>
      'The verification code is invalid. Please check again.';

  @override
  String get authResendCode => 'Resend Code';

  @override
  String get authNewPasswordGuide => 'Please enter a new password.';

  @override
  String get authNewPassword => 'New Password';

  @override
  String get authConfirmNewPassword => 'Confirm New Password';

  @override
  String get authChangePassword => 'Change Password';

  @override
  String get chatTitle => 'Chat';

  @override
  String get chatSelfChatTitle => 'My Chat';

  @override
  String chatTypingSingle(String nickname) {
    return '$nickname is typing...';
  }

  @override
  String chatTypingMultiple(int count) {
    return '$count people are typing...';
  }

  @override
  String get chatSearchHint => 'Search chats';

  @override
  String get chatListLoadFailed => 'Failed to load chats';

  @override
  String get chatListEmpty =>
      'No chats yet\nAdd friends and start a conversation';

  @override
  String chatSearchNoResults(Object query) {
    return 'No results for \"$query\"';
  }

  @override
  String get chatSelfName => 'Me';

  @override
  String get chatDirectTitle => 'Direct chat';

  @override
  String chatRoomLoadFailed(Object error) {
    return 'Unable to load chat room: $error';
  }

  @override
  String get chatRoomPreparing => 'Preparing chat room...';

  @override
  String get chatUnknownError => 'An unknown error occurred';

  @override
  String get chatRoomImageUpdated => 'Chat room image updated.';

  @override
  String get chatRoomImageUpdateFailed => 'Failed to update image.';

  @override
  String get chatRoomChangeImage => 'Change chat room image';

  @override
  String get chatMediaGallery => 'Media gallery';

  @override
  String get chatRoomLeave => 'Leave chat room';

  @override
  String get chatRoomLeaveConfirm =>
      'Leave this chat room?\nThe conversation will be deleted.';

  @override
  String get chatRoomLeaveAction => 'Leave';

  @override
  String chatReinviteSuccess(Object nickname) {
    return 'Re-invited $nickname';
  }

  @override
  String chatReinviteFailed(Object error) {
    return 'Re-invite failed: $error';
  }

  @override
  String get chatMessageForwarded => 'Message forwarded';

  @override
  String chatForwardFailed(Object error) {
    return 'Failed to forward message: $error';
  }

  @override
  String get chatOtherUser => 'The other user';

  @override
  String get chatMediaTabPhotos => 'Photos';

  @override
  String get chatMediaTabFiles => 'Files';

  @override
  String get chatMediaTabLinks => 'Links';

  @override
  String get chatMediaLoadFailed => 'Unable to load media';

  @override
  String get chatMediaEmptyPhotos => 'No photos';

  @override
  String get chatMediaEmptyFiles => 'No files';

  @override
  String get chatMediaEmptyLinks => 'No links';

  @override
  String get chatFileFallback => 'File';

  @override
  String get chatLinkFallback => 'Link';

  @override
  String get chatDeletedMessage => 'Deleted message';

  @override
  String get chatDeletedMessageBubble => 'This message was deleted';

  @override
  String get chatOriginalMessageNotFound => 'Original message not found';

  @override
  String get chatUnknownSender => 'Unknown';

  @override
  String get chatForwarded => 'Forwarded';

  @override
  String get chatResend => 'Resend';

  @override
  String chatCannotOpenUrl(Object url) {
    return 'Cannot open URL: $url';
  }

  @override
  String get chatViewFullScreen => 'View full screen';

  @override
  String get chatSaveToGallery => 'Save to gallery';

  @override
  String get chatImageSavedToGallery => 'Image saved to gallery';

  @override
  String chatSaveFailed(Object error) {
    return 'Save failed: $error';
  }

  @override
  String get chatDownload => 'Download';

  @override
  String chatCannotOpenFile(Object file) {
    return 'Cannot open file: $file';
  }

  @override
  String chatDownloadFailed(Object error) {
    return 'Download failed: $error';
  }

  @override
  String get chatEditMessageTitle => 'Edit message';

  @override
  String get chatMessageInputHint => 'Enter a message';

  @override
  String get chatDeleteMessageTitle => 'Delete message';

  @override
  String get chatDeleteMessageConfirm => 'Delete this message?';

  @override
  String get chatReply => 'Reply';

  @override
  String get chatForward => 'Forward';

  @override
  String get chatReport => 'Report';

  @override
  String get chatVideo => 'Video';

  @override
  String get chatTapToViewImage => 'Tap to view image';

  @override
  String get chatImageLoadFailed => 'Unable to load image';

  @override
  String get chatSelectRoom => 'Select chat room';

  @override
  String get chatRoomListEmpty => 'No chat rooms';

  @override
  String chatImagePasteFailed(Object error) {
    return 'Failed to paste image: $error';
  }

  @override
  String get chatPickFromGallery => 'Choose from gallery';

  @override
  String get chatPickFromGallerySubtitle => 'Select a photo or video';

  @override
  String get chatCamera => 'Camera';

  @override
  String get chatCameraSubtitle => 'Take a photo';

  @override
  String get chatFile => 'File';

  @override
  String get chatFileSubtitle => 'Select a document, PDF, or other file';

  @override
  String get chatImagePathUnavailable =>
      'Image path unavailable. Please use the file picker.';

  @override
  String get chatImageFileNotFound => 'The selected image file was not found.';

  @override
  String get chatImageUnavailable =>
      'Image unavailable. Please use the file picker.';

  @override
  String chatImagePickFailed(Object error) {
    return 'Unable to pick image: $error';
  }

  @override
  String get chatCameraImageUnavailable =>
      'Captured image unavailable. Please use the file picker.';

  @override
  String chatCameraFailed(Object error) {
    return 'Unable to use camera: $error';
  }

  @override
  String chatFilePickFailed(Object error) {
    return 'Unable to pick file: $error';
  }

  @override
  String get chatFileUploading => 'Uploading file...';

  @override
  String chatOtherUserLeft(Object nickname) {
    return '$nickname left the chat room';
  }

  @override
  String get chatOtherUserInfoNotFound =>
      'Could not find the other user\'s info';

  @override
  String get chatReinviting => 'Inviting...';

  @override
  String get chatReinvite => 'Invite again';

  @override
  String get chatKeyboard => 'Keyboard';

  @override
  String get chatEmoji => 'Emoji';

  @override
  String get chatAttach => 'Attach';

  @override
  String get chatEmojiSearch => 'Search emoji';

  @override
  String get chatNoMessages => 'No messages';

  @override
  String get chatStartConversation => 'Start a conversation';

  @override
  String get chatVideoPlaybackFailed => 'Unable to play video';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonRetry => 'Retry';

  @override
  String get friendsTitle => 'Friends';

  @override
  String get friendsAdd => 'Add Friend';

  @override
  String get friendsAddShort => 'Add';

  @override
  String get friendsManage => 'Manage Friends';

  @override
  String friendsCount(Object count) {
    return '$count friends';
  }

  @override
  String get friendsListLoadError => 'Failed to load friend list';

  @override
  String get friendsEmptyTitle => 'No friends yet';

  @override
  String get friendsEmptyDesc => 'Add friends and start a conversation';

  @override
  String get friendsHide => 'Hide';

  @override
  String get friendsBlock => 'Block';

  @override
  String get friendsHideTitle => 'Hide Friend';

  @override
  String friendsHideConfirm(Object name) {
    return 'Hide $name?\nYou can find them again in friend settings.';
  }

  @override
  String get friendsHideSuccess => 'Friend hidden';

  @override
  String get friendsBlockTitle => 'Block Friend';

  @override
  String friendsBlockConfirm(Object name) {
    return 'Block $name?';
  }

  @override
  String get friendsBlockSuccess => 'Friend blocked';

  @override
  String get friendsDeleteTitle => 'Delete Friend';

  @override
  String get friendsDeleteSuccess => 'Friend deleted';

  @override
  String friendsDeleteConfirm(Object name) {
    return 'Remove $name from your friends?';
  }

  @override
  String get friendsSearchHint => 'Search by nickname';

  @override
  String get friendsSearchPrompt => 'Enter a nickname to search';

  @override
  String get friendsSearchError => 'An error occurred while searching';

  @override
  String get friendsSearchNoResults => 'No search results';

  @override
  String friendsSearchNoResultsFor(Object query) {
    return 'No results for \"$query\"';
  }

  @override
  String get friendsRequestSent => 'Friend request sent';

  @override
  String get friendSettingsTitle => 'Manage Friends';

  @override
  String get friendSettingsRequestSection => 'Friend Requests';

  @override
  String get friendSettingsReceivedRequests => 'Received Requests';

  @override
  String get friendSettingsReceivedRequestsDesc =>
      'Check requests awaiting your response';

  @override
  String get friendSettingsSentRequests => 'Sent Requests';

  @override
  String get friendSettingsSentRequestsDesc =>
      'Check the requests you\'ve sent';

  @override
  String get friendSettingsManageSection => 'Friend Management';

  @override
  String get friendSettingsHiddenFriends => 'Manage Hidden Friends';

  @override
  String get friendSettingsHiddenFriendsDesc => 'Check your hidden friends';

  @override
  String get friendSettingsBlockedUsers => 'Manage Blocked Users';

  @override
  String get friendSettingsBlockedUsersDesc => 'Manage users you\'ve blocked';

  @override
  String get friendsHiddenTitle => 'Hidden Friends';

  @override
  String get friendsHiddenLoadError => 'Failed to load hidden friends';

  @override
  String get friendsHiddenEmptyTitle => 'No hidden friends';

  @override
  String get friendsHiddenEmptyDesc =>
      'Friends you hide from your list appear here';

  @override
  String get friendsUnhide => 'Unhide';

  @override
  String friendsUnhideSuccess(Object name) {
    return 'Unhid $name';
  }

  @override
  String get friendsBlockedTitle => 'Blocked Users';

  @override
  String get friendsBlockedLoadError => 'Failed to load blocked list';

  @override
  String get friendsBlockedEmptyTitle => 'No blocked users';

  @override
  String get friendsBlockedEmptyDesc => 'Users you block appear here';

  @override
  String get friendsUnblock => 'Unblock';

  @override
  String friendsUnblockConfirm(Object name) {
    return 'Unblock $name?';
  }

  @override
  String friendsUnblockSuccess(Object name) {
    return 'Unblocked $name';
  }

  @override
  String get friendsReceivedTitle => 'Received Requests';

  @override
  String get friendsReceivedLoadError => 'Failed to load received requests';

  @override
  String get friendsReceivedEmptyTitle => 'No received requests';

  @override
  String get friendsReceivedEmptyDesc =>
      'Requests from other users appear here';

  @override
  String get friendsReject => 'Decline';

  @override
  String get friendsAccept => 'Accept';

  @override
  String get friendsSentTitle => 'Sent Requests';

  @override
  String get friendsSentLoadError => 'Failed to load sent requests';

  @override
  String get friendsSentEmptyTitle => 'No sent requests';

  @override
  String get friendsSentEmptyDesc => 'Search for friends and send a request';

  @override
  String get friendsSentPending => 'Pending';

  @override
  String get mainTabFriends => 'Friends';

  @override
  String get mainTabChat => 'Chat';

  @override
  String get appLockPrompt => 'Authenticate to unlock';

  @override
  String get appLockAuthenticate => 'Authenticate';

  @override
  String get reportSubmitted => 'Your report has been submitted';

  @override
  String reportSubmitFailed(Object error) {
    return 'Failed to submit report: $error';
  }

  @override
  String get reportTargetUser => 'User';

  @override
  String get reportTargetMessage => 'Message';

  @override
  String reportTitle(Object target) {
    return 'Report $target';
  }

  @override
  String get reportSelectReason => 'Please select a reason for reporting';

  @override
  String get reportDescriptionLabel => 'Details (optional)';

  @override
  String get reportDescriptionHint => 'Enter additional details';

  @override
  String get reportSubmit => 'Report';

  @override
  String get errorTitle => 'Error';

  @override
  String get errorPageLoadFailed => 'Unable to load the page';

  @override
  String get errorGoHome => 'Go to home';

  @override
  String get imageEditorProcessing => 'Processing...';

  @override
  String get imageEditorCloseWarningTitle => 'Cancel editing';

  @override
  String get imageEditorCloseWarningMessage => 'Discard your edits?';

  @override
  String get imageEditorContinueEditing => 'Keep editing';

  @override
  String get imageEditorPaint => 'Draw';

  @override
  String get imageEditorFreestyle => 'Freestyle';

  @override
  String get imageEditorArrow => 'Arrow';

  @override
  String get imageEditorLine => 'Line';

  @override
  String get imageEditorRectangle => 'Rectangle';

  @override
  String get imageEditorCircle => 'Circle';

  @override
  String get imageEditorDashLine => 'Dashed line';

  @override
  String get imageEditorLineWidth => 'Width';

  @override
  String get imageEditorToggleFill => 'Fill';

  @override
  String get imageEditorUndo => 'Undo';

  @override
  String get imageEditorRedo => 'Redo';

  @override
  String get imageEditorDone => 'Done';

  @override
  String get imageEditorBack => 'Back';

  @override
  String get imageEditorTextInputHint => 'Enter text';

  @override
  String get imageEditorText => 'Text';

  @override
  String get imageEditorCrop => 'Crop';

  @override
  String get imageEditorRotate => 'Rotate';

  @override
  String get imageEditorFlip => 'Flip';

  @override
  String get imageEditorRatio => 'Ratio';

  @override
  String get imageEditorReset => 'Reset';

  @override
  String get imageEditorFilter => 'Filter';

  @override
  String get imageEditorEmoji => 'Emoji';

  @override
  String get imageEditorSaving => 'Saving...';

  @override
  String get widgetConnectionFailed => 'Connection failed - retrying stopped';

  @override
  String get widgetConnectionLost => 'Connection lost';

  @override
  String get widgetReconnect => 'Reconnect';

  @override
  String widgetCannotOpenUrl(Object url) {
    return 'Cannot open URL: $url';
  }

  @override
  String get widgetMessageSearchHint => 'Search messages';

  @override
  String get widgetSearchError => 'An error occurred while searching';

  @override
  String get widgetSearchNoResults => 'No results found';

  @override
  String get widgetSearchPrompt => 'Enter a search term';

  @override
  String get widgetUnknownSender => 'Unknown';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileEditTitle => 'Edit Profile';

  @override
  String get profileStatusLabel => 'Status';

  @override
  String get profileOnlineStatusLabel => 'Online Status';

  @override
  String get profileJoinDateLabel => 'Joined';

  @override
  String get profileStatusActive => 'Active';

  @override
  String get profileStatusInactive => 'Inactive';

  @override
  String get profileStatusSuspended => 'Suspended';

  @override
  String get profileStatusUnknown => 'Unknown';

  @override
  String get profileOnlineStatusOnline => 'Online';

  @override
  String get profileOnlineStatusAway => 'Away';

  @override
  String get profileOnlineStatusOffline => 'Offline';

  @override
  String profileFilePickFailed(Object error) {
    return 'Unable to select file: $error';
  }

  @override
  String get profileCameraUnavailable => 'Camera is unavailable';

  @override
  String get profileGalleryUnavailable => 'Unable to access album';

  @override
  String get profileImageFileNotFound =>
      'The selected image file could not be found.';

  @override
  String profileImageEditUnavailable(Object error) {
    return 'Image editing is unavailable: $error';
  }

  @override
  String get profileAvatarDeleted => 'Profile photo deleted';

  @override
  String get profileUpdated => 'Profile updated';

  @override
  String get profileUpdateFailed => 'Failed to update profile';

  @override
  String get profileUpdateSuccess => 'Profile updated.';

  @override
  String get profileSetPrivateSuccess => 'Set to private.';

  @override
  String get profileSetPublicSuccess => 'Set to public.';

  @override
  String get profileHistoryDeleteSuccess => 'Profile history deleted.';

  @override
  String get profileSetCurrentSuccess => 'Set as current profile.';

  @override
  String get profileBackgroundChanged => 'Background changed';

  @override
  String get profileAvatarChanged => 'Profile photo changed';

  @override
  String get profileImageChangeFailed => 'Failed to change image';

  @override
  String get profileSaveButton => 'Save';

  @override
  String get profileNoChanges => 'No changes';

  @override
  String get profileLoadFailed => 'Unable to load profile';

  @override
  String get profileStatusMessage => 'Status Message';

  @override
  String get profileStatusMessageHint => 'Enter a status message';

  @override
  String get profileBackground => 'Background';

  @override
  String get profileAvatar => 'Profile Photo';

  @override
  String get profileViewFullScreen => 'View full screen';

  @override
  String get profileBackgroundChange => 'Change background';

  @override
  String get profileBackgroundChangeSubtitle =>
      'Select a new background from album';

  @override
  String get profileBackgroundHistory => 'Background history';

  @override
  String get profileBackgroundHistorySubtitle => 'View previous backgrounds';

  @override
  String get profileAvatarChange => 'Change profile photo';

  @override
  String get profileAvatarChangeSubtitle => 'Select a new photo from album';

  @override
  String get profileAvatarHistory => 'Profile photo history';

  @override
  String get profileAvatarHistorySubtitle => 'View previous profile photos';

  @override
  String get profileMakePublic => 'Make public';

  @override
  String get profileMakePrivate => 'Private';

  @override
  String get profilePublicDescription => 'Visible to others';

  @override
  String get profilePrivateDescription => 'Only you can see this';

  @override
  String profileDeleteItemTitle(Object item) {
    return 'Delete $item';
  }

  @override
  String profileDeleteItemConfirm(Object item) {
    return 'Delete $item?';
  }

  @override
  String get profileImagePickFailed => 'Unable to select image';

  @override
  String get profileAddStatusMessage => 'Add status message';

  @override
  String get profileDirectChat => '1:1 Chat';

  @override
  String get profileReport => 'Report';

  @override
  String get profileSelfChat => 'Chat with myself';

  @override
  String get profileEditAction => 'Edit profile';

  @override
  String get profileLoginInfoNotFound => 'Login information not found';

  @override
  String profileHistoryEmpty(Object type) {
    return 'No $type history yet';
  }

  @override
  String get profileAddAvatar => 'Add photo';

  @override
  String get profileAddBackground => 'Add background';

  @override
  String get profileMore => 'More';

  @override
  String get profileBadgeCurrent => 'Current';

  @override
  String get profileBadgePrivate => 'Private';

  @override
  String get profileNickname => 'Nickname';

  @override
  String get profileNicknameHint => 'Enter a nickname';

  @override
  String get profileStatusMessageOptionalHint =>
      'Enter a status message (optional)';

  @override
  String get profileAccountInfo => 'Account Info';

  @override
  String get profileEmail => 'Email';

  @override
  String get profileNotEditable => 'Not editable';

  @override
  String get profileBackgroundChangeShort => 'Change background';

  @override
  String get profileBackgroundHistoryShort => 'Background history';

  @override
  String get profileChangePhoto => 'Change photo';

  @override
  String get profileSetAsCurrent => 'Set as current profile';

  @override
  String get profileMakePublicShort => 'Make public';

  @override
  String get profileDeleteConfirmTitle => 'Confirm deletion';

  @override
  String get profileDeleteCurrentWarning =>
      'This is your current profile.\nDeleting it will revert to a previous one.';

  @override
  String get profileDeleteHistoryConfirm => 'Delete this history item?';

  @override
  String get profileTakePhoto => 'Take a photo';

  @override
  String get profileTakePhotoSubtitle => 'Capture a new photo';

  @override
  String get profileSelectFromAlbum => 'Select from album';

  @override
  String get profileSelectFromAlbumSubtitle => 'Choose a saved photo';

  @override
  String get profileSelectFromExisting => 'Select from existing profiles';

  @override
  String get profileSelectFromExistingSubtitle =>
      'Choose a previously used photo';

  @override
  String get profileResetToDefault => 'Reset to default image';

  @override
  String get profileResetToDefaultSubtitle => 'Delete current profile photo';

  @override
  String get profileSelectFromFile => 'Select from file';

  @override
  String get profileSelectFromFileSubtitle => 'Choose an image file';

  @override
  String get profileSelectFromBackgroundHistory =>
      'Select from background history';

  @override
  String get profileSelectBackgroundFileSubtitle =>
      'Choose a background image file';

  @override
  String get profileAvatarDeleteTitle => 'Delete profile photo';

  @override
  String get profileAvatarDeleteConfirm =>
      'Delete your profile photo and reset to the default image?';

  @override
  String get profileNicknameRequired => 'Please enter a nickname';

  @override
  String get profileNicknameTooShort =>
      'Nickname must be at least 2 characters';

  @override
  String get profileNicknameTooLong =>
      'Nickname must be 20 characters or fewer';

  @override
  String get profileStatusMessageTooLong =>
      'Status message must be 60 characters or fewer';

  @override
  String get commonSave => 'Save';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsProfile => 'Profile';

  @override
  String get settingsMyProfile => 'My Profile';

  @override
  String get settingsNotification => 'Notifications';

  @override
  String get settingsNotificationSettings => 'Notification Settings';

  @override
  String get settingsNotificationDesc =>
      'Messages, friend requests, group invite notifications';

  @override
  String get settingsChat => 'Chat';

  @override
  String get settingsChatSettings => 'Chat Settings';

  @override
  String get settingsChatDesc => 'Font size, media auto-download';

  @override
  String get settingsFriends => 'Friends';

  @override
  String get settingsFriendManagement => 'Manage Friends';

  @override
  String get settingsFriendManagementDesc =>
      'Manage friend requests, hidden, and blocked';

  @override
  String get settingsGeneral => 'General';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageKorean => 'Korean (Default)';

  @override
  String get settingsDarkMode => 'Dark Mode';

  @override
  String get settingsSecurity => 'Security';

  @override
  String get settingsBiometric => 'Biometric Authentication';

  @override
  String get settingsBiometricDesc => 'Use biometrics to unlock the app';

  @override
  String get settingsAccount => 'Account';

  @override
  String get settingsChangePassword => 'Change Password';

  @override
  String get settingsAccountDeletion => 'Delete Account';

  @override
  String get settingsInfo => 'About';

  @override
  String get settingsAppVersion => 'App Version';

  @override
  String get settingsTerms => 'Terms of Service';

  @override
  String get settingsPrivacyPolicy => 'Privacy Policy';

  @override
  String get settingsOpenSourceLicense => 'Open Source Licenses';

  @override
  String get settingsLogout => 'Log Out';

  @override
  String get settingsLogoutConfirm => 'Are you sure you want to log out?';

  @override
  String get settingsErrorOccurred => 'An error occurred';

  @override
  String get settingsNotificationType => 'Notification Type';

  @override
  String get settingsMessageNotification => 'Message Notifications';

  @override
  String get settingsMessageNotificationDesc =>
      'Notify when you receive a new message';

  @override
  String get settingsFriendRequestNotification =>
      'Friend Request Notifications';

  @override
  String get settingsFriendRequestNotificationDesc =>
      'Notify when you receive a new friend request';

  @override
  String get settingsGroupInviteNotification => 'Group Invite Notifications';

  @override
  String get settingsGroupInviteNotificationDesc =>
      'Notify when you are invited to a group chat';

  @override
  String get settingsNotificationMethod => 'Notification Method';

  @override
  String get settingsSound => 'Sound';

  @override
  String get settingsSoundDesc => 'Play notification sound';

  @override
  String get settingsVibration => 'Vibration';

  @override
  String get settingsVibrationDesc => 'Vibrate on notification';

  @override
  String get settingsDoNotDisturb => 'Do Not Disturb';

  @override
  String get settingsDoNotDisturbMode => 'Do Not Disturb Mode';

  @override
  String get settingsDoNotDisturbDesc =>
      'Mute notifications during the set time';

  @override
  String get settingsStartTime => 'Start Time';

  @override
  String get settingsEndTime => 'End Time';

  @override
  String get settingsNotificationPreview => 'Notification Preview';

  @override
  String get settingsNotificationPreviewDesc =>
      'Choose what to show in notifications';

  @override
  String get settingsPreviewNameAndMessage => 'Name + Message';

  @override
  String get settingsPreviewNameAndMessageDesc =>
      'Show the sender\'s name and message content';

  @override
  String get settingsPreviewNameOnly => 'Name Only';

  @override
  String get settingsPreviewNameOnlyDesc => 'Show only the sender\'s name';

  @override
  String get settingsPreviewNothing => 'Show Nothing';

  @override
  String get settingsPreviewNothingDesc =>
      'Hide both the name and message content';

  @override
  String get settingsBiometricNotSupported =>
      'This device does not support biometric authentication.';

  @override
  String get settingsBiometricEnabledDesc => 'Use biometrics to unlock the app';

  @override
  String get settingsBiometricUnavailable => 'Not available on this device';

  @override
  String get settingsBiometricAuthReason =>
      'Please authenticate to enable biometrics';

  @override
  String get settingsBiometricBackgroundNotice =>
      'Biometric authentication is required when you return after the app has been in the background for over 30 seconds.';

  @override
  String get settingsBiometricLoadFailed =>
      'Failed to load biometric settings.';

  @override
  String get settingsAccountDeletionComplete => 'Your account has been deleted';

  @override
  String get settingsAccountDeletionInvalidConfirmation =>
      'Please enter the correct confirmation text';

  @override
  String get settingsAccountDeletionEmptyPassword =>
      'Please enter your password';

  @override
  String get settingsAccountDeletionUserNotFound =>
      'User information not found';

  @override
  String get settingsAccountDeletionUnknownError =>
      'An error occurred while deleting your account. Please check your password.';

  @override
  String get settingsAccountDeletionProcessing => 'Processing deletion...';

  @override
  String get settingsWarning => 'Warning';

  @override
  String get settingsDeletionWarningTitle =>
      'The following data will be permanently deleted when you delete your account:';

  @override
  String get settingsDeletionItemChats => 'All chat history';

  @override
  String get settingsDeletionItemFriends => 'Friend list';

  @override
  String get settingsDeletionItemProfile => 'Profile information';

  @override
  String get settingsDeletionItemNotifications => 'Notification settings';

  @override
  String get settingsDeletionIrreversible => 'This action cannot be undone.';

  @override
  String get settingsDeletionStep1 => '1. Confirm Password';

  @override
  String get settingsCurrentPassword => 'Current Password';

  @override
  String get settingsDeletionStep2 => '2. Confirm Deletion';

  @override
  String get settingsDeletionConfirmInstruction =>
      'To confirm deletion, type \"삭제합니다\" below.';

  @override
  String get settingsDeletionConfirmKeyword => '삭제합니다';

  @override
  String get settingsDeletionConfirmMismatch => 'Please type \"삭제합니다\" exactly';

  @override
  String settingsDeletionCountdown(Object count) {
    return 'The delete button will be enabled in $count seconds';
  }

  @override
  String settingsAccountDeletionButtonDisabled(Object detail) {
    return 'Delete Account ($detail)';
  }

  @override
  String get settingsDeletionNeedInput => 'Input required';

  @override
  String settingsDeletionSeconds(Object count) {
    return '${count}s';
  }

  @override
  String get settingsFinalConfirm => 'Final Confirmation';

  @override
  String get settingsDeletionFinalConfirmContent =>
      'Are you sure you want to delete your account?\n\nAll data will be permanently deleted and this action cannot be undone.';

  @override
  String get settingsDeletionConfirmButton => 'Delete';

  @override
  String get settingsClearingCache => 'Clearing cache...';

  @override
  String get settingsCacheCleared => 'Cache cleared';

  @override
  String get settingsCacheClearFailed => 'Failed to clear cache';

  @override
  String get settingsFontSize => 'Font Size';

  @override
  String get settingsMediaAutoDownload => 'Media Auto-Download';

  @override
  String get settingsImage => 'Image';

  @override
  String get settingsOnWifi => 'On Wi-Fi';

  @override
  String get settingsOnMobileData => 'On Mobile Data';

  @override
  String get settingsVideo => 'Video';

  @override
  String get settingsImageAutoDownload => 'Auto-Download Images';

  @override
  String get settingsVideoAutoDownload => 'Auto-Download Videos';

  @override
  String get settingsTypingDisplay => 'Typing Indicator';

  @override
  String get settingsTypingIndicator => 'Show Typing';

  @override
  String get settingsTypingIndicatorDesc =>
      'Shows when the other person is typing. When on, your typing status is also sent to them.';

  @override
  String get settingsStorage => 'Storage';

  @override
  String get settingsClearCache => 'Clear Cache';

  @override
  String get settingsClearCacheDesc => 'Delete temporarily stored data';

  @override
  String get settingsClearCacheConfirm =>
      'Do you want to delete temporarily stored data?\nDownloaded image and video caches will be deleted.';

  @override
  String get settingsFontSizeSmall => 'Small';

  @override
  String get settingsFontSizeLarge => 'Large';

  @override
  String get settingsPreview => 'Preview';

  @override
  String get settingsFontPreviewKorean => '안녕하세요! 글꼴 크기를 조절해보세요.';

  @override
  String get settingsFontPreviewEnglish =>
      'Hello! Try adjusting the font size.';

  @override
  String get settingsFontSizeVerySmall => 'Very Small';

  @override
  String get settingsFontSizeNormal => 'Normal';

  @override
  String get settingsFontSizeVeryLarge => 'Very Large';

  @override
  String get settingsFontSizeExtraLarge => 'Extra Large';

  @override
  String get settingsPasswordChangeSuccess =>
      'Your password has been changed successfully.';

  @override
  String get settingsPasswordChangeFailed =>
      'Failed to change password. Please check your current password.';

  @override
  String get settingsNewPassword => 'New Password';

  @override
  String get settingsConfirmNewPassword => 'Confirm New Password';

  @override
  String get settingsCurrentPasswordRequired =>
      'Please enter your current password';

  @override
  String get settingsNewPasswordRequired => 'Please enter a new password';

  @override
  String get settingsPasswordMinLength =>
      'Password must be at least 8 characters';

  @override
  String get settingsPasswordAlphanumeric => 'Must include letters and numbers';

  @override
  String get settingsConfirmPasswordRequired =>
      'Please re-enter your new password';

  @override
  String get settingsPasswordMismatch => 'Passwords do not match';

  @override
  String get settingsPasswordRequirements => 'Password Requirements';

  @override
  String get settingsPasswordReqMinLength => 'At least 8 characters';

  @override
  String get settingsPasswordReqLetters =>
      'Include upper and lowercase letters';

  @override
  String get settingsPasswordReqNumbers => 'Include numbers';

  @override
  String get settingsPasswordReqSpecial => 'Include special characters';
}
