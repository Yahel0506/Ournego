#!/bin/bash

# Clonar Flutter si no existe
if [ ! -d "flutter" ]; then
  git clone https://github.com/flutter/flutter.git -b stable
fi

# Agregar Flutter al PATH de esta sesión
export PATH="$PATH:`pwd`/flutter/bin"

# Pre-descargar artefactos y correr build
flutter doctor
flutter build web --release --web-renderer auto