import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ournego/features/auth/data/models/user_model.dart';

/// Datasource for authentication operations using Supabase.
///
/// Handles all direct communication with Supabase Auth and the 'users' table.
/// Returns [UserModel] instances for use by the repository layer.
class SupabaseAuthDatasource {
  final _supabase = Supabase.instance.client;

  /// Gets the current authenticated user's ID.
  /// Throws if no user is authenticated.
  String _requireUserId() {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw NoAuthenticatedUserException();
    }
    return user.id;
  }

  /// Signs up a new user with email and password.
  /// Returns [UserModel] on success.
  Future<UserModel> signUpWithEmail(String email, String password) async {
    final AuthResponse res = await _supabase.auth.signUp(
      email: email,
      password: password,
    );

    final rawUser = res.user;

    if (rawUser != null) {
      return UserModel.fromSupabaseUser(rawUser);
    } else {
      throw SignupException('signup-error');
    }
  }

  /// Logs in an existing user with email and password.
  /// Returns [UserModel] on success.
  Future<UserModel> logInWithEmail(String email, String password) async {
    final AuthResponse res = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final User? rawUser = res.user;

    if (rawUser != null) {
      return UserModel.fromSupabaseUser(rawUser);
    } else {
      throw LoginException('login-error');
    }
  }

  /// Checks if the current user has completed their profile.
  Future<bool> checkHasProfile() async {
    final String userId = _requireUserId();

    final data = await _supabase
        .from('users')
        .select('has_profile')
        .eq('id', userId)
        .maybeSingle();

    if (data == null) {
      return false;
    }

    return (data['has_profile'] as bool?) ?? false;
  }

  Future<void> resendEmailVerification(String email) async {
    await _supabase.auth.resend(type: OtpType.signup, email: email);
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  Future<bool> isEmailVerified() async {
    return _supabase.auth.currentUser?.emailConfirmedAt != null;
  }

  Stream<bool> watchEmailVerificationStatus() async* {
    yield await _syncEmailVerificationStatus();

    await for (final _ in Stream<void>.periodic(const Duration(seconds: 3))) {
      yield await _syncEmailVerificationStatus();
    }
  }

  Future<bool> _syncEmailVerificationStatus() async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      return false;
    }

    try {
      final UserResponse userResponse = await _supabase.auth.getUser();
      final user = userResponse.user;

      if (user == null || user.id != currentUser.id) {
        return false;
      }

      if (user.emailConfirmedAt != null &&
          _supabase.auth.currentUser?.emailConfirmedAt == null) {
        await _supabase.auth.refreshSession();
      }

      return user.emailConfirmedAt != null;
    } catch (_) {
      return _supabase.auth.currentUser?.emailConfirmedAt != null;
    }
  }

  /// Gets a stream of user profile data.
  /// If [id] is provided, gets that user's profile.
  /// Otherwise, gets the current user's profile.
  /// Returns a stream of [UserModel].
  Stream<UserModel> getProfileStream({String? id}) {
    final targetId = id ?? _requireUserId();

    return _supabase
        .from('users')
        .stream(primaryKey: ['id'])
        .eq('id', targetId)
        .map((data) {
          if (data.isEmpty) {
            throw ProfileNotFoundException();
          }
          return UserModel.fromJson(data.first);
        });
  }

  /// Updates the profile picture for the current user.
  Future<void> updateProfilePicture(File profilePicture) async {
    final String userId = _requireUserId();
    await _supabase.storage
        .from('profile_pictures')
        .upload(
          '$userId${p.extension(profilePicture.path)}',
          profilePicture,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
        );
  }

  /// Updates the user's display name.
  Future<void> updateUserName(String name) async {
    final userId = _requireUserId();
    await _supabase.from('users').upsert({
      'id': userId,
      'name': name,
      'has_profile': true,
    }, onConflict: 'id');
  }

  /// Marks the current user's profile as complete.
  Future<void> confirmHasProfile() async {
    final userId = _requireUserId();
    await _supabase.from('users').upsert({
      'id': userId,
      'has_profile': true,
    }, onConflict: 'id');
  }

  /// Signs out the current user.
  Future<void> logOut() async {
    await _supabase.auth.signOut();
  }

  /// Signs in with Google.
  /// On web, uses OAuth redirect flow.
  /// On mobile, uses google_sign_in package.
  Future<void> signInWithGoogle() async {
    if (kIsWeb) {
      // For web, use Supabase's native OAuth flow
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: null,
      );
      // On web, OAuth redirects so code below won't execute
      // Profile verification should happen after redirect in the app
    } else {
      // For mobile (Android/iOS), use google_sign_in
      const webClientId =
          '544311850300-ajutqk3e1djlccqiqs0o7a1qsuck5arl.apps.googleusercontent.com';

      final GoogleSignIn googleSignIn = GoogleSignIn.instance;
      await googleSignIn.initialize(serverClientId: webClientId);

      final googleUser = await googleSignIn.authenticate();
      final googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw GoogleSignInException('No ID Token found');
      }

      await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );

      // Verify and create profile if necessary
      await _ensureUserProfile(googleUser.displayName, googleUser.photoUrl);
    }
  }

  /// Ensures the user has a profile entry in the database.
  /// Creates one if it doesn't exist.
  Future<void> _ensureUserProfile(String? displayName, String? photoUrl) async {
    try {
      final hasProfile = await checkHasProfile();

      if (!hasProfile) {
        await _supabase.from('users').insert({
          'id': _supabase.auth.currentUser!.id,
          'name': displayName,
          'has_profile': true,
        });

        // Only try to update profile picture on mobile
        if (!kIsWeb && photoUrl != null) {
          try {
            updateProfilePicture(File.fromUri(Uri.parse(photoUrl)));
          } catch (e) {
            debugPrint('Error updating profile picture: $e');
          }
        }
      }
    } catch (e) {
      // User doesn't exist in table, create them
      await _supabase.from('users').insert({
        'id': _supabase.auth.currentUser!.id,
        'name': displayName,
        'has_profile': true,
      });
    }
  }

  /// Gets the current user's ID if authenticated, null otherwise.
  String? get currentUserId => _supabase.auth.currentUser?.id;

  /// Checks if a user is currently authenticated.
  bool get isAuthenticated => _supabase.auth.currentUser != null;
}

// |---------------------------------| \\
// |------- CUSTOM EXCEPTIONS -------| \\
// |---------------------------------| \\

/// Thrown when an operation requires authentication but no user is logged in.
class NoAuthenticatedUserException implements Exception {
  final String message;
  NoAuthenticatedUserException([this.message = 'No authenticated user']);

  @override
  String toString() => message;
}

/// Thrown when signup fails.
class SignupException implements Exception {
  final String message;
  SignupException(this.message);

  @override
  String toString() => message;
}

/// Thrown when login fails.
class LoginException implements Exception {
  final String message;
  LoginException(this.message);

  @override
  String toString() => message;
}

/// Thrown when a user's profile is not found.
class ProfileNotFoundException implements Exception {
  final String message;
  ProfileNotFoundException([this.message = 'Profile not found']);

  @override
  String toString() => message;
}

/// Thrown when Google Sign-In fails.
class GoogleSignInException implements Exception {
  final String message;
  GoogleSignInException(this.message);

  @override
  String toString() => message;
}

/// Thrown when email verification flow fails.
class EmailVerificationException implements Exception {
  final String message;
  EmailVerificationException(this.message);

  @override
  String toString() => message;
}
