import '../models/tren_model.dart';

class CacheFlotaPersistente {
  // Almacén central en memoria volátil para retener la flota de la R11/RG1
  static final Map<String, Tren> _almacenMemoria = {};

  // Tiempo de cortesía exacto de 2 horas para anular desfases horarios
  static const Duration _tiempoCortesia = Duration(hours: 2);

  // INTERRUPTOR DE PRECARGA: Controla el primer milisegundo del arranque de la app
  static bool _esArranqueInicial = true;

  static List<Tren> procesarPersistenciaFlota(List<Tren> trenesNuevos) {
    final DateTime ahora = DateTime.now();
    final Set<String> idsDetectadosEnEsteCiclo = {};

    // 1. REGISTRO DE SEÑAL FRESCA:
    // Guardamos o actualizamos en el almacén los trenes que emiten señal en este ciclo
    for (var tren in trenesNuevos) {
      _almacenMemoria[tren.id] = tren;
      idsDetectadosEnEsteCiclo.add(tren.id);
    }

    // 2. DISPARADOR DE PRECARGA DE ARRANQUE:
    // Si la app se acaba de abrir, saltamos los bucles de comparación horaria 
    // y volcamos los 6 trenes de golpe al Canvas sin filtros intermedios residuales.
    if (_esArranqueInicial && trenesNuevos.isNotEmpty) {
      _esArranqueInicial = false; // Desactivamos el interruptor para los siguientes ciclos
      return trenesNuevos;
    }

    // 3. PURGA LIMPIA: El removeWhere solo borra lo que supere las 2 horas sin señal
    _almacenMemoria.removeWhere((idTren, trenHistorico) {
      if (!idsDetectadosEnEsteCiclo.contains(idTren)) {
        final Duration antiguedad = ahora.difference(trenHistorico.ultimaActualizacion);
        return antiguedad > _tiempoCortesia;
      }
      return false;
    });

    // 4. GENERACIÓN SEGURA DE LA LISTA DE SALIDA CON PERSISTENCIA ACTIVA:
    final List<Tren> listaConsolidadaSalida = [];

    _almacenMemoria.forEach((idTren, trenHistorico) {
      if (!idsDetectadosEnEsteCiclo.contains(idTren)) {
        listaConsolidadaSalida.add(
          trenHistorico.copiarConDatosComerciales(
            origen: trenHistorico.origen,
            destino: trenHistorico.destino,
            retraso: trenHistorico.retrasoMinutos,
            estado: 'Túnel / Sin cobertura GPS',
            anteriorId: trenHistorico.idEstacionAnterior,
            siguienteId: trenHistorico.idEstacionSiguiente,
          ),
        );
      } else {
        listaConsolidadaSalida.add(trenHistorico);
      }
    });

    return listaConsolidadaSalida;
  }
}
