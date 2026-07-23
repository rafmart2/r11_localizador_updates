class SeparadorTextosService {
  /// Escanea la flota y devuelve el desvío vertical exclusivo para el texto de un tren específico,
  /// evitando que las letras se solapen en los cruces.
  static double calcularDesvioVerticalTexto({
    required String trenId,
    required int direccionId,
    required double trenYFisico,
    required Map<String, double> mapaPosicionesY,
    required List<dynamic> listaTodosLosTrenes,
  }) {
    bool hayRiesgoSolapamientoTextos = false;

    // Escaneamos el resto de la flota en vivo
    for (var otroTren in listaTodosLosTrenes) {
      if (otroTren.id != trenId) {
        final double? otroYFisico = mapaPosicionesY[otroTren.id];
        
        // Si la distancia vertical es menor a 14 píxeles, las cajas de texto se van a pisar
        if (otroYFisico != null && (trenYFisico - otroYFisico).abs() < 14.0) {
          hayRiesgoSolapamientoTextos = true;
          break;
        }
      }
    }

    // ALGORITMO DE FRENADO VISUAL: El texto se para antes de solaparse
    if (hayRiesgoSolapamientoTextos) {
      // Si el tren va hacia Barcelona (baja por la pantalla), empujamos su texto hacia abajo (+8px)
      if (direccionId == 1) {
        return 0.4;
      } else {
        // Si el tren va hacia el norte (sube por la pantalla), frenamos su texto empujándolo hacia arriba (-8px)
        return -0.4;
      }
    }

    return 0.0; // Sin solapamientos, el texto se alinea perfectamente con el círculo
  }
}
