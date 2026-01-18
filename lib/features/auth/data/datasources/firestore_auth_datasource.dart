import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ournego/features/auth/domain/entities/app_user.dart';

class FirestoreAuthDatasource {
  var db = FirebaseFirestore.instance;

  Future createUserDoc(AppUser user) async {
    db.collection('users').doc(user.uid).set({
      'createdAt': FieldValue.serverTimestamp(),
      'hasProfile': false,
    });
  }

  Future<DocumentSnapshot> getUserDoc(AppUser user) async {
    final DocumentSnapshot doc = await db
        .collection('users')
        .doc(user.uid)
        .get();

    return doc;
  }
}
