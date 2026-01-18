class AppUser {
  final String uid;
  String? name;
  String? email;
  String? phoneNum;
  String? profilePicture;

  AppUser({
    required this.uid,
    this.name,
    this.email,
    this.phoneNum,
    this.profilePicture,
  });
}
