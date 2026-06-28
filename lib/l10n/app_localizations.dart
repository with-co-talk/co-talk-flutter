import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko'),
  ];

  /// The application title
  ///
  /// In ko, this message translates to:
  /// **'Co-Talk'**
  String get appTitle;

  /// No description provided for @authSignUp.
  ///
  /// In ko, this message translates to:
  /// **'회원가입'**
  String get authSignUp;

  /// No description provided for @authSignUpFailed.
  ///
  /// In ko, this message translates to:
  /// **'회원가입에 실패했습니다'**
  String get authSignUpFailed;

  /// No description provided for @authLogin.
  ///
  /// In ko, this message translates to:
  /// **'로그인'**
  String get authLogin;

  /// No description provided for @authLoginFailed.
  ///
  /// In ko, this message translates to:
  /// **'로그인에 실패했습니다'**
  String get authLoginFailed;

  /// No description provided for @authEmail.
  ///
  /// In ko, this message translates to:
  /// **'이메일'**
  String get authEmail;

  /// No description provided for @authNickname.
  ///
  /// In ko, this message translates to:
  /// **'닉네임'**
  String get authNickname;

  /// No description provided for @authPassword.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호'**
  String get authPassword;

  /// No description provided for @authConfirmPassword.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호 확인'**
  String get authConfirmPassword;

  /// No description provided for @authKoreanInputWarning.
  ///
  /// In ko, this message translates to:
  /// **'한글이 입력되어 있습니다. 영문 키보드를 확인하세요.'**
  String get authKoreanInputWarning;

  /// No description provided for @authNoAccountSignUp.
  ///
  /// In ko, this message translates to:
  /// **'계정이 없으신가요? 회원가입'**
  String get authNoAccountSignUp;

  /// No description provided for @authForgotEmail.
  ///
  /// In ko, this message translates to:
  /// **'아이디를 잊으셨나요?'**
  String get authForgotEmail;

  /// No description provided for @authForgotPassword.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호를 잊으셨나요?'**
  String get authForgotPassword;

  /// No description provided for @authEmailVerification.
  ///
  /// In ko, this message translates to:
  /// **'이메일 인증'**
  String get authEmailVerification;

  /// No description provided for @authErrorOccurred.
  ///
  /// In ko, this message translates to:
  /// **'오류가 발생했습니다'**
  String get authErrorOccurred;

  /// No description provided for @authVerificationEmailResent.
  ///
  /// In ko, this message translates to:
  /// **'인증 이메일이 재발송되었습니다. 이메일을 확인해주세요.'**
  String get authVerificationEmailResent;

  /// No description provided for @authEmailVerificationRequired.
  ///
  /// In ko, this message translates to:
  /// **'이메일 인증이 필요합니다'**
  String get authEmailVerificationRequired;

  /// No description provided for @authVerificationEmailSentTo.
  ///
  /// In ko, this message translates to:
  /// **'{email} 으로\n인증 이메일이 발송되었습니다.'**
  String authVerificationEmailSentTo(Object email);

  /// No description provided for @authVerificationLinkGuide.
  ///
  /// In ko, this message translates to:
  /// **'이메일의 인증 링크를 클릭하여\n인증을 완료해주세요.'**
  String get authVerificationLinkGuide;

  /// No description provided for @authResendVerificationEmail.
  ///
  /// In ko, this message translates to:
  /// **'인증 이메일 재발송'**
  String get authResendVerificationEmail;

  /// No description provided for @authBackToLogin.
  ///
  /// In ko, this message translates to:
  /// **'로그인으로 돌아가기'**
  String get authBackToLogin;

  /// No description provided for @authFindEmailResult.
  ///
  /// In ko, this message translates to:
  /// **'아이디 찾기 결과'**
  String get authFindEmailResult;

  /// No description provided for @authEmailFound.
  ///
  /// In ko, this message translates to:
  /// **'가입된 이메일을 찾았습니다'**
  String get authEmailFound;

  /// No description provided for @authGoToLogin.
  ///
  /// In ko, this message translates to:
  /// **'로그인하기'**
  String get authGoToLogin;

  /// No description provided for @authForgotPasswordTitle.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호 찾기'**
  String get authForgotPasswordTitle;

  /// No description provided for @authFindEmail.
  ///
  /// In ko, this message translates to:
  /// **'아이디 찾기'**
  String get authFindEmail;

  /// No description provided for @authAccountNotFound.
  ///
  /// In ko, this message translates to:
  /// **'일치하는 계정을 찾을 수 없습니다.'**
  String get authAccountNotFound;

  /// No description provided for @authFindEmailGuide.
  ///
  /// In ko, this message translates to:
  /// **'가입 시 등록한 닉네임과 전화번호를\n입력해주세요.'**
  String get authFindEmailGuide;

  /// No description provided for @authNicknameRequired.
  ///
  /// In ko, this message translates to:
  /// **'닉네임을 입력해주세요'**
  String get authNicknameRequired;

  /// No description provided for @authPhoneNumber.
  ///
  /// In ko, this message translates to:
  /// **'전화번호'**
  String get authPhoneNumber;

  /// No description provided for @authPhoneNumberRequired.
  ///
  /// In ko, this message translates to:
  /// **'전화번호를 입력해주세요'**
  String get authPhoneNumberRequired;

  /// No description provided for @authFindEmailButton.
  ///
  /// In ko, this message translates to:
  /// **'이메일 찾기'**
  String get authFindEmailButton;

  /// No description provided for @authPasswordChanged.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호가 성공적으로 변경되었습니다'**
  String get authPasswordChanged;

  /// No description provided for @authForgotPasswordEmailGuide.
  ///
  /// In ko, this message translates to:
  /// **'가입한 이메일 주소를 입력해주세요.\n인증 코드를 발송해드립니다.'**
  String get authForgotPasswordEmailGuide;

  /// No description provided for @authRequestCode.
  ///
  /// In ko, this message translates to:
  /// **'인증 코드 받기'**
  String get authRequestCode;

  /// No description provided for @authCodeSentTo.
  ///
  /// In ko, this message translates to:
  /// **'{email}으로\n인증 코드를 발송했습니다.'**
  String authCodeSentTo(Object email);

  /// No description provided for @authVerificationCode.
  ///
  /// In ko, this message translates to:
  /// **'인증 코드 (6자리)'**
  String get authVerificationCode;

  /// No description provided for @authCodeRequired.
  ///
  /// In ko, this message translates to:
  /// **'인증 코드를 입력해주세요'**
  String get authCodeRequired;

  /// No description provided for @authCodeLengthInvalid.
  ///
  /// In ko, this message translates to:
  /// **'6자리 코드를 입력해주세요'**
  String get authCodeLengthInvalid;

  /// No description provided for @authVerifyCode.
  ///
  /// In ko, this message translates to:
  /// **'인증 코드 확인'**
  String get authVerifyCode;

  /// No description provided for @authInvalidCode.
  ///
  /// In ko, this message translates to:
  /// **'인증 코드가 유효하지 않습니다. 다시 확인해주세요.'**
  String get authInvalidCode;

  /// No description provided for @authResendCode.
  ///
  /// In ko, this message translates to:
  /// **'인증 코드 재발송'**
  String get authResendCode;

  /// No description provided for @authNewPasswordGuide.
  ///
  /// In ko, this message translates to:
  /// **'새로운 비밀번호를 입력해주세요.'**
  String get authNewPasswordGuide;

  /// No description provided for @authNewPassword.
  ///
  /// In ko, this message translates to:
  /// **'새 비밀번호'**
  String get authNewPassword;

  /// No description provided for @authConfirmNewPassword.
  ///
  /// In ko, this message translates to:
  /// **'새 비밀번호 확인'**
  String get authConfirmNewPassword;

  /// No description provided for @authChangePassword.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호 변경'**
  String get authChangePassword;

  /// No description provided for @chatTitle.
  ///
  /// In ko, this message translates to:
  /// **'채팅'**
  String get chatTitle;

  /// No description provided for @chatSelfChatTitle.
  ///
  /// In ko, this message translates to:
  /// **'나와의 채팅'**
  String get chatSelfChatTitle;

  /// No description provided for @chatTypingSingle.
  ///
  /// In ko, this message translates to:
  /// **'{nickname}님이 입력 중...'**
  String chatTypingSingle(String nickname);

  /// No description provided for @chatTypingMultiple.
  ///
  /// In ko, this message translates to:
  /// **'{count}명이 입력 중...'**
  String chatTypingMultiple(int count);

  /// No description provided for @chatSearchHint.
  ///
  /// In ko, this message translates to:
  /// **'채팅방 검색'**
  String get chatSearchHint;

  /// No description provided for @chatListLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'채팅방을 불러오는데 실패했습니다'**
  String get chatListLoadFailed;

  /// No description provided for @chatListEmpty.
  ///
  /// In ko, this message translates to:
  /// **'채팅방이 없습니다\n친구를 추가하고 대화를 시작해보세요'**
  String get chatListEmpty;

  /// No description provided for @chatSearchNoResults.
  ///
  /// In ko, this message translates to:
  /// **'\"{query}\" 검색 결과가 없습니다'**
  String chatSearchNoResults(Object query);

  /// No description provided for @chatSelfName.
  ///
  /// In ko, this message translates to:
  /// **'나'**
  String get chatSelfName;

  /// No description provided for @chatDirectTitle.
  ///
  /// In ko, this message translates to:
  /// **'1:1 채팅'**
  String get chatDirectTitle;

  /// No description provided for @chatRoomLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'채팅방을 불러올 수 없습니다: {error}'**
  String chatRoomLoadFailed(Object error);

  /// No description provided for @chatRoomPreparing.
  ///
  /// In ko, this message translates to:
  /// **'채팅방을 준비 중...'**
  String get chatRoomPreparing;

  /// No description provided for @chatUnknownError.
  ///
  /// In ko, this message translates to:
  /// **'알 수 없는 오류가 발생했습니다'**
  String get chatUnknownError;

  /// No description provided for @chatRoomImageUpdated.
  ///
  /// In ko, this message translates to:
  /// **'채팅방 이미지가 변경되었습니다.'**
  String get chatRoomImageUpdated;

  /// No description provided for @chatRoomImageUpdateFailed.
  ///
  /// In ko, this message translates to:
  /// **'이미지 변경에 실패했습니다.'**
  String get chatRoomImageUpdateFailed;

  /// No description provided for @chatRoomChangeImage.
  ///
  /// In ko, this message translates to:
  /// **'채팅방 이미지 변경'**
  String get chatRoomChangeImage;

  /// No description provided for @chatMediaGallery.
  ///
  /// In ko, this message translates to:
  /// **'미디어 모아보기'**
  String get chatMediaGallery;

  /// No description provided for @chatRoomLeave.
  ///
  /// In ko, this message translates to:
  /// **'채팅방 나가기'**
  String get chatRoomLeave;

  /// No description provided for @chatRoomLeaveConfirm.
  ///
  /// In ko, this message translates to:
  /// **'채팅방을 나가시겠습니까?\n대화 내용은 삭제됩니다.'**
  String get chatRoomLeaveConfirm;

  /// No description provided for @chatRoomLeaveAction.
  ///
  /// In ko, this message translates to:
  /// **'나가기'**
  String get chatRoomLeaveAction;

  /// No description provided for @chatReinviteSuccess.
  ///
  /// In ko, this message translates to:
  /// **'{nickname}님을 다시 초대했습니다'**
  String chatReinviteSuccess(Object nickname);

  /// No description provided for @chatReinviteFailed.
  ///
  /// In ko, this message translates to:
  /// **'재초대 실패: {error}'**
  String chatReinviteFailed(Object error);

  /// No description provided for @chatMessageForwarded.
  ///
  /// In ko, this message translates to:
  /// **'메시지가 전달되었습니다'**
  String get chatMessageForwarded;

  /// No description provided for @chatForwardFailed.
  ///
  /// In ko, this message translates to:
  /// **'메시지 전달에 실패했습니다: {error}'**
  String chatForwardFailed(Object error);

  /// No description provided for @chatOtherUser.
  ///
  /// In ko, this message translates to:
  /// **'상대방'**
  String get chatOtherUser;

  /// No description provided for @chatMediaTabPhotos.
  ///
  /// In ko, this message translates to:
  /// **'사진'**
  String get chatMediaTabPhotos;

  /// No description provided for @chatMediaTabFiles.
  ///
  /// In ko, this message translates to:
  /// **'파일'**
  String get chatMediaTabFiles;

  /// No description provided for @chatMediaTabLinks.
  ///
  /// In ko, this message translates to:
  /// **'링크'**
  String get chatMediaTabLinks;

  /// No description provided for @chatMediaLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'미디어를 불러올 수 없습니다'**
  String get chatMediaLoadFailed;

  /// No description provided for @chatMediaEmptyPhotos.
  ///
  /// In ko, this message translates to:
  /// **'사진이 없습니다'**
  String get chatMediaEmptyPhotos;

  /// No description provided for @chatMediaEmptyFiles.
  ///
  /// In ko, this message translates to:
  /// **'파일이 없습니다'**
  String get chatMediaEmptyFiles;

  /// No description provided for @chatMediaEmptyLinks.
  ///
  /// In ko, this message translates to:
  /// **'링크가 없습니다'**
  String get chatMediaEmptyLinks;

  /// No description provided for @chatFileFallback.
  ///
  /// In ko, this message translates to:
  /// **'파일'**
  String get chatFileFallback;

  /// No description provided for @chatLinkFallback.
  ///
  /// In ko, this message translates to:
  /// **'링크'**
  String get chatLinkFallback;

  /// No description provided for @chatDeletedMessage.
  ///
  /// In ko, this message translates to:
  /// **'삭제된 메시지'**
  String get chatDeletedMessage;

  /// No description provided for @chatDeletedMessageBubble.
  ///
  /// In ko, this message translates to:
  /// **'삭제된 메시지입니다'**
  String get chatDeletedMessageBubble;

  /// No description provided for @chatOriginalMessageNotFound.
  ///
  /// In ko, this message translates to:
  /// **'원본 메시지를 찾을 수 없습니다'**
  String get chatOriginalMessageNotFound;

  /// No description provided for @chatUnknownSender.
  ///
  /// In ko, this message translates to:
  /// **'알 수 없음'**
  String get chatUnknownSender;

  /// No description provided for @chatForwarded.
  ///
  /// In ko, this message translates to:
  /// **'전달됨'**
  String get chatForwarded;

  /// No description provided for @chatResend.
  ///
  /// In ko, this message translates to:
  /// **'재전송'**
  String get chatResend;

  /// No description provided for @chatCannotOpenUrl.
  ///
  /// In ko, this message translates to:
  /// **'URL을 열 수 없습니다: {url}'**
  String chatCannotOpenUrl(Object url);

  /// No description provided for @chatViewFullScreen.
  ///
  /// In ko, this message translates to:
  /// **'전체 화면 보기'**
  String get chatViewFullScreen;

  /// No description provided for @chatSaveToGallery.
  ///
  /// In ko, this message translates to:
  /// **'갤러리에 저장'**
  String get chatSaveToGallery;

  /// No description provided for @chatImageSavedToGallery.
  ///
  /// In ko, this message translates to:
  /// **'사진이 갤러리에 저장되었습니다'**
  String get chatImageSavedToGallery;

  /// No description provided for @chatSaveFailed.
  ///
  /// In ko, this message translates to:
  /// **'저장 실패: {error}'**
  String chatSaveFailed(Object error);

  /// No description provided for @chatDownload.
  ///
  /// In ko, this message translates to:
  /// **'다운로드'**
  String get chatDownload;

  /// No description provided for @chatCannotOpenFile.
  ///
  /// In ko, this message translates to:
  /// **'파일을 열 수 없습니다: {file}'**
  String chatCannotOpenFile(Object file);

  /// No description provided for @chatDownloadFailed.
  ///
  /// In ko, this message translates to:
  /// **'다운로드 실패: {error}'**
  String chatDownloadFailed(Object error);

  /// No description provided for @chatEditMessageTitle.
  ///
  /// In ko, this message translates to:
  /// **'메시지 수정'**
  String get chatEditMessageTitle;

  /// No description provided for @chatMessageInputHint.
  ///
  /// In ko, this message translates to:
  /// **'메시지를 입력하세요'**
  String get chatMessageInputHint;

  /// No description provided for @chatDeleteMessageTitle.
  ///
  /// In ko, this message translates to:
  /// **'메시지 삭제'**
  String get chatDeleteMessageTitle;

  /// No description provided for @chatDeleteMessageConfirm.
  ///
  /// In ko, this message translates to:
  /// **'이 메시지를 삭제하시겠습니까?'**
  String get chatDeleteMessageConfirm;

  /// No description provided for @chatReply.
  ///
  /// In ko, this message translates to:
  /// **'답장'**
  String get chatReply;

  /// No description provided for @chatForward.
  ///
  /// In ko, this message translates to:
  /// **'전달'**
  String get chatForward;

  /// No description provided for @chatReport.
  ///
  /// In ko, this message translates to:
  /// **'신고'**
  String get chatReport;

  /// No description provided for @chatVideo.
  ///
  /// In ko, this message translates to:
  /// **'동영상'**
  String get chatVideo;

  /// No description provided for @chatTapToViewImage.
  ///
  /// In ko, this message translates to:
  /// **'탭하여 이미지 보기'**
  String get chatTapToViewImage;

  /// No description provided for @chatImageLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'이미지를 불러올 수 없습니다'**
  String get chatImageLoadFailed;

  /// No description provided for @chatSelectRoom.
  ///
  /// In ko, this message translates to:
  /// **'채팅방 선택'**
  String get chatSelectRoom;

  /// No description provided for @chatRoomListEmpty.
  ///
  /// In ko, this message translates to:
  /// **'채팅방이 없습니다'**
  String get chatRoomListEmpty;

  /// No description provided for @chatImagePasteFailed.
  ///
  /// In ko, this message translates to:
  /// **'이미지 붙여넣기 실패: {error}'**
  String chatImagePasteFailed(Object error);

  /// No description provided for @chatPickFromGallery.
  ///
  /// In ko, this message translates to:
  /// **'갤러리에서 선택'**
  String get chatPickFromGallery;

  /// No description provided for @chatPickFromGallerySubtitle.
  ///
  /// In ko, this message translates to:
  /// **'사진 또는 동영상을 선택합니다'**
  String get chatPickFromGallerySubtitle;

  /// No description provided for @chatCamera.
  ///
  /// In ko, this message translates to:
  /// **'카메라'**
  String get chatCamera;

  /// No description provided for @chatCameraSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'사진을 촬영합니다'**
  String get chatCameraSubtitle;

  /// No description provided for @chatFile.
  ///
  /// In ko, this message translates to:
  /// **'파일'**
  String get chatFile;

  /// No description provided for @chatFileSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'문서, PDF 등의 파일을 선택합니다'**
  String get chatFileSubtitle;

  /// No description provided for @chatImagePathUnavailable.
  ///
  /// In ko, this message translates to:
  /// **'이미지 경로를 사용할 수 없습니다. 파일 선택을 이용해 주세요.'**
  String get chatImagePathUnavailable;

  /// No description provided for @chatImageFileNotFound.
  ///
  /// In ko, this message translates to:
  /// **'선택한 이미지 파일을 찾을 수 없습니다.'**
  String get chatImageFileNotFound;

  /// No description provided for @chatImageUnavailable.
  ///
  /// In ko, this message translates to:
  /// **'이미지를 사용할 수 없습니다. 파일 선택을 이용해 주세요.'**
  String get chatImageUnavailable;

  /// No description provided for @chatImagePickFailed.
  ///
  /// In ko, this message translates to:
  /// **'이미지를 선택할 수 없습니다: {error}'**
  String chatImagePickFailed(Object error);

  /// No description provided for @chatCameraImageUnavailable.
  ///
  /// In ko, this message translates to:
  /// **'촬영한 이미지를 사용할 수 없습니다. 파일 선택을 이용해 주세요.'**
  String get chatCameraImageUnavailable;

  /// No description provided for @chatCameraFailed.
  ///
  /// In ko, this message translates to:
  /// **'카메라를 사용할 수 없습니다: {error}'**
  String chatCameraFailed(Object error);

  /// No description provided for @chatFilePickFailed.
  ///
  /// In ko, this message translates to:
  /// **'파일을 선택할 수 없습니다: {error}'**
  String chatFilePickFailed(Object error);

  /// No description provided for @chatFileUploading.
  ///
  /// In ko, this message translates to:
  /// **'파일 업로드 중...'**
  String get chatFileUploading;

  /// No description provided for @chatOtherUserLeft.
  ///
  /// In ko, this message translates to:
  /// **'{nickname}님이 채팅방을 나갔습니다'**
  String chatOtherUserLeft(Object nickname);

  /// No description provided for @chatOtherUserInfoNotFound.
  ///
  /// In ko, this message translates to:
  /// **'상대방 정보를 찾을 수 없습니다'**
  String get chatOtherUserInfoNotFound;

  /// No description provided for @chatReinviting.
  ///
  /// In ko, this message translates to:
  /// **'초대 중...'**
  String get chatReinviting;

  /// No description provided for @chatReinvite.
  ///
  /// In ko, this message translates to:
  /// **'다시 초대하기'**
  String get chatReinvite;

  /// No description provided for @chatKeyboard.
  ///
  /// In ko, this message translates to:
  /// **'키보드'**
  String get chatKeyboard;

  /// No description provided for @chatEmoji.
  ///
  /// In ko, this message translates to:
  /// **'이모지'**
  String get chatEmoji;

  /// No description provided for @chatAttach.
  ///
  /// In ko, this message translates to:
  /// **'첨부'**
  String get chatAttach;

  /// No description provided for @chatEmojiSearch.
  ///
  /// In ko, this message translates to:
  /// **'이모지 검색'**
  String get chatEmojiSearch;

  /// No description provided for @chatNoMessages.
  ///
  /// In ko, this message translates to:
  /// **'메시지가 없습니다'**
  String get chatNoMessages;

  /// No description provided for @chatStartConversation.
  ///
  /// In ko, this message translates to:
  /// **'대화를 시작해보세요'**
  String get chatStartConversation;

  /// No description provided for @chatVideoPlaybackFailed.
  ///
  /// In ko, this message translates to:
  /// **'비디오를 재생할 수 없습니다'**
  String get chatVideoPlaybackFailed;

  /// No description provided for @commonCancel.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get commonCancel;

  /// No description provided for @commonDelete.
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get commonDelete;

  /// No description provided for @commonEdit.
  ///
  /// In ko, this message translates to:
  /// **'수정'**
  String get commonEdit;

  /// No description provided for @commonRetry.
  ///
  /// In ko, this message translates to:
  /// **'다시 시도'**
  String get commonRetry;

  /// No description provided for @friendsTitle.
  ///
  /// In ko, this message translates to:
  /// **'친구'**
  String get friendsTitle;

  /// No description provided for @friendsAdd.
  ///
  /// In ko, this message translates to:
  /// **'친구 추가'**
  String get friendsAdd;

  /// No description provided for @friendsAddShort.
  ///
  /// In ko, this message translates to:
  /// **'추가'**
  String get friendsAddShort;

  /// No description provided for @friendsManage.
  ///
  /// In ko, this message translates to:
  /// **'친구 관리'**
  String get friendsManage;

  /// No description provided for @friendsCount.
  ///
  /// In ko, this message translates to:
  /// **'친구 {count}명'**
  String friendsCount(Object count);

  /// No description provided for @friendsListLoadError.
  ///
  /// In ko, this message translates to:
  /// **'친구 목록을 불러오는데 실패했습니다'**
  String get friendsListLoadError;

  /// No description provided for @friendsEmptyTitle.
  ///
  /// In ko, this message translates to:
  /// **'친구가 없습니다'**
  String get friendsEmptyTitle;

  /// No description provided for @friendsEmptyDesc.
  ///
  /// In ko, this message translates to:
  /// **'친구를 추가하고 대화를 시작해보세요'**
  String get friendsEmptyDesc;

  /// No description provided for @friendsHide.
  ///
  /// In ko, this message translates to:
  /// **'숨김'**
  String get friendsHide;

  /// No description provided for @friendsBlock.
  ///
  /// In ko, this message translates to:
  /// **'차단'**
  String get friendsBlock;

  /// No description provided for @friendsHideTitle.
  ///
  /// In ko, this message translates to:
  /// **'친구 숨김'**
  String get friendsHideTitle;

  /// No description provided for @friendsHideConfirm.
  ///
  /// In ko, this message translates to:
  /// **'{name}님을 숨기시겠습니까?\n친구 관리에서 다시 볼 수 있습니다.'**
  String friendsHideConfirm(Object name);

  /// No description provided for @friendsHideSuccess.
  ///
  /// In ko, this message translates to:
  /// **'친구를 숨김 처리했습니다'**
  String get friendsHideSuccess;

  /// No description provided for @friendsBlockTitle.
  ///
  /// In ko, this message translates to:
  /// **'친구 차단'**
  String get friendsBlockTitle;

  /// No description provided for @friendsBlockConfirm.
  ///
  /// In ko, this message translates to:
  /// **'{name}님을 차단하시겠습니까?'**
  String friendsBlockConfirm(Object name);

  /// No description provided for @friendsBlockSuccess.
  ///
  /// In ko, this message translates to:
  /// **'친구를 차단했습니다'**
  String get friendsBlockSuccess;

  /// No description provided for @friendsDeleteTitle.
  ///
  /// In ko, this message translates to:
  /// **'친구 삭제'**
  String get friendsDeleteTitle;

  /// No description provided for @friendsDeleteSuccess.
  ///
  /// In ko, this message translates to:
  /// **'친구를 삭제했습니다'**
  String get friendsDeleteSuccess;

  /// No description provided for @friendsDeleteConfirm.
  ///
  /// In ko, this message translates to:
  /// **'{name}님을 친구에서 삭제하시겠습니까?'**
  String friendsDeleteConfirm(Object name);

  /// No description provided for @friendsSearchHint.
  ///
  /// In ko, this message translates to:
  /// **'닉네임으로 검색'**
  String get friendsSearchHint;

  /// No description provided for @friendsSearchPrompt.
  ///
  /// In ko, this message translates to:
  /// **'닉네임을 입력하여 검색하세요'**
  String get friendsSearchPrompt;

  /// No description provided for @friendsSearchError.
  ///
  /// In ko, this message translates to:
  /// **'검색 중 오류가 발생했습니다'**
  String get friendsSearchError;

  /// No description provided for @friendsSearchNoResults.
  ///
  /// In ko, this message translates to:
  /// **'검색 결과가 없습니다'**
  String get friendsSearchNoResults;

  /// No description provided for @friendsSearchNoResultsFor.
  ///
  /// In ko, this message translates to:
  /// **'\"{query}\"에 대한 결과가 없습니다'**
  String friendsSearchNoResultsFor(Object query);

  /// No description provided for @friendsRequestSent.
  ///
  /// In ko, this message translates to:
  /// **'친구 요청을 보냈습니다'**
  String get friendsRequestSent;

  /// No description provided for @friendSettingsTitle.
  ///
  /// In ko, this message translates to:
  /// **'친구 관리'**
  String get friendSettingsTitle;

  /// No description provided for @friendSettingsRequestSection.
  ///
  /// In ko, this message translates to:
  /// **'친구 요청'**
  String get friendSettingsRequestSection;

  /// No description provided for @friendSettingsReceivedRequests.
  ///
  /// In ko, this message translates to:
  /// **'받은 친구 요청'**
  String get friendSettingsReceivedRequests;

  /// No description provided for @friendSettingsReceivedRequestsDesc.
  ///
  /// In ko, this message translates to:
  /// **'수락 대기 중인 요청을 확인하세요'**
  String get friendSettingsReceivedRequestsDesc;

  /// No description provided for @friendSettingsSentRequests.
  ///
  /// In ko, this message translates to:
  /// **'보낸 친구 요청'**
  String get friendSettingsSentRequests;

  /// No description provided for @friendSettingsSentRequestsDesc.
  ///
  /// In ko, this message translates to:
  /// **'보낸 요청을 확인하세요'**
  String get friendSettingsSentRequestsDesc;

  /// No description provided for @friendSettingsManageSection.
  ///
  /// In ko, this message translates to:
  /// **'친구 관리'**
  String get friendSettingsManageSection;

  /// No description provided for @friendSettingsHiddenFriends.
  ///
  /// In ko, this message translates to:
  /// **'숨김 친구 관리'**
  String get friendSettingsHiddenFriends;

  /// No description provided for @friendSettingsHiddenFriendsDesc.
  ///
  /// In ko, this message translates to:
  /// **'숨긴 친구를 확인하세요'**
  String get friendSettingsHiddenFriendsDesc;

  /// No description provided for @friendSettingsBlockedUsers.
  ///
  /// In ko, this message translates to:
  /// **'차단 사용자 관리'**
  String get friendSettingsBlockedUsers;

  /// No description provided for @friendSettingsBlockedUsersDesc.
  ///
  /// In ko, this message translates to:
  /// **'차단한 사용자를 관리하세요'**
  String get friendSettingsBlockedUsersDesc;

  /// No description provided for @friendsHiddenTitle.
  ///
  /// In ko, this message translates to:
  /// **'숨김 친구'**
  String get friendsHiddenTitle;

  /// No description provided for @friendsHiddenLoadError.
  ///
  /// In ko, this message translates to:
  /// **'숨김 친구 목록을 불러오는데 실패했습니다'**
  String get friendsHiddenLoadError;

  /// No description provided for @friendsHiddenEmptyTitle.
  ///
  /// In ko, this message translates to:
  /// **'숨긴 친구가 없습니다'**
  String get friendsHiddenEmptyTitle;

  /// No description provided for @friendsHiddenEmptyDesc.
  ///
  /// In ko, this message translates to:
  /// **'친구 목록에서 숨긴 친구가 여기에 표시됩니다'**
  String get friendsHiddenEmptyDesc;

  /// No description provided for @friendsUnhide.
  ///
  /// In ko, this message translates to:
  /// **'숨김 해제'**
  String get friendsUnhide;

  /// No description provided for @friendsUnhideSuccess.
  ///
  /// In ko, this message translates to:
  /// **'{name}님을 숨김 해제했습니다'**
  String friendsUnhideSuccess(Object name);

  /// No description provided for @friendsBlockedTitle.
  ///
  /// In ko, this message translates to:
  /// **'차단 사용자'**
  String get friendsBlockedTitle;

  /// No description provided for @friendsBlockedLoadError.
  ///
  /// In ko, this message translates to:
  /// **'차단 목록을 불러오는데 실패했습니다'**
  String get friendsBlockedLoadError;

  /// No description provided for @friendsBlockedEmptyTitle.
  ///
  /// In ko, this message translates to:
  /// **'차단한 사용자가 없습니다'**
  String get friendsBlockedEmptyTitle;

  /// No description provided for @friendsBlockedEmptyDesc.
  ///
  /// In ko, this message translates to:
  /// **'차단한 사용자가 여기에 표시됩니다'**
  String get friendsBlockedEmptyDesc;

  /// No description provided for @friendsUnblock.
  ///
  /// In ko, this message translates to:
  /// **'차단 해제'**
  String get friendsUnblock;

  /// No description provided for @friendsUnblockConfirm.
  ///
  /// In ko, this message translates to:
  /// **'{name}님의 차단을 해제하시겠습니까?'**
  String friendsUnblockConfirm(Object name);

  /// No description provided for @friendsUnblockSuccess.
  ///
  /// In ko, this message translates to:
  /// **'{name}님의 차단을 해제했습니다'**
  String friendsUnblockSuccess(Object name);

  /// No description provided for @friendsReceivedTitle.
  ///
  /// In ko, this message translates to:
  /// **'받은 친구 요청'**
  String get friendsReceivedTitle;

  /// No description provided for @friendsReceivedLoadError.
  ///
  /// In ko, this message translates to:
  /// **'받은 친구 요청을 불러오는데 실패했습니다'**
  String get friendsReceivedLoadError;

  /// No description provided for @friendsReceivedEmptyTitle.
  ///
  /// In ko, this message translates to:
  /// **'받은 친구 요청이 없습니다'**
  String get friendsReceivedEmptyTitle;

  /// No description provided for @friendsReceivedEmptyDesc.
  ///
  /// In ko, this message translates to:
  /// **'다른 사용자가 친구 요청을 보내면 여기에 표시됩니다'**
  String get friendsReceivedEmptyDesc;

  /// No description provided for @friendsReject.
  ///
  /// In ko, this message translates to:
  /// **'거절'**
  String get friendsReject;

  /// No description provided for @friendsAccept.
  ///
  /// In ko, this message translates to:
  /// **'수락'**
  String get friendsAccept;

  /// No description provided for @friendsSentTitle.
  ///
  /// In ko, this message translates to:
  /// **'보낸 친구 요청'**
  String get friendsSentTitle;

  /// No description provided for @friendsSentLoadError.
  ///
  /// In ko, this message translates to:
  /// **'보낸 친구 요청을 불러오는데 실패했습니다'**
  String get friendsSentLoadError;

  /// No description provided for @friendsSentEmptyTitle.
  ///
  /// In ko, this message translates to:
  /// **'보낸 친구 요청이 없습니다'**
  String get friendsSentEmptyTitle;

  /// No description provided for @friendsSentEmptyDesc.
  ///
  /// In ko, this message translates to:
  /// **'친구를 검색하여 요청을 보내보세요'**
  String get friendsSentEmptyDesc;

  /// No description provided for @friendsSentPending.
  ///
  /// In ko, this message translates to:
  /// **'대기 중'**
  String get friendsSentPending;

  /// No description provided for @mainTabFriends.
  ///
  /// In ko, this message translates to:
  /// **'친구'**
  String get mainTabFriends;

  /// No description provided for @mainTabChat.
  ///
  /// In ko, this message translates to:
  /// **'채팅'**
  String get mainTabChat;

  /// No description provided for @appLockPrompt.
  ///
  /// In ko, this message translates to:
  /// **'잠금을 해제하려면 인증해주세요'**
  String get appLockPrompt;

  /// No description provided for @appLockAuthenticate.
  ///
  /// In ko, this message translates to:
  /// **'인증하기'**
  String get appLockAuthenticate;

  /// No description provided for @reportSubmitted.
  ///
  /// In ko, this message translates to:
  /// **'신고가 접수되었습니다'**
  String get reportSubmitted;

  /// No description provided for @reportSubmitFailed.
  ///
  /// In ko, this message translates to:
  /// **'신고 접수에 실패했습니다: {error}'**
  String reportSubmitFailed(Object error);

  /// No description provided for @reportTargetUser.
  ///
  /// In ko, this message translates to:
  /// **'사용자'**
  String get reportTargetUser;

  /// No description provided for @reportTargetMessage.
  ///
  /// In ko, this message translates to:
  /// **'메시지'**
  String get reportTargetMessage;

  /// No description provided for @reportTitle.
  ///
  /// In ko, this message translates to:
  /// **'{target} 신고'**
  String reportTitle(Object target);

  /// No description provided for @reportSelectReason.
  ///
  /// In ko, this message translates to:
  /// **'신고 사유를 선택해주세요'**
  String get reportSelectReason;

  /// No description provided for @reportDescriptionLabel.
  ///
  /// In ko, this message translates to:
  /// **'상세 설명 (선택)'**
  String get reportDescriptionLabel;

  /// No description provided for @reportDescriptionHint.
  ///
  /// In ko, this message translates to:
  /// **'추가 설명을 입력해주세요'**
  String get reportDescriptionHint;

  /// No description provided for @reportSubmit.
  ///
  /// In ko, this message translates to:
  /// **'신고하기'**
  String get reportSubmit;

  /// No description provided for @errorTitle.
  ///
  /// In ko, this message translates to:
  /// **'오류'**
  String get errorTitle;

  /// No description provided for @errorPageLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'페이지를 불러올 수 없습니다'**
  String get errorPageLoadFailed;

  /// No description provided for @errorGoHome.
  ///
  /// In ko, this message translates to:
  /// **'홈으로 돌아가기'**
  String get errorGoHome;

  /// No description provided for @imageEditorProcessing.
  ///
  /// In ko, this message translates to:
  /// **'처리 중...'**
  String get imageEditorProcessing;

  /// No description provided for @imageEditorCloseWarningTitle.
  ///
  /// In ko, this message translates to:
  /// **'편집 취소'**
  String get imageEditorCloseWarningTitle;

  /// No description provided for @imageEditorCloseWarningMessage.
  ///
  /// In ko, this message translates to:
  /// **'편집 내용을 취소하시겠습니까?'**
  String get imageEditorCloseWarningMessage;

  /// No description provided for @imageEditorContinueEditing.
  ///
  /// In ko, this message translates to:
  /// **'계속 편집'**
  String get imageEditorContinueEditing;

  /// No description provided for @imageEditorPaint.
  ///
  /// In ko, this message translates to:
  /// **'그리기'**
  String get imageEditorPaint;

  /// No description provided for @imageEditorFreestyle.
  ///
  /// In ko, this message translates to:
  /// **'자유'**
  String get imageEditorFreestyle;

  /// No description provided for @imageEditorArrow.
  ///
  /// In ko, this message translates to:
  /// **'화살표'**
  String get imageEditorArrow;

  /// No description provided for @imageEditorLine.
  ///
  /// In ko, this message translates to:
  /// **'직선'**
  String get imageEditorLine;

  /// No description provided for @imageEditorRectangle.
  ///
  /// In ko, this message translates to:
  /// **'사각형'**
  String get imageEditorRectangle;

  /// No description provided for @imageEditorCircle.
  ///
  /// In ko, this message translates to:
  /// **'원'**
  String get imageEditorCircle;

  /// No description provided for @imageEditorDashLine.
  ///
  /// In ko, this message translates to:
  /// **'점선'**
  String get imageEditorDashLine;

  /// No description provided for @imageEditorLineWidth.
  ///
  /// In ko, this message translates to:
  /// **'두께'**
  String get imageEditorLineWidth;

  /// No description provided for @imageEditorToggleFill.
  ///
  /// In ko, this message translates to:
  /// **'채우기'**
  String get imageEditorToggleFill;

  /// No description provided for @imageEditorUndo.
  ///
  /// In ko, this message translates to:
  /// **'실행 취소'**
  String get imageEditorUndo;

  /// No description provided for @imageEditorRedo.
  ///
  /// In ko, this message translates to:
  /// **'다시 실행'**
  String get imageEditorRedo;

  /// No description provided for @imageEditorDone.
  ///
  /// In ko, this message translates to:
  /// **'완료'**
  String get imageEditorDone;

  /// No description provided for @imageEditorBack.
  ///
  /// In ko, this message translates to:
  /// **'뒤로'**
  String get imageEditorBack;

  /// No description provided for @imageEditorTextInputHint.
  ///
  /// In ko, this message translates to:
  /// **'텍스트 입력'**
  String get imageEditorTextInputHint;

  /// No description provided for @imageEditorText.
  ///
  /// In ko, this message translates to:
  /// **'텍스트'**
  String get imageEditorText;

  /// No description provided for @imageEditorCrop.
  ///
  /// In ko, this message translates to:
  /// **'자르기'**
  String get imageEditorCrop;

  /// No description provided for @imageEditorRotate.
  ///
  /// In ko, this message translates to:
  /// **'회전'**
  String get imageEditorRotate;

  /// No description provided for @imageEditorFlip.
  ///
  /// In ko, this message translates to:
  /// **'뒤집기'**
  String get imageEditorFlip;

  /// No description provided for @imageEditorRatio.
  ///
  /// In ko, this message translates to:
  /// **'비율'**
  String get imageEditorRatio;

  /// No description provided for @imageEditorReset.
  ///
  /// In ko, this message translates to:
  /// **'초기화'**
  String get imageEditorReset;

  /// No description provided for @imageEditorFilter.
  ///
  /// In ko, this message translates to:
  /// **'필터'**
  String get imageEditorFilter;

  /// No description provided for @imageEditorEmoji.
  ///
  /// In ko, this message translates to:
  /// **'이모지'**
  String get imageEditorEmoji;

  /// No description provided for @imageEditorSaving.
  ///
  /// In ko, this message translates to:
  /// **'저장 중...'**
  String get imageEditorSaving;

  /// No description provided for @widgetConnectionFailed.
  ///
  /// In ko, this message translates to:
  /// **'연결 실패 - 재시도가 중단되었습니다'**
  String get widgetConnectionFailed;

  /// No description provided for @widgetConnectionLost.
  ///
  /// In ko, this message translates to:
  /// **'연결이 끊어졌습니다'**
  String get widgetConnectionLost;

  /// No description provided for @widgetReconnect.
  ///
  /// In ko, this message translates to:
  /// **'재연결'**
  String get widgetReconnect;

  /// No description provided for @widgetCannotOpenUrl.
  ///
  /// In ko, this message translates to:
  /// **'URL을 열 수 없습니다: {url}'**
  String widgetCannotOpenUrl(Object url);

  /// No description provided for @widgetMessageSearchHint.
  ///
  /// In ko, this message translates to:
  /// **'메시지 검색'**
  String get widgetMessageSearchHint;

  /// No description provided for @widgetSearchError.
  ///
  /// In ko, this message translates to:
  /// **'검색 중 오류가 발생했습니다'**
  String get widgetSearchError;

  /// No description provided for @widgetSearchNoResults.
  ///
  /// In ko, this message translates to:
  /// **'검색 결과가 없습니다'**
  String get widgetSearchNoResults;

  /// No description provided for @widgetSearchPrompt.
  ///
  /// In ko, this message translates to:
  /// **'검색어를 입력하세요'**
  String get widgetSearchPrompt;

  /// No description provided for @widgetUnknownSender.
  ///
  /// In ko, this message translates to:
  /// **'알 수 없음'**
  String get widgetUnknownSender;

  /// No description provided for @profileTitle.
  ///
  /// In ko, this message translates to:
  /// **'프로필'**
  String get profileTitle;

  /// No description provided for @profileEditTitle.
  ///
  /// In ko, this message translates to:
  /// **'프로필 편집'**
  String get profileEditTitle;

  /// No description provided for @profileStatusLabel.
  ///
  /// In ko, this message translates to:
  /// **'상태'**
  String get profileStatusLabel;

  /// No description provided for @profileOnlineStatusLabel.
  ///
  /// In ko, this message translates to:
  /// **'온라인 상태'**
  String get profileOnlineStatusLabel;

  /// No description provided for @profileJoinDateLabel.
  ///
  /// In ko, this message translates to:
  /// **'가입일'**
  String get profileJoinDateLabel;

  /// No description provided for @profileStatusActive.
  ///
  /// In ko, this message translates to:
  /// **'활성'**
  String get profileStatusActive;

  /// No description provided for @profileStatusInactive.
  ///
  /// In ko, this message translates to:
  /// **'비활성'**
  String get profileStatusInactive;

  /// No description provided for @profileStatusSuspended.
  ///
  /// In ko, this message translates to:
  /// **'정지됨'**
  String get profileStatusSuspended;

  /// No description provided for @profileStatusUnknown.
  ///
  /// In ko, this message translates to:
  /// **'알 수 없음'**
  String get profileStatusUnknown;

  /// No description provided for @profileOnlineStatusOnline.
  ///
  /// In ko, this message translates to:
  /// **'온라인'**
  String get profileOnlineStatusOnline;

  /// No description provided for @profileOnlineStatusAway.
  ///
  /// In ko, this message translates to:
  /// **'자리 비움'**
  String get profileOnlineStatusAway;

  /// No description provided for @profileOnlineStatusOffline.
  ///
  /// In ko, this message translates to:
  /// **'오프라인'**
  String get profileOnlineStatusOffline;

  /// No description provided for @profileFilePickFailed.
  ///
  /// In ko, this message translates to:
  /// **'파일을 선택할 수 없습니다: {error}'**
  String profileFilePickFailed(Object error);

  /// No description provided for @profileCameraUnavailable.
  ///
  /// In ko, this message translates to:
  /// **'카메라를 사용할 수 없습니다'**
  String get profileCameraUnavailable;

  /// No description provided for @profileGalleryUnavailable.
  ///
  /// In ko, this message translates to:
  /// **'앨범에 접근할 수 없습니다'**
  String get profileGalleryUnavailable;

  /// No description provided for @profileImageFileNotFound.
  ///
  /// In ko, this message translates to:
  /// **'선택한 이미지 파일을 찾을 수 없습니다.'**
  String get profileImageFileNotFound;

  /// No description provided for @profileImageEditUnavailable.
  ///
  /// In ko, this message translates to:
  /// **'이미지 편집을 사용할 수 없습니다: {error}'**
  String profileImageEditUnavailable(Object error);

  /// No description provided for @profileAvatarDeleted.
  ///
  /// In ko, this message translates to:
  /// **'프로필 사진이 삭제되었습니다'**
  String get profileAvatarDeleted;

  /// No description provided for @profileUpdated.
  ///
  /// In ko, this message translates to:
  /// **'프로필이 수정되었습니다'**
  String get profileUpdated;

  /// No description provided for @profileUpdateFailed.
  ///
  /// In ko, this message translates to:
  /// **'프로필 수정에 실패했습니다'**
  String get profileUpdateFailed;

  /// No description provided for @profileUpdateSuccess.
  ///
  /// In ko, this message translates to:
  /// **'프로필이 업데이트되었습니다.'**
  String get profileUpdateSuccess;

  /// No description provided for @profileSetPrivateSuccess.
  ///
  /// In ko, this message translates to:
  /// **'나만보기로 설정되었습니다.'**
  String get profileSetPrivateSuccess;

  /// No description provided for @profileSetPublicSuccess.
  ///
  /// In ko, this message translates to:
  /// **'공개로 설정되었습니다.'**
  String get profileSetPublicSuccess;

  /// No description provided for @profileHistoryDeleteSuccess.
  ///
  /// In ko, this message translates to:
  /// **'프로필 이력이 삭제되었습니다.'**
  String get profileHistoryDeleteSuccess;

  /// No description provided for @profileSetCurrentSuccess.
  ///
  /// In ko, this message translates to:
  /// **'현재 프로필로 설정되었습니다.'**
  String get profileSetCurrentSuccess;

  /// No description provided for @profileBackgroundChanged.
  ///
  /// In ko, this message translates to:
  /// **'배경이 변경되었습니다'**
  String get profileBackgroundChanged;

  /// No description provided for @profileAvatarChanged.
  ///
  /// In ko, this message translates to:
  /// **'프로필 사진이 변경되었습니다'**
  String get profileAvatarChanged;

  /// No description provided for @profileImageChangeFailed.
  ///
  /// In ko, this message translates to:
  /// **'이미지 변경에 실패했습니다'**
  String get profileImageChangeFailed;

  /// No description provided for @profileSaveButton.
  ///
  /// In ko, this message translates to:
  /// **'저장하기'**
  String get profileSaveButton;

  /// No description provided for @profileNoChanges.
  ///
  /// In ko, this message translates to:
  /// **'변경사항 없음'**
  String get profileNoChanges;

  /// No description provided for @profileLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'프로필을 불러올 수 없습니다'**
  String get profileLoadFailed;

  /// No description provided for @profileStatusMessage.
  ///
  /// In ko, this message translates to:
  /// **'상태메시지'**
  String get profileStatusMessage;

  /// No description provided for @profileStatusMessageHint.
  ///
  /// In ko, this message translates to:
  /// **'상태메시지를 입력하세요'**
  String get profileStatusMessageHint;

  /// No description provided for @profileBackground.
  ///
  /// In ko, this message translates to:
  /// **'배경화면'**
  String get profileBackground;

  /// No description provided for @profileAvatar.
  ///
  /// In ko, this message translates to:
  /// **'프로필 사진'**
  String get profileAvatar;

  /// No description provided for @profileViewFullScreen.
  ///
  /// In ko, this message translates to:
  /// **'전체 화면 보기'**
  String get profileViewFullScreen;

  /// No description provided for @profileBackgroundChange.
  ///
  /// In ko, this message translates to:
  /// **'배경화면 변경'**
  String get profileBackgroundChange;

  /// No description provided for @profileBackgroundChangeSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'앨범에서 새 배경 선택'**
  String get profileBackgroundChangeSubtitle;

  /// No description provided for @profileBackgroundHistory.
  ///
  /// In ko, this message translates to:
  /// **'배경화면 이력'**
  String get profileBackgroundHistory;

  /// No description provided for @profileBackgroundHistorySubtitle.
  ///
  /// In ko, this message translates to:
  /// **'이전 배경화면 보기'**
  String get profileBackgroundHistorySubtitle;

  /// No description provided for @profileAvatarChange.
  ///
  /// In ko, this message translates to:
  /// **'프로필 사진 변경'**
  String get profileAvatarChange;

  /// No description provided for @profileAvatarChangeSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'앨범에서 새 사진 선택'**
  String get profileAvatarChangeSubtitle;

  /// No description provided for @profileAvatarHistory.
  ///
  /// In ko, this message translates to:
  /// **'프로필 사진 이력'**
  String get profileAvatarHistory;

  /// No description provided for @profileAvatarHistorySubtitle.
  ///
  /// In ko, this message translates to:
  /// **'이전 프로필 사진 보기'**
  String get profileAvatarHistorySubtitle;

  /// No description provided for @profileMakePublic.
  ///
  /// In ko, this message translates to:
  /// **'전체 공개로 변경'**
  String get profileMakePublic;

  /// No description provided for @profileMakePrivate.
  ///
  /// In ko, this message translates to:
  /// **'나만 보기'**
  String get profileMakePrivate;

  /// No description provided for @profilePublicDescription.
  ///
  /// In ko, this message translates to:
  /// **'다른 사람에게 공개됩니다'**
  String get profilePublicDescription;

  /// No description provided for @profilePrivateDescription.
  ///
  /// In ko, this message translates to:
  /// **'나만 볼 수 있습니다'**
  String get profilePrivateDescription;

  /// No description provided for @profileDeleteItemTitle.
  ///
  /// In ko, this message translates to:
  /// **'{item} 삭제'**
  String profileDeleteItemTitle(Object item);

  /// No description provided for @profileDeleteItemConfirm.
  ///
  /// In ko, this message translates to:
  /// **'{item}을(를) 삭제하시겠습니까?'**
  String profileDeleteItemConfirm(Object item);

  /// No description provided for @profileImagePickFailed.
  ///
  /// In ko, this message translates to:
  /// **'이미지를 선택할 수 없습니다'**
  String get profileImagePickFailed;

  /// No description provided for @profileAddStatusMessage.
  ///
  /// In ko, this message translates to:
  /// **'상태메시지 추가'**
  String get profileAddStatusMessage;

  /// No description provided for @profileDirectChat.
  ///
  /// In ko, this message translates to:
  /// **'1:1 채팅'**
  String get profileDirectChat;

  /// No description provided for @profileReport.
  ///
  /// In ko, this message translates to:
  /// **'신고'**
  String get profileReport;

  /// No description provided for @profileSelfChat.
  ///
  /// In ko, this message translates to:
  /// **'나와의 채팅'**
  String get profileSelfChat;

  /// No description provided for @profileEditAction.
  ///
  /// In ko, this message translates to:
  /// **'프로필 편집'**
  String get profileEditAction;

  /// No description provided for @profileLoginInfoNotFound.
  ///
  /// In ko, this message translates to:
  /// **'로그인 정보를 찾을 수 없습니다'**
  String get profileLoginInfoNotFound;

  /// No description provided for @profileHistoryEmpty.
  ///
  /// In ko, this message translates to:
  /// **'아직 {type} 이력이 없습니다'**
  String profileHistoryEmpty(Object type);

  /// No description provided for @profileAddAvatar.
  ///
  /// In ko, this message translates to:
  /// **'사진 추가하기'**
  String get profileAddAvatar;

  /// No description provided for @profileAddBackground.
  ///
  /// In ko, this message translates to:
  /// **'배경 추가하기'**
  String get profileAddBackground;

  /// No description provided for @profileMore.
  ///
  /// In ko, this message translates to:
  /// **'더보기'**
  String get profileMore;

  /// No description provided for @profileBadgeCurrent.
  ///
  /// In ko, this message translates to:
  /// **'현재'**
  String get profileBadgeCurrent;

  /// No description provided for @profileBadgePrivate.
  ///
  /// In ko, this message translates to:
  /// **'나만보기'**
  String get profileBadgePrivate;

  /// No description provided for @profileNickname.
  ///
  /// In ko, this message translates to:
  /// **'닉네임'**
  String get profileNickname;

  /// No description provided for @profileNicknameHint.
  ///
  /// In ko, this message translates to:
  /// **'닉네임을 입력하세요'**
  String get profileNicknameHint;

  /// No description provided for @profileStatusMessageOptionalHint.
  ///
  /// In ko, this message translates to:
  /// **'상태메시지를 입력하세요 (선택)'**
  String get profileStatusMessageOptionalHint;

  /// No description provided for @profileAccountInfo.
  ///
  /// In ko, this message translates to:
  /// **'계정 정보'**
  String get profileAccountInfo;

  /// No description provided for @profileEmail.
  ///
  /// In ko, this message translates to:
  /// **'이메일'**
  String get profileEmail;

  /// No description provided for @profileNotEditable.
  ///
  /// In ko, this message translates to:
  /// **'수정불가'**
  String get profileNotEditable;

  /// No description provided for @profileBackgroundChangeShort.
  ///
  /// In ko, this message translates to:
  /// **'배경 변경'**
  String get profileBackgroundChangeShort;

  /// No description provided for @profileBackgroundHistoryShort.
  ///
  /// In ko, this message translates to:
  /// **'배경 이력'**
  String get profileBackgroundHistoryShort;

  /// No description provided for @profileChangePhoto.
  ///
  /// In ko, this message translates to:
  /// **'사진 변경'**
  String get profileChangePhoto;

  /// No description provided for @profileSetAsCurrent.
  ///
  /// In ko, this message translates to:
  /// **'현재 프로필로 설정'**
  String get profileSetAsCurrent;

  /// No description provided for @profileMakePublicShort.
  ///
  /// In ko, this message translates to:
  /// **'공개로 변경'**
  String get profileMakePublicShort;

  /// No description provided for @profileDeleteConfirmTitle.
  ///
  /// In ko, this message translates to:
  /// **'삭제 확인'**
  String get profileDeleteConfirmTitle;

  /// No description provided for @profileDeleteCurrentWarning.
  ///
  /// In ko, this message translates to:
  /// **'현재 프로필로 사용 중입니다.\n삭제하면 이전 이력으로 변경됩니다.'**
  String get profileDeleteCurrentWarning;

  /// No description provided for @profileDeleteHistoryConfirm.
  ///
  /// In ko, this message translates to:
  /// **'이 이력을 삭제하시겠습니까?'**
  String get profileDeleteHistoryConfirm;

  /// No description provided for @profileTakePhoto.
  ///
  /// In ko, this message translates to:
  /// **'카메라로 촬영'**
  String get profileTakePhoto;

  /// No description provided for @profileTakePhotoSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'새 사진 찍기'**
  String get profileTakePhotoSubtitle;

  /// No description provided for @profileSelectFromAlbum.
  ///
  /// In ko, this message translates to:
  /// **'앨범에서 선택'**
  String get profileSelectFromAlbum;

  /// No description provided for @profileSelectFromAlbumSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'저장된 사진 선택'**
  String get profileSelectFromAlbumSubtitle;

  /// No description provided for @profileSelectFromExisting.
  ///
  /// In ko, this message translates to:
  /// **'기존 프로필에서 선택'**
  String get profileSelectFromExisting;

  /// No description provided for @profileSelectFromExistingSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'이전에 사용한 사진 선택'**
  String get profileSelectFromExistingSubtitle;

  /// No description provided for @profileResetToDefault.
  ///
  /// In ko, this message translates to:
  /// **'기본 이미지로 변경'**
  String get profileResetToDefault;

  /// No description provided for @profileResetToDefaultSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'현재 프로필 사진 삭제'**
  String get profileResetToDefaultSubtitle;

  /// No description provided for @profileSelectFromFile.
  ///
  /// In ko, this message translates to:
  /// **'파일에서 선택'**
  String get profileSelectFromFile;

  /// No description provided for @profileSelectFromFileSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'이미지 파일을 선택합니다'**
  String get profileSelectFromFileSubtitle;

  /// No description provided for @profileSelectFromBackgroundHistory.
  ///
  /// In ko, this message translates to:
  /// **'배경 이력에서 선택'**
  String get profileSelectFromBackgroundHistory;

  /// No description provided for @profileSelectBackgroundFileSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'배경 이미지 파일을 선택합니다'**
  String get profileSelectBackgroundFileSubtitle;

  /// No description provided for @profileAvatarDeleteTitle.
  ///
  /// In ko, this message translates to:
  /// **'프로필 사진 삭제'**
  String get profileAvatarDeleteTitle;

  /// No description provided for @profileAvatarDeleteConfirm.
  ///
  /// In ko, this message translates to:
  /// **'프로필 사진을 삭제하고 기본 이미지로 변경하시겠습니까?'**
  String get profileAvatarDeleteConfirm;

  /// No description provided for @profileNicknameRequired.
  ///
  /// In ko, this message translates to:
  /// **'닉네임을 입력해주세요'**
  String get profileNicknameRequired;

  /// No description provided for @profileNicknameTooShort.
  ///
  /// In ko, this message translates to:
  /// **'닉네임은 2자 이상이어야 합니다'**
  String get profileNicknameTooShort;

  /// No description provided for @profileNicknameTooLong.
  ///
  /// In ko, this message translates to:
  /// **'닉네임은 20자 이하여야 합니다'**
  String get profileNicknameTooLong;

  /// No description provided for @profileStatusMessageTooLong.
  ///
  /// In ko, this message translates to:
  /// **'상태메시지는 60자 이하여야 합니다'**
  String get profileStatusMessageTooLong;

  /// No description provided for @commonSave.
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get commonSave;

  /// No description provided for @settingsTitle.
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get settingsTitle;

  /// No description provided for @settingsProfile.
  ///
  /// In ko, this message translates to:
  /// **'프로필'**
  String get settingsProfile;

  /// No description provided for @settingsMyProfile.
  ///
  /// In ko, this message translates to:
  /// **'내 프로필'**
  String get settingsMyProfile;

  /// No description provided for @settingsNotification.
  ///
  /// In ko, this message translates to:
  /// **'알림'**
  String get settingsNotification;

  /// No description provided for @settingsNotificationSettings.
  ///
  /// In ko, this message translates to:
  /// **'알림 설정'**
  String get settingsNotificationSettings;

  /// No description provided for @settingsNotificationDesc.
  ///
  /// In ko, this message translates to:
  /// **'메시지, 친구 요청, 그룹 초대 알림'**
  String get settingsNotificationDesc;

  /// No description provided for @settingsChat.
  ///
  /// In ko, this message translates to:
  /// **'채팅'**
  String get settingsChat;

  /// No description provided for @settingsChatSettings.
  ///
  /// In ko, this message translates to:
  /// **'채팅 설정'**
  String get settingsChatSettings;

  /// No description provided for @settingsChatDesc.
  ///
  /// In ko, this message translates to:
  /// **'글꼴 크기, 미디어 자동 다운로드'**
  String get settingsChatDesc;

  /// No description provided for @settingsFriends.
  ///
  /// In ko, this message translates to:
  /// **'친구'**
  String get settingsFriends;

  /// No description provided for @settingsFriendManagement.
  ///
  /// In ko, this message translates to:
  /// **'친구 관리'**
  String get settingsFriendManagement;

  /// No description provided for @settingsFriendManagementDesc.
  ///
  /// In ko, this message translates to:
  /// **'친구 요청, 숨김, 차단 관리'**
  String get settingsFriendManagementDesc;

  /// No description provided for @settingsGeneral.
  ///
  /// In ko, this message translates to:
  /// **'일반'**
  String get settingsGeneral;

  /// No description provided for @settingsLanguage.
  ///
  /// In ko, this message translates to:
  /// **'언어'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageKorean.
  ///
  /// In ko, this message translates to:
  /// **'한국어 (기본)'**
  String get settingsLanguageKorean;

  /// No description provided for @settingsDarkMode.
  ///
  /// In ko, this message translates to:
  /// **'다크 모드'**
  String get settingsDarkMode;

  /// No description provided for @settingsSecurity.
  ///
  /// In ko, this message translates to:
  /// **'보안'**
  String get settingsSecurity;

  /// No description provided for @settingsBiometric.
  ///
  /// In ko, this message translates to:
  /// **'생체 인증'**
  String get settingsBiometric;

  /// No description provided for @settingsBiometricDesc.
  ///
  /// In ko, this message translates to:
  /// **'앱 잠금 해제 시 생체 인증 사용'**
  String get settingsBiometricDesc;

  /// No description provided for @settingsAccount.
  ///
  /// In ko, this message translates to:
  /// **'계정'**
  String get settingsAccount;

  /// No description provided for @settingsChangePassword.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호 변경'**
  String get settingsChangePassword;

  /// No description provided for @settingsAccountDeletion.
  ///
  /// In ko, this message translates to:
  /// **'회원 탈퇴'**
  String get settingsAccountDeletion;

  /// No description provided for @settingsInfo.
  ///
  /// In ko, this message translates to:
  /// **'정보'**
  String get settingsInfo;

  /// No description provided for @settingsAppVersion.
  ///
  /// In ko, this message translates to:
  /// **'앱 버전'**
  String get settingsAppVersion;

  /// No description provided for @settingsTerms.
  ///
  /// In ko, this message translates to:
  /// **'이용약관'**
  String get settingsTerms;

  /// No description provided for @settingsPrivacyPolicy.
  ///
  /// In ko, this message translates to:
  /// **'개인정보 처리방침'**
  String get settingsPrivacyPolicy;

  /// No description provided for @settingsOpenSourceLicense.
  ///
  /// In ko, this message translates to:
  /// **'오픈소스 라이선스'**
  String get settingsOpenSourceLicense;

  /// No description provided for @settingsLogout.
  ///
  /// In ko, this message translates to:
  /// **'로그아웃'**
  String get settingsLogout;

  /// No description provided for @settingsLogoutConfirm.
  ///
  /// In ko, this message translates to:
  /// **'정말 로그아웃하시겠습니까?'**
  String get settingsLogoutConfirm;

  /// No description provided for @settingsErrorOccurred.
  ///
  /// In ko, this message translates to:
  /// **'오류가 발생했습니다'**
  String get settingsErrorOccurred;

  /// No description provided for @settingsNotificationType.
  ///
  /// In ko, this message translates to:
  /// **'알림 유형'**
  String get settingsNotificationType;

  /// No description provided for @settingsMessageNotification.
  ///
  /// In ko, this message translates to:
  /// **'메시지 알림'**
  String get settingsMessageNotification;

  /// No description provided for @settingsMessageNotificationDesc.
  ///
  /// In ko, this message translates to:
  /// **'새 메시지를 받을 때 알림'**
  String get settingsMessageNotificationDesc;

  /// No description provided for @settingsFriendRequestNotification.
  ///
  /// In ko, this message translates to:
  /// **'친구 요청 알림'**
  String get settingsFriendRequestNotification;

  /// No description provided for @settingsFriendRequestNotificationDesc.
  ///
  /// In ko, this message translates to:
  /// **'새 친구 요청을 받을 때 알림'**
  String get settingsFriendRequestNotificationDesc;

  /// No description provided for @settingsGroupInviteNotification.
  ///
  /// In ko, this message translates to:
  /// **'그룹 초대 알림'**
  String get settingsGroupInviteNotification;

  /// No description provided for @settingsGroupInviteNotificationDesc.
  ///
  /// In ko, this message translates to:
  /// **'그룹 채팅에 초대받을 때 알림'**
  String get settingsGroupInviteNotificationDesc;

  /// No description provided for @settingsNotificationMethod.
  ///
  /// In ko, this message translates to:
  /// **'알림 방식'**
  String get settingsNotificationMethod;

  /// No description provided for @settingsSound.
  ///
  /// In ko, this message translates to:
  /// **'소리'**
  String get settingsSound;

  /// No description provided for @settingsSoundDesc.
  ///
  /// In ko, this message translates to:
  /// **'알림 소리 재생'**
  String get settingsSoundDesc;

  /// No description provided for @settingsVibration.
  ///
  /// In ko, this message translates to:
  /// **'진동'**
  String get settingsVibration;

  /// No description provided for @settingsVibrationDesc.
  ///
  /// In ko, this message translates to:
  /// **'알림 시 진동'**
  String get settingsVibrationDesc;

  /// No description provided for @settingsDoNotDisturb.
  ///
  /// In ko, this message translates to:
  /// **'방해 금지'**
  String get settingsDoNotDisturb;

  /// No description provided for @settingsDoNotDisturbMode.
  ///
  /// In ko, this message translates to:
  /// **'방해 금지 모드'**
  String get settingsDoNotDisturbMode;

  /// No description provided for @settingsDoNotDisturbDesc.
  ///
  /// In ko, this message translates to:
  /// **'설정된 시간 동안 알림 무음'**
  String get settingsDoNotDisturbDesc;

  /// No description provided for @settingsStartTime.
  ///
  /// In ko, this message translates to:
  /// **'시작 시간'**
  String get settingsStartTime;

  /// No description provided for @settingsEndTime.
  ///
  /// In ko, this message translates to:
  /// **'종료 시간'**
  String get settingsEndTime;

  /// No description provided for @settingsNotificationPreview.
  ///
  /// In ko, this message translates to:
  /// **'알림 미리보기'**
  String get settingsNotificationPreview;

  /// No description provided for @settingsNotificationPreviewDesc.
  ///
  /// In ko, this message translates to:
  /// **'알림에 표시할 내용을 선택합니다'**
  String get settingsNotificationPreviewDesc;

  /// No description provided for @settingsPreviewNameAndMessage.
  ///
  /// In ko, this message translates to:
  /// **'이름 + 메시지'**
  String get settingsPreviewNameAndMessage;

  /// No description provided for @settingsPreviewNameAndMessageDesc.
  ///
  /// In ko, this message translates to:
  /// **'보낸 사람 이름과 메시지 내용을 표시'**
  String get settingsPreviewNameAndMessageDesc;

  /// No description provided for @settingsPreviewNameOnly.
  ///
  /// In ko, this message translates to:
  /// **'이름만'**
  String get settingsPreviewNameOnly;

  /// No description provided for @settingsPreviewNameOnlyDesc.
  ///
  /// In ko, this message translates to:
  /// **'보낸 사람 이름만 표시'**
  String get settingsPreviewNameOnlyDesc;

  /// No description provided for @settingsPreviewNothing.
  ///
  /// In ko, this message translates to:
  /// **'표시 안함'**
  String get settingsPreviewNothing;

  /// No description provided for @settingsPreviewNothingDesc.
  ///
  /// In ko, this message translates to:
  /// **'이름과 메시지 내용 모두 숨김'**
  String get settingsPreviewNothingDesc;

  /// No description provided for @settingsBiometricNotSupported.
  ///
  /// In ko, this message translates to:
  /// **'이 기기는 생체 인증을 지원하지 않습니다.'**
  String get settingsBiometricNotSupported;

  /// No description provided for @settingsBiometricEnabledDesc.
  ///
  /// In ko, this message translates to:
  /// **'앱 잠금 해제 시 생체 인증을 사용합니다'**
  String get settingsBiometricEnabledDesc;

  /// No description provided for @settingsBiometricUnavailable.
  ///
  /// In ko, this message translates to:
  /// **'이 기기에서 사용할 수 없습니다'**
  String get settingsBiometricUnavailable;

  /// No description provided for @settingsBiometricAuthReason.
  ///
  /// In ko, this message translates to:
  /// **'생체 인증을 활성화하려면 인증해주세요'**
  String get settingsBiometricAuthReason;

  /// No description provided for @settingsBiometricBackgroundNotice.
  ///
  /// In ko, this message translates to:
  /// **'앱을 30초 이상 백그라운드에 둔 후 복귀하면 생체 인증을 요청합니다.'**
  String get settingsBiometricBackgroundNotice;

  /// No description provided for @settingsBiometricLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'생체 인증 설정을 불러오는데 실패했습니다.'**
  String get settingsBiometricLoadFailed;

  /// No description provided for @settingsAccountDeletionComplete.
  ///
  /// In ko, this message translates to:
  /// **'회원 탈퇴가 완료되었습니다'**
  String get settingsAccountDeletionComplete;

  /// No description provided for @settingsAccountDeletionInvalidConfirmation.
  ///
  /// In ko, this message translates to:
  /// **'올바른 확인 텍스트를 입력해주세요'**
  String get settingsAccountDeletionInvalidConfirmation;

  /// No description provided for @settingsAccountDeletionEmptyPassword.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호를 입력해주세요'**
  String get settingsAccountDeletionEmptyPassword;

  /// No description provided for @settingsAccountDeletionUserNotFound.
  ///
  /// In ko, this message translates to:
  /// **'사용자 정보를 찾을 수 없습니다'**
  String get settingsAccountDeletionUserNotFound;

  /// No description provided for @settingsAccountDeletionUnknownError.
  ///
  /// In ko, this message translates to:
  /// **'회원 탈퇴 처리 중 오류가 발생했습니다. 비밀번호를 확인해주세요.'**
  String get settingsAccountDeletionUnknownError;

  /// No description provided for @settingsAccountDeletionProcessing.
  ///
  /// In ko, this message translates to:
  /// **'탈퇴 처리 중...'**
  String get settingsAccountDeletionProcessing;

  /// No description provided for @settingsWarning.
  ///
  /// In ko, this message translates to:
  /// **'주의'**
  String get settingsWarning;

  /// No description provided for @settingsDeletionWarningTitle.
  ///
  /// In ko, this message translates to:
  /// **'회원 탈퇴 시 다음 데이터가 영구적으로 삭제됩니다:'**
  String get settingsDeletionWarningTitle;

  /// No description provided for @settingsDeletionItemChats.
  ///
  /// In ko, this message translates to:
  /// **'모든 채팅 내역'**
  String get settingsDeletionItemChats;

  /// No description provided for @settingsDeletionItemFriends.
  ///
  /// In ko, this message translates to:
  /// **'친구 목록'**
  String get settingsDeletionItemFriends;

  /// No description provided for @settingsDeletionItemProfile.
  ///
  /// In ko, this message translates to:
  /// **'프로필 정보'**
  String get settingsDeletionItemProfile;

  /// No description provided for @settingsDeletionItemNotifications.
  ///
  /// In ko, this message translates to:
  /// **'알림 설정'**
  String get settingsDeletionItemNotifications;

  /// No description provided for @settingsDeletionIrreversible.
  ///
  /// In ko, this message translates to:
  /// **'이 작업은 되돌릴 수 없습니다.'**
  String get settingsDeletionIrreversible;

  /// No description provided for @settingsDeletionStep1.
  ///
  /// In ko, this message translates to:
  /// **'1. 비밀번호 확인'**
  String get settingsDeletionStep1;

  /// No description provided for @settingsCurrentPassword.
  ///
  /// In ko, this message translates to:
  /// **'현재 비밀번호'**
  String get settingsCurrentPassword;

  /// No description provided for @settingsDeletionStep2.
  ///
  /// In ko, this message translates to:
  /// **'2. 탈퇴 확인'**
  String get settingsDeletionStep2;

  /// No description provided for @settingsDeletionConfirmInstruction.
  ///
  /// In ko, this message translates to:
  /// **'탈퇴를 확인하려면 아래에 \"삭제합니다\"를 입력하세요.'**
  String get settingsDeletionConfirmInstruction;

  /// No description provided for @settingsDeletionConfirmKeyword.
  ///
  /// In ko, this message translates to:
  /// **'삭제합니다'**
  String get settingsDeletionConfirmKeyword;

  /// No description provided for @settingsDeletionConfirmMismatch.
  ///
  /// In ko, this message translates to:
  /// **'\"삭제합니다\"를 정확히 입력해주세요'**
  String get settingsDeletionConfirmMismatch;

  /// No description provided for @settingsDeletionCountdown.
  ///
  /// In ko, this message translates to:
  /// **'{count}초 후 탈퇴 버튼이 활성화됩니다'**
  String settingsDeletionCountdown(Object count);

  /// No description provided for @settingsAccountDeletionButtonDisabled.
  ///
  /// In ko, this message translates to:
  /// **'회원 탈퇴 ({detail})'**
  String settingsAccountDeletionButtonDisabled(Object detail);

  /// No description provided for @settingsDeletionNeedInput.
  ///
  /// In ko, this message translates to:
  /// **'입력 완료 필요'**
  String get settingsDeletionNeedInput;

  /// No description provided for @settingsDeletionSeconds.
  ///
  /// In ko, this message translates to:
  /// **'{count}초'**
  String settingsDeletionSeconds(Object count);

  /// No description provided for @settingsFinalConfirm.
  ///
  /// In ko, this message translates to:
  /// **'최종 확인'**
  String get settingsFinalConfirm;

  /// No description provided for @settingsDeletionFinalConfirmContent.
  ///
  /// In ko, this message translates to:
  /// **'정말로 탈퇴하시겠습니까?\n\n모든 데이터가 영구적으로 삭제되며, 이 작업은 되돌릴 수 없습니다.'**
  String get settingsDeletionFinalConfirmContent;

  /// No description provided for @settingsDeletionConfirmButton.
  ///
  /// In ko, this message translates to:
  /// **'탈퇴'**
  String get settingsDeletionConfirmButton;

  /// No description provided for @settingsClearingCache.
  ///
  /// In ko, this message translates to:
  /// **'캐시를 삭제하는 중...'**
  String get settingsClearingCache;

  /// No description provided for @settingsCacheCleared.
  ///
  /// In ko, this message translates to:
  /// **'캐시가 삭제되었습니다'**
  String get settingsCacheCleared;

  /// No description provided for @settingsCacheClearFailed.
  ///
  /// In ko, this message translates to:
  /// **'캐시 삭제에 실패했습니다'**
  String get settingsCacheClearFailed;

  /// No description provided for @settingsFontSize.
  ///
  /// In ko, this message translates to:
  /// **'글꼴 크기'**
  String get settingsFontSize;

  /// No description provided for @settingsMediaAutoDownload.
  ///
  /// In ko, this message translates to:
  /// **'미디어 자동 다운로드'**
  String get settingsMediaAutoDownload;

  /// No description provided for @settingsImage.
  ///
  /// In ko, this message translates to:
  /// **'이미지'**
  String get settingsImage;

  /// No description provided for @settingsOnWifi.
  ///
  /// In ko, this message translates to:
  /// **'Wi-Fi 연결 시'**
  String get settingsOnWifi;

  /// No description provided for @settingsOnMobileData.
  ///
  /// In ko, this message translates to:
  /// **'모바일 데이터 사용 시'**
  String get settingsOnMobileData;

  /// No description provided for @settingsVideo.
  ///
  /// In ko, this message translates to:
  /// **'동영상'**
  String get settingsVideo;

  /// No description provided for @settingsImageAutoDownload.
  ///
  /// In ko, this message translates to:
  /// **'이미지 자동 다운로드'**
  String get settingsImageAutoDownload;

  /// No description provided for @settingsVideoAutoDownload.
  ///
  /// In ko, this message translates to:
  /// **'동영상 자동 다운로드'**
  String get settingsVideoAutoDownload;

  /// No description provided for @settingsTypingDisplay.
  ///
  /// In ko, this message translates to:
  /// **'입력 표시'**
  String get settingsTypingDisplay;

  /// No description provided for @settingsTypingIndicator.
  ///
  /// In ko, this message translates to:
  /// **'입력중 표시'**
  String get settingsTypingIndicator;

  /// No description provided for @settingsTypingIndicatorDesc.
  ///
  /// In ko, this message translates to:
  /// **'상대방이 메시지를 입력 중일 때 표시합니다. 켜면 나의 입력 상태도 상대방에게 전송됩니다.'**
  String get settingsTypingIndicatorDesc;

  /// No description provided for @settingsStorage.
  ///
  /// In ko, this message translates to:
  /// **'저장 공간'**
  String get settingsStorage;

  /// No description provided for @settingsClearCache.
  ///
  /// In ko, this message translates to:
  /// **'캐시 삭제'**
  String get settingsClearCache;

  /// No description provided for @settingsClearCacheDesc.
  ///
  /// In ko, this message translates to:
  /// **'임시 저장된 데이터를 삭제합니다'**
  String get settingsClearCacheDesc;

  /// No description provided for @settingsClearCacheConfirm.
  ///
  /// In ko, this message translates to:
  /// **'임시 저장된 데이터를 삭제하시겠습니까?\n다운로드한 이미지와 동영상 캐시가 삭제됩니다.'**
  String get settingsClearCacheConfirm;

  /// No description provided for @settingsFontSizeSmall.
  ///
  /// In ko, this message translates to:
  /// **'작게'**
  String get settingsFontSizeSmall;

  /// No description provided for @settingsFontSizeLarge.
  ///
  /// In ko, this message translates to:
  /// **'크게'**
  String get settingsFontSizeLarge;

  /// No description provided for @settingsPreview.
  ///
  /// In ko, this message translates to:
  /// **'미리보기'**
  String get settingsPreview;

  /// No description provided for @settingsFontPreviewKorean.
  ///
  /// In ko, this message translates to:
  /// **'안녕하세요! 글꼴 크기를 조절해보세요.'**
  String get settingsFontPreviewKorean;

  /// No description provided for @settingsFontPreviewEnglish.
  ///
  /// In ko, this message translates to:
  /// **'Hello! Try adjusting the font size.'**
  String get settingsFontPreviewEnglish;

  /// No description provided for @settingsFontSizeVerySmall.
  ///
  /// In ko, this message translates to:
  /// **'아주 작게'**
  String get settingsFontSizeVerySmall;

  /// No description provided for @settingsFontSizeNormal.
  ///
  /// In ko, this message translates to:
  /// **'보통'**
  String get settingsFontSizeNormal;

  /// No description provided for @settingsFontSizeVeryLarge.
  ///
  /// In ko, this message translates to:
  /// **'아주 크게'**
  String get settingsFontSizeVeryLarge;

  /// No description provided for @settingsFontSizeExtraLarge.
  ///
  /// In ko, this message translates to:
  /// **'매우 크게'**
  String get settingsFontSizeExtraLarge;

  /// No description provided for @settingsPasswordChangeSuccess.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호가 성공적으로 변경되었습니다.'**
  String get settingsPasswordChangeSuccess;

  /// No description provided for @settingsPasswordChangeFailed.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호 변경에 실패했습니다. 현재 비밀번호를 확인해주세요.'**
  String get settingsPasswordChangeFailed;

  /// No description provided for @settingsNewPassword.
  ///
  /// In ko, this message translates to:
  /// **'새 비밀번호'**
  String get settingsNewPassword;

  /// No description provided for @settingsConfirmNewPassword.
  ///
  /// In ko, this message translates to:
  /// **'새 비밀번호 확인'**
  String get settingsConfirmNewPassword;

  /// No description provided for @settingsCurrentPasswordRequired.
  ///
  /// In ko, this message translates to:
  /// **'현재 비밀번호를 입력해주세요'**
  String get settingsCurrentPasswordRequired;

  /// No description provided for @settingsNewPasswordRequired.
  ///
  /// In ko, this message translates to:
  /// **'새 비밀번호를 입력해주세요'**
  String get settingsNewPasswordRequired;

  /// No description provided for @settingsPasswordMinLength.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호는 8자 이상이어야 합니다'**
  String get settingsPasswordMinLength;

  /// No description provided for @settingsPasswordAlphanumeric.
  ///
  /// In ko, this message translates to:
  /// **'영문과 숫자를 포함해야 합니다'**
  String get settingsPasswordAlphanumeric;

  /// No description provided for @settingsConfirmPasswordRequired.
  ///
  /// In ko, this message translates to:
  /// **'새 비밀번호를 다시 입력해주세요'**
  String get settingsConfirmPasswordRequired;

  /// No description provided for @settingsPasswordMismatch.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호가 일치하지 않습니다'**
  String get settingsPasswordMismatch;

  /// No description provided for @settingsPasswordRequirements.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호 요구 사항'**
  String get settingsPasswordRequirements;

  /// No description provided for @settingsPasswordReqMinLength.
  ///
  /// In ko, this message translates to:
  /// **'최소 8자 이상'**
  String get settingsPasswordReqMinLength;

  /// No description provided for @settingsPasswordReqLetters.
  ///
  /// In ko, this message translates to:
  /// **'영문 대/소문자 포함'**
  String get settingsPasswordReqLetters;

  /// No description provided for @settingsPasswordReqNumbers.
  ///
  /// In ko, this message translates to:
  /// **'숫자 포함'**
  String get settingsPasswordReqNumbers;

  /// No description provided for @settingsPasswordReqSpecial.
  ///
  /// In ko, this message translates to:
  /// **'특수문자 포함'**
  String get settingsPasswordReqSpecial;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
