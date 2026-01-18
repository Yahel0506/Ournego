import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthDatasource {
  var auth = FirebaseAuth.instance;

  Future<User> signUpWithEmail(String email, String password) async {
    UserCredential newUserCredential = await auth
        .createUserWithEmailAndPassword(email: email, password: password);

    final rawUser = newUserCredential.user;

    if (rawUser != null) {
      return rawUser;
    } else {
      throw Exception();
    }
  }

  Future<User> logInWithEmail(String email, String password) async {
    UserCredential rawUserCredential = await auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final rawUser = rawUserCredential.user;

    if (rawUser != null) {
      return rawUser;
    } else {
      throw Exception();
    }
  }
}
