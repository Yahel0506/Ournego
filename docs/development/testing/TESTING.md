# UI Automation Testing (Patrol)

## Requisitos previos

1. Instalar dependencias:

```bash
flutter pub get
```

2. Tener Patrol CLI instalado:

```bash
dart pub global activate patrol_cli
```

## Cómo correr la suite completa

```bash
patrol test
```

## Cómo correr solo tests críticos de auth

```bash
patrol test --tags auth
```

## Qué hacer cuando un test falla

1. Revisa primero el nombre del escenario que falla (Patrol imprime el test exacto y el paso).
2. Busca el primer `expect` fallido o timeout en el stacktrace.
3. Si falla en permisos nativos, valida que el emulador/simulador permita automation del diálogo.
4. Repite solo ese archivo para depuración rápida:

```bash
patrol test integration_test/auth_test.dart
```

5. Si el fallo viene de un TODO documentado, compara con el comportamiento actual de la app y ajusta cuando la feature exista.

## Escenarios cubiertos

### Onboarding / Sesión (`integration_test/onboarding_test.dart`)

- Usuario nuevo completa onboarding y persiste flag en storage.
- Usuario con onboarding completo salta a autenticación.
- Sesión válida entra a app sin login.
- Token expirado redirige a login sin crash/spinner infinito.
- Cierre de app a mitad de onboarding conserva comportamiento actual (TODO funcional documentado).
- Logout manual exige credenciales en próxima apertura.

### Auth por tipo de usuario (`integration_test/auth_test.dart`)

- Login cliente normal navega a mapa.
- Login dueño con negocio navega a dashboard de negocio.
- Login dueño sin negocio navega a registro de negocio.
- Credenciales incorrectas muestran error legible.
- Sin conexión muestra error controlado.
- Cuenta suspendida: caso cubierto con TODO por ausencia de estado explícito en modelo actual.

### Flujo core de mapa (`integration_test/core_flow_test.dart`)

- Permiso de ubicación concedido carga markers de negocios.
- Permiso de ubicación denegado no crashea y mantiene estado estable.
- Sin negocios en radio actual (TODO: falta componente explícito de estado vacío en UI actual).
- Tap en negocio abre detalle y muestra nombre (TODO: distancia aún no renderizada).
- Actualización de nombre de negocio por stream se refleja sin reload manual.
