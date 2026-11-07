import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ournego/features/map/domain/entities/business.dart';
import 'package:ournego/features/map/domain/entities/business_type.dart';
import 'package:ournego/features/map/presentation/providers/map_providers.dart';
import 'package:ournego/features/map/presentation/providers/notifiers/map_businesses_notifier.dart';

import '../../../../fakes/fake_map_repository.dart';

Business _business(String id) => Business(
  id: id,
  name: 'Negocio $id',
  description: '',
  ownerId: 'owner',
  address: 'Calle 1',
  phoneNumber: null,
  latitude: 19.4,
  longitude: -99.1,
  type: BusinessType.drinkAndEat,
  images: const [],
  visitCount: 0,
  hours: const [],
);

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  late FakeMapRepository repository;
  late ProviderContainer container;

  MapBusinesses current() => container.read(mapBusinessesProvider);

  setUp(() async {
    repository = FakeMapRepository();
    container = ProviderContainer(
      overrides: [mapRepositoryProvider.overrideWith((ref) => repository)],
    );
    addTearDown(container.dispose);
    container.listen(businessesStreamProvider, (_, _) {});
    container.listen(mapBusinessesProvider, (_, _) {});
    await _settle();
    repository.setBusinesses([_business('a')]);
    await _settle();
  });

  test(
    'keeps the last businesses and marks them stale when the stream fails',
    () async {
      expect(current().businesses!.map((b) => b.id), ['a']);
      expect(current().isStale, isFalse);

      repository.emitBusinessesError();
      await _settle();

      expect(container.read(businessesStreamProvider).hasError, isTrue);
      expect(current().businesses!.map((b) => b.id), ['a']);
      expect(current().isStale, isTrue);
    },
  );

  test(
    'stays populated while the stream reloads after an invalidation',
    () async {
      repository.emitBusinessesError();
      await _settle();

      container.invalidate(businessesStreamProvider);
      await _settle();

      expect(current().businesses!.map((b) => b.id), ['a']);
    },
  );

  test(
    'refreshes by itself and drops the stale mark when data returns',
    () async {
      repository.emitBusinessesError();
      await _settle();

      repository.setBusinesses([_business('a'), _business('b')]);
      await _settle();

      expect(current().businesses!.map((b) => b.id), ['a', 'b']);
      expect(current().isStale, isFalse);
    },
  );
}
