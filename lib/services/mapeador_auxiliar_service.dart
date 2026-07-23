import '../models/estacion_model.dart';

class MapeadorAuxiliarService {
  /// Devuelve el mapa completo indexado que requiere el calculador geométrico
  /// mapeando de forma idéntica las coordenadas físicas de tu infraestructura.
  static Map<String, Estacion> generarMapaEstacionesAux(List<Estacion> estacionesEstaticas) {
    final Map<String, Estacion> mapaFijo = {};
    
    for (var est in estacionesEstaticas) {
      mapaFijo[est.id] = est;
      mapaFijo[est.nombre] = est;
    }
    
    return mapaFijo;
  }
}
