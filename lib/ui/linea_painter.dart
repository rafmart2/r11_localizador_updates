import 'package:flutter/material.dart';
import '../models/estacion_model.dart';

class LineaPainter extends CustomPainter {
  final List<Estacion> estaciones;
  final double escalaPxPorKm;

  static const double ejeXLinea = 160.0;
  static const double colchonVertical = 20.0;

  LineaPainter({
    required this.estaciones,
    required this.escalaPxPorKm,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintEje = Paint()
      ..color = Colors.blueAccent
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final paintEstacionCircle = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final paintEstacionBorde = Paint()
      ..color = Colors.blueAccent
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // 1. DIBUJAR EL EJE PRINCIPAL DE LA VÍA CON COLCHÓN
    double alturaUtilConColchon = size.height - (colchonVertical * 2);
    double escalaAjustada = alturaUtilConColchon / 168.7;

    double km0Y = size.height - colchonVertical; 
    double km168Y = colchonVertical; 
    canvas.drawLine(Offset(ejeXLinea, km0Y), Offset(ejeXLinea, km168Y), paintEje);

    // 2. RENDERIZAR LAS ESTACIONES CON LA TABLA DE ALTURAS FIJAS DEL NORTE
    for (var est in estaciones) {
      // El círculo blanco de Adif se queda clavado en su coordenada física kilométrica real
      double estacionY = (size.height - colchonVertical) - (est.pkReal * escalaAjustada);

      canvas.drawCircle(Offset(ejeXLinea, estacionY), 5.0, paintEstacionCircle);
      canvas.drawCircle(Offset(ejeXLinea, estacionY), 5.0, paintEstacionBorde);

      final textPainter = TextPainter(
        text: TextSpan(
          text: est.nombre,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10.0,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      // TABLA DE COMPENSACIÓN ESTRICTA: 
      // Vilamalla se queda en su sitio real (0.0). A partir de ella, los nombres van subiendo
      // de forma consecutiva restando los píxeles exactos de la caja de texto para que queden pegados.
      double desplaceVerticalY = 0.0;
      final String nombreUpper = est.nombre.toUpperCase();

      if (nombreUpper.contains('VILAMALLA')) {
        desplaceVerticalY = 0.0;   // CLAVADA EN SU SITIO REAL EXACTO
      } else if (nombreUpper.contains('FIGUERES')) {
        desplaceVerticalY = -0.0;  // Sube una fila exacta respecto a Vilamalla
      } else if (nombreUpper.contains('VILAJU')) {
        desplaceVerticalY = -0.2;  // Sube dos filas exactas
      } else if (nombreUpper.contains('PORT DE LA SELVA')) {
        desplaceVerticalY = -0.5;  // Sube tres filas exactas
      } else if (nombreUpper.contains('LLAN')) {
        desplaceVerticalY = -0.5;  // Sube cuatro filas exactas
      } else if (nombreUpper.contains('COLERA')) {
        desplaceVerticalY = -0.6;  // Sube cinco filas exactas
      } else if (nombreUpper.contains('PORTBOU')) {
        desplaceVerticalY = -5.5;  // Sube seis filas exactas
      } else if (nombreUpper.contains('CERBERE') || nombreUpper.contains('CERBÈRE')) {
        desplaceVerticalY = -11.5;  // Sube siete filas exactas, coronando la cima de forma visible
      }

      // ALINEACIÓN IZQUIERDA PURA: Todos los textos limpios en columna antes de la vía
      double posXTexto = ejeXLinea - textPainter.width - 15.0;
      double posYTexto = estacionY - (textPainter.height / 2) + desplaceVerticalY;

      // Amortiguador de seguridad final para que Cerbère nunca se salga por el techo del Canvas
      if (posYTexto < 6.0) {
        posYTexto = 6.0;
      }

      textPainter.paint(canvas, Offset(posXTexto, posYTexto));
    }
  }

  @override
  bool shouldRepaint(covariant LineaPainter oldDelegate) {
    return oldDelegate.estaciones != estaciones || oldDelegate.escalaPxPorKm != escalaPxPorKm;
  }
}
