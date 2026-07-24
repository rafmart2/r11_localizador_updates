import '../models/tren_model.dart';
import 'cache_flota_persistente.dart';
import 'extractor_retrasos_service.dart';
import 'package:flutter/material.dart';

class FusionadorFeedsGtfs {
  // IDENTIFICADORES DE RUTA OFICIALES DE LA GENERALITAT (13 = R11 | 36 = RG1)
  static const Set<String> _routesR11Girona = {'13', '36'};

  static List<Tren> fusionarYFiltrarCorredor({
    required Map<String, dynamic> jsonPosiciones,
    required Map<String, dynamic> jsonActualizaciones,
  }) {
    // 1. INDEXACIÓN COMPACTA DE ACTUALIZACIONES COMERCIALES
    final List<dynamic> entidadesUpd = jsonActualizaciones['entity'] ?? [];
    final Map<String, Map<String, dynamic>> mapaTripUpdates = {};

    for (var entidad in entidadesUpd) {
      final Map<String, dynamic> tripUpdateNode = entidad['trip_update'] ?? entidad['tripUpdate'] ?? {};
      final Map<String, dynamic> tripNode = tripUpdateNode['trip'] ?? {};
      
      final String tripId = (tripNode['trip_id'] ?? tripNode['tripId'] ?? '').toString().trim();
      if (tripId.isNotEmpty) {
        mapaTripUpdates[tripId] = entidad;
        
        // Guardamos también por número limpio para coincidencias más fáciles
        final String numeroLimpio = tripId.replaceAll(RegExp(r'[^0-9]'), '');
        if (numeroLimpio.isNotEmpty) {
          mapaTripUpdates[numeroLimpio] = entidad;
        }
      }
    }

    // 2. Extraemos el array nativo de posiciones geográficas en tiempo real
    final List<dynamic> jsonListaEntidadesPos = jsonPosiciones['entity'] ?? [];
    final List<Tren> trenesFrescosFiltrados = [];
    final DateTime ahora = DateTime.now();
    
    int totalTrenes = jsonListaEntidadesPos.length;
    int trenesR11RG1 = 0;
    int trenesEnCorredor = 0;
    int trenesFinales = 0;
    
    // 3. BUCLE MAESTRO DE AUDITORÍA DIRECTA SOBRE EL JSON BRUTO REAL
    for (var entidadPos in jsonListaEntidadesPos) {
      final String idEntidad = (entidadPos['id'] ?? '').toString();
      final Map<String, dynamic> vehicleNode = entidadPos['vehicle'] ?? {};
      
      // Estructura interna de coordenadas GPS del satélite
      final Map<String, dynamic> positionNode = vehicleNode['position'] ?? {};
      final double latitudGps = double.tryParse(positionNode['latitude']?.toString() ?? '0.0') ?? 0.0;
      final double longitudGps = double.tryParse(positionNode['longitude']?.toString() ?? '0.0') ?? 0.0;

      // Estructura interna de metadatos del viaje
      final Map<String, dynamic> tripNodeInterno = vehicleNode['trip'] ?? {};
      final String tripIdOficialRaw = (tripNodeInterno['tripId'] ?? tripNodeInterno['trip_id'] ?? idEntidad).toString();

      // ✅ CORRECCIÓN: Acceso directo a vehicle.id y vehicle.label
      final Map<String, dynamic> subVehicleNode = vehicleNode['vehicle'] ?? {};
      final String vehicleId = (subVehicleNode['id'] ?? '').toString().trim(); // ID directo del vehículo
      final String labelTren = (subVehicleNode['label'] ?? '').toString();

      // Normalizamos las cadenas a mayúsculas para el filtrado estricto
      final String idEntidadUpper = idEntidad.toUpperCase();
      final String tripIdUpper = tripIdOficialRaw.toUpperCase().trim();
      final String labelUpper = labelTren.toUpperCase();
      final String vehicleIdUpper = vehicleId.toUpperCase();
      final String routeIdOficial = (tripNodeInterno['route_id'] ?? tripNodeInterno['routeId'] ?? '').toString().trim();

      // =======================================================================
      // FILTRADO ESTRICTO EXCLUSIVO (Solo R11 y RG1)
      // =======================================================================
      final bool esTrenR11oRG1 = idEntidadUpper.contains('R11') || 
                                 idEntidadUpper.contains('RG1') ||
                                 tripIdUpper.contains('R11') ||
                                 tripIdUpper.contains('RG1') ||
                                 labelUpper.contains('R11') || 
                                 labelUpper.contains('RG1') ||
                                 vehicleIdUpper.contains('R11') ||
                                 vehicleIdUpper.contains('RG1') ||
                                 _routesR11Girona.contains(routeIdOficial);

      if (esTrenR11oRG1) {
        trenesR11RG1++;
      }

      // Candado geográfico del pasillo interior del corredor de Girona
      final bool estaEnViasCorredor = latitudGps >= 41.30 && latitudGps <= 42.50 &&
                                      longitudGps >= 2.10 && longitudGps <= 3.20;

      final bool perteneceAlCorredorR11 = esTrenR11oRG1 && estaEnViasCorredor;

      if (perteneceAlCorredorR11) {
        trenesEnCorredor++;
        
        // Purgamos misiones de talleres o vacíos
        if (labelUpper.contains('VACIO') || labelUpper.contains('MANIOBRA') || labelUpper.contains('TALLER')) {
          continue;
        }

        // =======================================================================
        // EXTRACCIÓN DIRECTA DEL NÚMERO DE TREN (id y label de Adif)
        // =======================================================================
        String numeroTrenTexto = vehicleId; // ✅ Usar el ID directo del vehículo primero
        
        if (numeroTrenTexto.isEmpty) {
          if (idEntidad.contains('-')) {
            numeroTrenTexto = idEntidad.split('-').last;
          } else if (labelTren.contains('-')) {
            numeroTrenTexto = labelTren.split('-').last;
          } else {
            numeroTrenTexto = idEntidad.replaceAll(RegExp(r'[^0-9]'), '');
          }
        }

        final int? numeroTrenPuro = int.tryParse(numeroTrenTexto.replaceAll(RegExp(r'[^0-9]'), ''));
        final String tripKey = numeroTrenPuro != null ? numeroTrenPuro.toString() : numeroTrenTexto;

        // =======================================================================
        // DETERMINACIÓN DE SENTIDO DE LA MARCHA EN CORREDOR
        // =======================================================================
        bool vaHaciaBarcelona = false;
        
        if (numeroTrenPuro != null) {
          if (numeroTrenPuro == 15820) {
            vaHaciaBarcelona = false; 
          } else {
            vaHaciaBarcelona = (numeroTrenPuro % 2 == 0); 
          }
        } else {
          vaHaciaBarcelona = tripIdUpper.contains('BARCELONA') || idEntidadUpper.contains('BARCELONA');
        }

        String origenCalculado = vaHaciaBarcelona ? 'Cerbère / Portbou' : 'Barcelona-Sants';
        String destinoCalculado = vaHaciaBarcelona ? 'Barcelona-Sants' : 'Cerbère / Portbou';

        if (tripIdUpper.contains('RG1') || routeIdOficial == '36') {
          origenCalculado = vaHaciaBarcelona ? 'Figueres-Vilafant' : 'L\'Hospitalet de Llobregat';
          destinoCalculado = vaHaciaBarcelona ? 'L\'Hospitalet de Llobregat' : 'Figueres-Vilafant';
        }

        // =======================================================================
        // SANITIZADOR DE STOP_ID NATIVO DE ADIF
        // =======================================================================
        // ✅ CORRECCIÓN: Acceso directo a vehicleNode['stopId']
        String stopIdAdifReal = (vehicleNode['stopId'] ?? vehicleNode['stop_id'] ?? '').toString().trim();

        if (stopIdAdifReal.contains('_')) {
          stopIdAdifReal = stopIdAdifReal.split('_').last;
        }

        if (stopIdAdifReal.startsWith('0') && stopIdAdifReal.length > 4) {
          if (stopIdAdifReal.startsWith('07')) {
            stopIdAdifReal = stopIdAdifReal.substring(1);
          } else if (stopIdAdifReal == '03208') {
            stopIdAdifReal = '79200';
          }
        }

        if (stopIdAdifReal.isEmpty) {
          if (latitudGps < 41.70) {
            stopIdAdifReal = '71408'; 
          } else if (latitudGps < 42.0) {
            stopIdAdifReal = '79400'; 
          } else {
            stopIdAdifReal = '79600'; 
          }
        }

        // ✅ CORRECCIÓN: Usar currentStatus (camelCase) en lugar de current_status
        final String currentStatus = (vehicleNode['currentStatus'] ?? vehicleNode['current_status'] ?? 'IN_TRANSIT_TO').toString();

        // LLAMADA AL EXTRACTOR DE RETRASOS SEGURO 
        final Map<String, dynamic> datosRetraso = ExtractorRetrasosService.extraerRetrasoReal(
          numeroTrenPuro: tripKey,
          stopIdActual: stopIdAdifReal,
          mapaTripUpdates: mapaTripUpdates,
        );

        final int minutosRetraso = datosRetraso['minutos'] ?? 0;
        final String estadoMarchaTexto = datosRetraso['texto'] ?? 'En hora';

        String anteriorAdif = stopIdAdifReal;
        String siguienteAdif = stopIdAdifReal;

        // Instanciamos el objeto Tren totalmente purificado listo para el Canvas
        trenesFrescosFiltrados.add(
          Tren(
            id: idEntidad,
            tipo: labelTren.isNotEmpty ? labelTren.split('-').first : 'R11',
            idEstacionAnterior: anteriorAdif,
            idEstacionSiguiente: siguienteAdif, 
            porcentajeTramo: currentStatus == 'STOPPED_AT' ? 0.0 : 0.5,
            retrasoMinutos: minutosRetraso,
            latitud: latitudGps,
            longitud: longitudGps,
            direccionId: vaHaciaBarcelona ? 1 : 0, 
            origen: origenCalculado,
            destino: destinoCalculado,
            estadoTexto: estadoMarchaTexto,
            ultimaActualizacion: ahora,
          ),
        );
        trenesFinales++;
      }
    }

    // Debug: Imprime estadísticas de filtrado
    debugPrint('=== ESTADÍSTICAS DE FILTRADO GTFS ===');
    debugPrint('Total trenes en JSON: $totalTrenes');
    debugPrint('Trenes R11/RG1 detectados: $trenesR11RG1');
    debugPrint('Trenes en corredor geográfico: $trenesEnCorredor');
    debugPrint('Trenes finales mostrados: $trenesFinales');
    debugPrint('=====================================');

    return CacheFlotaPersistente.procesarPersistenciaFlota(trenesFrescosFiltrados);
  }
}
