import 'package:flutter_test/flutter_test.dart';

import 'package:ournego/features/map/domain/entities/business.dart';
import 'package:ournego/features/map/domain/entities/business_hours.dart';
import 'package:ournego/features/map/domain/entities/business_type.dart';
import 'package:ournego/features/map/presentation/widgets/floating_sheet/models/sheet_business_data.dart';

void main() {
  Business buildBusiness() {
    return Business(
      id: 'biz-1',
      name: 'Panaderia Sol',
      description: 'Pan fresco',
      ownerId: 'owner-1',
      address: 'Av. Principal 123',
      phoneNumber: '521234567890',
      latitude: 19.4326,
      longitude: -99.1332,
      type: BusinessType.drinkAndEat,
      images: const ['https://example.com/image.jpg'],
      visitCount: 7,
      hours: const [
        BusinessHours(dayOfWeek: 0, openMinutes: 9 * 60, closeMinutes: 18 * 60),
        BusinessHours(dayOfWeek: 4, openMinutes: 8 * 60, closeMinutes: 16 * 60),
      ],
    );
  }

  test('preserves hours through json roundtrip', () {
    final sheet = SheetBusinessData.fromBusiness(
      buildBusiness(),
      isFavorite: true,
    );
    final roundTrip = SheetBusinessData.fromJson(sheet.toJson());

    expect(roundTrip.hours, hasLength(2));
    expect(roundTrip.hours.first.dayOfWeek, 0);
    expect(roundTrip.hours.first.openMinutes, 9 * 60);
    expect(roundTrip.isFavorite, isTrue);
  });

  test('accepts legacy json without hours', () {
    final sheet = SheetBusinessData.fromJson({
      'id': 'biz-1',
      'name': 'Panaderia Sol',
      'description': 'Pan fresco',
      'ownerId': 'owner-1',
      'address': 'Av. Principal 123',
      'phoneNumber': '521234567890',
      'type': BusinessType.drinkAndEat.index,
      'isFavorite': false,
      'rating': 4.5,
      'images': const <String>[],
    });

    expect(sheet.hours, isEmpty);
  });
}
