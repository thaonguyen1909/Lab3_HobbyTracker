// SDK sealed-type mocks are test doubles only; production uses the injected adapter.
// ignore_for_file: subtype_of_sealed_class

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hobby_tracker/firebase/firebase_auth_service.dart';
import 'package:hobby_tracker/services/auth_service.dart';
import 'package:hobby_tracker/models/auth_user.dart';
import 'package:mocktail/mocktail.dart';

class MockAuth extends Mock implements FirebaseAuth {}

class MockFirestore extends Mock implements FirebaseFirestore {}

class MockGoogle extends Mock implements GoogleSignIn {}

class MockAccount extends Mock implements GoogleSignInAccount {}

class MockTokens extends Mock implements GoogleSignInAuthentication {}

class MockResult extends Mock implements UserCredential {}

class MockUser extends Mock implements User {}

class MockCollection extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class MockDocument extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

class MockTransaction extends Mock implements Transaction {}

class MockSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

class FakeCredential extends Fake implements AuthCredential {}

void main() {
  late MockFirestore db;
  late MockAuth auth;
  late MockGoogle google;
  late MockAccount account;
  late MockTokens tokens;
  late FirebaseAuthService service;
  setUpAll(() {
    registerFallbackValue(FakeCredential());
    registerFallbackValue((Transaction _) async {});
  });
  setUp(() {
    db = MockFirestore();
    auth = MockAuth();
    google = MockGoogle();
    account = MockAccount();
    tokens = MockTokens();
    service = FirebaseAuthService(auth: auth, db: db, google: google);
    when(() => google.signIn()).thenAnswer((_) async => account);
    when(() => account.authentication).thenAnswer((_) async => tokens);
    when(() => tokens.idToken).thenReturn('test-id-token');
    when(() => tokens.accessToken).thenReturn('test-access-token');
    when(
      () => auth.signInWithCredential(any()),
    ).thenAnswer((_) async => MockResult());
  });

  test('Google cancellation never creates Firebase session', () async {
    when(() => google.signIn()).thenAnswer((_) async => null);
    await expectLater(
      service.signInWithGoogle(),
      throwsA(isA<AuthCancelled>()),
    );
    verifyNever(() => auth.signInWithCredential(any()));
  });
  test('platform cancellation is translated to AuthCancelled', () async {
    when(
      () => google.signIn(),
    ).thenThrow(PlatformException(code: 'sign_in_canceled'));
    await expectLater(
      service.signInWithGoogle(),
      throwsA(isA<AuthCancelled>()),
    );
  });
  test('missing Google ID token blocks Firebase credential sign in', () async {
    when(() => tokens.idToken).thenReturn(null);
    await expectLater(service.signInWithGoogle(), throwsA(isA<AuthFailure>()));
    verifyNever(() => auth.signInWithCredential(any()));
  });
  test('Google tokens are passed to Firebase credential sign in', () async {
    await service.signInWithGoogle();
    final credential =
        verify(() => auth.signInWithCredential(captureAny())).captured.single
            as OAuthCredential;
    expect(credential.providerId, 'google.com');
    expect(credential.idToken, 'test-id-token');
  });
  test('provider conflict is exposed for controlled recovery', () async {
    when(() => auth.signInWithCredential(any())).thenThrow(
      FirebaseAuthException(code: 'account-exists-with-different-credential'),
    );
    await expectLater(
      service.signInWithGoogle(),
      throwsA(
        isA<AuthFailure>().having(
          (error) => error.isConflict,
          'isConflict',
          isTrue,
        ),
      ),
    );
  });
  test('email is trimmed while password is preserved', () async {
    when(
      () => auth.signInWithEmailAndPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => MockResult());
    await service.signInWithEmail(' alice@example.com ', ' password ');
    verify(
      () => auth.signInWithEmailAndPassword(
        email: 'alice@example.com',
        password: ' password ',
      ),
    ).called(1);
  });
  test('network errors become visible domain failures', () async {
    when(
      () => auth.sendPasswordResetEmail(email: any(named: 'email')),
    ).thenThrow(FirebaseAuthException(code: 'network-request-failed'));
    await expectLater(
      service.sendPasswordReset('alice@example.com'),
      throwsA(
        isA<AuthFailure>().having(
          (error) => error.message,
          'message',
          contains('mạng'),
        ),
      ),
    );
  });
  test('Firebase session is cleared even when Google cleanup fails', () async {
    when(() => auth.signOut()).thenAnswer((_) async {});
    when(
      () => google.signOut(),
    ).thenThrow(PlatformException(code: 'network_error'));
    await service.signOut();
    verifyInOrder([() => auth.signOut(), () => google.signOut()]);
  });
  test('Google linking requires current account and same email', () async {
    when(() => auth.currentUser).thenReturn(null);
    await expectLater(
      service.linkGoogleToCurrentAccount(),
      throwsA(isA<AuthFailure>()),
    );
    verifyNever(() => google.signIn());
    final user = MockUser();
    when(() => auth.currentUser).thenReturn(user);
    when(() => user.providerData).thenReturn([]);
    when(() => user.email).thenReturn('alice@example.com');
    when(() => account.email).thenReturn('bob@example.com');
    when(() => google.signOut()).thenAnswer((_) async => null);
    await expectLater(
      service.linkGoogleToCurrentAccount(),
      throwsA(isA<AuthFailure>()),
    );
    verifyNever(() => user.linkWithCredential(any()));
    verify(() => google.signOut()).called(1);
  });
  test(
    'registration rejects invalid display name before creating account',
    () async {
      await expectLater(
        service.registerWithEmail(
          'alice@example.com',
          'secret123',
          displayName: ' ',
        ),
        throwsA(isA<AuthFailure>()),
      );
      verifyNever(
        () => auth.createUserWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      );
    },
  );

  for (final exists in [false, true]) {
    test(
      'registration persists requested name; existing profile=$exists retains role',
      () async {
        final user = MockUser();
        final result = MockResult();
        final collection = MockCollection();
        final document = MockDocument();
        final transaction = MockTransaction();
        final snapshot = MockSnapshot();
        when(
          () => auth.createUserWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => result);
        when(() => result.user).thenReturn(user);
        when(() => user.uid).thenReturn('alice');
        when(() => user.email).thenReturn('alice@example.com');
        when(() => user.displayName).thenReturn('Alice');
        when(() => user.emailVerified).thenReturn(false);
        when(() => user.providerData).thenReturn([]);
        when(() => user.updateDisplayName(any())).thenAnswer((_) async {});
        when(() => db.collection('users')).thenReturn(collection);
        when(() => collection.doc('alice')).thenReturn(document);
        when(() => snapshot.exists).thenReturn(exists);
        when(() => transaction.get(document)).thenAnswer((_) async => snapshot);
        when(
          () => transaction.set<Map<String, dynamic>>(document, any()),
        ).thenReturn(transaction);
        when(() => transaction.update(document, any())).thenReturn(transaction);
        when(() => db.runTransaction<void>(any())).thenAnswer((
          invocation,
        ) async {
          final callback =
              invocation.positionalArguments.first
                  as Future<void> Function(Transaction);
          await callback(transaction);
        });
        await service.registerWithEmail(
          ' alice@example.com ',
          'secret123',
          displayName: ' Alice ',
        );
        verify(() => user.updateDisplayName('Alice')).called(1);
        if (exists) {
          final data =
              verify(
                    () => transaction.update(document, captureAny()),
                  ).captured.single
                  as Map<String, dynamic>;
          expect(data, {'displayName': 'Alice'});
          verifyNever(
            () => transaction.set<Map<String, dynamic>>(document, any()),
          );
        } else {
          final data =
              verify(
                    () => transaction.set<Map<String, dynamic>>(
                      document,
                      captureAny(),
                    ),
                  ).captured.single
                  as Map<String, dynamic>;
          expect(
            data.keys,
            unorderedEquals(['role', 'displayName', 'createdAt']),
          );
          expect(data['displayName'], 'Alice');
          expect(data['role'], 'user');
        }
      },
    );
  }

  test('bootstrap does not overwrite an existing profile', () async {
    final collection = MockCollection();
    final document = MockDocument();
    final transaction = MockTransaction();
    final snapshot = MockSnapshot();
    when(() => db.collection('users')).thenReturn(collection);
    when(() => collection.doc('alice')).thenReturn(document);
    when(() => snapshot.exists).thenReturn(true);
    when(() => transaction.get(document)).thenAnswer((_) async => snapshot);
    when(() => db.runTransaction<void>(any())).thenAnswer((invocation) async {
      final callback =
          invocation.positionalArguments.first
              as Future<void> Function(Transaction);
      await callback(transaction);
    });
    await service.ensureOwnProfile(
      const AuthUser(uid: 'alice', displayName: 'New provider name'),
    );
    verifyNever(() => transaction.set<Map<String, dynamic>>(document, any()));
    verifyNever(() => transaction.update(document, any()));
  });
}
