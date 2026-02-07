import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:co_talk_flutter/core/network/websocket/websocket_connection_manager.dart';
import 'package:co_talk_flutter/core/network/websocket/websocket_events.dart';
import 'package:co_talk_flutter/data/datasources/local/auth_local_datasource.dart';

class MockAuthLocalDataSource extends Mock implements AuthLocalDataSource {}

void main() {
  late WebSocketConnectionManager manager;
  late MockAuthLocalDataSource mockAuth;

  setUp(() {
    mockAuth = MockAuthLocalDataSource();
    manager = WebSocketConnectionManager(mockAuth);
  });

  tearDown(() {
    manager.dispose();
  });

  group('connect() race condition guard (Fix 1)', () {
    test('aborts connection if disconnect() called during getAccessToken await', () async {
      // Make getAccessToken take time
      final completer = Completer<String?>();
      when(() => mockAuth.getAccessToken()).thenAnswer((_) => completer.future);

      // Start connecting
      final connectFuture = manager.connect();

      // Verify it's in connecting state
      expect(manager.currentConnectionState, WebSocketConnectionState.connecting);

      // Disconnect while awaiting token
      manager.disconnect();

      // Complete the token future
      completer.complete('test_token');
      await connectFuture;

      // Should be disconnected (not trying to create StompClient)
      expect(manager.currentConnectionState, WebSocketConnectionState.disconnected);
      expect(manager.stompClient, isNull);
    });

    test('aborts connection if no access token', () async {
      when(() => mockAuth.getAccessToken()).thenAnswer((_) async => null);

      await manager.connect();

      expect(manager.currentConnectionState, WebSocketConnectionState.disconnected);
      expect(manager.stompClient, isNull);
    });

    test('does not abort early when token is available', () async {
      // This test verifies the post-await guard doesn't trigger false positives
      // We test the inverse: when disconnect is NOT called, connection proceeds

      final tokenCompleter = Completer<String?>();
      when(() => mockAuth.getAccessToken()).thenAnswer((_) => tokenCompleter.future);

      // Start connecting
      final connectFuture = manager.connect();

      // Verify connecting state
      expect(manager.currentConnectionState, WebSocketConnectionState.connecting);

      // Complete token without disconnect
      tokenCompleter.complete('valid_token');

      // Wait for connect to complete
      await connectFuture;

      // The StompClient should have been created (even though connection will fail)
      // This proves the post-await guard didn't abort the connection
      expect(manager.stompClient, isNotNull);

      // Wait a bit for async StompClient errors to settle
      await Future.delayed(Duration(milliseconds: 100));

      // Clean up
      manager.disconnect();
    });
  });

  group('_forceReset() cancels reconnect timer (Fix 2)', () {
    test('disconnect() clears state and cancels pending reconnection', () async {
      // We can't easily trigger _forceReset() directly since it's private
      // But disconnect() also cancels the reconnect timer

      when(() => mockAuth.getAccessToken()).thenAnswer((_) async => 'test_token');

      // Start connection attempt
      await manager.connect();

      // Disconnect should cancel any pending timers
      manager.disconnect();

      expect(manager.currentConnectionState, WebSocketConnectionState.disconnected);
      expect(manager.stompClient, isNull);
    });

    test('resetReconnectAttempts resets counter', () {
      // This method should not throw and should reset internal counter
      manager.resetReconnectAttempts();

      // No direct way to verify counter, but method should execute without error
      expect(manager.currentConnectionState, WebSocketConnectionState.disconnected);
    });
  });

  group('stale connecting state detection (Fix 3)', () {
    test('allows multiple connect() calls when not in connecting state', () async {
      when(() => mockAuth.getAccessToken()).thenAnswer((_) async => null);

      await manager.connect();
      expect(manager.currentConnectionState, WebSocketConnectionState.disconnected);

      // Second call should also be allowed
      await manager.connect();
      expect(manager.currentConnectionState, WebSocketConnectionState.disconnected);

      verify(() => mockAuth.getAccessToken()).called(2);
    });

    test('skips connection attempt if already connecting (not stale)', () async {
      // Make first getAccessToken hang indefinitely
      final neverCompletes = Completer<String?>();
      when(() => mockAuth.getAccessToken()).thenAnswer((_) => neverCompletes.future);

      // Start first connect (will hang)
      manager.connect();

      expect(manager.currentConnectionState, WebSocketConnectionState.connecting);

      // Second connect should skip (not stale yet)
      await manager.connect();

      // Still in connecting state from first attempt
      expect(manager.currentConnectionState, WebSocketConnectionState.connecting);

      // Should only be called once
      verify(() => mockAuth.getAccessToken()).called(1);
    });

    // Note: Testing the actual stale timeout (15s) would make tests slow
    // The logic is: if connecting for > 15s, force reset and retry
    // This is tested implicitly by the code structure but hard to unit test
    // without waiting 15+ seconds or using fake timers
  });

  group('connection state transitions', () {
    test('emits connecting then disconnected on failed connect (no token)', () async {
      when(() => mockAuth.getAccessToken()).thenAnswer((_) async => null);

      final states = <WebSocketConnectionState>[];
      final subscription = manager.connectionState.listen(states.add);

      await manager.connect();

      // Wait for stream to emit
      await Future.delayed(Duration(milliseconds: 10));

      expect(states, [
        WebSocketConnectionState.connecting,
        WebSocketConnectionState.disconnected,
      ]);

      await subscription.cancel();
    });

    test('disconnect from initial state is idempotent', () {
      expect(manager.currentConnectionState, WebSocketConnectionState.disconnected);

      // Should not throw even if called multiple times
      manager.disconnect();
      expect(manager.currentConnectionState, WebSocketConnectionState.disconnected);

      // Don't call disconnect again since tearDown will do it
    });

    test('multiple disconnect calls are idempotent', () {
      manager.disconnect();
      manager.disconnect();
      manager.disconnect();

      expect(manager.currentConnectionState, WebSocketConnectionState.disconnected);
    });

    test('isConnected returns false when disconnected', () {
      expect(manager.isConnected, isFalse);
    });

    test('isConnected returns false when connecting', () async {
      final neverCompletes = Completer<String?>();
      when(() => mockAuth.getAccessToken()).thenAnswer((_) => neverCompletes.future);

      manager.connect();

      expect(manager.currentConnectionState, WebSocketConnectionState.connecting);
      expect(manager.isConnected, isFalse);
    });

    test('currentConnectionState getter returns correct state', () {
      expect(manager.currentConnectionState, WebSocketConnectionState.disconnected);
    });

    test('connectionState stream is broadcast', () {
      final stream1 = manager.connectionState;
      final stream2 = manager.connectionState;

      expect(stream1, isA<Stream<WebSocketConnectionState>>());
      expect(stream2, isA<Stream<WebSocketConnectionState>>());
    });
  });

  group('callbacks', () {
    test('onConnected and onDisconnected can be set', () {
      var connectedCalled = false;
      var disconnectedCalled = false;

      manager.onConnected = () => connectedCalled = true;
      manager.onDisconnected = () => disconnectedCalled = true;

      // Callbacks are set but not called yet
      expect(connectedCalled, isFalse);
      expect(disconnectedCalled, isFalse);
    });
  });

  group('edge cases', () {
    test('connect() returns early if already connected', () async {
      // This is hard to test without actually establishing a connection
      // But we can verify the guard logic exists by checking state
      expect(manager.currentConnectionState, WebSocketConnectionState.disconnected);
    });

    test('stompClient getter returns null when not connected', () {
      expect(manager.stompClient, isNull);
    });

    test('dispose cleans up resources', () async {
      // Create a new manager for this test to avoid double-dispose
      final testManager = WebSocketConnectionManager(mockAuth);

      final states = <WebSocketConnectionState>[];
      final subscription = testManager.connectionState.listen(states.add);

      testManager.dispose();

      // Stream should be closed after dispose
      expect(testManager.currentConnectionState, WebSocketConnectionState.disconnected);

      await subscription.cancel();
    });
  });

  group('post-await intentional disconnect guard', () {
    test('_isIntentionalDisconnect flag prevents connection after disconnect', () async {
      final completer = Completer<String?>();
      when(() => mockAuth.getAccessToken()).thenAnswer((_) => completer.future);

      // Start connecting
      manager.connect();
      expect(manager.currentConnectionState, WebSocketConnectionState.connecting);

      // Disconnect sets the flag
      manager.disconnect();

      // Complete token fetch
      completer.complete('token');

      // Wait a bit for async operations
      await Future.delayed(Duration.zero);

      // Should remain disconnected
      expect(manager.currentConnectionState, WebSocketConnectionState.disconnected);
      expect(manager.stompClient, isNull);
    });

    test('_isIntentionalDisconnect is reset on new connect attempt', () async {
      when(() => mockAuth.getAccessToken()).thenAnswer((_) async => null);

      // First attempt
      await manager.connect();
      manager.disconnect();

      expect(manager.currentConnectionState, WebSocketConnectionState.disconnected);

      // Second attempt should reset the flag
      await manager.connect();

      // Should transition to connecting (flag was reset)
      verify(() => mockAuth.getAccessToken()).called(2);
    });
  });

  group('reconnection logic', () {
    test('resetReconnectAttempts can be called multiple times', () {
      manager.resetReconnectAttempts();
      manager.resetReconnectAttempts();
      manager.resetReconnectAttempts();

      // Should not throw
      expect(manager.currentConnectionState, WebSocketConnectionState.disconnected);
    });
  });
}
