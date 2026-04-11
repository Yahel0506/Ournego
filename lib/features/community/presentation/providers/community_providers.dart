import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ournego/features/community/data/datasources/community_datasource.dart';
import 'package:ournego/features/community/data/repositories/community_repository_impl.dart';
import 'package:ournego/features/community/domain/repositories/community_repository.dart';

final communityDatasourceProvider = Provider<CommunityDatasource>((ref) {
  return CommunityDatasource();
});

final communityRepositoryProvider = Provider<CommunityRepository>((ref) {
  final datasource = ref.watch(communityDatasourceProvider);
  return CommunityRepositoryImpl(datasource: datasource);
});
