import 'package:dartz/dartz.dart';

import '../../../../core/failures.dart';

abstract class BusinessRepository {
  Future<Either<Failure, bool>> isLoggedIn();
}
