String businessPendingReasonLabel(String? code) {
  return switch (code) {
    'outside_pilot' => 'Fuera de la zona piloto de Ciudad Guzmán.',
    'possible_duplicate' =>
      'Hay una ficha similar; se revisará antes de publicar.',
    'prohibited_language' => 'El texto necesita revisión antes de publicar.',
    'suspicious_contact' => 'Los datos de contacto necesitan revisión.',
    _ => 'Tu solicitud está pendiente de revisión.',
  };
}
