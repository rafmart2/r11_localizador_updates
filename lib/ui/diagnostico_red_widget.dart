import 'package:flutter/material.dart';

class DiagnosticoRedWidget extends StatelessWidget {
  final bool esExitoso;
  final String mensajeError; // Recibe la descripción técnica real del fallo mecánico

  const DiagnosticoRedWidget({
    super.key,
    required this.esExitoso,
    required this.mensajeError,
  });

  // FUNCIÓN SEPARADA: Se encarga exclusivamente de levantar la ventana de diagnóstico técnico
  void _mostrarInformeDetallado(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E24),
          title: Row(
            children: [
              Icon(
                esExitoso ? Icons.check_circle : Icons.error_outline,
                color: esExitoso ? Colors.greenAccent : Colors.redAccent,
              ),
              const SizedBox(width: 10),
              const Text('Terminal de Diagnóstico', style: TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ESTADO DEL ENLACE DE RED:',
                style: TextStyle(fontSize: 10, color: Colors.white38, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
              const SizedBox(height: 6),
              Text(
                esExitoso ? 'Conexión activa y estable con https://tiempo-real.renfe.com.' : 'Enlace interrumpido con el servidor de la flota.',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              if (!esExitoso) ...[
                const SizedBox(height: 16),
                const Text(
                  'INFORME NATIVO DEL SISTEMA OPERATIVO:',
                  style: TextStyle(fontSize: 10, color: Colors.redAccent, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    mensajeError,
                    style: const TextStyle(color: Colors.redAccent, fontFamily: 'monospace', fontSize: 11),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar', style: TextStyle(color: Colors.blueAccent)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color colorLED = esExitoso ? Colors.greenAccent : Colors.redAccent;

    return GestureDetector(
      onTap: () => _mostrarInformeDetallado(context), // Captura el clic directo sobre el LED
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 14, // Ampliamos ligeramente a 14px para facilitar la pulsación táctil con el dedo
        height: 14,
        decoration: BoxDecoration(
          color: colorLED,
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(2),
          boxShadow: [
            BoxShadow(
              color: colorLED.withValues(alpha: 0.5),
              blurRadius: 4,
              spreadRadius: 1,
            )
          ],
        ),
      ),
    );
  }
}
