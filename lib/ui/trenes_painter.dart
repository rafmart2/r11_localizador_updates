import 'package:flutter/material.dart';
import '../models/estacion_model.dart';
import '../models/tren_model.dart';
import '../services/geometria_ferroviaria.dart';
import '../services/separador_textos_service.dart'; // Importación unificada del nuevo servicio de empuje

class TrenesPainter extends CustomPainter {
  final List<Estacion> estaciones;
  final List<Tren> trenes;
  final double escalaPxPorKm;
  
  static const double ejeXLinea = 160.0;
  static const double colchonVertical = 20.0;

  TrenesPainter({
    required this.estaciones,
    required this.trenes,
    required this.escalaPxPorKm,
  });

  @override
  void paint(Canvas canvas, Size size) {
    double alturaUtilConColchon = size.height - (colchonVertical * 2);
    double escalaAjustada = alturaUtilConColchon / 168.7;

    final geometria = GeometriaFerroviaria();
    
    final Map<String, Estacion> mapaEstaciones = {
      for (var est in estaciones) est.id: est
    };

    // 1. PRIMERA PASADA: Calculamos la coordenada Y física real de cada tren en la recta
    final Map<String, double> mapaPosicionesY = {};
    for (var tren in trenes) {
      double kilometroReal = geometria.calcularKilometroLineal(tren, mapaEstaciones);
      if (kilometroReal >= 0) {
        double trenY = (size.height - colchonVertical) - (kilometroReal * escalaAjustada);
        mapaPosicionesY[tren.id] = trenY;
      }
    }

    // 2. SEGUNDA PASADA: Pintamos invocando la función independiente de desvío
    for (var tren in trenes) {
      final double? trenYFisico = mapaPosicionesY[tren.id];
      
      if (trenYFisico != null) {
        // LLAMADA AL NUEVO SERVICIO EXTERNO: Toda la matemática de colisiones sale del pintor
        double desvioYTextoCalculado = SeparadorTextosService.calcularDesvioVerticalTexto(
          trenId: tren.id,
          direccionId: tren.direccionId,
          trenYFisico: trenYFisico,
          mapaPosicionesY: mapaPosicionesY,
          listaTodosLosTrenes: trenes,
        );

        // Invocamos el renderizado pasando el desvío exclusivo del texto (Bloque 2)
        _dibujarTrenConDireccion(canvas, size, tren, trenYFisico, desvioYTextoCalculado, mapaEstaciones);
      }
    }
  }
  void _dibujarTrenConDireccion(
    Canvas canvas, 
    Size size, 
    Tren tren, 
    double trenYReal, 
    double desvioYTexto, 
    Map<String, Estacion> mapaEstaciones,
  ) {
    final paintTren = Paint()
      ..color = Colors.orangeAccent 
      ..style = PaintingStyle.fill;

    // EL CÍRCULO SE QUEDA FIJO: Mantiene la coordenada X e Y GPS real de la vía sin inmutarse
    double trenX = ejeXLinea + 15.0;
    canvas.drawCircle(Offset(trenX, trenYReal), 4.5, paintTren);

    bool vaHaciaCerbere = tren.direccionId == 0;

    final paintFlecha = Paint()
      ..color = Colors.orangeAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final Path pathFlecha = Path();
    double flechaX = trenX + 10.0; 

    // LA FLECHA SE QUEDA FIJA: Sigue apuntando al lado del círculo real del tren
    if (vaHaciaCerbere) {
      pathFlecha.moveTo(flechaX - 3, trenYReal + 2);
      pathFlecha.lineTo(flechaX, trenYReal - 2);
      pathFlecha.lineTo(flechaX + 3, trenYReal + 2);
      pathFlecha.moveTo(flechaX, trenYReal + 4);
      pathFlecha.lineTo(flechaX, trenYReal - 2);
    } else {
      pathFlecha.moveTo(flechaX - 3, trenYReal - 2);
      pathFlecha.lineTo(flechaX, trenYReal + 2);
      pathFlecha.lineTo(flechaX + 3, trenYReal - 2);
      pathFlecha.moveTo(flechaX, trenYReal - 4);
      pathFlecha.lineTo(flechaX, trenYReal + 2);
    }
    canvas.drawPath(pathFlecha, paintFlecha);

    // 1. FILTRADO DEL NOMBRE REAL (ej: 15866)
    final String numeroTrenLimpio = tren.id.contains('-') ? tren.id.split('-').last : tren.id;

    // 2. CONSTRUCCIÓN DE LA STRING DE TEXTO REAL
    String infoTrenTexto = numeroTrenLimpio;
    if (tren.estadoTexto.isNotEmpty && tren.estadoTexto.trim() != '""') {
      infoTrenTexto += ' (${tren.estadoTexto})';
    }

    final Estacion? proxEstacionObjeto = mapaEstaciones[tren.idEstacionSiguiente];
    if (proxEstacionObjeto != null && proxEstacionObjeto.nombre.isNotEmpty) {
      infoTrenTexto += ' ➔ ${proxEstacionObjeto.nombre}';
    }

    final trenTextPainter = TextPainter(
      text: TextSpan(
        text: infoTrenTexto,
        style: const TextStyle(
          color: Colors.orangeAccent,
          fontSize: 8.5,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.start,
    );
    
    double textoXPos = flechaX + 8.0;
    trenTextPainter.layout(maxWidth: size.width - textoXPos - 10);
    
    // EL TEXTO SE COMPORTA DE FORMA ELÁSTICA: 
    // Sumamos el desvioYTexto calculado por tu nueva función independiente
    double posYTextoCalculada = trenYReal - (trenTextPainter.height / 2) + desvioYTexto;

    trenTextPainter.paint(canvas, Offset(textoXPos, posYTextoCalculada));
  }

  @override
  bool shouldRepaint(covariant TrenesPainter oldDelegate) {
    return oldDelegate.trenes != trenes || oldDelegate.escalaPxPorKm != escalaPxPorKm;
  }
}
