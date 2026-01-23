import 'package:flutter/material.dart';

class OurnegoColors {
  // --- Códigos Base del PDF ---
  static const Color azulCielo = Color(0xFF3BCFED);
  static const Color cianClaro = Color(0xFFD8F7FD);
  static const Color azulVerde = Color(0xFF009ABE);

  static const Color aguamarina = Color(0xFF7EEFC2);
  static const Color verdeMenta = Color(0xFFDFFDF1);
  static const Color mentaOscuro = Color(0xFF3EBF89);

  static const Color verdeCastleton = Color(0xFF055F46);
  static const Color verdeBrunswick = Color(0xFF034E3A);

  static const Color noche = Color(0xFF161616);
  static const Color blanco = Color(0xFFFFFFFF);

  // TODO: Extract semantic color tokens (e.g. `background`, `surface`,
  // `accent`) and provide accessibility helpers (contrast checks).
  // Perspective: Add unit tests for color contrast and a `fromHex`
  // helper to allow theming from design tokens.

  //* --- TEMA CLARO ---
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: blanco,
    colorScheme: const ColorScheme.light(
      primary: azulCielo,
      onPrimary: Colors.white, // Texto sobre el color primario
      primaryContainer: cianClaro,
      onPrimaryContainer: azulVerde,

      secondary: aguamarina,
      onSecondary: verdeCastleton,
      secondaryContainer: verdeMenta,

      tertiary: verdeCastleton, // Usamos tu acento como terciario

      surface: Color(0xFFF4FBF9), // Superficie con tinte ligero
      onSurface: noche,
      error: Color(0xFFBA1A1A),
    ),
  );

  // --- TEMA OSCURO ---
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: noche,
    colorScheme: const ColorScheme.dark(
      primary: azulCielo, // El color brillante se mantiene para acentos
      onPrimary: noche, // Texto negro sobre el azul brillante es muy legible
      primaryContainer: verdeBrunswick, // Fondo de botones más apagado
      onPrimaryContainer: cianClaro,

      secondary: mentaOscuro,
      onSecondary: noche,
      secondaryContainer: verdeCastleton,

      surface: Color(0xFF1E2625), // Gris oscuro verdoso
      onSurface: Color(0xFFE1E3E1), // Blanco hueso

      outline: Color(0xFF89938F), // Bordes
    ),
  ); //*/
}
