import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ournego/core/location/app_position.dart';
import 'package:ournego/core/location/geolocator_location_datasource.dart';
import 'package:ournego/core/location/location_datasource.dart';
import 'package:ournego/features/auth/domain/entities/app_user.dart';
import 'package:ournego/features/auth/domain/usecases/get_profile_usecase.dart';
import 'package:ournego/features/auth/presentation/providers/auth_providers.dart';
import 'package:ournego/features/map/data/datasources/supabase_map_datasource.dart';
import 'package:ournego/features/map/data/repositories/map_repository_impl.dart';
import 'package:ournego/features/map/domain/entities/business.dart';
import 'package:ournego/features/map/domain/repositories/map_repository.dart';
import 'package:ournego/features/map/domain/usecases/business_favorites_usecase.dart';
import 'package:ournego/features/map/domain/usecases/get_business_by_id_usecase.dart';
import 'package:ournego/features/map/domain/usecases/get_businesses_usecase.dart';
import 'package:ournego/features/map/domain/usecases/check_location_access_usecase.dart';
import 'package:ournego/features/map/domain/usecases/enable_location_service_usecase.dart';
import 'package:ournego/features/map/domain/usecases/get_current_location_usecase.dart';
import 'package:ournego/features/map/domain/usecases/request_location_permission_usecase.dart';
import 'package:ournego/features/map/domain/usecases/watch_location_service_usecase.dart';
import 'package:ournego/features/map/domain/usecases/track_business_visit_usecase.dart';
import 'package:ournego/features/map/presentation/providers/notifiers/map_notifier.dart';
import 'package:ournego/features/map/presentation/providers/notifiers/map_voice_search_notifier.dart';
import 'package:ournego/features/map/presentation/services/speech_to_text_voice_search_service.dart';

// |---------------------------------| \\
// |------- LAYER 1: DATASOURCES ----| \\
// |---------------------------------| \\

final geolocationDatasourceProvider = Provider<LocationDatasource>(
  (ref) => GeolocatorLocationDatasource(),
);

final businessesDatasourceProvider = Provider<SupabaseMapDatasource>(
  (ref) => SupabaseMapDatasource(),
);

// |---------------------------------| \\
// |------- LAYER 2: REPOSITORY -----| \\
// |---------------------------------| \\

final mapRepositoryProvider = Provider<MapRepository>((ref) {
  final businessesDatasource = ref.watch(businessesDatasourceProvider);
  final geolocationDatasource = ref.watch(geolocationDatasourceProvider);
  return MapRepositoryImpl(
    geolocationDatasource: geolocationDatasource,
    businessesDatasource: businessesDatasource,
  );
});

// |---------------------------------| \\
// |------- LAYER 3: USECASES -------| \\
// |---------------------------------| \\

final getCurrentLocationUsecaseProvider = Provider<GetCurrentLocationUsecase>((
  ref,
) {
  final repository = ref.watch(mapRepositoryProvider);
  return GetCurrentLocationUsecase(repository: repository);
});

final checkLocationAccessUsecaseProvider = Provider<CheckLocationAccessUsecase>(
  (ref) {
    final repository = ref.watch(mapRepositoryProvider);
    return CheckLocationAccessUsecase(repository: repository);
  },
);

final requestLocationPermissionUsecaseProvider =
    Provider<RequestLocationPermissionUsecase>((ref) {
      final repository = ref.watch(mapRepositoryProvider);
      return RequestLocationPermissionUsecase(repository: repository);
    });

final enableLocationServiceUsecaseProvider =
    Provider<EnableLocationServiceUsecase>((ref) {
      final repository = ref.watch(mapRepositoryProvider);
      return EnableLocationServiceUsecase(repository: repository);
    });

final watchLocationServiceUsecaseProvider =
    Provider<WatchLocationServiceUsecase>((ref) {
      final repository = ref.watch(mapRepositoryProvider);
      return WatchLocationServiceUsecase(repository: repository);
    });

final getBusinessByIdUsecaseProvider = Provider<GetBusinessByIdUsecase>((ref) {
  final repository = ref.watch(mapRepositoryProvider);
  return GetBusinessByIdUsecase(repository: repository);
});

final businessFavoritesUsecaseProvider = Provider<BusinessFavoritesUsecase>((
  ref,
) {
  final repository = ref.watch(mapRepositoryProvider);
  return BusinessFavoritesUsecase(repository: repository);
});

final trackBusinessVisitUsecaseProvider = Provider<TrackBusinessVisitUsecase>((
  ref,
) {
  final repository = ref.watch(mapRepositoryProvider);
  return TrackBusinessVisitUsecase(repository: repository);
});

// |---------------------------------| \\
// |------- LAYER 4: STATE ----------| \\
// |---------------------------------| \\

final mapTilesEnabledProvider = Provider<bool>((ref) => true);

final mapProvider = AsyncNotifierProvider<MapNotifier, AppPosition>(
  MapNotifier.new,
);

final businessesStreamProvider = StreamProvider<List<Business>>((ref) {
  final repository = ref.watch(mapRepositoryProvider);
  return GetBusinessesUsecase(repository: repository)();
});

final ownerProfileStreamProvider = StreamProvider.autoDispose
    .family<AppUser, String>((ref, ownerId) {
      final authRepository = ref.watch(authRepositoryProvider);
      return GetProfileUsecase(repository: authRepository)(userId: ownerId);
    });

final isBusinessFavoriteStreamProvider = StreamProvider.autoDispose
    .family<bool, String>((ref, businessId) {
      final repository = ref.watch(mapRepositoryProvider);
      return BusinessFavoritesUsecase(
        repository: repository,
      ).isFavorite(businessId);
    });

final mapVoiceSearchProvider =
    NotifierProvider<MapVoiceSearchNotifier, MapVoiceSearchState>(
      () => MapVoiceSearchNotifier(
        voiceSearchService: SpeechToTextVoiceSearchService(),
      ),
    );
