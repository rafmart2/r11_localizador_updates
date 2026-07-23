import 'package:flutter/material.dart';
import '../models/incidencia_model.dart';

class IncidenciasDetalleModal { // CORRECCIÓN CLAVE: Sincronizado a "Detalle" en castellano
  static void mostrar({
    required BuildContext context,
    required Incidencia incidencia,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E24),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        String formatearHora(DateTime? dt) {
          if (dt == null) return '--:--';
          return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} h';
        }

        return Padding(
          padding: EdgeInsets.only(
            left: 24.0, 
            right: 24.0, 
            top: 24.0, 
            bottom: MediaQuery.of(context).viewInsets.bottom + 24.0
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'ALERTA OFICIAL REVELADA: #${incidencia.id}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(color: Colors.white24, height: 24),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CAUSA RAÍZ ADIF: ${incidencia.causa}',
                      style: const TextStyle(color: Colors.orangeAccent, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'IMPACTO ACTUAL: ${incidencia.efecto}',
                      style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'AFECTACIÓN: ${incidencia.lineasAfectadas}',
                      style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w400),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'VIGENCIA: Desde ${formatearHora(incidencia.horaInicio)}',
                      style: const TextStyle(color: Colors.white38, fontSize: 10, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'DESCRIPCIÓN TEXTUAL EN CRUDO:',
                style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: SingleChildScrollView(
                  child: Text(
                    incidencia.descripcion,
                    style: const TextStyle(
                      color: Colors.white, 
                      fontSize: 13,
                      height: 1.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              const Text(
                'Servidor de alertas: ://renfe.com',
                style: TextStyle(
                  color: Colors.white30,
                  fontSize: 9,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
