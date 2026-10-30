import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ournego/core/failures.dart';
import 'package:ournego/features/auth/domain/entities/app_user.dart';
import 'package:ournego/features/auth/domain/repositories/auth_repository.dart';
import 'package:ournego/features/auth/presentation/providers/auth_providers.dart';
import 'package:ournego/features/auth/presentation/services/profile_photo_picker.dart';
import 'package:ournego/features/auth/presentation/widgets/edit_profile_dialog_widget.dart';

import '../../../fakes/fake_auth_repository.dart';

class _RecordingRepository extends FakeAuthRepository {
  _RecordingRepository({this.failure});

  final Failure? failure;
  String? savedName;
  int photoUploads = 0;

  @override
  Future<Either<Failure, void>> updateUserName(String name) async {
    if (failure != null) return Left(failure!);
    savedName = name;
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> updateProfilePicture(
    File profilePicture,
  ) async {
    if (failure != null) return Left(failure!);
    photoUploads++;
    return const Right(null);
  }
}

class _FakePicker implements ProfilePhotoPicker {
  @override
  Future<File?> pickSquarePhoto() async => File('photo.png');
}

void main() {
  Future<ProviderContainer> pump(
    WidgetTester tester,
    AuthRepository repository,
  ) async {
    late ProviderContainer container;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          profilePhotoPickerProvider.overrideWithValue(_FakePicker()),
          profileStreamProvider.overrideWith(
            (ref) => Stream.value(const AppUser(uid: 'u1', name: 'Ana')),
          ),
        ],
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) {
              container = ProviderScope.containerOf(context);
              return const EditProfileDialogWidget();
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('prefills the current name', (tester) async {
    await pump(tester, _RecordingRepository());

    expect(find.widgetWithText(TextFormField, 'Ana'), findsOneWidget);
  });

  testWidgets('an empty name shows a validation error and does not save', (
    tester,
  ) async {
    final repo = _RecordingRepository();
    await pump(tester, repo);

    await tester.enterText(
      find.byKey(const ValueKey('editProfileNameField')),
      '   ',
    );
    await tester.tap(find.byKey(const ValueKey('editProfileSaveButton')));
    await tester.pumpAndSettle();

    expect(find.text('Escribe tu nombre'), findsOneWidget);
    expect(repo.savedName, isNull);
  });

  testWidgets('saves the trimmed name', (tester) async {
    final repo = _RecordingRepository();
    await pump(tester, repo);

    await tester.enterText(
      find.byKey(const ValueKey('editProfileNameField')),
      '  Beto  ',
    );
    await tester.tap(find.byKey(const ValueKey('editProfileSaveButton')));
    await tester.pumpAndSettle();

    expect(repo.savedName, 'Beto');
  });

  testWidgets('a failed save keeps the dialog open and shows the error', (
    tester,
  ) async {
    final repo = _RecordingRepository(failure: NetworkFailure());
    await pump(tester, repo);

    await tester.enterText(
      find.byKey(const ValueKey('editProfileNameField')),
      'Beto',
    );
    await tester.tap(find.byKey(const ValueKey('editProfileSaveButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('editProfileError')), findsOneWidget);
    expect(find.byType(EditProfileDialogWidget), findsOneWidget);
  });

  testWidgets('changing the photo uploads it and bumps the avatar version', (
    tester,
  ) async {
    final repo = _RecordingRepository();
    final container = await pump(tester, repo);

    await tester.tap(find.byKey(const ValueKey('editProfilePhotoButton')));
    await tester.pumpAndSettle();

    expect(repo.photoUploads, 1);
    expect(container.read(profileAvatarVersionProvider), isNot(0));
    expect(find.byKey(const ValueKey('editProfilePhotoSaved')), findsOneWidget);
  });

  testWidgets('a failed photo upload keeps the old version and shows error', (
    tester,
  ) async {
    final repo = _RecordingRepository(failure: ServerFailure());
    final container = await pump(tester, repo);

    await tester.tap(find.byKey(const ValueKey('editProfilePhotoButton')));
    await tester.pumpAndSettle();

    expect(container.read(profileAvatarVersionProvider), 0);
    expect(find.byKey(const ValueKey('editProfileError')), findsOneWidget);
  });
}
