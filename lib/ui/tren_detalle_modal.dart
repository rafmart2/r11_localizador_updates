import 'package:flutter/material.dart';
import '../models/estacion_model.dart';
import '../models/tren_model.dart';
import '../services/itinerario_service.dart';

class TrenDetalleModal {
  static void mostrar({
    required BuildContext context,
    required Tren tren,
    required Estacion? estacionAnterior,
    required Estacion? estacionSiguiente,
    required List<Estacion> listaEstacionesGlobal,
    required Map<String, dynamic>? entidadComercialNode, // Recibe el JSON bruto de internet
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E24),
      isScrollControlled: true, 
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final bool tieneRetraso = tren.retrasoMinutos > 0;
        final String numeroTrenLimpio = tren.id.contains('-') ? tren.id.split('-').last : tren.id;

        String tramoLineaTexto = '';
        if (estacionAnterior != null && estacionSiguiente != null) {
          if (estacionAnterior.id == estacionSiguiente.id) {
            tramoLineaTexto = 'Llegando / Estacionado en: ${estacionAnterior.nombre}';
          } else {
            tramoLineaTexto = '${estacionAnterior.nombre} ➔ ${estacionSiguiente.nombre}';
          }
        } else {
          tramoLineaTexto = '${estacionAnterior?.nombre ?? "Origen"} ➔ ${estacionSiguiente?.nombre ?? "Destino"}';
        }

        return Padding(
          padding: EdgeInsets.only(
            top: 24.0,
            left: 24.0,
            right: 24.0,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ENCABEZADO NARANJA UNIFICADO
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${tren.tipo} #$numeroTrenLimpio', 
                    style: const TextStyle(color: Colors.orangeAccent, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: tieneRetraso ? Colors.redAccent.withValues(alpha: 0.15) : Colors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: tieneRetraso ? Colors.redAccent : Colors.greenAccent),
                    ),
                    child: Text(
                      tren.estadoTexto, 
                      style: TextStyle(color: tieneRetraso ? Colors.redAccent : Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // TRAYECTO GENERAL COMERCIAL
              Text(
                '${tren.origen} ➔ ${tren.destino}',
                style: const TextStyle(color: Colors.white70, fontSize: 11.5, fontWeight: FontWeight.w400),
              ),
              const Divider(color: Colors.white12, height: 24),

              // UBICACIÓN OPERATIVA EN LA VÍA
              const Text('POSICIÓN OPERATIVA EN LA VÍA', style: TextStyle(color: Colors.white30, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
              const SizedBox(height: 6),
              Text(tramoLineaTexto, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
              const Divider(color: Colors.white12, height: 24),

              // CUENTA ATRÁS Y LISTADO DE ESTACIONES EN TIEMPO REAL
              const Text('ITINERARIO ESTIMADO (TIEMPO REAL)', style: TextStyle(color: Colors.white30, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
              const SizedBox(height: 12),
              
              // Caja adaptable con scroll nativo para no desbordar pantallas pequeñas
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.35,
                ),
                child: SingleChildScrollView(
                  child: _construirListaParadasFuturas(tren, listaEstacionesGlobal, entidadComercialNode),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _construirListaParadasFuturas(
    Tren tren, 
    List<Estacion> estacionesEstaticas, 
    Map<String, dynamic>? entidadComercial
  ) {
    final Map<String, String> diccionarioNombres = {
      for (var est in estacionesEstaticas) est.id: est.nombre
    };

    final List<Map<String, dynamic>> proximas = ItinerarioService.obtenerProximasParadasReales(
      entidadComercial, 
      diccionarioNombres,
    );

    if (proximas.isEmpty) {
      return const Text(
        'Tren aproximándose a la estación terminal o sin paradas comerciales pendientes hoy.', 
        style: TextStyle(color: Colors.white54, fontSize: 12, fontStyle: FontStyle.italic)
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: proximas.length,
      itemBuilder: (context, index) {
        final Map<String, dynamic> parada = proximas[index];
        final String horaFormateada = parada['horaTexto'] ?? '--:--';
        final String paradasRestantes = parada['paradasRestantesText'] ?? 'Próxima parada';
        final String tiempoRestante = parada['tiempoRestanteText'] ?? 'Llegando';
        final bool esUltima = index == proximas.length - 1;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2.0),
                child: Icon(
                  esUltima ? Icons.location_on : Icons.radio_button_checked, 
                  color: esUltima ? Colors.redAccent : Colors.orangeAccent, 
                  size: 13,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(parada['nombre'], style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                        Text(
                          horaFormateada, // Hora exacta recalculada de Adif en tiempo real
                          style: TextStyle(
                            color: tren.retrasoMinutos > 0 ? Colors.redAccent : Colors.greenAccent, 
                            fontSize: 12, 
                            fontWeight: FontWeight.bold, 
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    // TEXTO DE CUENTA ATRÁS RECALCULADO (ej: Le queda 1 parada • Llegará en 4 min)
                    Text(
                      '$paradasRestantes • $tiempoRestante', 
                      style: const TextStyle(color: Colors.white30, fontSize: 10.5, fontWeight: FontWeight.w400),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
