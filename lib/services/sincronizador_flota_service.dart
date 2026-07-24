import '../models/tren_model.dart';
import '../models/incidencia_model.dart';
import '../models/estacion_model.dart';
import 'tren_service.dart';
import 'incidencias_service.dart';
import 'linea_service.dart';

/// Clase contenedora que encapsula la respuesta unificada y purificada de la red
class ResultadoSincronizacion {
  final bool esExitoso;
  final String estadoConexion;
  final List<Tren> trenes;
  final Incidencia? incidencia;
  final List<Estacion> estaciones;

  ResultadoSincronizacion({
    required this.esExitoso,
    required this.estadoConexion,
    required this.trenes,
    this.incidencia,
    this.estaciones = const [],
  });
}

class SincronizadorFlotaService {
  final TrenService _trenService = TrenService();
  final IncidenciasService _incidenciasService = IncidenciasService();
  final LineaService _lineaService = LineaService();

  /// El núcleo del orquestador: Descarga y fusiona ambos feeds en el mismo milisegundo de red
  Future<ResultadoSincronizacion> ejecutarSincronizacionCombinada(Set<String> idsEstaciones) async {
    try {
      // Cargamos estaciones
      final estacionesFuture = _lineaService.cargarEstaciones();

      // Disparamos ambas peticiones HTTP de producción de forma simultánea en hilos concurrentes
      final List<dynamic> respuestas = await Future.wait([
        _trenService.consultarTrenesActivos(idsEstaciones),
        _incidenciasService.consultarIncidenciasR11(),
      ]);

      // Obtenemos las estaciones
      final estaciones = await estacionesFuture;

      // SOLUCIÓN AL BLOQUEO DE OBJECT: Desempaquetamos la primera posición (Trenes) 
      final dynamic respuestaTrenes = respuestas[0];
      
      // Desempaquetamos la segunda posición (Incidencias) casteando su estructura de forma segura.
      final Incidencia? avisoObjeto = respuestas[1] as Incidencia?;

      // Aplicamos el filtro estricto de tiempo para fulminar trenes fantasma de la caché
      final DateTime limiteTiempo = DateTime.now().subtract(const Duration(minutes: 2));
      List<Tren> trenesFiltrados = [];
      
      if (respuestaTrenes != null) {
        final List<dynamic> trenesBrutos = respuestaTrenes.trenes ?? [];
        
        // Filtramos por minutos y forzamos el casteo estricto hacia el modelo final
        trenesFiltrados = trenesBrutos.where((tren) {
          return tren.ultimaActualizacion.isAfter(limiteTiempo);
        }).cast<Tren>().toList();
      }

      // Devolvemos el contenedor unificado directo para el setState de la pantalla
      return ResultadoSincronizacion(
        esExitoso: respuestaTrenes?.esExitoso ?? false,
        estadoConexion: respuestaTrenes?.estadoConexion ?? 'Vías Libres',
        trenes: trenesFiltrados,
        incidencia: avisoObjeto,
        estaciones: estaciones,
      );
    } catch (e) {
      return ResultadoSincronizacion(
        esExitoso: false,
        estadoConexion: 'Fallo crítico en el orquestador de red: ${e.toString()}',
        trenes: [],
        incidencia: null,
        estaciones: [],
      );
    }
  }
}
