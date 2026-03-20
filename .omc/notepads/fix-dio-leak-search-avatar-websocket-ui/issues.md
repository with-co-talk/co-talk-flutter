# Issues Encountered

## Widget Testing with NetworkImage

### Issue
Testing `CircleAvatar` with `backgroundImage: NetworkImage(url)` is tricky:
- NetworkImage is not a widget, it's an ImageProvider
- Can't use `find.byType(NetworkImage)`
- Must check `CircleAvatar.backgroundImage` property instead

### Solution
```dart
final avatarWidget = tester.widget<CircleAvatar>(avatarFinder);
expect(avatarWidget.backgroundImage, isA<NetworkImage>());
```

### Gotcha
Network requests in tests fail with 400 status by design. This is expected and not a test failure if the NetworkImage is constructed correctly.

---

## Multiple Widgets with Same Icon

### Issue
`find.byIcon(Icons.person_add)` found 2 widgets - one in AppBar, one in the list.

### Solution
Use more specific finder:
```dart
find.widgetWithIcon(IconButton, Icons.person_add)
```

---

## Deprecation: withOpacity()

### Issue
Analyzer warning: `'withOpacity' is deprecated and shouldn't be used`

### Solution
Flutter 3.32+ requires:
```dart
// Old
Colors.white.withOpacity(0.2)

// New
Colors.white.withValues(alpha: 0.2)
```

---

## Bottom Sheet Widget Hierarchy

### Issue
Finding widgets within a modal bottom sheet requires understanding the hierarchy.

### Solution
Search results are in a `ListView` within the bottom sheet:
```dart
find.descendant(
  of: find.byType(ListView),
  matching: find.byType(CircleAvatar),
)
```

Don't search globally or you'll find the wrong CircleAvatar (e.g., from "My Profile" card).
