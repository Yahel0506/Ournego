import 'package:ournego/features/auth/domain/entities/app_user.dart';
import 'package:ournego/features/auth/domain/repositories/auth_repository.dart';

class GetProfileUsecase {
  final AuthRepository repository;

  GetProfileUsecase({required this.repository});

  Stream<AppUser> call({String? userId}) {
    if (userId != null) {
      return repository.getProfile(userId: userId);
    } else {
      return repository.getProfile();
    }
  }
}
