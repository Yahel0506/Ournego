/// Domain entity representing an authenticated user.
///
/// This is a pure business object with no serialization logic.
/// For serialization, see [UserModel] in the data layer.
class AppUser {
  final String uid;
  final String? name;
  final String? email;
  final String? phoneNum;
  final String? profilePicture;

  const AppUser({
    required this.uid,
    this.name,
    this.email,
    this.phoneNum,
    this.profilePicture,
  });
}
