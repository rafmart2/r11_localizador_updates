import 'package:flutter/material.dart';

class IncidenciasCintilloWidget extends StatelessWidget {
  final bool hayIncidenciaReal;
  final String incidenciaTexto;
  final VoidCallback alPulsarBarra;

  const IncidenciasCintilloWidget({
    super.key,
    required this.hayIncidenciaReal,
    required this.incidenciaTexto,
    required this.alPulsarBarra,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: alPulsarBarra,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: hayIncidenciaReal 
              ? Colors.red.withValues(alpha: 0.25) 
              : Colors.green.withValues(alpha: 0.15),
          border: Border(
            top: BorderSide(
              color: hayIncidenciaReal ? Colors.redAccent : Colors.green, 
              width: 1.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              hayIncidenciaReal ? Icons.warning_amber_rounded : Icons.check_circle_outline, 
              color: hayIncidenciaReal ? Colors.redAccent : Colors.greenAccent, 
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                incidenciaTexto,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.keyboard_arrow_up_rounded, color: Colors.white38, size: 18),
          ],
        ),
      ),
    );
  }
}
