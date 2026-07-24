import 'package:flutter/material.dart';
import '../models/estacion_model.dart';
import '../models/tren_model.dart';
import '../services/itinerario_service.dart';
import '../services/tren_service.dart';

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

        // Intentamos obtener el nodo comercial si no fue pasado
        var nodoComercial = entidadComercialNode ?? TrenService.obtenerNodoComercialDelTren(numeroTrenLimpio);

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
                      tieneRetraso ? '${tren.retrasoMinutos}min de retraso' : 'En hora', 
                      style: TextStyle(color: tieneRetraso ? Colors.redAccent : Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // TRAYECTO GENERAL COMERCIAL (Origen ➔ Destino)
              Text(
                '${tren.origen} ➔ ${tren.destino}',
                style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
              ),
              const Divider(color: Colors.white12, height: 24),

              // UBICACIÓN OPERATIVA EN LA VÍA
              const Text('POSICIÓN OPERATIVA EN LA VÍA', style: TextStyle(color: Colors.white30, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
              const SizedBox(height: 6),
              Text(tramoLineaTexto, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
              const Divider(color: Colors.white12, height: 24),

              // RUTA COMPLETA Y PRÓXIMAS PARADAS
              const Text('RUTA COMPLETA DEL VIAJE', style: TextStyle(color: Colors.white30, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
              const SizedBox(height: 12),
              
              // Caja adaptable con scroll nativo para no desbordar pantallas pequeñas
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.40,
                ),
                child: SingleChildScrollView(
                  child: _construirListaRutaCompletaYProximas(tren, listaEstacionesGlobal, nodoComercial),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _construirListaRutaCompletaYProximas(
    Tren tren, 
    List<Estacion> estacionesEstaticas, 
    Map<String, dynamic>? entidadComercial
  ) {
    final Map<String, String> diccionarioNombres = {
      for (var est in estacionesEstaticas) est.id: est.nombre
    };

    // Obtenemos TODAS las paradas del viaje
    final List<Map<String, dynamic>> todasLasParadas = ItinerarioService.obtenerTodasLasParadas(
      entidadComercial, 
      diccionarioNombres,
    );

    if (todasLasParadas.isEmpty) {
      return const Text(
        'No hay información de paradas disponible. El servidor de Adif podría estar sin datos para este tren.', 
        style: TextStyle(color: Colors.white54, fontSize: 12, fontStyle: FontStyle.italic)
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: todasLasParadas.length,
      itemBuilder: (context, index) {
        final Map<String, dynamic> parada = todasLasParadas[index];
        final String horaFormateada = parada['horaTexto'] ?? '--:--';
        final bool esParadaPasada = parada['esParadaPasada'] as bool? ?? false;
        final bool esUltima = index == todasLasParadas.length - 1;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2.0),
                child: Icon(
                  esUltima ? Icons.location_on : (esParadaPasada ? Icons.check_circle : Icons.radio_button_checked), 
                  color: esUltima ? Colors.redAccent : (esParadaPasada ? Colors.white30 : Colors.orangeAccent), 
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
                        Text(
                          parada['nombre'], 
                          style: TextStyle(
                            color: esParadaPasada ? Colors.white30 : Colors.white, 
                            fontSize: 12, 
                            fontWeight: FontWeight.bold,
                            decoration: esParadaPasada ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        Text(
                          horaFormateada,
                          style: TextStyle(
                            color: esParadaPasada ? Colors.white30 : (tren.retrasoMinutos > 0 ? Colors.redAccent : Colors.greenAccent), 
                            fontSize: 11, 
                            fontWeight: FontWeight.bold, 
                            fontFamily: 'monospace',
                            decoration: esParadaPasada ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ],
                    ),
                    if (!esParadaPasada) ...[
                      const SizedBox(height: 2),
                      Text(
                        'En ${parada['minutosFaltan']} minutos', 
                        style: const TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.w400),
                      ),
                    ]
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
