import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ournego/features/business/data/datasources/business_geocoding_datasource.dart';
import 'package:ournego/features/business/data/datasources/business_supabase_datasource.dart';
import 'package:ournego/features/business/data/repositories/business_repository_impl.dart';
import 'package:ournego/features/business/domain/repositories/business_repository.dart';
import 'package:ournego/features/business/domain/usecases/check_if_owner_usecase.dart';
import 'package:ournego/features/business/domain/usecases/get_addresses_suggestions_usecase.dart';
import 'package:ournego/features/business/domain/usecases/register_business_usecase.dart';

// |---------------------------------| \\
// |------- LAYER 1: DATASOURCES ---| \\
// |---------------------------------| \\

final businessSupabaseDatasourceProvider = Provider<BusinessSupabaseDatasource>(
  (ref) => BusinessSupabaseDatasource(),
);

final businessGeocodingDatasourceProvider =
    Provider<BusinessGeocodingDatasource>(
      (ref) => BusinessGeocodingDatasource(),
    );

// |---------------------------------| \\
// |------- LAYER 2: REPOSITORIES --| \\
// |---------------------------------| \\

final businessRepositoryProvider = Provider<BusinessRepository>((ref) {
  final businessDatasource = ref.watch(businessSupabaseDatasourceProvider);
  final geocodingDatasource = ref.watch(businessGeocodingDatasourceProvider);
  return BusinessRepositoryImpl(
    businessDatasource: businessDatasource,
    geocodingDatasource: geocodingDatasource,
  );
});

// |---------------------------------| \\
// |------- LAYER 3: USECASES ------| \\
// |---------------------------------| \\

// NOTE: For auth state (isLoggedIn), use authSessionProvider from
// 'package:ournego/features/auth/presentation/providers/auth_providers.dart'

final getAdressesSuggestionsUsecaseProvider =
    Provider<GetAddressesSuggestionsUsecase>((ref) {
      final repository = ref.watch(businessRepositoryProvider);
      return GetAddressesSuggestionsUsecase(repository: repository);
    });

final registerBusinessUsecaseProvider = Provider<RegisterBusinessUsecase>((
  ref,
) {
  final repository = ref.watch(businessRepositoryProvider);
  return RegisterBusinessUsecase(repository: repository);
});

final checkIfOwnerUsecaseProvider = Provider<CheckIfOwnerUsecase>((ref) {
  final repository = ref.watch(businessRepositoryProvider);
  return CheckIfOwnerUsecase(repository: repository);
});

final isOwnerProvider = FutureProvider<bool>((ref) async {
  final usecase = ref.watch(checkIfOwnerUsecaseProvider);
  final result = await usecase();
  return result.fold((failure) => false, (isOwner) => isOwner);
});
