import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:co_talk_flutter/presentation/pages/profile/widgets/profile_dialogs.dart';

Widget buildTestApp(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  group('ImageSourceChoice enum', () {
    test('has camera value', () {
      expect(ImageSourceChoice.camera, isNotNull);
    });

    test('has gallery value', () {
      expect(ImageSourceChoice.gallery, isNotNull);
    });

    test('has file value', () {
      expect(ImageSourceChoice.file, isNotNull);
    });

    test('has history value', () {
      expect(ImageSourceChoice.history, isNotNull);
    });

    test('has delete value', () {
      expect(ImageSourceChoice.delete, isNotNull);
    });

    test('has 5 values in total', () {
      expect(ImageSourceChoice.values.length, 5);
    });
  });

  group('ProfileDialogs.showAvatarSourcePicker', () {
    testWidgets('shows 프로필 사진 title', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => ProfileDialogs.showAvatarSourcePicker(
                context,
                hasAvatar: false,
                onCamera: () {},
                onGallery: () {},
                onHistory: () {},
                onDelete: () {},
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('프로필 사진'), findsOneWidget);
    });

    testWidgets('shows camera, gallery, history options', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => ProfileDialogs.showAvatarSourcePicker(
                context,
                hasAvatar: false,
                onCamera: () {},
                onGallery: () {},
                onHistory: () {},
                onDelete: () {},
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('카메라로 촬영'), findsOneWidget);
      expect(find.text('앨범에서 선택'), findsOneWidget);
      expect(find.text('기존 프로필에서 선택'), findsOneWidget);
    });

    testWidgets('shows delete option when hasAvatar is true', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => ProfileDialogs.showAvatarSourcePicker(
                context,
                hasAvatar: true,
                onCamera: () {},
                onGallery: () {},
                onHistory: () {},
                onDelete: () {},
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('기본 이미지로 변경'), findsOneWidget);
    });

    testWidgets('hides delete option when hasAvatar is false', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => ProfileDialogs.showAvatarSourcePicker(
                context,
                hasAvatar: false,
                onCamera: () {},
                onGallery: () {},
                onHistory: () {},
                onDelete: () {},
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('기본 이미지로 변경'), findsNothing);
    });

    testWidgets('calls onCamera when 카메라로 촬영 tapped', (tester) async {
      bool called = false;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => ProfileDialogs.showAvatarSourcePicker(
                context,
                hasAvatar: false,
                onCamera: () => called = true,
                onGallery: () {},
                onHistory: () {},
                onDelete: () {},
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('카메라로 촬영'));
      await tester.pumpAndSettle();

      expect(called, isTrue);
    });

    testWidgets('calls onGallery when 앨범에서 선택 tapped', (tester) async {
      bool called = false;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => ProfileDialogs.showAvatarSourcePicker(
                context,
                hasAvatar: false,
                onCamera: () {},
                onGallery: () => called = true,
                onHistory: () {},
                onDelete: () {},
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('앨범에서 선택'));
      await tester.pumpAndSettle();

      expect(called, isTrue);
    });

    testWidgets('calls onHistory when 기존 프로필에서 선택 tapped', (tester) async {
      bool called = false;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => ProfileDialogs.showAvatarSourcePicker(
                context,
                hasAvatar: false,
                onCamera: () {},
                onGallery: () {},
                onHistory: () => called = true,
                onDelete: () {},
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('기존 프로필에서 선택'));
      await tester.pumpAndSettle();

      expect(called, isTrue);
    });
  });

  group('ProfileDialogs.showBackgroundSourcePicker', () {
    testWidgets('shows 배경화면 title', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => ProfileDialogs.showBackgroundSourcePicker(
                context,
                onGallery: () {},
                onHistory: () {},
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('배경화면'), findsOneWidget);
    });

    testWidgets('shows gallery and history options', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => ProfileDialogs.showBackgroundSourcePicker(
                context,
                onGallery: () {},
                onHistory: () {},
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('앨범에서 선택'), findsOneWidget);
      expect(find.text('배경 이력에서 선택'), findsOneWidget);
    });
  });

  group('ProfileDialogs.showDesktopFilePicker', () {
    testWidgets('shows 파일에서 선택 option', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => ProfileDialogs.showDesktopFilePicker(
                context,
                onFilePick: () {},
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('파일에서 선택'), findsOneWidget);
    });

    testWidgets('calls onFilePick when option tapped', (tester) async {
      bool called = false;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => ProfileDialogs.showDesktopFilePicker(
                context,
                onFilePick: () => called = true,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('파일에서 선택'));
      await tester.pumpAndSettle();

      expect(called, isTrue);
    });
  });

  group('ProfileDialogs.showDesktopBackgroundFilePicker', () {
    testWidgets('shows 파일에서 선택 with subtitle for background', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => ProfileDialogs.showDesktopBackgroundFilePicker(
                context,
                onFilePick: () {},
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('파일에서 선택'), findsOneWidget);
      expect(find.text('배경 이미지 파일을 선택합니다'), findsOneWidget);
    });
  });

  group('ProfileDialogs.showDeleteAvatarConfirmation', () {
    testWidgets('shows confirmation dialog with title and content', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => ProfileDialogs.showDeleteAvatarConfirmation(context),
              child: const Text('open'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('프로필 사진 삭제'), findsOneWidget);
      expect(find.text('프로필 사진을 삭제하고 기본 이미지로 변경하시겠습니까?'), findsOneWidget);
    });

    testWidgets('shows 취소 and 삭제 buttons', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => ProfileDialogs.showDeleteAvatarConfirmation(context),
              child: const Text('open'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('취소'), findsOneWidget);
      expect(find.text('삭제'), findsOneWidget);
    });

    testWidgets('returns true when 삭제 is tapped', (tester) async {
      bool? result;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await ProfileDialogs.showDeleteAvatarConfirmation(context);
              },
              child: const Text('open'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('삭제'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });

    testWidgets('returns false when 취소 is tapped', (tester) async {
      bool? result;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await ProfileDialogs.showDeleteAvatarConfirmation(context);
              },
              child: const Text('open'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
    });
  });
}
