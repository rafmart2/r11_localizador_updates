class Incidencia {
  final String id;
  final String descripcion;
  final String causa;
  final String efecto;
  final String lineasAfectadas;
  final DateTime? horaInicio;
  final DateTime? horaFin;

  Incidencia({
    required this.id,
    required this.descripcion,
    required this.causa,
    required this.efecto,
    required this.lineasAfectadas,
    this.horaInicio,
    this.horaFin,
  });

  factory Incidencia.fromGtfsRt(Map<String, dynamic> entityNode) {
    final String alertId = (entityNode['id'] ?? 'Aviso-S/N').toString();
    final Map<String, dynamic> alertNode = entityNode['alert'] ?? {};
    
    // 1. Parsear Descripción Completa
    final Map<String, dynamic> descTextNode = alertNode['description_text'] ?? {};
    final List<dynamic> translationList = descTextNode['translation'] ?? [];
    String descTexto = 'Sin descripción detallada proporcionada.';
    if (translationList.isNotEmpty) {
      descTexto = (translationList.first['text'] ?? descTexto).toString();
    }

    // 2. Traducir Causas Técnicas Oficiales de Adif
    final String causeRaw = (alertNode['cause'] ?? 'UNKNOWN_CAUSE').toString().toUpperCase();
    String causaLegible = 'Causa Desconocida';
    if (causeRaw.contains('TECHNICAL')) causaLegible = 'Avería Técnica / Caída de Tensión';
    if (causeRaw.contains('WEATHER')) causaLegible = 'Meteorología Adversa / Temporal';
    if (causeRaw.contains('ACCIDENT')) causaLegible = 'Incidente / Accidente en la Vía';
    if (causeRaw.contains('MAINTENANCE')) causaLegible = 'Obras de Mantenimiento Planificadas';
    if (causeRaw.contains('STRIKE')) causaLegible = 'Huelga / Paro de Personal';

    // 3. Traducir Efectos en el Servicio Ferroviario
    final String effectRaw = (alertNode['effect'] ?? 'UNKNOWN_EFFECT').toString().toUpperCase();
    String efectoLegible = 'Retrasos indeterminados';
    if (effectRaw.contains('SIGNIFICANT_DELAYS')) efectoLegible = 'Retrasos Significativos generalizados';
    if (effectRaw.contains('DETOUR')) efectoLegible = 'Desvío de Trenes / Vía Única Provisional';
    if (effectRaw.contains('NO_SERVICE')) efectoLegible = 'Servicio Suspendido / Transbordo por Carretera';
    if (effectRaw.contains('REDUCED_SERVICE')) efectoLegible = 'Frecuencias de paso Reducidas';

    // 4. Rastrear Líneas o Servicios Afectados
    final List<dynamic> informedEntityList = alertNode['informed_entity'] ?? [];
    // CORRECCIÓN CLAVE: Cambiado 'codigosLíneas' por 'codigosLineas' (sin tilde nativa en Dart)
    List<String> codigosLineas = [];
    for (var item in informedEntityList) {
      final String route = (item['routeId'] ?? '').toString();
      final String trip = (item['tripId'] ?? '').toString();
      if (route.isNotEmpty && !codigosLineas.contains(route)) codigosLineas.add('Línea $route');
      if (trip.isNotEmpty && !codigosLineas.contains(trip)) codigosLineas.add('Tren #$trip');
    }
    String lineasTexto = codigosLineas.isEmpty ? 'Afectación general a Rodalies' : codigosLineas.join(', ');

    // 5. Transformar Marcas de Tiempo Unix a Reloj Real
    final List<dynamic> activePeriodList = alertNode['active_period'] ?? [];
    DateTime? inicio;
    DateTime? fin;
    if (activePeriodList.isNotEmpty) {
      final Map<String, dynamic> primerPeriodo = activePeriodList.first;
      final int? startUnix = int.tryParse(primerPeriodo['start']?.toString() ?? '');
      final int? endUnix = int.tryParse(primerPeriodo['end']?.toString() ?? '');
      
      if (startUnix != null && startUnix > 0) {
        inicio = DateTime.fromMillisecondsSinceEpoch(startUnix * 1000);
      }
      if (endUnix != null && endUnix > 0) {
        fin = DateTime.fromMillisecondsSinceEpoch(endUnix * 1000);
      }
    }

    return Incidencia(
      id: alertId,
      descripcion: descTexto,
      causa: causaLegible,
      efecto: efectoLegible,
      lineasAfectadas: lineasTexto,
      horaInicio: inicio,
      horaFin: fin,
    );
  }
}
