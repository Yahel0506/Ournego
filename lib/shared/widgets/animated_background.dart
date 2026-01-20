import 'dart:async';
import 'dart:math';
import 'dart:ui' as imageUrl;

import 'package:flutter/material.dart';
import 'package:ournego/main.dart';
import 'package:ournego/core/ournego_colors.dart';

class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({super.key});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

// AGREGAMOS LOS MIXINS (Los poderes para vigilar)
class _AnimatedBackgroundState extends State<AnimatedBackground>
    with WidgetsBindingObserver, RouteAware {
  Timer? timerAnimation;

  // Posiciones
  double top1 = 0;
  double left1 = 0;
  double top2 = 0;
  double left2 = 0;
  double top3 = 0;
  double left3 = 0;

  @override
  void initState() {
    super.initState();
    // 1. Nos registramos como vigilantes del ciclo de vida de la App
    WidgetsBinding.instance.addObserver(this);

    // 2. Iniciamos el movimiento INMEDIATAMENTE después de que se dibuje el primer frame
    // Esto evita que esperes 4 segundos para ver las bolas moverse la primera vez.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updatePositions(); // Mueve las bolas ya
      _startTimer(); // Prende el reloj para el futuro
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 3. Nos registramos en el RouteObserver para saber si nos tapan
    // (Importa routeObserver de tu main.dart)
    final modalRoute = ModalRoute.of(context);
    if (modalRoute is PageRoute) {
      routeObserver.subscribe(
        this,
        modalRoute,
      ); // Descomenta esto cuando importes routeObserver
    }
  }

  // --- LÓGICA DE CONTROL ---

  void _startTimer() {
    // Si ya existe un timer corriendo, no creamos otro
    if (timerAnimation != null && (timerAnimation?.isActive ?? false)) return;

    timerAnimation = Timer.periodic(const Duration(seconds: 4), (timer) {
      _updatePositions();
    });
  }

  void _stopTimer() {
    timerAnimation?.cancel();
    timerAnimation = null;
    print(
      "Animación Pausada (Ahorrando Batería)",
    ); // Para que veas en consola que funciona
  }

  void _updatePositions() {
    if (!mounted) return; // Seguridad extra

    setState(() {
      double w = MediaQuery.of(context).size.width;
      double h = MediaQuery.of(context).size.height;

      // Tu fórmula del efecto infinito
      top1 = (Random().nextDouble() * h) - 150;
      left1 = (Random().nextDouble() * w) - 150;

      top2 = (Random().nextDouble() * h) - 175;
      left2 = (Random().nextDouble() * w) - 175;

      top3 = (Random().nextDouble() * h) - 125;
      left3 = (Random().nextDouble() * w) - 125;
    });
  }

  // --- VIGILANTE 1: ESTADO DE LA APP (Home / Segundo Plano) ---
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _stopTimer(); // Si minimiza la app -> Stop
    } else if (state == AppLifecycleState.resumed) {
      _startTimer(); // Si vuelve -> Play
    }
  }

  // --- VIGILANTE 2: NAVEGACIÓN (Pila de pantallas) ---

  // Cuando empujas una pantalla nueva ENCIMA de esta (Did Push Next)
  @override
  void didPushNext() {
    _stopTimer();
  }

  // Cuando quitas la pantalla de arriba y esta vuelve a verse (Did Pop Next)
  @override
  void didPopNext() {
    _startTimer();
    _updatePositions(); // Para que se mueva apenas vuelvas
  }

  @override
  void dispose() {
    // LIMPIEZA TOTAL
    WidgetsBinding.instance.removeObserver(this); // Dejar de vigilar app
    routeObserver.unsubscribe(
      this,
    ); // Dejar de vigilar rutas (Descomenta al tener routeObserver)
    _stopTimer();
    super.dispose(); // El super SIEMPRE al final
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // CAPA 1
        AnimatedPositioned(
          duration: const Duration(seconds: 4),
          curve: Curves.easeInOut,
          top: top1,
          left: left1,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: OurnegoColors.aguamarina.withOpacity(0.4),
            ),
          ),
        ),
        // CAPA 2
        AnimatedPositioned(
          duration: const Duration(seconds: 4),
          curve: Curves.easeInOut,
          top: top2,
          left: left2,
          child: Container(
            width: 350,
            height: 350,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: OurnegoColors.azulCielo.withOpacity(0.3),
            ),
          ),
        ),
        // CAPA 3
        AnimatedPositioned(
          duration: const Duration(seconds: 4),
          curve: Curves.easeInOut,
          top: top3,
          left: left3,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: OurnegoColors.verdeCastleton.withOpacity(0.1),
            ),
          ),
        ),
        // CAPA BLUR
        BackdropFilter(
          filter: imageUrl.ImageFilter.blur(sigmaX: 80, sigmaY: 80),
          child: Container(
            color: Colors.transparent,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
      ],
    );
  }
}
