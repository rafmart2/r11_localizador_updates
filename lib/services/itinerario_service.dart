class ItinerarioService {
  // Diccionario unificado y maestro con los PKs de tu estaciones.json
  static const Map<String, double> pksEstaciones = {
    'Barcelona-Sants': 0.0, 'Barcelona-Passeig de Gràcia': 4.8, 'Barcelona-El Clot-Aragó': 7.5,
    'Sant Andreu Comtal': 11.1, 'Montcada i Reixac': 18.2, 'Mollet-Sant Fost': 23.3, 'Granollers Centre': 35.5,
    'Cardedeu': 43.1, 'Sant Celoni': 58.7, 'Gualba': 64.3, 'Riells i Viabrea-Breda': 68.4, 'Hostalric': 75.2,
    'Maçanet-Massanes': 82.2, 'Sils': 89.8, 'Caldes de Malavella': 97.4, 'Riudellots': 103.5, 'Fornells de la Selva': 109.7,
    'Girona': 115.1, 'Celrà': 123.9, 'Bordils-Juià': 128.7, 'Flaçà': 132.8, 'Sant Jordi Desvalls': 139.4, 
    'Camallera': 144.9, 'Vilamalla': 154.8, 'Figueres': 159.9, 'Vilajuïga': 163.5, 'Llançà': 165.2, 
    'Colera': 166.8, 'Portbou': 167.3, 'Cerbère': 168.7
  };

  /// Extrae el itinerario de paradas futuras reales de Adif y calcula la cuenta atrás
  static List<Map<String, dynamic>> obtenerProximasParadasReales(
    Map<String, dynamic>? entidadComercial, 
    Map<String, String> diccionarioNombresEstaciones
  ) {
    if (entidadComercial == null) {
      return [];
    }

    final Map<String, dynamic> tripUpdateNode = entidadComercial['trip_update'] ?? entidadComercial['tripUpdate'] ?? {};
    final List<dynamic> stopTimeUpdates = tripUpdateNode['stop_time_update'] ?? tripUpdateNode['stopTimeUpdate'] ?? [];
    
    final List<Map<String, dynamic>> itinerarioResultado = [];
    final DateTime ahoraLocal = DateTime.now();

    for (var update in stopTimeUpdates) {
      if (update == null) {
        continue;
      }

      String stopId = (update['stop_id'] ?? update['stopId'] ?? '').toString().trim();
      if (stopId.contains('_')) {
        stopId = stopId.split('_').last;
      }
      if (stopId.startsWith('0') && stopId.length > 4 && stopId.startsWith('07')) {
        stopId = stopId.substring(1);
      }

      // TRADUCTOR DE ANDENES LOCALES DE LA RG1 (Caza los códigos 79308 y 79309)
      String nombreLegible = diccionarioNombresEstaciones[stopId] ?? 'Punto de control';
      if (stopId == '79309') {
        nombreLegible = 'Figueres';
      } else if (stopId == '79308') {
        nombreLegible = 'Vilamalla';
      }

      if (!pksEstaciones.containsKey(nombreLegible)) {
        continue;
      }

      final Map<String, dynamic> timeNode = update['arrival'] ?? update['departure'] ?? {};
      final int? unixTimestampUtc = int.tryParse(timeNode['time']?.toString() ?? '');

      if (unixTimestampUtc != null && unixTimestampUtc > 0) {
        final DateTime horaUtc = DateTime.fromMillisecondsSinceEpoch(unixTimestampUtc * 1000, isUtc: true);
        final DateTime horaLocalAdif = horaUtc.toLocal();

        // =======================================================================
        // BLINDAJE DE CALENDARIO REAL (Sana el vaciado del mes congelado)
        // =======================================================================
        // Reconstruimos la fecha forzando el día de hoy en el móvil del usuario, 
        // absorbiendo únicamente la hora y el minuto real que envía Adif.
        final DateTime horaSincronizadaHoy = DateTime(
          ahoraLocal.year,
          ahoraLocal.month,
          ahoraLocal.day,
          horaLocalAdif.hour,
          horaLocalAdif.minute,
        );

        final String horaFormateada = '${horaSincronizadaHoy.hour.toString().padLeft(2, '0')}:${horaSincronizadaHoy.minute.toString().padLeft(2, '0')}';
        
        // MATEMÁTICA DE TIEMPO RESTANTE SOBRE EL MISMO DÍA
        final Duration diferencia = horaSincronizadaHoy.difference(ahoraLocal);
        int minutosRestantes = diferencia.inMinutes;
        if (minutosRestantes < 0) {
          minutosRestantes = 0;
        }

        itinerarioResultado.add({
          'nombre': nombreLegible,
          'horaTexto': horaFormateada,
          'minutosFaltan': minutosRestantes,
          'timestamp': unixTimestampUtc,
        });
      }
    }

    // Ordenamos cronológicamente según la marcha real de Adif
    itinerarioResultado.sort((a, b) => (a['timestamp'] as int).compareTo(b['timestamp'] as int));

    // INYECCIÓN DINÁMICA DE TEXTOS DE CUENTA ATRÁS CORRELATIVOS
    for (int i = 0; i < itinerarioResultado.length; i++) {
      itinerarioResultado[i]['paradasRestantesText'] = 'Le queda ${i + 1} parada${i > 0 ? "s" : ""}';
      itinerarioResultado[i]['tiempoRestanteText'] = 'Llegará en ${itinerarioResultado[i]['minutosFaltan']} min';
    }

    return itinerarioResultado;
  }
}
