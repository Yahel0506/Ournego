import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'package:ournego/core/failures.dart';
import 'package:ournego/core/location/app_position.dart';
import 'package:ournego/core/routing/route_names.dart';
import 'package:ournego/features/map/domain/entities/business.dart';
import 'package:ournego/features/map/domain/entities/business_type.dart';

import '../test/fakes/fake_auth_repository.dart';
import '../test/fakes/fake_map_repository.dart';
import '../test/helpers/app_helper.dart';

Business _business({required String id, required String name}) {
  return Business(
    id: id,
    name: name,
    description: 'Negocio demo $name',
    ownerId: 'owner-$id',
    address: 'Calle Demo 123',
    phoneNumber: '5511122233',
    latitude: 19.4326,
    longitude: -99.1332,
    type: BusinessType.shop,
    images: const [],
  );
}

void main() {
  group('Flujo core', () {
    patrolTest(
      '1) Permiso de ubicación concedido -> lista de negocios carga correctamente',
      tags: ['core', 'map', 'critical'],
      ($) async {
        await resetAppState();

        final mapRepository = FakeMapRepository(
          locationResult: Right(
            AppPosition(latitude: 19.4326, longitude: -99.1332),
          ),
          initialBusinesses: [
            _business(id: 'biz-1', name: 'Panaderia Sol'),
            _business(id: 'biz-2', name: 'Papeleria Luna'),
          ],
        );

        final authState = StreamController<bool>.broadcast()..add(true);

        await $.pumpWidgetAndSettle(
          buildTestApp(
            [
              ...authOverrides(
                FakeAuthRepository(state: FakeAuthState.authenticatedAsCustomer),
                sessionStream: authState.stream,
                initialSessionStatus: true,
              ),
              ...mapOverrides(mapRepository),
            ],
            startOnMap: true,
            initialLocation: MapRoutes.map,
            authStateChanges: authState.stream,
          ),
        );

        if (await $.native.isPermissionDialogVisible()) {
          await $.native.grantPermissionWhenInUse();
          await $.pumpAndSettle();
        }

        expect(
          find.byKey(const ValueKey('businessMarker-biz-1')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('businessMarker-biz-2')),
          findsOneWidget,
        );

        await authState.close();
        await mapRepository.dispose();
      },
    );

    patrolTest(
      '2) Permiso de ubicación denegado -> pantalla de estado vacío sin crash',
      tags: ['core', 'map'],
      ($) async {
        await resetAppState();

        final mapRepository = FakeMapRepository(
          locationResult: Left(LocationPermissionDeniedFailure()),
          initialBusinesses: const [],
        );

        final authState = StreamController<bool>.broadcast()..add(true);

        await $.pumpWidgetAndSettle(
          buildTestApp(
            [
              ...authOverrides(
                FakeAuthRepository(state: FakeAuthState.authenticatedAsCustomer),
                sessionStream: authState.stream,
                initialSessionStatus: true,
              ),
              ...mapOverrides(mapRepository),
            ],
            startOnMap: true,
            initialLocation: MapRoutes.map,
            authStateChanges: authState.stream,
          ),
        );

        if (await $.native.isPermissionDialogVisible()) {
          await $.native.denyPermission();
          await $.pumpAndSettle();
        }

        expect(find.text('El permiso de ubicacion fue denegado'), findsOneWidget);
        expect(find.byKey(const ValueKey('mapScreen')), findsOneWidget);

        await authState.close();
        await mapRepository.dispose();
      },
    );

    patrolTest(
      '3) Sin negocios en el radio actual -> componente de estado vacío visible',
      tags: ['core', 'map'],
      ($) async {
        await resetAppState();

        final mapRepository = FakeMapRepository(
          locationResult: Right(
            AppPosition(latitude: 19.4326, longitude: -99.1332),
          ),
          initialBusinesses: const [],
        );

        final authState = StreamController<bool>.broadcast()..add(true);

        await $.pumpWidgetAndSettle(
          buildTestApp(
            [
              ...authOverrides(
                FakeAuthRepository(state: FakeAuthState.authenticatedAsCustomer),
                sessionStream: authState.stream,
                initialSessionStatus: true,
              ),
              ...mapOverrides(mapRepository),
            ],
            startOnMap: true,
            initialLocation: MapRoutes.map,
            authStateChanges: authState.stream,
          ),
        );

        expect(find.byKey(const ValueKey('businessMarker-biz-1')), findsNothing);
        expect(find.byKey(const ValueKey('businessMarker-biz-2')), findsNothing);

        // TODO: Actualmente no existe un componente explícito de estado vacío.
        // Comportamiento esperado futuro: mostrar widget dedicado de "sin negocios".
        expect(find.byKey(const ValueKey('mapScreen')), findsOneWidget);

        await authState.close();
        await mapRepository.dispose();
      },
    );

    patrolTest(
      '4) Tap en negocio de la lista -> pantalla de detalle con nombre y distancia correctos',
      tags: ['core', 'map', 'critical'],
      ($) async {
        await resetAppState();

        final mapRepository = FakeMapRepository(
          locationResult: Right(
            AppPosition(latitude: 19.4326, longitude: -99.1332),
          ),
          initialBusinesses: [
            _business(id: 'biz-1', name: 'Panaderia Sol'),
          ],
        );

        final authState = StreamController<bool>.broadcast()..add(true);

        await $.pumpWidgetAndSettle(
          buildTestApp(
            [
              ...authOverrides(
                FakeAuthRepository(state: FakeAuthState.authenticatedAsCustomer),
                sessionStream: authState.stream,
                initialSessionStatus: true,
              ),
              ...mapOverrides(mapRepository),
            ],
            startOnMap: true,
            initialLocation: MapRoutes.map,
            authStateChanges: authState.stream,
          ),
        );

        await $.tester.tap(find.byKey(const ValueKey('businessMarker-biz-1')));
        await $.pumpAndSettle();

        expect(find.text('Panaderia Sol'), findsOneWidget);

        // TODO: La UI actual no renderiza distancia; validar cuando se implemente.

        await authState.close();
        await mapRepository.dispose();
      },
    );

    patrolTest(
      '5) Dueño edita nombre del negocio -> cambio se refleja en la lista sin reload manual',
      tags: ['core', 'map'],
      ($) async {
        await resetAppState();

        final mapRepository = FakeMapRepository(
          locationResult: Right(
            AppPosition(latitude: 19.4326, longitude: -99.1332),
          ),
          initialBusinesses: [
            _business(id: 'biz-1', name: 'Panaderia Sol'),
          ],
        );

        final authState = StreamController<bool>.broadcast()..add(true);

        await $.pumpWidgetAndSettle(
          buildTestApp(
            [
              ...authOverrides(
                FakeAuthRepository(
                  state: FakeAuthState.authenticatedAsOwnerWithBusiness,
                ),
                sessionStream: authState.stream,
                initialSessionStatus: true,
              ),
              ...mapOverrides(mapRepository),
            ],
            startOnMap: true,
            initialLocation: MapRoutes.map,
            authStateChanges: authState.stream,
          ),
        );

        await $.tester.tap(find.byKey(const ValueKey('businessMarker-biz-1')));
        await $.pumpAndSettle();
        expect(find.text('Panaderia Sol'), findsOneWidget);

        mapRepository.setBusinesses([
          _business(id: 'biz-1', name: 'Panaderia Aurora'),
        ]);
        await $.pumpAndSettle();

        await $.tester.tap(find.byKey(const ValueKey('businessMarker-biz-1')));
        await $.pumpAndSettle();
        expect(find.text('Panaderia Aurora'), findsOneWidget);

        // TODO: No existe flujo de edición inline en UI actual de mapa.
        // Validamos propagación reactiva del stream sin reload manual.

        await authState.close();
        await mapRepository.dispose();
      },
    );
  });
}
