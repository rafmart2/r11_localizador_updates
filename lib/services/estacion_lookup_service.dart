import 'dart:math';
import '../models/estacion_model.dart';
import '../models/tren_model.dart';

/// Servicio de búsqueda de estaciones adyacentes basado en posición GPS
/// Resuelve el problema de IDs de estación faltantes en los modelos de tren
class EstacionLookupService {
  
  /// Encuentra las estaciones anterior y siguiente para un tren según su latitud
  /// Retorna un mapa con las claves 'anterior' y 'siguiente'
  static Map<String, String> encontrarEstacionesAdyacentes(
    Tren tren,
    List<Estacion> estaciones,
  ) {
    if (estaciones.isEmpty) {
      return {'anterior': 'AUTO_START', 'siguiente': 'AUTO_END'};
    }

    // Ordenamos las estaciones por su kilómetro real (pkReal)
    final sorted = estaciones.toList()
      ..sort((a, b) => a.pkReal.compareTo(b.pkReal));

    String anterior = sorted.first.id;
    String siguiente = sorted.first.id;

    // Buscamos entre qué estaciones se encuentra el tren según su latitud
    for (int i = 0; i < sorted.length - 1; i++) {
      final estA = sorted[i];
      final estB = sorted[i + 1];
      
      // Determinamos los límites basados en la latitud
      final minLat = estA.latitud < estB.latitud ? estA.latitud : estB.latitud;
      final maxLat = estA.latitud > estB.latitud ? estA.latitud : estB.latitud;

      if (tren.latitud >= minLat && tren.latitud <= maxLat) {
        anterior = estA.id;
        siguiente = estB.id;
        break;
      }
    }

    // Si el tren está fuera de rango, asignamos las estaciones extremas
    if (tren.latitud < sorted.first.latitud) {
      anterior = sorted.first.id;
      siguiente = sorted.first.id;
    } else if (tren.latitud > sorted.last.latitud) {
      anterior = sorted.last.id;
      siguiente = sorted.last.id;
    }

    return {'anterior': anterior, 'siguiente': siguiente};
  }

  /// Encuentra la estación más cercana al tren por distancia GPS
  static Estacion? encontrarEstacionMasCercana(
    Tren tren,
    List<Estacion> estaciones,
  ) {
    if (estaciones.isEmpty) return null;

    Estacion? masProxima;
    double distanciaMinima = double.infinity;

    for (var estacion in estaciones) {
      // Aproximación rápida usando diferencia de latitud/longitud
      final diffLat = (tren.latitud - estacion.latitud).abs();
      final diffLon = (tren.longitud - estacion.longitud).abs();
      final distanciaAproximada = sqrt(diffLat * diffLat + diffLon * diffLon);

      if (distanciaAproximada < distanciaMinima) {
        distanciaMinima = distanciaAproximada;
        masProxima = estacion;
      }
    }

    return masProxima;
  }
}
