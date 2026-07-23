class ExtractorRetrasosService {
  
  /// Estructura de respuesta interna para encapsular el análisis del delay
  static Map<String, dynamic> extraerRetrasoReal({
    required String numeroTrenPuro,
    required String stopIdActual,
    required Map<String, Map<String, dynamic>> mapaTripUpdates,
  }) {
    int minutosRetraso = 0;
    String estadoMarchaTexto = 'En hora';
    Map<String, dynamic>? tripUpdateNode;

    // 1. BÚSQUEDA ELÁSTICA BLINDADA DE LA MISIÓN COMERCIAL
    if (mapaTripUpdates.containsKey(numeroTrenPuro)) {
      final Map<String, dynamic> entidad = mapaTripUpdates[numeroTrenPuro] ?? {};
      tripUpdateNode = entidad['trip_update'] ?? entidad['tripUpdate'];
    } else {
      for (var entry in mapaTripUpdates.entries) {
        if (entry.key.toUpperCase().contains(numeroTrenPuro.toUpperCase())) {
          tripUpdateNode = entry.value['trip_update'] ?? entry.value['tripUpdate'];
          break; 
        }
      }
    }

    // Si el cruce con el JSON secundario falla por completo, retornamos el estado base
    if (tripUpdateNode == null) {
      return {
        'minutos': 0,
        'texto': 'En hora',
      };
    }

    // 2. EXTRACCIÓN DIRECTA DE LA RAÍZ DE ADIF (Sufijo _LD)
    int? delaySegundosDetectado;
    if (tripUpdateNode.containsKey('delay')) {
      delaySegundosDetectado = int.tryParse(tripUpdateNode['delay']?.toString() ?? '0');
    }

    // 3. ESCANEO SECUNDARIO POR PARADAS (Tolerante a formatos CamelCase / snake_case)
    if (delaySegundosDetectado == null || delaySegundosDetectado == 0) {
      final List<dynamic> stopTimeUpdates = tripUpdateNode['stop_time_update'] ?? tripUpdateNode['stopTimeUpdate'] ?? [];
      
      if (stopTimeUpdates.isNotEmpty) {
        for (var update in stopTimeUpdates) {
          final String stopIdUpdate = (update['stop_id'] ?? update['stopId'] ?? '').toString().trim();
          if (stopIdUpdate == stopIdActual && stopIdActual.isNotEmpty) {
            final Map<String, dynamic> delayNode = update['departure'] ?? update['arrival'] ?? {};
            if (delayNode.containsKey('delay')) {
              delaySegundosDetectado = int.tryParse(delayNode['delay']?.toString() ?? '0');
              break; 
            }
          }
        }

        // Si sigue sin detectarse, rescatamos el delay de la primera parada registrada
        if (delaySegundosDetectado == null || delaySegundosDetectado == 0) {
          final Map<String, dynamic> primerControl = stopTimeUpdates.first;
          final Map<String, dynamic> delayNode = primerControl['departure'] ?? primerControl['arrival'] ?? {};
          if (delayNode.containsKey('delay')) {
            delaySegundosDetectado = int.tryParse(delayNode['delay']?.toString() ?? '0');
          }
        }
      }
    }

    // 4. COMPUTACIÓN FERROVIARIA FINAL DEL RETRASO (Formato compacto con símbolos)
    if (delaySegundosDetectado != null && delaySegundosDetectado != 0) {
      minutosRetraso = (delaySegundosDetectado / 60).round();
      
      if (minutosRetraso > 0) {
        // En lugar de "Demorado +X min", dejamos solo el "+X min"
        estadoMarchaTexto = '+$minutosRetraso min';
      } else if (minutosRetraso < 0) {
        // En lugar de "Adelantado", dejamos solo el "-X min"
        minutosRetraso = minutosRetraso.abs();
        estadoMarchaTexto = '-$minutosRetraso min';
      }
    }


    return {
      'minutos': minutosRetraso,
      'texto': estadoMarchaTexto,
    };
  }
}
