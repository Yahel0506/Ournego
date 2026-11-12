import 'package:ournego/features/moderation/domain/entities/review_listing.dart';

/// Something a reviewer should know before approving a listing.
enum ListingIssue {
  // Blocking: the listing is not useful (or not valid) as it is.
  nameTooShort(blocking: true, message: 'El nombre es demasiado corto.'),
  invalidCategory(blocking: true, message: 'La categoría no es válida.'),
  missingAddress(blocking: true, message: 'Falta la dirección.'),
  invalidCoordinates(
    blocking: true,
    message: 'Las coordenadas faltan o están fuera de rango.',
  ),
  missingImages(blocking: true, message: 'No tiene ninguna imagen.'),
  invalidPhone(
    blocking: true,
    message: 'El teléfono no parece un número válido.',
  ),
  invalidHours(
    blocking: true,
    message: 'Hay horarios con una hora inválida o sin duración.',
  ),

  // Warnings: worth a look, the reviewer may still approve.
  missingPhone(blocking: false, message: 'No tiene teléfono de contacto.'),
  missingHours(blocking: false, message: 'No tiene horarios.'),
  missingDescription(blocking: false, message: 'No tiene descripción.');

  const ListingIssue({required this.blocking, required this.message});

  /// A blocking issue stops the approval; a warning only informs.
  final bool blocking;
  final String message;
}

/// Why two listings look like the same business.
enum DuplicateReason {
  sameNameAndPlace('Mismo nombre y misma zona'),
  samePhone('Mismo teléfono'),
  sameAddress('Misma dirección');

  const DuplicateReason(this.label);
  final String label;
}

class PossibleDuplicate {
  const PossibleDuplicate({required this.listing, required this.reason});

  final ReviewListing listing;
  final DuplicateReason reason;
}

/// Result of checking a listing before approving it.
class ListingReport {
  const ListingReport({required this.issues, required this.duplicates});

  final List<ListingIssue> issues;
  final List<PossibleDuplicate> duplicates;

  List<ListingIssue> get blocking =>
      issues.where((i) => i.blocking).toList(growable: false);

  List<ListingIssue> get warnings =>
      issues.where((i) => !i.blocking).toList(growable: false);

  /// Approving is not allowed while there is invalid content.
  bool get canApprove => blocking.isEmpty;

  /// Approving needs an explicit second look when anything was flagged.
  bool get needsAttention => issues.isNotEmpty || duplicates.isNotEmpty;
}
