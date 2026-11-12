import 'dart:math' as math;

import 'package:ournego/features/moderation/domain/entities/listing_check.dart';
import 'package:ournego/features/moderation/domain/entities/review_listing.dart';

/// Two listings with the same name closer than this count as the same place.
const double duplicateRadiusMeters = 150;

const int _minNameLength = 3;
const int _maxCategory = 12;
const int _minPhoneDigits = 7;
const int _maxPhoneDigits = 15;

/// Checks one listing against the pilot contract (name, category, address,
/// coordinates, contact, images and hours) and against the rest of the catalog
/// for obvious duplicates. Pure: [others] is whatever the caller loaded.
ListingReport checkListing(
  ReviewListing listing, {
  Iterable<ReviewListing> others = const [],
}) {
  return ListingReport(
    issues: _issuesOf(listing),
    duplicates: _duplicatesOf(listing, others),
  );
}

List<ListingIssue> _issuesOf(ReviewListing l) {
  final issues = <ListingIssue>[];

  if (l.name.trim().length < _minNameLength) {
    issues.add(ListingIssue.nameTooShort);
  }
  if (l.category < 0 || l.category > _maxCategory) {
    issues.add(ListingIssue.invalidCategory);
  }
  if (l.address.trim().isEmpty) issues.add(ListingIssue.missingAddress);
  if (!_hasValidCoordinates(l)) issues.add(ListingIssue.invalidCoordinates);
  if (l.images.isEmpty) issues.add(ListingIssue.missingImages);

  final phone = l.phoneNumber;
  if (phone == null) {
    issues.add(ListingIssue.missingPhone);
  } else {
    final digits = phoneDigits(phone);
    if (digits.length < _minPhoneDigits || digits.length > _maxPhoneDigits) {
      issues.add(ListingIssue.invalidPhone);
    }
  }

  if (l.hours.isEmpty) {
    issues.add(ListingIssue.missingHours);
  } else if (l.hours.any(
    (h) =>
        h.dayOfWeek < 0 ||
        h.dayOfWeek > 6 ||
        h.openMinutes < 0 ||
        h.openMinutes >= 24 * 60 ||
        h.closeMinutes < 0 ||
        h.closeMinutes > 24 * 60 ||
        h.openMinutes == h.closeMinutes,
  )) {
    issues.add(ListingIssue.invalidHours);
  }

  if (l.description.trim().isEmpty) issues.add(ListingIssue.missingDescription);
  return issues;
}

bool _hasValidCoordinates(ReviewListing l) {
  final lat = l.latitude;
  final lng = l.longitude;
  if (lat == null || lng == null) return false;
  if (lat.isNaN || lng.isNaN) return false;
  if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return false;
  // (0, 0) is what an unset position looks like.
  return !(lat == 0 && lng == 0);
}

List<PossibleDuplicate> _duplicatesOf(
  ReviewListing listing,
  Iterable<ReviewListing> others,
) {
  final result = <PossibleDuplicate>[];
  final seen = <String>{};
  for (final other in others) {
    if (other.id == listing.id || !seen.add(other.id)) continue;
    final reason = _duplicateReason(listing, other);
    if (reason != null) {
      result.add(PossibleDuplicate(listing: other, reason: reason));
    }
  }
  return result;
}

DuplicateReason? _duplicateReason(ReviewListing a, ReviewListing b) {
  final phoneA = a.phoneNumber == null ? '' : phoneDigits(a.phoneNumber!);
  final phoneB = b.phoneNumber == null ? '' : phoneDigits(b.phoneNumber!);
  if (phoneA.length >= _minPhoneDigits &&
      _lastDigits(phoneA) == _lastDigits(phoneB)) {
    return DuplicateReason.samePhone;
  }

  final nameA = normalizeText(a.name);
  final nameB = normalizeText(b.name);
  if (nameA.isNotEmpty && nameA == nameB) {
    final distance = _distanceMeters(a, b);
    final sameAddress =
        normalizeText(a.address).isNotEmpty &&
        normalizeText(a.address) == normalizeText(b.address);
    if (sameAddress ||
        (distance != null && distance <= duplicateRadiusMeters)) {
      return DuplicateReason.sameNameAndPlace;
    }
  }

  final addressA = normalizeText(a.address);
  if (addressA.isNotEmpty && addressA == normalizeText(b.address)) {
    return DuplicateReason.sameAddress;
  }
  return null;
}

String _lastDigits(String digits) =>
    digits.length <= 8 ? digits : digits.substring(digits.length - 8);

/// Digits only, so "+34 600-111-222" and "600111222" compare equal.
String phoneDigits(String raw) => raw.replaceAll(RegExp(r'\D'), '');

/// Lower case, no accents or punctuation, single spaces.
String normalizeText(String raw) {
  const from = 'áàäâãéèëêíìïîóòöôõúùüûñç';
  const to = 'aaaaaeeeeiiiiooooouuuunc';
  final buffer = StringBuffer();
  for (final rune in raw.toLowerCase().runes) {
    final char = String.fromCharCode(rune);
    final index = from.indexOf(char);
    buffer.write(index == -1 ? char : to[index]);
  }
  return buffer
      .toString()
      .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

double? _distanceMeters(ReviewListing a, ReviewListing b) {
  if (!_hasValidCoordinates(a) || !_hasValidCoordinates(b)) return null;
  const earthRadius = 6371000.0;
  double rad(double deg) => deg * math.pi / 180;
  final dLat = rad(b.latitude! - a.latitude!);
  final dLng = rad(b.longitude! - a.longitude!);
  final h =
      math.pow(math.sin(dLat / 2), 2) +
      math.cos(rad(a.latitude!)) *
          math.cos(rad(b.latitude!)) *
          math.pow(math.sin(dLng / 2), 2);
  return 2 * earthRadius * math.asin(math.sqrt(h.toDouble()));
}
