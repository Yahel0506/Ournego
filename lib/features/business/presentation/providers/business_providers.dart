import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ournego/features/business/data/datasources/business_supabase_datasource.dart';
import 'package:ournego/features/business/domain/repositories/business_repository.dart'
    show BusinessRepository;
import 'package:riverpod/src/framework.dart';

import '../../data/repositories/business_repository_impl.dart';

final businessSupabaseDatasourceProvider = Provider<BusinessSupabaseDatasource>(
  (ref) {
    return BusinessSupabaseDatasource();
  },
);
final businessRepositoryProvider = Provider<BusinessRepository>((ref) {
  final datasource = ref.watch(businessSupabaseDatasourceProvider);
  return BusinessRepositoryImpl(businessDatasource: datasource);
});
