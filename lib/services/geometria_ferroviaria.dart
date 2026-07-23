import 'dart:math' as math;
import '../models/estacion_model.dart';
import '../models/tren_model.dart';

class GeometriaFerroviaria {
  
  // FUNCION 1: Fórmula de Haversine pura (Distancia física real en Km)
  double calcularDistanciaGPS(double lat1, double lon1, double lat2, double lon2) {
    const double radioTierraKm = 6371.0;
    
    double dLat = _gradosARadianes(lat2 - lat1);
    double dLon = _gradosARadianes(lon2 - lon1);
    
    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
               math.cos(_gradosARadianes(lat1)) * math.cos(_gradosARadianes(lat2)) *
               math.sin(dLon / 2) * math.sin(dLon / 2);
               
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return radioTierraKm * c;
  }

  // FUNCION 2: Proyección por Teorema del Coseno sobre tramos individuales cortos
  double calcularProgresoEnTramo(double trenLat, double trenLon, Estacion estA, Estacion estB) {
    double distanciaTotalTramo = calcularDistanciaGPS(estA.latitud, estA.longitud, estB.latitud, estB.longitud);
    if (distanciaTotalTramo == 0) return 0.0;

    double distanciaATren = calcularDistanciaGPS(estA.latitud, estA.longitud, trenLat, trenLon);
    double distanciaBTren = calcularDistanciaGPS(estB.latitud, estB.longitud, trenLat, trenLon);

    double progresoProyectado = (distanciaATren * distanciaATren + distanciaTotalTramo * distanciaTotalTramo - distanciaBTren * distanciaBTren) / 
                                (2 * distanciaTotalTramo);
    
    double porcentaje = progresoProyectado / distanciaTotalTramo;
    
    return porcentaje.clamp(0.0, 1.0);
  }

  // FUNCION 3: El cerebro del contraste de fallos (CALIBRADO Y BLINDADO CONTRA CORTES DE COBERTURA)
  double contrastarYCorregirPosicion({
    required double? trenLat,
    required double? trenLon,
    required double porcentajeTramoAdif,
    required Estacion? estacionAnterior,
    required Estacion? estacionSiguiente,
    required Map<String, Estacion> mapaEstaciones, // Añadido para resolver el tramo colateral dinámico
  }) {
    // 1. BLINDAJE Y RESCATE GEOGRÁFICO: Si el stopId viene vacío o no existe en tu listado de estaciones.json,
    // calculamos la posición lineal continua mapeando las coordenadas reales de tu estaciones.json.
    if (estacionAnterior == null || estacionSiguiente == null) {
      if (trenLat == null || trenLon == null || trenLat == 0.0) return -1.0;
      
      const double latBarcelona = 41.379220;
      const double latGirona = 41.979140;
      const double latFigueres = 42.264930;
      const double latCerbere = 42.441110;

      if (trenLat < latGirona) {
        double pct = (trenLat - latBarcelona) / (latGirona - latBarcelona);
        return 115.1 * pct.clamp(0.0, 1.0);
      } else if (trenLat < latFigueres) {
        double pct = (trenLat - latGirona) / (latFigueres - latGirona);
        return 115.1 + ((159.9 - 115.1) * pct.clamp(0.0, 1.0));
      } else {
        double pct = (trenLat - latFigueres) / (latCerbere - latFigueres);
        return 159.9 + ((168.7 - 159.9) * pct.clamp(0.0, 1.0));
      }
    }

    final Estacion estA = estacionAnterior;
    final Estacion estB = estacionSiguiente;

    // 2. CONTROL DE COBERTURA (FALLO GPS): Si el satélite pierde señal en zonas ciegas o trincheras
    if (trenLat == null || trenLon == null || (trenLat == 0.0 && trenLon == 0.0)) {
      // Si Adif ya ha saltado el ID a la próxima estación de destino (estA.id == estB.id)
      if (estA.id == estB.id) {
        // En lugar de teletransportar el tren al centro de la estación, lo dibujamos progresando en los
        // 7.6 km teóricos del tramo usando el porcentaje chivato para que no pegue el salto brusco.
        return estA.pkReal - (7.6 * (1.0 - porcentajeTramoAdif).clamp(0.0, 0.5)); 
      }
      return estA.pkReal + ((estB.pkReal - estA.pkReal) * porcentajeTramoAdif);
    }

    // 3. CONTROL DE TRAMO REPETIDO CON GPS ACTIVO: Si Adif ya marca la próxima estación pero el satélite responde
    if (estA.id == estB.id) {
      final List<Estacion> listaOrdenada = mapaEstaciones.values.toList()
        ..sort((x, y) => x.pkReal.compareTo(y.pkReal));

      int indiceActual = listaOrdenada.indexWhere((e) => e.id == estA.id);
      
      if (indiceActual != -1) {
        // Si el tren está al sur de la estación objetivo, viene desde el tramo anterior (Sils -> Caldes)
        if (trenLat < estA.latitud && indiceActual > 0) {
          final Estacion estacionOrigenReal = listaOrdenada[indiceActual - 1];
          double progresoGPS = calcularProgresoEnTramo(trenLat, trenLon, estacionOrigenReal, estA);
          return estacionOrigenReal.pkReal + ((estA.pkReal - estacionOrigenReal.pkReal) * progresoGPS);
        } 
        // Si la latitud es mayor, viene bajando desde el norte hacia Barcelona
        else if (trenLat > estA.latitud && indiceActual < listaOrdenada.length - 1) {
          final Estacion estacionDestinoReal = listaOrdenada[indiceActual + 1];
          double progresoGPS = calcularProgresoEnTramo(trenLat, trenLon, estA, estacionDestinoReal);
          return estA.pkReal + ((estacionDestinoReal.pkReal - estA.pkReal) * progresoGPS);
        }
      }
      return estA.pkReal;
    }

    // 4. CASO ESTÁNDAR: Ambos IDs de estación son diferentes y el GPS funciona con precisión quirúrgica
    double progresoGPS = calcularProgresoEnTramo(trenLat, trenLon, estA, estB);
    return estA.pkReal + ((estB.pkReal - estA.pkReal) * progresoGPS);
  }

  // FUNCION 4: Conversión final a Kilómetro lineal de vía continua (Sincronizada con la Función 3)
  double calcularKilometroLineal(Tren tren, Map<String, Estacion> mapaEstaciones) {
    final Estacion? estAnterior = mapaEstaciones[tren.idEstacionAnterior];
    final Estacion? estSiguiente = mapaEstaciones[tren.idEstacionSiguiente];

    return contrastarYCorregirPosicion(
      trenLat: tren.latitud, 
      trenLon: tren.longitud,
      porcentajeTramoAdif: tren.porcentajeTramo,
      estacionAnterior: estAnterior, 
      estacionSiguiente: estSiguiente, 
      mapaEstaciones: mapaEstaciones, // Pasamos el diccionario unificado para resolver tramos colaterales
    );
  }

  double _gradosARadianes(double grados) {
    return grados * (math.pi / 180.0);
  }
}
