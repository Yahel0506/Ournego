import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ournego/features/business/data/datasources/business_geocoding_datasource.dart';
import 'package:ournego/features/business/data/datasources/business_supabase_datasource.dart';
import 'package:ournego/features/business/data/repositories/business_repository_impl.dart';
import 'package:ournego/features/business/domain/entities/owned_business_profile.dart';
import 'package:ournego/features/business/domain/entities/business_panel_metrics.dart';
import 'package:ournego/features/business/domain/repositories/business_repository.dart';
import 'package:ournego/features/business/domain/usecases/check_if_owner_usecase.dart';
import 'package:ournego/features/business/domain/usecases/delete_business_image_usecase.dart';
import 'package:ournego/features/business/domain/usecases/delete_business_phone_number_usecase.dart';
import 'package:ournego/features/business/domain/usecases/get_addresses_suggestions_usecase.dart';
import 'package:ournego/features/business/domain/usecases/get_owned_business_usecase.dart';
import 'package:ournego/features/business/domain/usecases/get_business_panel_metrics_usecase.dart';
import 'package:ournego/features/business/domain/usecases/insert_business_image_usecase.dart';
import 'package:ournego/features/business/domain/usecases/register_business_usecase.dart';
import 'package:ournego/features/business/domain/usecases/upsert_business_category_usecase.dart';
import 'package:ournego/features/business/domain/usecases/upsert_business_description_usecase.dart';
import 'package:ournego/features/business/domain/usecases/upsert_business_hours_usecase.dart';
import 'package:ournego/features/business/domain/usecases/upsert_business_location_usecase.dart';
import 'package:ournego/features/business/domain/usecases/upsert_business_name_usecase.dart';
import 'package:ournego/features/business/domain/usecases/upsert_business_phone_number_usecase.dart';

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

final upsertBusinessNameUsecaseProvider = Provider<UpsertBusinessNameUsecase>((
  ref,
) {
  final repository = ref.watch(businessRepositoryProvider);
  return UpsertBusinessNameUsecase(repository: repository);
});

final upsertBusinessDescriptionUsecaseProvider =
    Provider<UpsertBusinessDescriptionUsecase>((ref) {
      final repository = ref.watch(businessRepositoryProvider);
      return UpsertBusinessDescriptionUsecase(repository: repository);
    });

final upsertBusinessLocationUsecaseProvider =
    Provider<UpsertBusinessLocationUsecase>((ref) {
      final repository = ref.watch(businessRepositoryProvider);
      return UpsertBusinessLocationUsecase(repository: repository);
    });

final upsertBusinessCategoryUsecaseProvider =
    Provider<UpsertBusinessCategoryUsecase>((ref) {
      final repository = ref.watch(businessRepositoryProvider);
      return UpsertBusinessCategoryUsecase(repository: repository);
    });

final insertBusinessImageUsecaseProvider = Provider<InsertBusinessImageUsecase>(
  (ref) {
    final repository = ref.watch(businessRepositoryProvider);
    return InsertBusinessImageUsecase(repository: repository);
  },
);

final deleteBusinessImageUsecaseProvider = Provider<DeleteBusinessImageUsecase>(
  (ref) {
    final repository = ref.watch(businessRepositoryProvider);
    return DeleteBusinessImageUsecase(repository: repository);
  },
);

final upsertBusinessPhoneNumberUsecaseProvider =
    Provider<UpsertBusinessPhoneNumberUsecase>((ref) {
      final repository = ref.watch(businessRepositoryProvider);
      return UpsertBusinessPhoneNumberUsecase(repository: repository);
    });

final upsertBusinessHoursUsecaseProvider = Provider<UpsertBusinessHoursUsecase>(
  (ref) {
    final repository = ref.watch(businessRepositoryProvider);
    return UpsertBusinessHoursUsecase(repository: repository);
  },
);

final deleteBusinessPhoneNumberUsecaseProvider =
    Provider<DeleteBusinessPhoneNumberUsecase>((ref) {
      final repository = ref.watch(businessRepositoryProvider);
      return DeleteBusinessPhoneNumberUsecase(repository: repository);
    });

final checkIfOwnerUsecaseProvider = Provider<CheckIfOwnerUsecase>((ref) {
  final repository = ref.watch(businessRepositoryProvider);
  return CheckIfOwnerUsecase(repository: repository);
});

final getOwnedBusinessUsecaseProvider = Provider<GetOwnedBusinessUsecase>((
  ref,
) {
  final repository = ref.watch(businessRepositoryProvider);
  return GetOwnedBusinessUsecase(repository: repository);
});

final getBusinessPanelMetricsUsecaseProvider =
    Provider<GetBusinessPanelMetricsUsecase>((ref) {
      final repository = ref.watch(businessRepositoryProvider);
      return GetBusinessPanelMetricsUsecase(repository: repository);
    });

final isOwnerProvider = FutureProvider<bool>((ref) async {
  final usecase = ref.watch(checkIfOwnerUsecaseProvider);
  final result = await usecase();
  // Failures must surface: treating them as "not owner" shows the wrong screen.
  return result.fold((failure) => throw failure, (isOwner) => isOwner);
});

final ownedBusinessProvider = FutureProvider<OwnedBusinessProfile?>((
  ref,
) async {
  final usecase = ref.watch(getOwnedBusinessUsecaseProvider);
  final result = await usecase();
  return result.fold((failure) => throw failure, (business) => business);
});

final businessPanelMetricsProvider =
    FutureProvider.family<BusinessPanelMetrics, String>((
      ref,
      businessId,
    ) async {
      final usecase = ref.watch(getBusinessPanelMetricsUsecaseProvider);
      final result = await usecase(businessId: businessId);
      return result.fold(
        (failure) => const BusinessPanelMetrics(
          averageRating: 0,
          monthlyInteractions: 0,
          favoriteCount: 0,
        ),
        (metrics) => metrics,
      );
    });
