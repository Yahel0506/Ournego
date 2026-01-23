import 'package:dartz/dartz.dart';
import 'package:ournego/core/failures.dart';
import 'package:ournego/features/business/data/datasources/business_supabase_datasource.dart';

import '../../domain/repositories/business_repository.dart';

class BusinessRepositoryImpl implements BusinessRepository {
  final BusinessSupabaseDatasource businessDatasource;

  BusinessRepositoryImpl({required this.businessDatasource});

  @override
  Future<Either<Failure, bool>> isLoggedIn() async {
    try {
      final session = await businessDatasource.isLoggedIn();
      final result = session != null;
      return Right(result);
    } catch (e) {
      return Left(ServerFailure());
    }
  }
}
