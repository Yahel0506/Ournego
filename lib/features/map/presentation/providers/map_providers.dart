import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ournego/features/auth/domain/entities/app_user.dart';
import 'package:ournego/features/auth/domain/usecases/get_profile_usecase.dart';
import 'package:ournego/features/auth/presentation/providers/auth_providers.dart';
import 'package:ournego/features/map/data/datasources/geolocator_datasource.dart';
import 'package:ournego/features/map/data/datasources/supabase_map_datasource.dart';
import 'package:ournego/features/map/data/repositories/map_repository_impl.dart';
import 'package:ournego/features/map/domain/entities/app_position.dart';
import 'package:ournego/features/map/domain/entities/business.dart';
import 'package:ournego/features/map/domain/usecases/get_businesses_usecase.dart';
import 'package:ournego/features/map/domain/usecases/get_current_location_usecase.dart';
import 'package:ournego/features/map/presentation/providers/notifiers/map_notifier.dart';
import 'package:ournego/features/map/presentation/providers/notifiers/modal_state_notifier.dart';
import 'package:ournego/features/map/presentation/providers/notifiers/selected_business_notifier.dart';

import '../../domain/usecases/business_favorites_usecase.dart';

final geolocationDatasourceProvider = Provider((ref) {
  return GeolocatorDatasource();
});

final businessesDatasourceProvider = Provider((ref) {
  return SupabaseMapDatasource();
});

final mapRepositoryProvider = Provider<MapRepositoryImpl>((ref) {
  final businessesDatasource = ref.read(businessesDatasourceProvider);
  final geolocationDatasource = ref.read(geolocationDatasourceProvider);
  return MapRepositoryImpl(
    geolocationDatasource: geolocationDatasource,
    businessesDatasource: businessesDatasource,
  );
});

final getCurrentLocationUsecaseProvider = Provider((ref) {
  final repository = ref.read(mapRepositoryProvider);
  return GetCurrentLocationUsecase(repository: repository);
});

final mapProvider = AsyncNotifierProvider<MapNotifier, AppPosition>(
  MapNotifier.new,
);

final businessesStreamProvider = StreamProvider<List<Business>>((ref) {
  final repository = ref.read(mapRepositoryProvider);
  return GetBusinessesUsecase(repository: repository)();
});

final modalState = NotifierProvider<ModalStateNotifier, int>(
  ModalStateNotifier.new,
);

final selectedBusiness = NotifierProvider<SelectedBusinessNotifier, Business?>(
  SelectedBusinessNotifier.new,
);

final ownerProfileStreamProvider = StreamProvider.autoDispose
    .family<AppUser, String>((ref, ownerId) {
      final authRepository = ref.watch(authRepositoryProvider);
      return GetProfileUsecase(repository: authRepository)(userId: ownerId);
    });

final isBusinessFavoriteStreamProvider = StreamProvider.autoDispose
    .family<bool, String>((ref, businessId) {
      final repository = ref.read(mapRepositoryProvider);
      return BusinessFavoritesUsecase(
        repository: repository,
      ).isFavorite(businessId);
    });

final businessFavoritesUsecaseProvider = Provider((ref) {
  final repository = ref.read(mapRepositoryProvider);
  return BusinessFavoritesUsecase(repository: repository);
});
