import 'package:ournego/features/community/data/datasources/community_datasource.dart';
import 'package:ournego/features/community/domain/repositories/community_repository.dart';

class CommunityRepositoryImpl implements CommunityRepository {
  final CommunityDatasource datasource;

  CommunityRepositoryImpl({required this.datasource});
}
