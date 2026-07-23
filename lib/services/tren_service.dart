import 'dart:convert';
import 'cliente_http_renfe.dart';
import '../models/tren_model.dart';
import 'fusionador_feeds_gtfs.dart';

class TrenService {
  // =======================================================================
  // ALMACÉN GLOBAL DE ACTUALIZACIONES COMERCIALES (Persistencia RAM)
  // =======================================================================
  // Guardamos una copia estática del mapa de horarios para que el detector 
  // táctil de la pantalla principal pueda leer las paradas futuras en vivo.
  static final Map<String, dynamic> mapaTripUpdatesUltimoCiclo = {};

  // DIRECCIONES OFICIALES DE PRODUCCIÓN CORREGIDAS Y RESTAURADAS
  final String _urlPosiciones = 'https://gtfsrt.renfe.com/vehicle_positions.json';
  final String _urlActualizaciones = 'https://gtfsrt.renfe.com/trip_updates.json';

  /// Descarga los ficheros en vivo y actualiza la matriz de horarios comerciales
  Future<RespuestaFlota> consultarTrenesActivos(Set<String> idsEstaciones) async {
    try {
      // Lanzamos las peticiones HTTP concurrentes usando tu cliente de producción
      final respuestas = await Future.wait([
        ClienteHttpRenfe.get(_urlPosiciones),
        ClienteHttpRenfe.get(_urlActualizaciones),
      ]);

      final responsePos = respuestas[0];
      final responseUpd = respuestas[1];

      if (responsePos.statusCode == 200 && responseUpd.statusCode == 200) {
        final Map<String, dynamic> jsonPos = json.decode(responsePos.body);
        final Map<String, dynamic> jsonUpd = json.decode(responseUpd.body);

        // =======================================================================
        // PERSISTENCIA EN CALIENTE DE LA MATRIZ DE HORARIOS
        // =======================================================================
        // Limpiamos el almacén del ciclo anterior para no arrastrar trenes pasados
        mapaTripUpdatesUltimoCiclo.clear();

        final List<dynamic> entidadesUpd = jsonUpd['entity'] ?? jsonUpd['Entity'] ?? [];
        for (var entidad in entidadesUpd) {
          if (entidad == null) {
            continue;
          }
          
          final Map<String, dynamic> tripUpdateNode = entidad['trip_update'] ?? entidad['tripUpdate'] ?? {};
          final Map<String, dynamic> tripNode = tripUpdateNode['trip'] ?? {};
          final String tripId = (tripNode['trip_id'] ?? tripNode['tripId'] ?? '').toString().trim();
          
          if (tripId.isNotEmpty) {
            // Guardamos el nodo indexado por su identificador oficial largo de Adif
            mapaTripUpdatesUltimoCiclo[tripId] = entidad;

            // Guardamos también una réplica limpia por número de tren puro (ej: 15918)
            final String tripKey = tripId.contains('-') ? tripId.split('-').last : tripId;
            mapaTripUpdatesUltimoCiclo[tripKey] = entidad;
          }
        }

        // Invocamos a tu fusionador purificado para filtrar la R11 y RG1
        final List<Tren> trenesFiltrados = FusionadorFeedsGtfs.fusionarYFiltrarCorredor(
          jsonPosiciones: jsonPos,
          jsonActualizaciones: jsonUpd,
        );

        return RespuestaFlota(
          esExitoso: true,
          estadoConexion: 'Vías Libres',
          trenes: trenesFiltrados,
        );
      }

      return RespuestaFlota(
        esExitoso: false, 
        estadoConexion: 'Error de servidor HTTP: ${responsePos.statusCode} / ${responseUpd.statusCode}', 
        trenes: [],
      );
    } catch (e) {
      return RespuestaFlota(
        esExitoso: false, 
        estadoConexion: 'Fallo crítico en descarga de flota: ${e.toString()}', 
        trenes: [],
      );
    }
  }
}

/// Contenedor auxiliar de respuesta de tu servicio
class RespuestaFlota {
  final bool esExitoso;
  final String estadoConexion;
  final List<Tren> trenes;

  RespuestaFlota({
    required this.esExitoso, 
    required this.estadoConexion, 
    required this.trenes,
  });
}
